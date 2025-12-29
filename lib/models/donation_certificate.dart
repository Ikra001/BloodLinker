class DonationCertificate {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodType;
  final DateTime donationDate;
  final String donationCenter;
  final int bagsDonated;
  final String certificateNumber;
  final DateTime issuedDate;
  final String issuerName;
  final String issuerSignature;
  final Map<String, dynamic>? additionalData;

  const DonationCertificate({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.bloodType,
    required this.donationDate,
    required this.donationCenter,
    required this.bagsDonated,
    required this.certificateNumber,
    required this.issuedDate,
    required this.issuerName,
    required this.issuerSignature,
    this.additionalData,
  });

  factory DonationCertificate.fromMap(Map<String, dynamic> map) {
    return DonationCertificate(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      bloodType: map['bloodType'] ?? '',
      donationDate: DateTime.fromMillisecondsSinceEpoch(
        map['donationDate'] ?? 0,
      ),
      donationCenter: map['donationCenter'] ?? '',
      bagsDonated: map['bagsDonated'] ?? 1,
      certificateNumber: map['certificateNumber'] ?? '',
      issuedDate: DateTime.fromMillisecondsSinceEpoch(map['issuedDate'] ?? 0),
      issuerName: map['issuerName'] ?? '',
      issuerSignature: map['issuerSignature'] ?? '',
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'bloodType': bloodType,
      'donationDate': donationDate.millisecondsSinceEpoch,
      'donationCenter': donationCenter,
      'bagsDonated': bagsDonated,
      'certificateNumber': certificateNumber,
      'issuedDate': issuedDate.millisecondsSinceEpoch,
      'issuerName': issuerName,
      'issuerSignature': issuerSignature,
      'additionalData': additionalData,
    };
  }

  String get formattedDonationDate =>
      '${donationDate.day}/${donationDate.month}/${donationDate.year}';
  String get formattedIssuedDate =>
      '${issuedDate.day}/${issuedDate.month}/${issuedDate.year}';
}
