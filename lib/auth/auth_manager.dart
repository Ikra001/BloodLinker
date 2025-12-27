import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:blood_linker/models/user.dart';
import 'package:blood_linker/utils/logger.dart';

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

  // Helper method to set loading state and error
  void _setLoading(bool loading, {String? error}) {
    _isLoading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user data from Firestore
      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false, error: _getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(
        false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
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
    _setLoading(true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a standard CustomUser object
      final customUser = CustomUser(
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
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false, error: _getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(
        false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
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
      AppLogger.error('Error loading user data', e);
    }
  }

  // Update last donation date
  Future<bool> updateLastDonationDate(DateTime? date) async {
    _setLoading(true);
    try {
      if (_user == null) throw Exception("User not logged in");

      final updateData = <String, dynamic>{};
      if (date != null) {
        updateData['lastDonationDate'] = Timestamp.fromDate(date);
      } else {
        updateData['lastDonationDate'] = null;
      }

      await _firestore.collection('users').doc(_user!.uid).update(updateData);

      // Reload user data to reflect the change
      await _loadUserData(_user!.uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(
        false,
        error: 'Failed to update donation date: ${e.toString()}',
      );
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false, error: 'Failed to logout: ${e.toString()}');
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
    double? latitude,
    double? longitude,
    String? hospitalName,
    String? address,
  }) async {
    _setLoading(true);
    try {
      if (_user == null) throw Exception("User not logged in");

      final requestData = <String, dynamic>{
        // --- FIXED: Now uses 'userId' to match the MyRequests query ---
        'userId': _user!.uid,
        // -----------------------------------------------------------
        'patientName': patientName,
        'bloodGroup': bloodGroup,
        'bagsNeeded': bagsNeeded,
        'contactNumber': contactNumber,
        'hospitalLocation': hospitalLocation,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      // Add location data if available
      if (latitude != null && longitude != null) {
        requestData['latitude'] = latitude;
        requestData['longitude'] = longitude;
      }
      if (hospitalName != null && hospitalName.isNotEmpty) {
        requestData['hospitalName'] = hospitalName;
      }
      if (address != null && address.isNotEmpty) {
        requestData['address'] = address;
      }

      await _firestore.collection('requests').add(requestData);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to create request: ${e.toString()}');
      return false;
    }
  }
}
