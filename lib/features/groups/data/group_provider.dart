import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:splitpay/features/auth/domain/app_user.dart';
import 'package:splitpay/features/groups/domain/group.dart';
import 'package:splitpay/features/groups/domain/invitation.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final searchUsersProvider = FutureProvider.family<List<AppUser>, String>((
  ref,
  query,
) async {
  final trimmed = query.trim();
  if (trimmed.length < 3) return [];

  final firestore = ref.watch(firestoreProvider);
  final currentUid = FirebaseAuth.instance.currentUser?.uid;

  final snapshot = await firestore
      .collection('users')
      .where('phoneNumber', isGreaterThanOrEqualTo: trimmed)
      .where('phoneNumber', isLessThanOrEqualTo: '$trimmed\uf8ff')
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => AppUser.fromMap(doc.data()))
      .where((user) => user.uid != currentUid)
      .toList();
});

final userGroupsProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('groups')
      .where('memberUids', arrayContains: user.uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final userInvitationsProvider = StreamProvider.autoDispose<List<Invitation>>((
  ref,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('invitations')
      .where('invitedUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Invitation.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final groupInvitationsProvider = StreamProvider.autoDispose
    .family<List<Invitation>, String>((ref, groupId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('invitations')
          .where('groupId', isEqualTo: groupId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Invitation.fromMap(doc.data(), doc.id))
                .toList(),
          );
    });

class GroupController extends StateNotifier<AsyncValue<void>> {
  GroupController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> createGroup({
    required String groupName,
    required List<String> invitedUids, // Changed from memberUids
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || groupName.trim().isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      final docRef = firestore.collection('groups').doc();

      // The creator is the only active member initially
      final newGroup = Group(
        uid: docRef.id,
        name: groupName.trim(),
        memberUids: [user.uid],
        creatorUid: user.uid,
      );

      final batch = firestore.batch();
      batch.set(docRef, newGroup.toMap());

      // Batch create invitations for everyone else
      for (final uid in invitedUids) {
        final inviteRef = firestore.collection('invitations').doc();
        final invitation = Invitation(
          id: inviteRef.id,
          groupId: newGroup.uid,
          groupName: newGroup.name,
          invitedUid: uid,
          inviterUid: user.uid,
        );
        batch.set(inviteRef, invitation.toMap());
      }

      await batch.commit();
    });
  }

  Future<void> deleteGroup(String groupId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      final batch = firestore.batch();

      // 1. Delete the group
      batch.delete(firestore.collection('groups').doc(groupId));

      // 2. Query and delete all orphaned invitations for this group
      final invites = await firestore
          .collection('invitations')
          .where('groupId', isEqualTo: groupId)
          .get();

      for (final doc in invites.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    });
  }

  Future<void> addMemberByUid({
    required String groupId,
    required String newMemberUid,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      await firestore.collection('groups').doc(groupId).update({
        'memberUids': FieldValue.arrayUnion([newMemberUid]),
      });
    });
  }

  Future<void> updateMemberShare({
    required String groupId,
    required String memberUid,
    required int shares,
  }) async {
    if (shares < 1) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      await firestore.collection('groups').doc(groupId).update({
        'memberShares.$memberUid': shares,
      });
    });
  }

  Future<void> restoreGroup(Group group) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      await firestore.collection('groups').doc(group.uid).set(group.toMap());
    });
  }

  Future<void> sendInvitation({
    required Group group,
    required String invitedUid,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);

      final existingQuery = await firestore
          .collection('invitations')
          .where('groupId', isEqualTo: group.uid)
          .where('invitedUid', isEqualTo: invitedUid)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final batch = firestore.batch();

        batch.update(existingQuery.docs.first.reference, {
          'status': 'pending',
          'inviterUid': user.uid,
        });

        for (int i = 1; i < existingQuery.docs.length; i++) {
          batch.delete(existingQuery.docs[i].reference);
        }

        await batch.commit();
      } else {
        final docRef = firestore.collection('invitations').doc();
        final invitation = Invitation(
          id: docRef.id,
          groupId: group.uid,
          groupName: group.name,
          invitedUid: invitedUid,
          inviterUid: user.uid,
        );
        await docRef.set(invitation.toMap());
      }
    });
  }

  Future<void> acceptInvitation(Invitation invitation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);

      // 1. Add user to group
      await firestore.collection('groups').doc(invitation.groupId).update({
        'memberUids': FieldValue.arrayUnion([invitation.invitedUid]),
      });

      // 2. Update invitation status
      await firestore.collection('invitations').doc(invitation.id).update({
        'status': 'accepted',
      });
    });
  }

  Future<void> declineInvitation(Invitation invitation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      await firestore.collection('invitations').doc(invitation.id).update({
        'status': 'declined',
      });
    });
  }
}

final groupControllerProvider =
    StateNotifierProvider<GroupController, AsyncValue<void>>((ref) {
      return GroupController(ref);
    });
