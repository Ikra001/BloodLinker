import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_linker/models/user.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class UserRepository {
  Future<CustomUser> getUser(String userId);
  Future<void> saveUser(CustomUser user);
  Future<void> updateUser(String userId, Map<String, dynamic> data);
  Stream<CustomUser?> watchUser(String userId);
}

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository(this._firestore);

  @override
  Future<CustomUser> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw DatabaseException('User not found', code: 'USER_NOT_FOUND');
      }
      return CustomUser.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch user: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching user',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveUser(CustomUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.userId)
          .set(user.toFirestore());
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to save user: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException('Unexpected error saving user', originalError: e);
    }
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to update user: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error updating user',
        originalError: e,
      );
    }
  }

  @override
  Stream<CustomUser?> watchUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? CustomUser.fromFirestore(doc) : null)
        .handleError((error) {
          throw DatabaseException(
            'Error watching user: $error',
            originalError: error,
          );
        });
  }
}
