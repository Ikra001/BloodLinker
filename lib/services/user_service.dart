import 'package:blood_linker/models/user.dart';
import 'package:blood_linker/models/blood_request.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';
import 'package:blood_linker/data/repositories/user_repository.dart';
import 'package:blood_linker/data/repositories/blood_request_repository.dart';

abstract class UserService {
  Future<CustomUser> getCurrentUser();
  Future<void> updateProfile(CustomUser user);
  Future<void> updateLastDonationDate(DateTime? date);
  Stream<CustomUser?> watchCurrentUser();
}

class UserServiceImpl implements UserService {
  final String _currentUserId;
  final UserRepository _userRepository;

  UserServiceImpl(this._userRepository, this._currentUserId);

  @override
  Future<CustomUser> getCurrentUser() async {
    if (_currentUserId.isEmpty) {
      throw const AuthException(
        'User not authenticated',
        code: 'NOT_AUTHENTICATED',
      );
    }
    return await _userRepository.getUser(_currentUserId);
  }

  @override
  Future<void> updateProfile(CustomUser user) async {
    if (_currentUserId != user.userId) {
      throw const AuthException(
        'Cannot update another user\'s profile',
        code: 'INVALID_USER',
      );
    }

    await _userRepository.updateUser(user.userId, user.toFirestore());
  }

  @override
  Future<void> updateLastDonationDate(DateTime? date) async {
    final updateData = <String, dynamic>{};
    if (date != null) {
      updateData['lastDonationDate'] = date;
    } else {
      updateData['lastDonationDate'] = null;
    }

    await _userRepository.updateUser(_currentUserId, updateData);
  }

  @override
  Stream<CustomUser?> watchCurrentUser() {
    if (_currentUserId.isEmpty) {
      return Stream.value(null);
    }
    return _userRepository.watchUser(_currentUserId);
  }
}

abstract class BloodRequestService {
  Future<List<BloodRequest>> getRequests({String? bloodGroup});
  Future<String> createRequest({
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
  });
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
  Stream<List<BloodRequest>> watchRequests({String? bloodGroup});
}

class BloodRequestServiceImpl implements BloodRequestService {
  final String _currentUserId;
  final BloodRequestRepository _repository;

  BloodRequestServiceImpl(this._repository, this._currentUserId);

  @override
  Future<List<BloodRequest>> getRequests({String? bloodGroup}) async {
    return await _repository.getRequests(bloodGroup: bloodGroup);
  }

  @override
  Future<String> createRequest({
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
    if (_currentUserId.isEmpty) {
      throw const AuthException(
        'User not authenticated',
        code: 'NOT_AUTHENTICATED',
      );
    }

    final request = BloodRequest(
      id: '', // Will be set by repository
      requesterId: _currentUserId,
      patientName: patientName,
      bloodGroup: bloodGroup,
      bagsNeeded: bagsNeeded,
      contactNumber: contactNumber,
      hospitalLocation: hospitalLocation,
      requestDate: DateTime.now(),
    );

    return await _repository.createRequest(request);
  }

  @override
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    await _repository.updateRequest(requestId, data);
  }

  @override
  Future<void> deleteRequest(String requestId) async {
    await _repository.deleteRequest(requestId);
  }

  @override
  Stream<List<BloodRequest>> watchRequests({String? bloodGroup}) {
    return _repository.watchRequests(bloodGroup: bloodGroup);
  }
}
