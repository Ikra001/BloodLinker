abstract class NotificationService {
  Future<void> showInstantNotification(String title, String body);
  Future<void> scheduleAppointmentReminder(
    String appointmentId,
    DateTime appointmentTime,
  );
}

class SimpleNotificationService implements NotificationService {
  @override
  Future<void> showInstantNotification(String title, String body) async {
    // For now, just print to console
    // In a real app, you would use flutter_local_notifications
    print('NOTIFICATION: $title - $body');
  }

  @override
  Future<void> scheduleAppointmentReminder(
    String appointmentId,
    DateTime appointmentTime,
  ) async {
    // For now, just print to console
    // In a real app, you would schedule actual notifications
    print('REMINDER SCHEDULED: Appointment $appointmentId at $appointmentTime');
  }
}
