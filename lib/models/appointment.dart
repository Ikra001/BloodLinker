import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, confirmed, completed, cancelled, missed }

enum AppointmentType { donation, bloodRequest, followUp }

class Appointment {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? location;
  final String? notes;
  final Duration estimatedDuration;
  final bool requiresConfirmation;
  final Map<String, dynamic>?
  metadata; // Additional data specific to appointment type

  const Appointment({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.createdAt,
    this.status = AppointmentStatus.scheduled,
    this.type = AppointmentType.donation,
    this.location,
    this.notes,
    this.estimatedDuration = const Duration(hours: 1),
    this.requiresConfirmation = false,
    this.metadata,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: AppointmentStatus.values[map['status'] ?? 0],
      type: AppointmentType.values[map['type'] ?? 0],
      location: map['location'],
      notes: map['notes'],
      estimatedDuration: Duration(
        minutes: map['estimatedDurationMinutes'] ?? 60,
      ),
      requiresConfirmation: map['requiresConfirmation'] ?? false,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.index,
      'type': type.index,
      'location': location,
      'notes': notes,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'requiresConfirmation': requiresConfirmation,
      'metadata': metadata,
    };
  }

  Appointment copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    DateTime? createdAt,
    AppointmentStatus? status,
    AppointmentType? type,
    String? location,
    String? notes,
    Duration? estimatedDuration,
    bool? requiresConfirmation,
    Map<String, dynamic>? metadata,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      type: type ?? this.type,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isUpcoming => scheduledDate.isAfter(DateTime.now());
  bool get isPast => scheduledDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }
}
