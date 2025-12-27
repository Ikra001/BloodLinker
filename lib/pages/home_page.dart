import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/pages/request_blood_page.dart';
import 'package:blood_linker/pages/welcome_page.dart';
import 'package:blood_linker/utils/logger.dart';
import 'package:blood_linker/pages/my_requests_page.dart'; // <--- ADDED IMPORT

class HomePage extends StatelessWidget {
  static const route = '/home';

  const HomePage({super.key});

  Future<void> onPressedLogout(BuildContext context) async {
    final authManager = Provider.of<AuthManager>(context, listen: false);

    await authManager.logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        title: const Text('BloodLinker Dashboard'),
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- NEW: My Requests Button ---
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyRequestsPage()),
              );
            },
            icon: const Icon(Icons.history), // Clock/History icon
            tooltip: 'My Requests',
          ),

          // --- End New Button ---
          IconButton(
            onPressed: () => onPressedLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. TOP SECTION: User Info & Actions
          _buildTopSection(context),

          // 2. HEADER: "Recent Requests"
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Text(
                  "Recent Requests",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Live Feed",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 3. BOTTOM SECTION: The Feed (StreamBuilder)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Listen to the 'requests' collection, ordered by newest first
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .orderBy('requestDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Handling Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handling Error State
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // Handling Empty State
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No blood requests found nearby."),
                  );
                }

                // Displaying the List
                final requests = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data = requests[index].data() as Map<String, dynamic>;
                    return _buildRequestCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  // The Profile and "Request Blood" Button Section
  Widget _buildTopSection(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);
    final user = authManager.customUser;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: const BoxDecoration(
        color: Constants.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  // Use the helper function here
                  _getDisplayBloodGroup(user?.bloodType),
                  style: const TextStyle(
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${user?.name ?? 'User'}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Donate Blood, Save Lives.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    if (user?.lastDonationDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Last donation: ${_formatLastDonationDate(user!.lastDonationDate!)}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "No donation recorded",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestBloodPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add_alert, color: Constants.primaryColor),
              label: const Text(
                'Request Blood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.primaryColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP ROW: Blood Group & Location ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['bloodGroup'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Constants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data['hospitalLocation'] ?? 'Unknown Location',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- MIDDLE ROW: Patient Name & Bags ---
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text("Patient: ${data['patientName'] ?? 'N/A'}"),
                const Spacer(),
                const Icon(Icons.local_hospital, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text("${data['bagsNeeded']} Bags"),
              ],
            ),

            // --- TIME ROW (ADDED HERE) ---
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Posted: ${_formatTimestamp(data['requestDate'])}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- BOTTOM ROW: The Call Button (FIXED) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // 1. Get the number
                  String phoneNumber = data['contactNumber'] ?? '';

                  // 2. Simple check: Is there a number?
                  if (phoneNumber.isNotEmpty) {
                    // 3. Create the command to open the dialer
                    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

                    // 4. FORCE open the dialer (we removed the 'if' check)
                    try {
                      await launchUrl(launchUri);
                    } catch (e) {
                      AppLogger.error('Error launching phone dialer', e);
                    }
                  }
                },
                icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                label: const Text(
                  "Call to Donate",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small helper to show "Just now" or date
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

  // Helper to display blood type (already in A+ format)
  String _getDisplayBloodGroup(String? bloodType) {
    if (bloodType == null || bloodType.isEmpty) return "N/A";

    // Handle legacy formats if any exist in database
    if (bloodType.contains('(+ve)')) {
      return bloodType.replaceAll(' (+ve)', '+');
    }
    if (bloodType.contains('(-ve)')) {
      return bloodType.replaceAll(' (-ve)', '-');
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

    return bloodType;
  }

  // Helper to format last donation date
  String _formatLastDonationDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}
