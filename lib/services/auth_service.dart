import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  static final ValueNotifier<User?> userNotifier = ValueNotifier<User?>(null);

  void init() {
    try {
      userNotifier.value = _auth.currentUser;
      _auth.authStateChanges().listen((user) {
        userNotifier.value = user;
      });
    } catch (_) {}
  }

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.uid;
  String? get currentEmail => currentUser?.email;
  String? get displayName => currentUser?.displayName ?? currentUser?.email?.split('@').first;

  /// Register with Email and Password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
      if (photoURL != null && photoURL.trim().isNotEmpty) {
        await credential.user?.updatePhotoURL(photoURL.trim());
      }
      if ((displayName != null && displayName.trim().isNotEmpty) ||
          (photoURL != null && photoURL.trim().isNotEmpty)) {
        await credential.user?.reload();
        userNotifier.value = _auth.currentUser;
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthErrorMessage(e);
    }
  }

  /// Update user profile (name or avatar)
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (displayName != null && displayName.trim().isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(displayName.trim());
      }
      if (photoURL != null && photoURL.trim().isNotEmpty) {
        await _auth.currentUser?.updatePhotoURL(photoURL.trim());
      }
      await _auth.currentUser?.reload();
      userNotifier.value = _auth.currentUser;
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  /// Sign In with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthErrorMessage(e);
    }
  }

  /// Send password reset link to user email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthErrorMessage(e);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthErrorMessage(e);
    }
  }

  /// Helper to return clear Arabic error messages
  String _getFriendlyAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لم يتم العثور على حساب مرتبط بهذا البريد الإلكتروني.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة المرور أو البريد الإلكتروني غير صحيح.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل بالفعل بحساب آخر.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً، يرجى كتابة 6 أحرف أو أرقام على الأقل.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب من قبل الإدارة.';
      case 'too-many-requests':
        return 'محاولات دخول كثيرة خاطئة، يرجى الانتظار قليلاً ثم المحاولة ثانية.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت، يرجى التحقق من اتصال الشبكة.';
      default:
        return e.message ?? 'حدث خطأ أثناء المصادقة، يرجى المحاولة لاحقاً.';
    }
  }
}
