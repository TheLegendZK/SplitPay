import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/domain/expense.dart';
import 'package:splitpay/features/settlements/domain/settlement.dart';

class SettlementParams {
  const SettlementParams({
    required this.memberUids,
    required this.expenses,
    this.memberShares = const {},
  });

  final List<String> memberUids;
  final List<Expense> expenses;
  final Map<String, int> memberShares;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementParams &&
          runtimeType == other.runtimeType &&
          _listEquals(memberUids, other.memberUids) &&
          _listEquals(expenses, other.expenses) &&
          _mapEquals(memberShares, other.memberShares);

  @override
  int get hashCode => Object.hashAll([
    ...memberUids,
    ...expenses,
    ...memberShares.entries.map((e) => Object.hash(e.key, e.value)),
  ]);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

class SettlementCalculator {
  /// Computes the minimal number of transactions required to settle all debts,
  /// weighted by each member's share count (e.g., 1 = solo, 2 = couple).
  static List<Settlement> calculate({
    required List<String> memberUids,
    required List<Expense> expenses,
    Map<String, int> memberShares = const {},
  }) {
    if (memberUids.length < 2 || expenses.isEmpty) {
      return const [];
    }

    // Total headcount across all accounts (defaulting to 1 share per member)
    final int totalShares = memberUids.fold<int>(
      0,
      (sum, uid) => sum + (memberShares[uid] ?? 1),
    );
    if (totalShares <= 0) return const [];

    // 1. Initialize balance map for each member
    final Map<String, double> balances = {
      for (final uid in memberUids) uid: 0.0,
    };

    // 2. Compute net balances: Paid - Weighted Fair Share
    for (final expense in expenses) {
      if (expense.type == 'settlement') {
        balances[expense.memberUid] =
            (balances[expense.memberUid] ?? 0.0) + expense.amount;
        if (expense.settlementToUid != null) {
          balances[expense.settlementToUid!] =
              (balances[expense.settlementToUid!] ?? 0.0) - expense.amount;
        }
      } else {
        final costPerShare = expense.amount / totalShares;

        // Each member owes according to their share count (1x, 2x, etc.)
        for (final uid in memberUids) {
          final userShares = memberShares[uid] ?? 1;
          balances[uid] = (balances[uid] ?? 0.0) - (costPerShare * userShares);
        }

        // Credited to the person who paid the expense
        balances[expense.memberUid] =
            (balances[expense.memberUid] ?? 0.0) + expense.amount;
      }
    }

    // 3. Separate members into Debtors (< 0) and Creditors (> 0)
    final List<_BalanceEntry> debtors = [];
    final List<_BalanceEntry> creditors = [];

    balances.forEach((uid, balance) {
      if (balance < -0.01) {
        debtors.add(_BalanceEntry(uid, -balance));
      } else if (balance > 0.01) {
        creditors.add(_BalanceEntry(uid, balance));
      }
    });

    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final List<Settlement> settlements = [];
    int debtorIndex = 0;
    int creditorIndex = 0;

    // 4. Match debtors to creditors greedily
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];

      final settleAmount = debtor.amount < creditor.amount
          ? debtor.amount
          : creditor.amount;

      if (settleAmount > 0.01) {
        settlements.add(
          Settlement(
            debtorUid: debtor.uid,
            creditorUid: creditor.uid,
            amount: double.parse(settleAmount.toStringAsFixed(2)),
          ),
        );
      }

      debtor.amount -= settleAmount;
      creditor.amount -= settleAmount;

      if (debtor.amount <= 0.01) debtorIndex++;
      if (creditor.amount <= 0.01) creditorIndex++;
    }

    return settlements;
  }
}

class _BalanceEntry {
  _BalanceEntry(this.uid, this.amount);

  final String uid;
  double amount;
}

final settlementsProvider = Provider.family<List<Settlement>, SettlementParams>(
  (ref, params) {
    return SettlementCalculator.calculate(
      memberUids: params.memberUids,
      expenses: params.expenses,
      memberShares: params.memberShares,
    );
  },
);
