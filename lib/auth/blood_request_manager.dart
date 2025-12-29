import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_linker/services/user_service.dart';
import 'package:blood_linker/models/blood_request.dart';

class BloodRequestManager extends ChangeNotifier {
  final BloodRequestService _requestService;

  List<BloodRequest> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'All';

  BloodRequestManager(this._requestService) {
    _loadRequests();
  }

  // Getters
  List<BloodRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading, {String? error}) {
    _isLoading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> _loadRequests() async {
    _setLoading(true);
    try {
      _requests = await _requestService.getRequests(
        bloodGroup: _selectedFilter,
      );
      _setLoading(false);
    } catch (e) {
      _setLoading(false, error: 'Failed to load requests: $e');
    }
  }

  Future<bool> createBloodRequest({
    required String patientName,
    required String bloodGroup,
    required int bagsNeeded,
    required String contactNumber,
    required String hospitalLocation,
    int? age,
    String? gender,
    DateTime? whenNeeded,
    bool isEmergency = false,
    String? additionalNotes,
    double? latitude,
    double? longitude,
    String? hospitalName,
    String? address,
  }) async {
    _setLoading(true);
    try {
      await _requestService.createRequest(
        patientName: patientName,
        bloodGroup: bloodGroup,
        bagsNeeded: bagsNeeded,
        contactNumber: contactNumber,
        hospitalLocation: hospitalLocation,
        age: age,
        gender: gender,
        whenNeeded: whenNeeded,
        isEmergency: isEmergency,
        additionalNotes: additionalNotes,
        latitude: latitude,
        longitude: longitude,
        hospitalName: hospitalName,
        address: address,
      );
      await _loadRequests(); // Reload requests
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to create request: $e');
      return false;
    }
  }

  Future<bool> updateBloodRequest({
    required String requestId,
    required String patientName,
    required String bloodGroup,
    required int bagsNeeded,
    required String contactNumber,
    required String hospitalLocation,
    int? age,
    String? gender,
    DateTime? whenNeeded,
    bool isEmergency = false,
    String? additionalNotes,
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
        'isEmergency': isEmergency,
        'age': age,
        'gender': gender,
        'additionalNotes': additionalNotes,
        'hospitalName': hospitalName,
        'address': address,
      };

      if (whenNeeded != null) {
        updateData['whenNeeded'] = whenNeeded;
      }
      if (latitude != null && longitude != null) {
        updateData['latitude'] = latitude;
        updateData['longitude'] = longitude;
      }

      await _requestService.updateRequest(requestId, updateData);
      await _loadRequests(); // Reload requests
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: 'Failed to update request: $e');
      return false;
    }
  }

  Future<void> deleteBloodRequest(String requestId) async {
    _setLoading(true);
    try {
      await _requestService.deleteRequest(requestId);
      await _loadRequests(); // Reload requests
      _setLoading(false);
    } catch (e) {
      _setLoading(false, error: 'Failed to delete request: $e');
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      _loadRequests();
    }
  }

  Stream<List<BloodRequest>> watchRequests({String? bloodGroup}) {
    return _requestService.watchRequests(
      bloodGroup: bloodGroup ?? _selectedFilter,
    );
  }
}
