import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/features/group_detail/domain/expense.dart';
import 'package:splitpay/features/group_detail/presentation/widgets/add_member_modal.dart';
import 'package:splitpay/features/group_detail/presentation/widgets/create_expense_modal.dart';
import 'package:splitpay/features/group_detail/presentation/widgets/expense_payer_subtitle.dart';
import 'package:splitpay/features/group_detail/presentation/widgets/payee_expenses_card.dart';
import 'package:splitpay/features/groups/data/group_provider.dart';
import 'package:splitpay/features/groups/domain/group.dart';
import 'package:splitpay/features/settlements/data/settlements_provider.dart';
import 'package:splitpay/features/settlements/presentation/settlement_card.dart';
import 'package:splitpay/shared/widgets/splitpay_modal_sheet.dart';

class GroupDetailsScreen extends ConsumerWidget {
  const GroupDetailsScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(group.uid));
    final liveGroup =
        ref
            .watch(userGroupsProvider)
            .value
            ?.where((g) => g.uid == group.uid)
            .firstOrNull ??
        group;

    ref.listen<AsyncValue<void>>(expenseControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              tooltip: 'Add Member',
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () {
                SplitPayModalSheet.show(
                  context: context,
                  child: AddMemberModal(group: group),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF0F172A),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF10B981),
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Dashboard'),
              Tab(text: 'Settlements'),
            ],
          ),
        ),
        body: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Failed to load expenses: $error')),
          data: (expenses) {
            if (expenses.isEmpty) {
              return const Center(
                child: Text(
                  'No expenses recorded yet. Tap + to add one.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return TabBarView(
              children: [
                _buildExpensesTab(context, ref, expenses),

                SingleChildScrollView(
                  child: Column(
                    children: [
                      PayeeExpensesCard(expenses: expenses),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Split Shares (1x = Solo, 2x = Couple)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...liveGroup.memberUids.map((uid) {
                                  final nameAsync = ref.watch(
                                    memberNameProvider(uid),
                                  );
                                  final shares = liveGroup.sharesFor(uid);
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      nameAsync.when(
                                        data: (name) => Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        loading: () => const Text('Loading...'),
                                        error: (_, _) => const Text('Unknown'),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 20,
                                            ),
                                            onPressed: shares > 1
                                                ? () => ref
                                                      .read(
                                                        groupControllerProvider
                                                            .notifier,
                                                      )
                                                      .updateMemberShare(
                                                        groupId: liveGroup.uid,
                                                        memberUid: uid,
                                                        shares: shares - 1,
                                                      )
                                                : null,
                                          ),
                                          Text(
                                            '${shares}x',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20,
                                            ),
                                            onPressed: () => ref
                                                .read(
                                                  groupControllerProvider
                                                      .notifier,
                                                )
                                                .updateMemberShare(
                                                  groupId: liveGroup.uid,
                                                  memberUid: uid,
                                                  shares: shares + 1,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSettlementsTab(ref, liveGroup, expenses),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            SplitPayModalSheet.show(
              context: context,
              child: CreateExpenseModal(groupId: group.uid),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    WidgetRef ref,
    List<Expense> expenses,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 2,
                offset: Offset(0, 1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Dismissible(
            key: Key(expense.id),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (direction) async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser?.uid != expense.memberUid) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Only the creator can delete this expense'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return false;
              }
              return true;
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              ref
                  .read(expenseControllerProvider.notifier)
                  .deleteExpense(expense.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Expense deleted'),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref
                          .read(expenseControllerProvider.notifier)
                          .restoreExpense(expense);
                    },
                  ),
                ),
              );
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  expense.name.isNotEmpty
                      ? expense.name[0].toUpperCase()
                      : r'$',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              title: Text(
                expense.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: -0.01,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: ExpensePayerSubtitle(memberUid: expense.memberUid),
              trailing: Text(
                '\$${expense.amount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.01,
                  color: Color(0xFF0F172A),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettlementsTab(
    WidgetRef ref,
    Group liveGroup,
    List<Expense> expenses,
  ) {
    final settlements = ref.watch(
      settlementsProvider(
        SettlementParams(
          memberUids: liveGroup.memberUids,
          expenses: expenses,
          memberShares: liveGroup.memberShares,
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
  }
}
