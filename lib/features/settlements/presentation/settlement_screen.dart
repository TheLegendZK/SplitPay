import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/features/groups/domain/group.dart';
import 'package:splitpay/features/settlements/data/settlements_provider.dart';
import 'package:splitpay/features/settlements/presentation/settlement_card.dart';

class SettlementScreen extends ConsumerWidget {
  const SettlementScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(group.uid));

    return Scaffold(
      appBar: AppBar(title: Text('${group.name} Settlements')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load expenses: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (expenses) {
          final settlements = ref.watch(
            settlementsProvider(
              SettlementParams(
                memberUids: group.memberUids,
                expenses: expenses,
              ),
            ),
          );

          if (settlements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 72,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'All Settled Up!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No pending debts for this group.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              return SettlementCard(
                settlement: settlements[index],
                groupId: group.uid,
              );
            },
          );
        },
      ),
    );
  }
}
