import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_linker/models/appointment.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getUserAppointments(String userId);
  Future<Appointment> getAppointment(String appointmentId);
  Future<String> createAppointment(Appointment appointment);
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> data,
  );
  Future<void> deleteAppointment(String appointmentId);
  Stream<List<Appointment>> watchUserAppointments(String userId);
  Future<List<Appointment>> getAppointmentsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );
}

class FirestoreAppointmentRepository implements AppointmentRepository {
  final FirebaseFirestore _firestore;

  FirestoreAppointmentRepository(this._firestore);

  @override
  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .orderBy('scheduledDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch appointments: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching appointments',
        originalError: e,
      );
    }
  }

  @override
  Future<Appointment> getAppointment(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (!doc.exists) {
        throw DatabaseException(
          'Appointment not found',
          code: 'APPOINTMENT_NOT_FOUND',
        );
      }
      return Appointment.fromMap(doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch appointment: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching appointment',
        originalError: e,
      );
    }
  }

  @override
  Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _firestore
          .collection('appointments')
          .add(appointment.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to create appointment: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error creating appointment',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(data);
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to update appointment: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error updating appointment',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to delete appointment: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error deleting appointment',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<Appointment>> watchUserAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Appointment.fromMap(doc.data()))
              .toList();
        })
        .handleError((error) {
          throw DatabaseException(
            'Error watching appointments: $error',
            originalError: error,
          );
        });
  }

  @override
  Future<List<Appointment>> getAppointmentsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .where(
            'scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('scheduledDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(
        'Failed to fetch appointments by date range: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw DatabaseException(
        'Unexpected error fetching appointments by date range',
        originalError: e,
      );
    }
  }
}
