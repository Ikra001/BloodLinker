import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  final String id;
  final String requesterId;
  final String patientName;
  final String bloodGroup; // Storing as String for simplicity (e.g., 'B+')
  final int bagsNeeded;
  final String contactNumber;
  final String hospitalLocation;
  final DateTime requestDate;

  BloodRequest({
    required this.id,
    required this.requesterId,
    required this.patientName,
    required this.bloodGroup,
    required this.bagsNeeded,
    required this.contactNumber,
    required this.hospitalLocation,
    required this.requestDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'bagsNeeded': bagsNeeded,
      'contactNumber': contactNumber,
      'hospitalLocation': hospitalLocation,
      'requestDate': Timestamp.fromDate(requestDate),
    };
  }

  // Create object from Firestore
  factory BloodRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return BloodRequest(
      id: documentId,
      requesterId: map['requesterId'] ?? '',
      patientName: map['patientName'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      bagsNeeded: map['bagsNeeded'] ?? 1,
      contactNumber: map['contactNumber'] ?? '',
      hospitalLocation: map['hospitalLocation'] ?? '',
      requestDate: (map['requestDate'] as Timestamp).toDate(),
    );
  }
}
