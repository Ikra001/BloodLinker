import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String bloodType;
  final DateTime? lastDonationDate;
  final int? age;

  const CustomUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bloodType,
    this.lastDonationDate,
    this.age,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'bloodType': bloodType,
      'age': age, // Save age to Firestore
    };

    if (lastDonationDate != null) {
      map['lastDonationDate'] = Timestamp.fromDate(lastDonationDate!);
    }

    return map;
  }

  // Create from Firestore DocumentSnapshot
  factory CustomUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomUser(
      userId: data['userId'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      bloodType: data['bloodType'] ?? 'O+',
      age: data['age'], // Read age from Firestore
      lastDonationDate: data['lastDonationDate'] != null
          ? (data['lastDonationDate'] as Timestamp).toDate()
          : null,
    );
  }

  // Helper method for local updates (optional but recommended)
  CustomUser copyWith({
    String? name,
    String? phone,
    String? bloodType,
    int? age,
    DateTime? lastDonationDate,
  }) {
    return CustomUser(
      userId: userId,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodType: bloodType ?? this.bloodType,
      age: age ?? this.age,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
    );
  }
}
