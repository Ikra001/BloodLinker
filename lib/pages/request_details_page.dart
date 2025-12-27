import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:blood_linker/constants.dart';
import 'package:blood_linker/utils/logger.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/pages/request_blood_page.dart';

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
  String? _requesterName;
  bool _isUserReserved = false;
  bool _isInitialLoading = true;

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
    // Check if user is already interested and load requester name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // Load all initial data in parallel
    await Future.wait([
      _checkIfInterested(),
      _loadRequesterName(),
      _checkIfUserReserved(),
    ]);

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _checkIfUserReserved() async {
    final authManager = Provider.of<AuthManager>(context, listen: false);
    final user = authManager.user;

    if (user == null) return;

    try {
      // Check if user is reserved in any request
      final reservedSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('reservedDonors', arrayContains: user.uid)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isUserReserved = reservedSnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      AppLogger.error('Error checking if user is reserved', e);
    }
  }

  Future<void> _loadRequesterName() async {
    try {
      final userId = widget.requestData['userId'] as String?;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        final name = userData?['name'] as String?;
        setState(() {
          _requesterName = name ?? 'Unknown';
        });
      } else if (mounted) {
        setState(() {
          _requesterName = 'Unknown';
        });
      }
    } catch (e) {
      AppLogger.error('Error loading requester name', e);
      if (mounted) {
        setState(() {
          _requesterName = 'Unknown';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDonorsData(
    List<dynamic> interestedDonorIds,
    List<dynamic> reservedDonorIds,
  ) async {
    final List<Map<String, dynamic>> donors = [];

    for (final donorId in interestedDonorIds) {
      if (donorId is! String) continue;

      try {
        final donorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(donorId)
            .get();

        if (donorDoc.exists) {
          final donorData = donorDoc.data();
          donors.add({
            'id': donorId,
            'name': donorData?['name'] ?? 'Unknown',
            'phone': donorData?['phone'] ?? '',
            'isReserved': reservedDonorIds.contains(donorId),
          });
        }
      } catch (e) {
        AppLogger.error('Error loading donor data for $donorId', e);
      }
    }

    return donors;
  }

  Future<void> _unreserveDonor(String donorId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId);

      // Remove from reservedDonors (but keep in interestedDonors)
      await requestRef.update({
        'reservedDonors': FieldValue.arrayRemove([donorId]),
      });

      // The StreamBuilder will automatically update the list

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donor unreserved successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error unreserving donor', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsCompleted() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current request data to find reserved donor
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .get();

      final requestData = requestDoc.data();
      final reservedDonors =
          (requestData?['reservedDonors'] as List<dynamic>?) ?? [];

      if (reservedDonors.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No donor is reserved for this request'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get the reserved donor ID (should be only one)
      final reservedDonorId = reservedDonors[0] as String;

      // Get patient information from request
      final patientName =
          widget.requestData['patientName'] as String? ?? 'Unknown';
      final contactNumber =
          widget.requestData['contactNumber'] as String? ?? '';

      // Add donation entry to the donor's donationHistory collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(reservedDonorId)
          .collection('donationHistory')
          .add({
            'patientName': patientName,
            'contactNumber': contactNumber,
            'markAsCompletedDate': FieldValue.serverTimestamp(),
            'requestId': widget.requestId,
          });

      // Update the donor's lastDonationDate
      await FirebaseFirestore.instance
          .collection('users')
          .doc(reservedDonorId)
          .update({'lastDonationDate': FieldValue.serverTimestamp()});

      // Delete the request after marking as completed
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .delete();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request marked as completed and removed!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back after deletion
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('Error marking request as completed', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reserveDonor(String donorId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId);

      // Get current document to check for existing reserved donors
      final currentDoc = await requestRef.get();
      final currentData = currentDoc.data();
      final currentReservedDonors =
          (currentData?['reservedDonors'] as List<dynamic>?) ?? [];

      // Rule: A requester can reserve only one donor
      // If there's already a reserved donor, remove them first
      if (currentReservedDonors.isNotEmpty) {
        final previousDonorId = currentReservedDonors[0] as String;
        // If trying to reserve the same donor, do nothing
        if (previousDonorId == donorId) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
        // Remove the previous reserved donor
        await requestRef.update({
          'reservedDonors': FieldValue.arrayRemove([previousDonorId]),
        });
      }

      // Add the new reserved donor
      await requestRef.update({
        'reservedDonors': FieldValue.arrayUnion([donorId]),
      });

      // Remove donor from interestedDonors of all other requests
      // (they can't donate to others when reserved)
      final allRequestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('interestedDonors', arrayContains: donorId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in allRequestsSnapshot.docs) {
        // Skip the current request (keep them interested in the request they're reserved for)
        if (doc.id != widget.requestId) {
          batch.update(doc.reference, {
            'interestedDonors': FieldValue.arrayRemove([donorId]),
          });
        }
      }
      await batch.commit();

      // The StreamBuilder will automatically update the list

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donor reserved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error reserving donor', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit() async {
    // Navigate to edit page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestBloodPage(
          requestId: widget.requestId,
          initialData: widget.requestData,
        ),
      ),
    );

    // If the edit was successful, pop this page to refresh
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Request?"),
        content: const Text(
          "This will permanently remove this request from the live feed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Request deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        AppLogger.error('Error deleting request', e);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    214,
                                    220,
                                  ),
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
                              child: Builder(
                                builder: (context) {
                                  final requestUserId =
                                      widget.requestData['userId'] as String?;
                                  final currentUserId = authManager.user?.uid;
                                  final isCurrentUser =
                                      requestUserId != null &&
                                      currentUserId != null &&
                                      requestUserId == currentUserId;

                                  final postedText = isCurrentUser
                                      ? "Posted ${_formatRelativeTime(requestDate)} by you"
                                      : _requesterName != null
                                      ? "Posted ${_formatRelativeTime(requestDate)} by $_requesterName"
                                      : "Posted ${_formatRelativeTime(requestDate)}";

                                  return Text(
                                    postedText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  );
                                },
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
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2,
                                ),
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
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                ),
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
                          // Share Button (shown for both eligible and not eligible)
                          if (isEligible) const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleShare,
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Share Request',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Call',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Constants.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Edit/Delete buttons (shown if current user is requester) or Interested button (shown if eligible and not requester)
                          Builder(
                            builder: (context) {
                              final authManager = Provider.of<AuthManager>(
                                context,
                              );
                              final currentUser = authManager.user;
                              final requestUserId =
                                  widget.requestData['userId'] as String?;
                              final isRequester =
                                  currentUser != null &&
                                  requestUserId != null &&
                                  requestUserId == currentUser.uid;

                              if (isRequester) {
                                // Show Edit and Delete buttons for requester
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleEdit,
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Edit Request',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[700],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleDelete,
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Delete Request',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[700],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else if (isEligible && !_isUserReserved) {
                                // Show Interested button for eligible users who are not the requester and not already reserved
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleInterested,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            _isInterested
                                                ? Icons.check
                                                : Icons.favorite,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      _isInterested
                                          ? 'Remove Interest'
                                          : 'I\'m Interested',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isInterested
                                          ? Colors.orange[700]
                                          : Constants.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interested Donors List (only shown if current user is the requester)
                  Builder(
                    builder: (context) {
                      final authManager = Provider.of<AuthManager>(context);
                      final currentUser = authManager.user;
                      final requestUserId =
                          widget.requestData['userId'] as String?;
                      final isRequester =
                          currentUser != null &&
                          requestUserId != null &&
                          requestUserId == currentUser.uid;

                      if (!isRequester) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                        Icons.favorite,
                                        color: Constants.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Interested Donors',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('requests')
                                        .doc(widget.requestId)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      if (!snapshot.hasData) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'No donors have shown interest yet.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }

                                      final requestData =
                                          snapshot.data!.data()
                                              as Map<String, dynamic>?;
                                      final interestedDonorIds =
                                          (requestData?['interestedDonors']
                                              as List<dynamic>?) ??
                                          [];
                                      final reservedDonorIds =
                                          (requestData?['reservedDonors']
                                              as List<dynamic>?) ??
                                          [];

                                      if (interestedDonorIds.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'No donors have shown interest yet.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }

                                      return FutureBuilder<
                                        List<Map<String, dynamic>>
                                      >(
                                        future: _fetchDonorsData(
                                          interestedDonorIds,
                                          reservedDonorIds,
                                        ),
                                        builder: (context, donorsSnapshot) {
                                          if (donorsSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }

                                          final donors =
                                              donorsSnapshot.data ?? [];

                                          if (donors.isEmpty) {
                                            return Padding(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Text(
                                                'No donors have shown interest yet.',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }

                                          return Column(
                                            children: donors.map((donor) {
                                              final isReserved =
                                                  donor['isReserved']
                                                      as bool? ??
                                                  false;
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isReserved
                                                      ? Colors.green[50]
                                                      : Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isReserved
                                                        ? Colors.green
                                                        : Colors.grey[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                donor['name']
                                                                        as String? ??
                                                                    'Unknown',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Call button
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.phone,
                                                        color: Constants
                                                            .primaryColor,
                                                      ),
                                                      onPressed: () {
                                                        final phone =
                                                            donor['phone']
                                                                as String? ??
                                                            '';
                                                        if (phone.isNotEmpty) {
                                                          _makeCall(phone);
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Phone number not available',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.orange,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      tooltip: 'Call donor',
                                                    ),
                                                    // Reserve/Unreserve button
                                                    ElevatedButton(
                                                      onPressed: _isLoading
                                                          ? null
                                                          : isReserved
                                                          ? () =>
                                                                _unreserveDonor(
                                                                  donor['id']
                                                                      as String,
                                                                )
                                                          : () => _reserveDonor(
                                                              donor['id']
                                                                  as String,
                                                            ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            isReserved
                                                            ? Colors.red[700]
                                                            : Colors.green[700],
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        isReserved
                                                            ? 'Unreserve'
                                                            : 'Reserve',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Mark as Completed button (shown if there's a reserved donor)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('requests')
                                .doc(widget.requestId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final requestData =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;
                              final reservedDonors =
                                  (requestData?['reservedDonors']
                                      as List<dynamic>?) ??
                                  [];

                              if (reservedDonors.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.blue[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.blue[700],
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Reserved Donor',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Mark this request as completed when the donation has been received.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoading
                                              ? null
                                              : _markAsCompleted,
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                          label: const Text(
                                            'Mark as Completed',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[700],
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Directions Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (latitude != null && longitude != null)
                                  ? () => _openDirections(
                                      context,
                                      latitude,
                                      longitude,
                                    )
                                  : null,
                              icon: const Icon(
                                Icons.directions,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Directions',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
