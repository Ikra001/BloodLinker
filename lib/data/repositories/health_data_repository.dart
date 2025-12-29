import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_linker/models/health_data.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class HealthDataRepository {
  Future<List<HealthData>> getUserHealthData(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<HealthData?> getTodayHealthData(String userId);
  Future<void> saveHealthData(HealthData data);
  Future<void> updateHealthData(
    String healthDataId,
    Map<String, dynamic> updates,
  );
  Stream<List<HealthData>> watchUserHealthData(
    String userId, {
    DateTime? startDate,
  });
  Future<UserHealthProfile?> getUserHealthProfile(String userId);
  Future<void> saveUserHealthProfile(UserHealthProfile profile);
}

class FirestoreHealthDataRepository implements HealthDataRepository {
  final FirebaseFirestore _firestore;

  FirestoreHealthDataRepository(this._firestore);

  @override
  Future<List<HealthData>> getUserHealthData(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('healthData')
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      query = query.orderBy('date', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => HealthData.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch health data: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching health data',
        originalError: e,
      );
    }
  }

  @override
  Future<HealthData?> getTodayHealthData(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('healthData')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return HealthData.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch today\'s health data: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching today\'s health data',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveHealthData(HealthData data) async {
    try {
      await _firestore.collection('healthData').doc(data.id).set(data.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to save health data: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error saving health data',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateHealthData(
    String healthDataId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('healthData')
          .doc(healthDataId)
          .update(updates);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to update health data: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error updating health data',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<HealthData>> watchUserHealthData(
    String userId, {
    DateTime? startDate,
  }) {
    Query query = _firestore
        .collection('healthData')
        .where('userId', isEqualTo: userId);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    query = query.orderBy('date', descending: true);

    return query
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => HealthData.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        })
        .handleError((error) {
          throw DatabaseException(
            'Error watching health data: $error',
            originalError: error,
          );
        });
  }

  @override
  Future<UserHealthProfile?> getUserHealthProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('healthProfiles')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserHealthProfile.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch health profile: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching health profile',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveUserHealthProfile(UserHealthProfile profile) async {
    try {
      await _firestore
          .collection('healthProfiles')
          .doc(profile.userId)
          .set(profile.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to save health profile: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error saving health profile',
        originalError: e,
      );
    }
  }
}
