import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';

class ExpensePayerSubtitle extends ConsumerWidget {
  const ExpensePayerSubtitle({super.key, required this.memberUid});

  final String memberUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payerAsync = ref.watch(memberNameProvider(memberUid));

    return payerAsync.when(
      data: (name) => Text(
        'Paid by $name',
        style: TextStyle(
          fontSize: 14,
          color: name == 'You' ? const Color(0xFF10B981) : const Color(0xFF64748B),
          fontWeight: name == 'You' ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      loading: () => const Text(
        'Loading...',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
      error: (_, _) => const Text(
        'Paid by unknown',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }
}
