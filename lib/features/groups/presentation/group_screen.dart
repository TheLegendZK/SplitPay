import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/auth/data/auth_provider.dart';
import 'package:splitpay/features/group_detail/presentation/group_details_screen.dart';
import 'package:splitpay/features/groups/data/group_provider.dart';
import 'package:splitpay/features/groups/presentation/create_group_modal.dart';
import 'package:splitpay/shared/widgets/async_elevated_button.dart';
import 'package:splitpay/shared/widgets/splitpay_card.dart';
import 'package:splitpay/shared/widgets/splitpay_modal_sheet.dart';

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  bool _showAllInvites = false;

  Future<void> _signOut() async {
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sign-Out'),
          content: const Text('Do you want to sign-out?'),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            AsyncElevatedButton(
              onPressed: ref.read(authProvider.notifier).signOut,
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsProvider);
    final invitationsAsync = ref.watch(userInvitationsProvider);

    ref.listen<AsyncValue<void>>(groupControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: Column(
        children: [
          invitationsAsync.when(
            data: (invites) {
              if (invites.isEmpty) return const SizedBox.shrink();

              final hasMore = invites.length > 2;
              final displayInvites = _showAllInvites
                  ? invites
                  : invites.take(2).toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pending Invites (${invites.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...displayInvites.map(
                      (invite) => SplitPayCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(invite.groupName),
                          subtitle: const Text('Invited to join'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => ref
                                    .read(groupControllerProvider.notifier)
                                    .declineInvitation(invite),
                                child: const Text(
                                  'Decline',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AsyncElevatedButton(
                                onPressed: () => ref
                                    .read(groupControllerProvider.notifier)
                                    .acceptInvitation(invite),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (hasMore)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllInvites =
                                !_showAllInvites; // Flip the state
                          });
                        },
                        child: Text(
                          _showAllInvites
                              ? 'Show less'
                              : 'View all ${invites.length} invites',
                        ),
                      ),
                    const Divider(height: 24),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load groups: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(
                    child: Text(
                      'No groups found. Tap + to create one.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return SplitPayCard(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            group.name.isNotEmpty
                                ? group.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            letterSpacing: -0.01,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          '${group.memberUids.length} members',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFCBD5E1),
                        ),
                        onLongPress: () {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (group.creatorUid != currentUser?.uid) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Only the creator can delete this group',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          SplitPayModalSheet.show<bool>(
                            context: context,
                            child: SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: const Text(
                                      'Delete Group',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ).then((wantsToDelete) {
                            if (wantsToDelete == true) {
                              showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Group'),
                                  content: const Text(
                                    'Are you sure you want to delete this group?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    AsyncElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ).then((confirmed) {
                                if (confirmed == true) {
                                  ref
                                      .read(groupControllerProvider.notifier)
                                      .deleteGroup(group.uid);
                                  ScaffoldMessenger.of(
                                    context,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Group deleted'),
                                      duration: const Duration(seconds: 4),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          ref
                                              .read(
                                                groupControllerProvider
                                                    .notifier,
                                              )
                                              .restoreGroup(group);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              });
                            }
                          });
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupDetailsScreen(group: group),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SplitPayModalSheet.show(
            context: context,
            child: const CreateGroupModal(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
