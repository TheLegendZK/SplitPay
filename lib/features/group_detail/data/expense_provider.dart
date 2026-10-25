import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:splitpay/features/auth/domain/app_user.dart';
import 'package:splitpay/features/group_detail/domain/expense.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final expensesProvider = StreamProvider.autoDispose
    .family<List<Expense>, String>((ref, groupId) {
      final authUser = ref.watch(authStateChangesProvider).value;
      if (authUser == null) {
        return const Stream.empty();
      }
      final firestore = ref.watch(firestoreProvider);

      return firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Expense.fromMap(doc.data(), doc.id))
                .toList(),
          );
    });

final memberNameProvider = FutureProvider.family<String, String>((
  ref,
  uid,
) async {
  final currentUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == currentUid) return 'You';

  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('users').doc(uid).get();

  final data = doc.data();
  if (!doc.exists || data == null) return 'Unknown member';

  final user = AppUser.fromMap(data);

  if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
    return user.displayName!.trim();
  }
  return user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Member';
});

class ExpenseController extends StateNotifier<AsyncValue<void>> {
  ExpenseController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> createExpense({
    required String groupId,
    required String name,
    required double amount,
  }) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null || name.trim().isEmpty || amount <= 0) return;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      final docRef = firestore.collection('expenses').doc();

      final newExpense = Expense(
        id: docRef.id,
        groupId: groupId,
        name: name.trim(),
        amount: amount,
        memberUid: user.uid,
      );

      await docRef.set(newExpense.toMap());
    });
  }

  Future<void> settleDebt({
    required String groupId,
    required String debtorUid,
    required String creditorUid,
    required double amount,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      final docRef = firestore.collection('expenses').doc();

      final newExpense = Expense(
        id: docRef.id,
        groupId: groupId,
        name: 'Settlement',
        amount: amount,
        memberUid: debtorUid,
        type: 'settlement',
        settlementToUid: creditorUid,
      );

      await docRef.set(newExpense.toMap());
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      await firestore.collection('expenses').doc(expenseId).delete();
    });
  }

  Future<void> restoreExpense(Expense expense) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final firestore = _ref.read(firestoreProvider);
      await firestore
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());
    });
  }
}

final expenseControllerProvider =
    StateNotifierProvider.autoDispose<ExpenseController, AsyncValue<void>>((
      ref,
    ) {
      return ExpenseController(ref);
    });
