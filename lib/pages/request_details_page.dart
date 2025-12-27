import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:blood_linker/constants.dart';
import 'package:blood_linker/utils/logger.dart';
import 'package:blood_linker/auth/auth_manager.dart';

class RequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const RequestDetailsPage({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  bool _isInterested = false;
  bool _isLoading = false;

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

  String _formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      }
      if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      }
      if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
      return 'Just now';
    }
    return '';
  }

  String _formatWhenNeeded(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    if (timestamp is Timestamp) {
      final dateStr = _formatHumanReadableDate(timestamp);
      final timeStr = _formatTime(timestamp);
      return '$dateStr at $timeStr';
    }
    return 'Not specified';
  }

  String _formatHumanReadableDate(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
    return 'Not specified';
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
    return 'Not specified';
  }

  String _normalizeBloodGroup(String bloodType) {
    // Convert various blood type formats to standard format (e.g., "A+")
    if (bloodType.contains('(+ve)')) {
      return bloodType.replaceAll(' (+ve)', '+').replaceAll('(+ve)', '+');
    }
    if (bloodType.contains('(-ve)')) {
      return bloodType.replaceAll(' (-ve)', '-').replaceAll('(-ve)', '-');
    }
    if (bloodType.toLowerCase().contains('positive') ||
        bloodType.toLowerCase().contains('negative')) {
      final clean = bloodType.toLowerCase();
      final sign = clean.contains('positive') ? '+' : '-';
      final type = clean
          .replaceAll('positive', '')
          .replaceAll('negative', '')
          .trim()
          .toUpperCase();
      return '$type$sign';
    }
    // If already in standard format (A+, B-, etc.), return as is
    return bloodType.trim();
  }

  bool _isEligible(String? userBloodType, String patientBloodGroup) {
    if (userBloodType == null || userBloodType.isEmpty) return false;

    final normalizedUser = _normalizeBloodGroup(userBloodType);
    final normalizedPatient = _normalizeBloodGroup(patientBloodGroup);

    return normalizedUser == normalizedPatient;
  }

  Future<void> _handleInterested() async {
    final authManager = Provider.of<AuthManager>(context, listen: false);
    final user = authManager.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to show interest')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId);

      // Get current interestedDonors array
      final doc = await requestRef.get();
      final currentData = doc.data();
      final currentInterested =
          (currentData?['interestedDonors'] as List<dynamic>?) ?? [];

      // Check if user is already in the list - toggle interest
      if (currentInterested.contains(user.uid)) {
        // Remove user ID from the array
        await requestRef.update({
          'interestedDonors': FieldValue.arrayRemove([user.uid]),
        });

        setState(() {
          _isInterested = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interest removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Add user ID to the array
      await requestRef.update({
        'interestedDonors': FieldValue.arrayUnion([user.uid]),
      });

      setState(() {
        _isInterested = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for showing interest!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error adding interest', e);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    final bloodGroup = widget.requestData['bloodGroup'] as String? ?? 'Unknown';
    final bagsNeeded = widget.requestData['bagsNeeded'] as int? ?? 1;
    final hospitalName = widget.requestData['hospitalName'] as String?;
    final requestDate = widget.requestData['requestDate'];
    final whenNeeded = widget.requestData['whenNeeded'];
    final contactNumber = widget.requestData['contactNumber'] as String? ?? '';
    final additionalNotes = widget.requestData['additionalNotes'] as String?;
    final isEmergency = widget.requestData['isEmergency'] as bool? ?? false;

    // Build the share text
    final buffer = StringBuffer();

    // First line: Emergency prefix (if applicable) + bags and blood group
    if (isEmergency) {
      buffer.write('Emergency: ');
    }
    buffer.write(
      '$bagsNeeded bag${bagsNeeded > 1 ? 's' : ''} of $bloodGroup blood needed.\n',
    );

    // Hospital
    buffer.write('Hospital: ${hospitalName ?? 'Not specified'}\n');

    // Date
    final dateStr = _formatHumanReadableDate(requestDate);
    buffer.write('Date: $dateStr\n');

    // Time (when needed)
    if (whenNeeded != null) {
      final timeStr = _formatTime(whenNeeded);
      buffer.write('Time: $timeStr\n');
    }

    // Contact
    buffer.write('Contact: $contactNumber\n');

    // Notes
    if (additionalNotes != null && additionalNotes.isNotEmpty) {
      buffer.write('Notes: $additionalNotes');
    } else {
      buffer.write('Notes: None');
    }

    final shareText = buffer.toString();

    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request details copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error copying to clipboard', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error copying to clipboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if user is already interested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfInterested();
    });
  }

  Future<void> _checkIfInterested() async {
    final authManager = Provider.of<AuthManager>(context, listen: false);
    final user = authManager.user;

    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .get();

      final data = doc.data();
      final interestedDonors =
          (data?['interestedDonors'] as List<dynamic>?) ?? [];

      if (mounted) {
        setState(() {
          _isInterested = interestedDonors.contains(user.uid);
        });
      }
    } catch (e) {
      AppLogger.error('Error checking interest status', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);
    final user = authManager.customUser;

    // Handle both double and num types from Firestore
    final latValue = widget.requestData['latitude'];
    final lngValue = widget.requestData['longitude'];
    final latitude = latValue != null
        ? (latValue is num ? latValue.toDouble() : latValue as double?)
        : null;
    final longitude = lngValue != null
        ? (lngValue is num ? lngValue.toDouble() : lngValue as double?)
        : null;
    final hospitalName = widget.requestData['hospitalName'] as String?;
    final address = widget.requestData['address'] as String?;
    final contactNumber = widget.requestData['contactNumber'] as String? ?? '';
    final patientName = widget.requestData['patientName'] as String? ?? 'N/A';
    final bloodGroup = widget.requestData['bloodGroup'] as String? ?? 'Unknown';
    final bagsNeeded = widget.requestData['bagsNeeded'] as int? ?? 1;
    final requestDate = widget.requestData['requestDate'];
    final age = widget.requestData['age'] as int?;
    final gender = widget.requestData['gender'] as String?;
    final whenNeeded = widget.requestData['whenNeeded'];
    final isEmergency = widget.requestData['isEmergency'] as bool? ?? false;
    final additionalNotes = widget.requestData['additionalNotes'] as String?;

    final isEligible = _isEligible(user?.bloodType, bloodGroup);

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
                    // Relative time subtitle
                    if (_formatRelativeTime(requestDate).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          "Posted ${_formatRelativeTime(requestDate)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'EMERGENCY',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Eligibility Chip
                    if (isEligible)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "You're Eligible",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Not Eligible',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildInfoRow('Patient Name', patientName),
                    if (age != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Age', '$age years'),
                    ],
                    if (gender != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Gender', gender),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow('Bags Needed', '$bagsNeeded'),
                    if (whenNeeded != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'When Needed',
                        _formatWhenNeeded(whenNeeded),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Interested Button (shown when eligible)
                    if (isEligible)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleInterested,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isInterested ? Icons.check : Icons.favorite,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isInterested
                                ? 'Remove Interest'
                                : 'I\'m Interested',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInterested
                                ? Colors.orange[700]
                                : Constants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    // Share Button (shown for both eligible and not eligible)
                    if (isEligible) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleShare,
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text(
                          'Share Request',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          'Hospital Address',
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
                      address ?? hospitalName ?? 'Address not available',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (additionalNotes != null &&
                        additionalNotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Additional Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        additionalNotes,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
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
