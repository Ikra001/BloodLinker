import 'package:cloud_firestore/cloud_firestore.dart';

class HealthData {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final double caloriesBurned;
  final double distanceWalked; // in kilometers
  final int activeMinutes;
  final double weight; // in kg (optional)
  final int heartRate; // bpm (optional)
  final int sleepHours;
  final int waterIntake; // in ml
  final List<String> activities; // list of activities performed
  final Map<String, dynamic>? metadata;

  const HealthData({
    required this.id,
    required this.userId,
    required this.date,
    this.steps = 0,
    this.caloriesBurned = 0.0,
    this.distanceWalked = 0.0,
    this.activeMinutes = 0,
    this.weight = 0.0,
    this.heartRate = 0,
    this.sleepHours = 0,
    this.waterIntake = 0,
    this.activities = const [],
    this.metadata,
  });

  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      steps: map['steps'] ?? 0,
      caloriesBurned: map['caloriesBurned'] ?? 0.0,
      distanceWalked: map['distanceWalked'] ?? 0.0,
      activeMinutes: map['activeMinutes'] ?? 0,
      weight: map['weight'] ?? 0.0,
      heartRate: map['heartRate'] ?? 0,
      sleepHours: map['sleepHours'] ?? 0,
      waterIntake: map['waterIntake'] ?? 0,
      activities: List<String>.from(map['activities'] ?? []),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'distanceWalked': distanceWalked,
      'activeMinutes': activeMinutes,
      'weight': weight,
      'heartRate': heartRate,
      'sleepHours': sleepHours,
      'waterIntake': waterIntake,
      'activities': activities,
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get isToday => DateTime.now().difference(date).inDays == 0;
  bool get isYesterday => DateTime.now().difference(date).inDays == 1;

  // Calculate BMI if weight is available
  double getBmi(double heightInMeters) {
    if (weight <= 0 || heightInMeters <= 0) return 0.0;
    return weight / (heightInMeters * heightInMeters);
  }

  // Get health score based on various metrics
  double getHealthScore() {
    double score = 0.0;

    // Steps (max 30 points)
    if (steps >= 10000)
      score += 30;
    else if (steps >= 8000)
      score += 25;
    else if (steps >= 6000)
      score += 20;
    else if (steps >= 4000)
      score += 15;
    else if (steps >= 2000)
      score += 10;

    // Active minutes (max 20 points)
    if (activeMinutes >= 60)
      score += 20;
    else if (activeMinutes >= 45)
      score += 15;
    else if (activeMinutes >= 30)
      score += 10;
    else if (activeMinutes >= 15)
      score += 5;

    // Sleep (max 20 points)
    if (sleepHours >= 8)
      score += 20;
    else if (sleepHours >= 7)
      score += 15;
    else if (sleepHours >= 6)
      score += 10;
    else if (sleepHours >= 5)
      score += 5;

    // Water intake (max 15 points)
    if (waterIntake >= 2000)
      score += 15;
    else if (waterIntake >= 1500)
      score += 12;
    else if (waterIntake >= 1000)
      score += 9;
    else if (waterIntake >= 500)
      score += 6;

    // Heart rate (max 15 points) - assuming normal range 60-100 bpm
    if (heartRate >= 60 && heartRate <= 100)
      score += 15;
    else if (heartRate >= 50 && heartRate <= 110)
      score += 10;
    else if (heartRate > 0)
      score += 5;

    return score.clamp(0.0, 100.0);
  }
}

class UserHealthProfile {
  final String userId;
  final DateTime lastDonationDate;
  final int totalDonations;
  final int currentStreak; // consecutive months with donations
  final int longestStreak;
  final String bloodType;
  final DateTime dateOfBirth;
  final double height; // in meters
  final double averageWeight; // in kg
  final List<String> medicalConditions;
  final List<String> allergies;
  final List<String> medications;
  final Map<String, dynamic>? preferences;

  const UserHealthProfile({
    required this.userId,
    required this.lastDonationDate,
    required this.totalDonations,
    required this.currentStreak,
    required this.longestStreak,
    required this.bloodType,
    required this.dateOfBirth,
    required this.height,
    required this.averageWeight,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.preferences,
  });

  int get age => DateTime.now().difference(dateOfBirth).inDays ~/ 365;

  double get bmi => averageWeight / (height * height);

  bool get isEligibleForDonation {
    final daysSinceLastDonation = DateTime.now()
        .difference(lastDonationDate)
        .inDays;
    return daysSinceLastDonation >= 56; // 8 weeks minimum
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  factory UserHealthProfile.fromMap(Map<String, dynamic> map) {
    return UserHealthProfile(
      userId: map['userId'] ?? '',
      lastDonationDate: (map['lastDonationDate'] as Timestamp).toDate(),
      totalDonations: map['totalDonations'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      bloodType: map['bloodType'] ?? '',
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      height: (map['height'] ?? 0.0).toDouble(),
      averageWeight: (map['averageWeight'] ?? 0.0).toDouble(),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      preferences: map['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lastDonationDate': Timestamp.fromDate(lastDonationDate),
      'totalDonations': totalDonations,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'bloodType': bloodType,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'height': height,
      'averageWeight': averageWeight,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'medications': medications,
      'preferences': preferences,
    };
  }
}
