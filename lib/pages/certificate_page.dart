import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blood_linker/models/donation_certificate.dart';
import 'package:blood_linker/services/certificate_service.dart';
import 'package:blood_linker/services/pdf_service.dart';
import 'package:blood_linker/widgets/common_widgets.dart';
import 'package:blood_linker/widgets/app_theme.dart';

class CertificatePage extends StatefulWidget {
  final DonationCertificate certificate;

  const CertificatePage({super.key, required this.certificate});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  final CertificateService _certificateService = CertificateServiceImpl();
  final PDFService _pdfService = CertificatePDFService();
  bool _isSharing = false;
  bool _isGeneratingPDF = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Certificate'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isGeneratingPDF ? null : _downloadPDF,
            icon: _isGeneratingPDF
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            tooltip: 'Download PDF',
          ),
          IconButton(
            onPressed: _shareCertificate,
            icon: const Icon(Icons.share),
            tooltip: 'Share Certificate',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: AppBorderRadius.lg,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: AppSpacing.xl),

              // Certificate Body
              _buildCertificateBody(),

              const SizedBox(height: AppSpacing.xl),

              // Footer with signature
              _buildSignatureSection(),

              const SizedBox(height: AppSpacing.xl),

              // Certificate Number
              _buildCertificateNumber(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.verified, size: 48, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Blood Donation Certificate',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Certificate of Appreciation',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCertificateBody() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.md,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow('Donor Name', widget.certificate.donorName),
          const Divider(),
          _buildInfoRow('Blood Type', widget.certificate.bloodType),
          const Divider(),
          _buildInfoRow(
            'Donation Date',
            widget.certificate.formattedDonationDate,
          ),
          const Divider(),
          _buildInfoRow('Donation Center', widget.certificate.donationCenter),
          const Divider(),
          _buildInfoRow(
            'Bags Donated',
            '${widget.certificate.bagsDonated} ${widget.certificate.bagsDonated == 1 ? 'bag' : 'bags'}',
          ),
          const Divider(),
          _buildInfoRow('Date Issued', widget.certificate.formattedIssuedDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      children: [
        Text(
          'This certifies that the above named individual has made a generous donation of blood, contributing to the noble cause of saving lives.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
          ),
          child: Column(
            children: [
              Text(
                widget.certificate.issuerName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.certificate.issuerSignature,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'BloodLinker Organization',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateNumber() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: AppBorderRadius.md,
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Certificate #: ${widget.certificate.certificateNumber}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPDF() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdfPath = await _pdfService.generateCertificatePDF(
        widget.certificate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Certificate PDF downloaded successfully!'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // In a real app, you would open the PDF file
                print('PDF saved at: $pdfPath');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download PDF: $e')));
      }
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  Future<void> _shareCertificate() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final shareUrl = await _certificateService.shareCertificate(
        widget.certificate.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate shared! Link: $shareUrl'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // In a real app, you would copy to clipboard
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share certificate: $e')),
        );
      }
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }
}
