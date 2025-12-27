import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:blood_linker/models/user.dart';

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
    required String bloodType,
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
      CustomUser customUser = CustomUser(
        userId: userCredential.user!.uid,
        name: name ?? '',
        email: email,
        phone: phone ?? '',
        bloodType: bloodType,
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
        _customUser = CustomUser.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
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
      case 'invalid-credential':
        return 'Invalid email or password.';
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

  // Create a new Blood Request
  Future<bool> createBloodRequest({
    required String patientName,
    required String bloodGroup,
    required int bagsNeeded,
    required String contactNumber,
    required String hospitalLocation,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user == null) throw Exception("User not logged in");

      await _firestore.collection('requests').add({
        'requesterId': _user!.uid,
        'patientName': patientName,
        'bloodGroup': bloodGroup,
        'bagsNeeded': bagsNeeded,
        'contactNumber': contactNumber,
        'hospitalLocation': hospitalLocation,
        'requestDate': FieldValue.serverTimestamp(),
        'status':
            'pending', // You can use this later to mark requests as fulfilled
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create request: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
