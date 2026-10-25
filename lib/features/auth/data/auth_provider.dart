import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:splitpay/features/auth/domain/app_user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthState {
  final bool isLoading;
  final bool codeSent;
  final String? verificationId;
  final String? error;
  final AppUser? user;

  const AuthState({
    this.isLoading = false,
    this.codeSent = false,
    this.verificationId,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? codeSent,
    String? verificationId,
    String? error,
    AppUser? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      codeSent: codeSent ?? this.codeSent,
      verificationId: verificationId ?? this.verificationId,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendOtp({
    required String phoneNumber,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential, displayName, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(isLoading: false, error: e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isLoading: false,
            codeSent: true,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp({
    required String otp,
    required String displayName,
    required String phoneNumber,
  }) async {
    if (state.verificationId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential, displayName, phoneNumber);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    String displayName, [
    String? fallbackPhone,
  ]) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? fallbackPhone ?? '',
        displayName: displayName.trim().isNotEmpty ? displayName.trim() : null,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap(), SetOptions(merge: true));

      state = state.copyWith(isLoading: false, user: appUser);
    }
  }

  Future<void> signOut() async {
    return _auth.signOut();
  }

  void reset() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
