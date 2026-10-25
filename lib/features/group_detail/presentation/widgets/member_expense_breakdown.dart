import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/features/group_detail/domain/expense.dart';

class MemberExpenseBreakdown extends ConsumerWidget {
  const MemberExpenseBreakdown({super.key, required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberTotals = <String, double>{};
    for (final expense in expenses) {
      memberTotals[expense.memberUid] =
          (memberTotals[expense.memberUid] ?? 0) + expense.amount;
    }

    return Column(
      children: memberTotals.entries.map((entry) {
        final memberNameAsync = ref.watch(memberNameProvider(entry.key));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              memberNameAsync.when(
                data: (name) => Text(name),
                loading: () => const Text('Loading...'),
                error: (_, _) => const Text('Unknown'),
              ),
              Text(
                '\$${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
