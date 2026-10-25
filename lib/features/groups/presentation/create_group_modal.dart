import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/auth/domain/app_user.dart';
import 'package:splitpay/features/groups/data/group_provider.dart';
import 'package:splitpay/shared/widgets/async_elevated_button.dart';
import 'package:splitpay/shared/widgets/splitpay_modal_sheet.dart';

class CreateGroupModal extends ConsumerStatefulWidget {
  const CreateGroupModal({super.key});

  @override
  ConsumerState<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends ConsumerState<CreateGroupModal> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final List<AppUser> _selectedUsers = [];
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchUsersProvider(_searchQuery));

    return SplitPayModalSheet(
      title: 'New Group',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          const SizedBox(height: 12),
          if (_selectedUsers.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _selectedUsers.map((user) {
                return InputChip(
                  label: Text(user.displayName ?? user.phoneNumber),
                  onDeleted: () => setState(() => _selectedUsers.remove(user)),
                );
              }).toList(),
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
                if (users.isEmpty) {
                  return const Center(child: Text('No registered user found'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    final isSelected = _selectedUsers.any(
                      (item) => item.uid == u.uid,
                    );
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
                            _selectedUsers.removeWhere(
                              (item) => item.uid == u.uid,
                            );
                          } else {
                            _selectedUsers.add(u);
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
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(groupControllerProvider.notifier)
                      .createGroup(
                        groupName: name,
                        invitedUids: _selectedUsers.map((u) => u.uid).toList(),
                      );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create Group'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
