import 'package:blood_linker/models/blood_type.dart';

class CustomUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final BloodType bloodType;

  const CustomUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bloodType,
  });
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
  });
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
  });
}