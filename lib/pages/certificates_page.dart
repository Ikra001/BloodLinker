import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/models/donation_certificate.dart';
import 'package:blood_linker/services/certificate_service.dart';
import 'package:blood_linker/pages/certificate_page.dart';
import 'package:blood_linker/widgets/common_widgets.dart';
import 'package:blood_linker/widgets/app_theme.dart';

class CertificatesPage extends StatefulWidget {
  static const route = '/certificates';

  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  List<DonationCertificate> _certificates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final certificateService = Provider.of<CertificateService>(
        context,
        listen: false,
      );

      // For now, we'll generate a sample certificate for demo
      // In a real app, you'd fetch from a database
      final user = authManager.customUser;
      if (user != null) {
        final sampleCertificate = await certificateService.generateCertificate(
          donorId: user.userId,
          donorName: user.name,
          bloodType: user.bloodType,
          donationDate: DateTime.now().subtract(const Duration(days: 30)),
          donationCenter: 'City General Hospital',
          bagsDonated: 1,
        );

        _certificates = [sampleCertificate];
      }
    } catch (e) {
      _error = 'Failed to load certificates: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCertificates,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    text: 'Retry',
                    onPressed: _loadCertificates,
                    width: 120,
                  ),
                ],
              ),
            )
          : _certificates.isEmpty
          ? EmptyState(
              icon: Icons.verified,
              title: 'No Certificates Yet',
              subtitle: 'Complete a blood donation to earn your certificate.',
              action: PrimaryButton(
                text: 'Schedule Donation',
                onPressed: () => Navigator.pushNamed(context, '/appointment'),
                width: 160,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _certificates.length,
              itemBuilder: (context, index) {
                final certificate = _certificates[index];
                return _buildCertificateCard(certificate);
              },
            ),
    );
  }

  Widget _buildCertificateCard(DonationCertificate certificate) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CertificatePage(certificate: certificate),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Donation Certificate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      certificate.donorName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  'Date: ${certificate.formattedDonationDate}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.location_on,
                  certificate.donationCenter,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.bloodtype,
                  'Type: ${certificate.bloodType}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.inventory,
                  '${certificate.bagsDonated} Bag${certificate.bagsDonated > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: AppBorderRadius.sm,
            ),
            child: Text(
              'Certificate #: ${certificate.certificateNumber}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
