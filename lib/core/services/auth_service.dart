import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect/core/constants/app_constants.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign Up with Email & Password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    // Validate college email domain
    if (!email.trim().toLowerCase().endsWith(AppConstants.allowedEmailDomain)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message:
            'Only ${AppConstants.allowedEmailDomain} email addresses are allowed.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Send email verification
    await credential.user?.sendEmailVerification();

    return credential;
  }

  // Sign In with Email & Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    if (!email.trim().toLowerCase().endsWith(AppConstants.allowedEmailDomain)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message:
            'Only ${AppConstants.allowedEmailDomain} email addresses are allowed.',
      );
    }

    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Update Display Name
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user (to check email verification)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Delete account
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
