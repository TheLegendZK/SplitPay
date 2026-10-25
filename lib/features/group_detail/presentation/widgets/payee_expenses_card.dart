import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/features/group_detail/domain/expense.dart';
import 'package:splitpay/shared/widgets/splitpay_card.dart';

class PayeeExpensesCard extends ConsumerWidget {
  const PayeeExpensesCard({super.key, required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realExpenses = expenses
        .where((item) => item.type != 'settlement')
        .toList();

    final totalExpense = realExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final Map<String, List<Expense>> expensesByPayer = {};
    for (final expense in expenses) {
      expensesByPayer.putIfAbsent(expense.memberUid, () => []).add(expense);
    }

    return SplitPayCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Expenses',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.01,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '\$$totalExpense',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.03,
                  color: Color(0xFF0F172A),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          ...expensesByPayer.entries.map((entry) {
            return _PayeeExpenseSection(
              memberUid: entry.key,
              expenses: entry.value,
            );
          }),
        ],
      ),
    );
  }
}

class _PayeeExpenseSection extends ConsumerWidget {
  const _PayeeExpenseSection({required this.memberUid, required this.expenses});

  final String memberUid;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberNameAsync = ref.watch(memberNameProvider(memberUid));
    final memberTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              memberNameAsync.when(
                data: (name) => Text(
                  'Paid by $name',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: name == 'You'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF0F172A),
                  ),
                ),
                loading: () => const Text(
                  'Paid by Loading...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                error: (_, _) => const Text(
                  'Paid by Unknown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Text(
                'Subtotal: \$$memberTotal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
