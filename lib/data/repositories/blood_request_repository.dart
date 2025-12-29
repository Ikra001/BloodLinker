import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_linker/models/blood_request.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class BloodRequestRepository {
  Future<List<BloodRequest>> getRequests({String? bloodGroup});
  Future<BloodRequest> getRequest(String requestId);
  Future<String> createRequest(BloodRequest request);
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
  Stream<List<BloodRequest>> watchRequests({String? bloodGroup});
}

class FirestoreBloodRequestRepository implements BloodRequestRepository {
  final FirebaseFirestore _firestore;

  FirestoreBloodRequestRepository(this._firestore);

  @override
  Future<List<BloodRequest>> getRequests({String? bloodGroup}) async {
    try {
      Query query = _firestore
          .collection('requests')
          .orderBy('requestDate', descending: true);

      if (bloodGroup != null && bloodGroup != 'All') {
        query = query.where('bloodGroup', isEqualTo: bloodGroup);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => BloodRequest.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch requests: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching requests',
        originalError: e,
      );
    }
  }

  @override
  Future<BloodRequest> getRequest(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (!doc.exists) {
        throw DatabaseException('Request not found', code: 'REQUEST_NOT_FOUND');
      }
      return BloodRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch request: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching request',
        originalError: e,
      );
    }
  }

  @override
  Future<String> createRequest(BloodRequest request) async {
    try {
      final docRef = await _firestore
          .collection('requests')
          .add(request.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to create request: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error creating request',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('requests').doc(requestId).update(data);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to update request: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error updating request',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to delete request: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error deleting request',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<BloodRequest>> watchRequests({String? bloodGroup}) {
    Query query = _firestore
        .collection('requests')
        .orderBy('requestDate', descending: true);

    if (bloodGroup != null && bloodGroup != 'All') {
      query = query.where('bloodGroup', isEqualTo: bloodGroup);
    }

    return query
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BloodRequest.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        })
        .handleError((error) {
          throw DatabaseException(
            'Error watching requests: $error',
            originalError: error,
          );
        });
  }
}
