import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';
import 'package:blood_linker/services/auth_service.dart';
import 'package:blood_linker/services/user_service.dart';
import 'package:blood_linker/models/user.dart';

class AuthManager extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  User? _user;
  CustomUser? _customUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthManager(this._authService, this._userService) {
    _authService.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
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
      await _authService.signIn(email, password);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
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
      final user = await _authService.register(email, password);

      final customUser = CustomUser(
        userId: user.uid,
        name: name ?? '',
        email: email,
        phone: phone ?? '',
        bloodType: bloodType,
      );

      await _userService.updateProfile(customUser);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setLoading(false, error: e.message);
      return false;
    } catch (e) {
      _setLoading(false, error: 'An unexpected error occurred: $e');
      return false;
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      _customUser = await _userService.getCurrentUser();
    } catch (e) {
      // Don't set error for silent data loading
      debugPrint('Error loading user data: $e');
    }
    notifyListeners();
  }

  Future<bool> updateLastDonationDate(DateTime? date) async {
    _setLoading(true);
    try {
      await _userService.updateLastDonationDate(date);
      await _loadUserData(); // Reload to get updated data
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to update donation date: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String name,
    required String phone,
    required String bloodType,
    int? age,
    DateTime? lastDonationDate,
  }) async {
    _setLoading(true);
    try {
      if (_customUser == null) throw Exception("User not loaded");

      final updatedUser = _customUser!.copyWith(
        name: name,
        phone: phone,
        bloodType: bloodType,
        age: age,
        lastDonationDate: lastDonationDate,
      );

      await _userService.updateProfile(updatedUser);
      await _loadUserData(); // Reload to get updated data
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to update profile: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _setLoading(false);
    } catch (e) {
      _setLoading(false, error: 'Failed to logout: $e');
    }
  }
}
