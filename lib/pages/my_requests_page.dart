import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_linker/pages/request_blood_page.dart'; // <--- IMPORT THIS

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the current logged-in user's ID
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text("Please log in."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('userId', isEqualTo: user.uid) // Filters for YOUR data
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Empty State
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "You haven't posted any requests.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Data List
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildMyRequestCard(context, doc.id, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildMyRequestCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Blood Group Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['bloodGroup'] ?? 'N/A',
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // --- CHANGED SECTION: ACTION BUTTONS ---
                Row(
                  children: [
                    // 1. EDIT BUTTON (Blue Pencil)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Request',
                      onPressed: () {
                        // Navigate to Request Page in "Edit Mode"
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestBloodPage(
                              requestId: docId, // Pass ID so it knows to UPDATE
                              initialData:
                                  data, // Pass Data so it fills the form
                            ),
                          ),
                        );
                      },
                    ),

                    // 2. DELETE BUTTON (Red Trash Can)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete Request',
                      onPressed: () => _confirmDelete(context, docId),
                    ),
                  ],
                ),
                // ---------------------------------------
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Patient: ${data['patientName'] ?? 'Unknown'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              "Location: ${data['hospitalLocation'] ?? 'Unknown'}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              "Bags: ${data['bagsNeeded']}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to show "Are you sure?" dialog
  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Request?"),
        content: const Text(
          "This will permanently remove this request from the live feed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              // Perform Delete
              await FirebaseFirestore.instance
                  .collection('requests')
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request deleted successfully")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
