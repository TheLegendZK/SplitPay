import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/features/settlements/domain/settlement.dart';
import 'package:splitpay/shared/widgets/async_elevated_button.dart';
import 'package:splitpay/shared/widgets/splitpay_card.dart';

class SettlementCard extends ConsumerWidget {
  const SettlementCard({
    super.key,
    required this.settlement,
    required this.groupId,
  });

  final Settlement settlement;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtorNameAsync = ref.watch(memberNameProvider(settlement.debtorUid));
    final creditorNameAsync = ref.watch(
      memberNameProvider(settlement.creditorUid),
    );
    final currentUserUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isCreditor = currentUserUid == settlement.creditorUid;

    return SplitPayCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: _PartyColumn(
                    role: 'Owes',
                    roleColor: const Color(0xFFB91C1C),
                    roleBgColor: const Color(0xFFFEF2F2),
                    nameAsync: debtorNameAsync,
                    statusText: 'owes',
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\$${settlement.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _PartyColumn(
                    role: 'Gets Back',
                    roleColor: const Color(0xFF047857),
                    roleBgColor: const Color(0xFFECFDF5),
                    nameAsync: creditorNameAsync,
                    statusText: 'receives',
                  ),
                ),
              ],
            ),
          ),
          if (isCreditor)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: AsyncElevatedButton(
                  onPressed: () {
                    ref
                        .read(expenseControllerProvider.notifier)
                        .settleDebt(
                          groupId: groupId,
                          debtorUid: settlement.debtorUid,
                          creditorUid: settlement.creditorUid,
                          amount: settlement.amount,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text('Mark Settled'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartyColumn extends StatelessWidget {
  const _PartyColumn({
    required this.role,
    required this.roleColor,
    required this.roleBgColor,
    required this.nameAsync,
    required this.statusText,
  });

  final String role;
  final Color roleColor;
  final Color roleBgColor;
  final AsyncValue<String> nameAsync;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: roleBgColor,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: roleColor,
              letterSpacing: 0.06,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: nameAsync.when(
            data: (name) => Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            loading: () => const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) =>
                const Icon(Icons.person, size: 18, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 6),
        nameAsync.when(
          data: (name) => Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          loading: () => const Text(
            'Loading...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          error: (_, _) => const Text(
            'Unknown',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Text(
          statusText,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
