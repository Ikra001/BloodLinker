import 'package:blood_linker/models/blood_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final BloodType bloodType;
  final String userType; // 'donor' or 'recipient'

  const CustomUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bloodType,
    required this.userType,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'bloodType': bloodType.name,
      'userType': userType,
    };
  }

  // Create from Firestore DocumentSnapshot
  factory CustomUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomUser(
      userId: data['userId'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      bloodType: BloodType.values.firstWhere(
        (bt) => bt.name == data['bloodType'],
        orElse: () => BloodType.oPositive,
      ),
      userType: data['userType'] ?? 'donor',
    );
  }

  // Create Donor from Firestore
  factory CustomUser.donorFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final baseUser = CustomUser.fromFirestore(doc);
    return Donor(
      userId: baseUser.userId,
      name: baseUser.name,
      email: baseUser.email,
      phone: baseUser.phone,
      bloodType: baseUser.bloodType,
      lastDonationDate: data['lastDonationDate'] != null
          ? (data['lastDonationDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create Recipient from Firestore
  factory CustomUser.recipientFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final baseUser = CustomUser.fromFirestore(doc);
    return Recipient(
      userId: baseUser.userId,
      name: baseUser.name,
      email: baseUser.email,
      phone: baseUser.phone,
      bloodType: baseUser.bloodType,
      needDate: data['needDate'] != null
          ? (data['needDate'] as Timestamp).toDate()
          : DateTime.now(),
      bagsNeeded: data['bagsNeeded'] ?? 1,
    );
  }
}

class Donor extends CustomUser {
  final DateTime lastDonationDate;

  const Donor({
    required super.userId,
    required super.name,
    required super.email,
    required super.phone,
    required super.bloodType,
    required this.lastDonationDate,
  }) : super(userType: 'donor');

  @override
  Map<String, dynamic> toFirestore() {
    final map = super.toFirestore();
    map['lastDonationDate'] = Timestamp.fromDate(lastDonationDate);
    return map;
  }
}

class Recipient extends CustomUser {
  final DateTime needDate;
  final int bagsNeeded;

  const Recipient({
    required super.userId,
    required super.name,
    required super.email,
    required super.phone,
    required super.bloodType,
    required this.needDate,
    required this.bagsNeeded,
  }) : super(userType: 'recipient');

  @override
  Map<String, dynamic> toFirestore() {
    final map = super.toFirestore();
    map['needDate'] = Timestamp.fromDate(needDate);
    map['bagsNeeded'] = bagsNeeded;
    return map;
  }
}
