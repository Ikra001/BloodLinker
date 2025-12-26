import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_linker/models/user.dart';
import 'package:blood_linker/models/blood_type.dart';
import 'package:flutter/foundation.dart';

class AuthManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  CustomUser? _customUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthManager() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _customUser = null;
      }
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  CustomUser? get customUser => _customUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user data from Firestore
      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Register with email, password, and basic profile data
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password, {
    String? name,
    String? phone,
    String? bloodType,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a standard CustomUser object
      // Defaulting userType to 'donor' since selection was removed,
      // or you can use 'user' if your model supports it.
      CustomUser customUser = CustomUser(
        userId: userCredential.user!.uid,
        name: name ?? '',
        email: email,
        phone: phone ?? '',
        bloodType: _parseBloodType(bloodType ?? 'oPositive'),
        userType: 'donor', // Defaulting to donor as the standard type
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(customUser.toFirestore());

      _customUser = customUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Since we simplified registration, we likely just use the basic factory
        // But keeping the check ensures backward compatibility if you had old data
        final userType = data['userType'] ?? 'donor';

        if (userType == 'donor') {
          // If you still have the specialized factory, use it, otherwise use basic
          // Assuming CustomUser.fromFirestore handles basic fields correctly
          _customUser = CustomUser.fromFirestore(doc);
        } else {
          _customUser = CustomUser.fromFirestore(doc);
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Parse blood type string to enum
  BloodType _parseBloodType(String bloodType) {
    return BloodType.values.firstWhere(
      (bt) => bt.name.toLowerCase() == bloodType.toLowerCase(),
      orElse: () => BloodType.oPositive,
    );
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to logout: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred: $code';
    }
  }
}
