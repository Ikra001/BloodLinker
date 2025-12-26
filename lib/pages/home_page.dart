import 'package:blood_linker/pages/welcome_page.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for database access
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_linker/pages/request_blood_page.dart';

class HomePage extends StatelessWidget {
  static const route = '/home';

  const HomePage({super.key});

  Future<void> onPressedLogout(BuildContext context) async {
    final authManager = Provider.of<AuthManager>(context, listen: false);
    await authManager.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, WelcomePage.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        title: const Text('BloodLinker Dashboard'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
        color: Color(0xFFB71C1C),
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
                  user?.bloodType.name.substring(0, 2).toUpperCase() ?? "O+",
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
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
                    "Donate Life, Save Lives.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
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
              icon: const Icon(Icons.add_alert, color: Color(0xFFB71C1C)),
              label: const Text(
                'Request Blood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C),
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

  // The Individual Request Card in the list
  Widget _buildRequestCard(Map<String, dynamic> data) {
    // Handling Timestamp safely
    // Note: Firestore returns a Timestamp, we need to convert it to DateTime logic if needed
    // For now we just show the static data

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      color: Color(0xFFB71C1C),
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0E0E0),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Future: Add Call Functionality here
                  // Helper function to launch phone dialer
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Donate Now",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
