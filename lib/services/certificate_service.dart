import 'dart:math';
import 'package:blood_linker/models/donation_certificate.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

abstract class CertificateService {
  Future<DonationCertificate> generateCertificate({
    required String donorId,
    required String donorName,
    required String bloodType,
    required DateTime donationDate,
    required String donationCenter,
    required int bagsDonated,
  });
  Future<DonationCertificate?> getCertificate(String certificateId);
  Future<List<DonationCertificate>> getUserCertificates(String donorId);
  Future<String> shareCertificate(String certificateId);
}

class CertificateServiceImpl implements CertificateService {
  static const String _issuerName = 'BloodLinker Organization';
  static const String _issuerSignature =
      'Dr. Sarah Johnson, MD - Chief Medical Officer';

  @override
  Future<DonationCertificate> generateCertificate({
    required String donorId,
    required String donorName,
    required String bloodType,
    required DateTime donationDate,
    required String donationCenter,
    required int bagsDonated,
  }) async {
    try {
      final certificateNumber = _generateCertificateNumber();
      final issuedDate = DateTime.now();

      final certificate = DonationCertificate(
        id: _generateCertificateId(),
        donorId: donorId,
        donorName: donorName,
        bloodType: bloodType,
        donationDate: donationDate,
        donationCenter: donationCenter,
        bagsDonated: bagsDonated,
        certificateNumber: certificateNumber,
        issuedDate: issuedDate,
        issuerName: _issuerName,
        issuerSignature: _issuerSignature,
        additionalData: {
          'generatedAt': issuedDate.millisecondsSinceEpoch,
          'version': '1.0',
        },
      );

      // In a real app, you would save this to a database
      // For now, we'll just return the certificate

      return certificate;
    } catch (e) {
      throw DatabaseException(
        'Failed to generate certificate: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<DonationCertificate?> getCertificate(String certificateId) async {
    // In a real app, you would fetch from database
    // For now, return null as we don't have persistence
    return null;
  }

  @override
  Future<List<DonationCertificate>> getUserCertificates(String donorId) async {
    // In a real app, you would fetch from database
    // For now, return empty list
    return [];
  }

  @override
  Future<String> shareCertificate(String certificateId) async {
    // In a real app, you would generate a shareable link or PDF
    // For now, return a placeholder
    return 'https://bloodlinker.com/certificates/$certificateId';
  }

  String _generateCertificateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'CERT-$timestamp-$random';
  }

  String _generateCertificateNumber() {
    final year = DateTime.now().year;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'BL-$year-$random';
  }
}
