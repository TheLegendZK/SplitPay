import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/auth/domain/app_user.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/features/groups/data/group_provider.dart';
import 'package:splitpay/features/groups/domain/group.dart';
import 'package:splitpay/features/groups/domain/invitation.dart';
import 'package:splitpay/shared/widgets/async_elevated_button.dart';
import 'package:splitpay/shared/widgets/splitpay_modal_sheet.dart';

class AddMemberModal extends ConsumerStatefulWidget {
  const AddMemberModal({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends ConsumerState<AddMemberModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  AppUser? _selectedUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchUsersProvider(_searchQuery));
    final controllerState = ref.watch(groupControllerProvider);
    final invitesAsync = ref.watch(groupInvitationsProvider(widget.group.uid));
    final isLoading = controllerState is AsyncLoading;

    final Map<String, Invitation> pendingOrDeclinedInvites = {};
    for (final inv in invitesAsync.value ?? <Invitation>[]) {
      if (!widget.group.memberUids.contains(inv.invitedUid)) {
        pendingOrDeclinedInvites[inv.invitedUid] = inv;
      }
    }
    final displayInvites = pendingOrDeclinedInvites.values.toList();

    return SplitPayModalSheet(
      title: 'Add Member',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayInvites.isNotEmpty) ...[
            const Text(
              'Invited Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            ...displayInvites.map((invite) {
              final nameAsync = ref.watch(
                memberNameProvider(invite.invitedUid),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    nameAsync.when(
                      data: (name) => Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      loading: () => const Text('Loading...'),
                      error: (_, _) => const Text('Unknown'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: invite.status == 'declined'
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        invite.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: invite.status == 'declined'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
          ],

          if (_selectedUser != null)
            InputChip(
              label: Text(
                _selectedUser!.displayName ?? _selectedUser!.phoneNumber,
              ),
              onDeleted: () => setState(() => _selectedUser = null),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Search by phone (+1...)',
              prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: searchResults.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (users) {
                if (_searchQuery.length < 3) {
                  return const Center(
                    child: Text('Type at least 3 digits to search'),
                  );
                }

                final availableUsers = users
                    .where((u) => !widget.group.memberUids.contains(u.uid))
                    .toList();

                if (availableUsers.isEmpty) {
                  return const Center(child: Text('No new users found'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableUsers.length,
                  itemBuilder: (ctx, i) {
                    final u = availableUsers[i];
                    final isSelected = _selectedUser?.uid == u.uid;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text(
                          u.displayName?.isNotEmpty == true
                              ? u.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        u.displayName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        u.phoneNumber,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                            )
                          : const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFFCBD5E1),
                            ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUser = null;
                          } else {
                            _selectedUser = u;
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AsyncElevatedButton(
              isLoading: isLoading,
              onPressed: _selectedUser == null
                  ? null
                  : () async {
                      await ref
                          .read(groupControllerProvider.notifier)
                          .sendInvitation(
                            group: widget.group,
                            invitedUid: _selectedUser!.uid,
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation sent!')),
                        );
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Send Invite'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
