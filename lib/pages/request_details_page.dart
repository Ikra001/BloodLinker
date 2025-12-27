import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:blood_linker/constants.dart';
import 'package:blood_linker/utils/logger.dart';

class RequestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const RequestDetailsPage({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      AppLogger.error('Error launching phone dialer', e);
    }
  }

  Future<void> _openDirections(
    BuildContext context,
    double? latitude,
    double? longitude,
  ) async {
    if (latitude == null || longitude == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates not available')),
        );
      }
      return;
    }

    // Try launching directly - canLaunchUrl can be unreliable
    // We'll try multiple URL schemes and catch errors

    // 1. Try Google Maps web URL first (most reliable, works everywhere)
    try {
      final googleMapsWebUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
      final launched = await launchUrl(
        googleMapsWebUrl,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      AppLogger.error('Google Maps web launch failed', e);
    }

    // 2. Try Google Maps app (Android)
    try {
      final googleMapsAppUrl = Uri.parse(
        'comgooglemaps://?q=$latitude,$longitude',
      );
      final launched = await launchUrl(
        googleMapsAppUrl,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      AppLogger.error('Google Maps app launch failed', e);
    }

    // 3. Try geo: scheme (Android default maps)
    try {
      final geoUrl = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude',
      );
      final launched = await launchUrl(
        geoUrl,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      AppLogger.error('Geo scheme launch failed', e);
    }

    // 4. Try Apple Maps (iOS)
    try {
      final appleMapsUrl = Uri.parse(
        'https://maps.apple.com/?q=$latitude,$longitude&ll=$latitude,$longitude',
      );
      final launched = await launchUrl(
        appleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      AppLogger.error('Apple Maps launch failed', e);
    }

    // 5. Last resort: Try opening in platform default (might open browser)
    try {
      final fallbackUrl = Uri.parse(
        'https://www.google.com/maps?q=$latitude,$longitude',
      );
      await launchUrl(fallbackUrl, mode: LaunchMode.platformDefault);
      return;
    } catch (e) {
      AppLogger.error('All map launch attempts failed', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open maps. Please install Google Maps or use a web browser.',
            ),
          ),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays} days ago';
      if (difference.inHours > 0) return '${difference.inHours} hours ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes} mins ago';
      return 'Just now';
    }
    return 'Recently';
  }

  @override
  Widget build(BuildContext context) {
    // Handle both double and num types from Firestore
    final latValue = requestData['latitude'];
    final lngValue = requestData['longitude'];
    final latitude = latValue != null
        ? (latValue is num ? latValue.toDouble() : latValue as double?)
        : null;
    final longitude = lngValue != null
        ? (lngValue is num ? lngValue.toDouble() : lngValue as double?)
        : null;
    final hospitalName = requestData['hospitalName'] as String?;
    final hospitalLocation =
        requestData['hospitalLocation'] as String? ?? 'Unknown Location';
    final contactNumber = requestData['contactNumber'] as String? ?? '';
    final patientName = requestData['patientName'] as String? ?? 'N/A';
    final bloodGroup = requestData['bloodGroup'] as String? ?? 'Unknown';
    final bagsNeeded = requestData['bagsNeeded'] as int? ?? 1;
    final requestDate = requestData['requestDate'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Constants.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Patient Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Blood Group Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 214, 220),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bloodGroup,
                            style: const TextStyle(
                              color: Constants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Patient Name', patientName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Bags Needed', '$bagsNeeded'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Posted', _formatTimestamp(requestDate)),
                    const SizedBox(height: 16),
                    // Call Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: contactNumber.isNotEmpty
                            ? () => _makeCall(contactNumber)
                            : null,
                        icon: const Icon(Icons.phone, color: Colors.white),
                        label: const Text(
                          'Call',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: Constants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Hospital Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hospitalName != null && hospitalName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          hospitalName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      hospitalLocation,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    // Directions Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (latitude != null && longitude != null)
                            ? () =>
                                  _openDirections(context, latitude, longitude)
                            : null,
                        icon: const Icon(Icons.directions, color: Colors.white),
                        label: const Text(
                          'Directions',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
