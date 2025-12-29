import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:blood_linker/models/donation_certificate.dart';

abstract class PDFService {
  Future<String> generateCertificatePDF(DonationCertificate certificate);
  Future<String> savePDF(Uint8List pdfBytes, String fileName);
  Future<bool> sharePDF(String filePath);
}

class CertificatePDFService implements PDFService {
  @override
  Future<String> generateCertificatePDF(DonationCertificate certificate) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.red, width: 3),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
            ),
            child: pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(10),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'BloodLinker Organization',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Certificate of Blood Donation',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Certificate Title
                pw.Text(
                  'Certificate of Appreciation',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 20),

                // Certificate Body
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(10),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'This certifies that',
                        style: const pw.TextStyle(fontSize: 16),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        certificate.donorName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'has made a generous donation of blood on',
                        style: const pw.TextStyle(fontSize: 16),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        certificate.formattedDonationDate,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'at ${certificate.donationCenter}',
                        style: const pw.TextStyle(fontSize: 16),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Blood Type Badge
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(25),
                    ),
                  ),
                  child: pw.Text(
                    'Blood Type: ${certificate.bloodType}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // Bags Donated
                pw.Text(
                  'Bags Donated: ${certificate.bagsDonated}',
                  style: const pw.TextStyle(fontSize: 16),
                  textAlign: pw.TextAlign.center,
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Certificate Number: ${certificate.certificateNumber}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Issued on: ${certificate.formattedIssuedDate}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        certificate.issuerName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        certificate.issuerSignature,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // QR Code placeholder (you could add actual QR code generation)
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'QR\nCODE',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final fileName =
        'blood_certificate_${certificate.certificateNumber.replaceAll('/', '_')}.pdf';
    return await savePDF(pdfBytes, fileName);
  }

  @override
  Future<String> savePDF(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return filePath;
  }

  @override
  Future<bool> sharePDF(String filePath) async {
    try {
      // In a real implementation, you would use share_plus package
      // For now, just return true as the file is saved locally
      print('PDF saved at: $filePath');
      return true;
    } catch (e) {
      print('Failed to share PDF: $e');
      return false;
    }
  }
}
