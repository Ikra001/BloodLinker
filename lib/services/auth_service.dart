import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class AuthService {
  Future<User> signIn(String email, String password);
  Future<User> register(String email, String password);
  Future<void> logout();
  Stream<User?> authStateChanges();
  User? get currentUser;
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService(this._auth);

  @override
  Future<User> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw const AuthException('Sign in failed', code: 'SIGN_IN_FAILED');
      }

      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AuthException('Unexpected error during sign in', originalError: e);
    }
  }

  @override
  Future<User> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw const AuthException(
          'Registration failed',
          code: 'REGISTRATION_FAILED',
        );
      }

      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AuthException(
        'Unexpected error during registration',
        originalError: e,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Failed to logout: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AuthException('Unexpected error during logout', originalError: e);
    }
  }

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
