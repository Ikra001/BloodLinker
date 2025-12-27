import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String bloodType;
  final DateTime? lastDonationDate;

  const CustomUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bloodType,
    this.lastDonationDate,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'bloodType': bloodType,
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
      lastDonationDate: data['lastDonationDate'] != null
          ? (data['lastDonationDate'] as Timestamp).toDate()
          : null,
    );
  }
}
