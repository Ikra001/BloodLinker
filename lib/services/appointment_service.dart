import 'package:blood_linker/models/appointment.dart';
import 'package:blood_linker/models/appointment.dart';
import 'package:blood_linker/data/repositories/appointment_repository.dart';
import 'package:blood_linker/services/certificate_service.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class AppointmentService {
  Future<List<Appointment>> getUserAppointments();
  Future<String> scheduleAppointment({
    required String title,
    required String description,
    required DateTime scheduledDate,
    required AppointmentType type,
    String? location,
    String? notes,
    Duration estimatedDuration = const Duration(hours: 1),
    Map<String, dynamic>? metadata,
  });
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  );
  Future<void> rescheduleAppointment(String appointmentId, DateTime newDate);
  Future<void> cancelAppointment(String appointmentId);
  Future<List<Appointment>> getUpcomingAppointments();
  Future<List<Appointment>> getAppointmentsForDate(DateTime date);
  Future<bool> isTimeSlotAvailable(DateTime dateTime, Duration duration);
  Stream<List<Appointment>> watchAppointments();
}

class AppointmentServiceImpl implements AppointmentService {
  final String _currentUserId;
  final AppointmentRepository _repository;
  final CertificateService? _certificateService;

  AppointmentServiceImpl(
    this._repository,
    this._currentUserId, {
    CertificateService? certificateService,
  }) : _certificateService = certificateService;

  @override
  Future<List<Appointment>> getUserAppointments() async {
    return await _repository.getUserAppointments(_currentUserId);
  }

  @override
  Future<String> scheduleAppointment({
    required String title,
    required String description,
    required DateTime scheduledDate,
    required AppointmentType type,
    String? location,
    String? notes,
    Duration estimatedDuration = const Duration(hours: 1),
    Map<String, dynamic>? metadata,
  }) async {
    // Validate appointment time
    if (scheduledDate.isBefore(DateTime.now())) {
      throw ValidationException('Cannot schedule appointment in the past');
    }

    // Check if time slot is available (basic check - could be enhanced)
    if (!await isTimeSlotAvailable(scheduledDate, estimatedDuration)) {
      throw ValidationException('Selected time slot is not available');
    }

    final appointment = Appointment(
      id: '', // Will be set by repository
      userId: _currentUserId,
      title: title,
      description: description,
      scheduledDate: scheduledDate,
      createdAt: DateTime.now(),
      type: type,
      location: location,
      notes: notes,
      estimatedDuration: estimatedDuration,
      metadata: metadata,
    );

    return await _repository.createAppointment(appointment);
  }

  @override
  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
  ) async {
    if (newDate.isBefore(DateTime.now())) {
      throw ValidationException('Cannot reschedule appointment to the past');
    }

    final appointment = await _repository.getAppointment(appointmentId);
    if (!await isTimeSlotAvailable(newDate, appointment.estimatedDuration)) {
      throw ValidationException('New time slot is not available');
    }

    final updateData = {
      'scheduledDate': newDate,
      'status': AppointmentStatus
          .scheduled
          .index, // Reset to scheduled when rescheduled
    };

    await _repository.updateAppointment(appointmentId, updateData);
  }

  @override
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    final updateData = {'status': status.index};

    await _repository.updateAppointment(appointmentId, updateData);

    // Generate certificate for completed donation appointments
    if (status == AppointmentStatus.completed) {
      final appointment = await _repository.getAppointment(appointmentId);
      if (appointment.type == AppointmentType.donation &&
          _certificateService != null) {
        try {
          // Generate certificate for completed donation
          await _certificateService.generateCertificate(
            donorId: _currentUserId,
            donorName: 'Donor Name', // In real app, get from user profile
            bloodType: 'O+', // In real app, get from user profile
            donationDate: appointment.scheduledDate,
            donationCenter: appointment.location ?? 'Blood Bank',
            bagsDonated: 1,
          );
        } catch (e) {
          // Certificate generation failure shouldn't block appointment update
          print('Failed to generate certificate: $e');
        }
      }
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  @override
  Future<List<Appointment>> getUpcomingAppointments() async {
    final allAppointments = await getUserAppointments();
    final now = DateTime.now();

    return allAppointments
        .where(
          (appointment) =>
              appointment.scheduledDate.isAfter(now) &&
              appointment.status != AppointmentStatus.cancelled,
        )
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  @override
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _repository.getAppointmentsByDateRange(
      _currentUserId,
      startOfDay,
      endOfDay,
    );
  }

  @override
  Future<bool> isTimeSlotAvailable(DateTime dateTime, Duration duration) async {
    // For simplicity, we're allowing multiple appointments at the same time
    // In a real app, you'd check against existing appointments and clinic capacity
    final endTime = dateTime.add(duration);

    // Basic validation - check if appointment is during business hours (9 AM - 6 PM)
    final hour = dateTime.hour;
    if (hour < 9 || hour >= 18) {
      return false;
    }

    // Check if end time is also within business hours
    if (endTime.hour >= 18) {
      return false;
    }

    return true;
  }

  @override
  Stream<List<Appointment>> watchAppointments() {
    return _repository.watchUserAppointments(_currentUserId);
  }
}
