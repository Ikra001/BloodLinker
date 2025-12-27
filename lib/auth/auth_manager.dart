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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading, {String? error}) {
    _isLoading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false, error: e.message);
      return false;
    } catch (e) {
      _setLoading(false, error: 'An unexpected error occurred: $e');
      return false;
    }
  }

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

      final customUser = CustomUser(
        userId: userCredential.user!.uid,
        name: name ?? '',
        email: email,
        phone: phone ?? '',
        bloodType: bloodType,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(customUser.toFirestore());

      _customUser = customUser;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false, error: e.message);
      return false;
    } catch (e) {
      _setLoading(false, error: 'An unexpected error occurred: $e');
      return false;
    }
  }

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
      await _loadUserData(_user!.uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to update donation date: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false, error: 'Failed to logout: $e');
    }
  }

  // --- UPDATED CREATE FUNCTION ---
  Future<bool> createBloodRequest({
    required String patientName,
    required String bloodGroup,
    required int bagsNeeded,
    required String contactNumber,
    required String hospitalLocation, // This was missing
    // New Fields
    int? age,
    String? gender,
    DateTime? whenNeeded,
    bool isEmergency = false,
    String? additionalNotes,
    // Location Fields
    double? latitude,
    double? longitude,
    String? hospitalName,
    String? address,
  }) async {
    _setLoading(true);
    try {
      if (_user == null) throw Exception("User not logged in");

      final requestData = <String, dynamic>{
        'userId': _user!.uid, // Links request to your "My Requests" page
        'patientName': patientName,
        'bloodGroup': bloodGroup,
        'bagsNeeded': bagsNeeded,
        'contactNumber': contactNumber,
        'hospitalLocation': hospitalLocation,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',

        // Save New Fields
        'age': age,
        'gender': gender,
        'isEmergency': isEmergency,
        'additionalNotes': additionalNotes,
      };

      if (whenNeeded != null) {
        requestData['whenNeeded'] = Timestamp.fromDate(whenNeeded);
      }

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
      _setLoading(false, error: 'Failed to create request: $e');
      return false;
    }
  }

  // --- UPDATED UPDATE FUNCTION ---
  Future<bool> updateBloodRequest({
    required String requestId,
    required String patientName,
    required String bloodGroup,
    required int bagsNeeded,
    required String contactNumber,
    required String hospitalLocation,
    // New Fields needed for Edit Mode
    int? age,
    String? gender,
    DateTime? whenNeeded,
    bool isEmergency = false,
    String? additionalNotes,
    // Location Fields
    double? latitude,
    double? longitude,
    String? hospitalName,
    String? address,
  }) async {
    _setLoading(true);
    try {
      final updateData = <String, dynamic>{
        'patientName': patientName,
        'bloodGroup': bloodGroup,
        'bagsNeeded': bagsNeeded,
        'contactNumber': contactNumber,
        'hospitalLocation': hospitalLocation,
        'age': age,
        'gender': gender,
        'isEmergency': isEmergency,
        'additionalNotes': additionalNotes,
      };

      if (whenNeeded != null) {
        updateData['whenNeeded'] = Timestamp.fromDate(whenNeeded);
      }

      if (latitude != null && longitude != null) {
        updateData['latitude'] = latitude;
        updateData['longitude'] = longitude;
      }
      if (hospitalName != null) updateData['hospitalName'] = hospitalName;
      if (address != null) updateData['address'] = address;

      await _firestore.collection('requests').doc(requestId).update(updateData);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to update request: $e');
      return false;
    }
  }
}
