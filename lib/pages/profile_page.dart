import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/pages/request_details_page.dart';
import 'package:blood_linker/utils/logger.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;

  String? _selectedBloodType;
  DateTime? _lastDonationDate;

  @override
  void initState() {
    super.initState();
    // Load initial data from AuthManager
    final user = Provider.of<AuthManager>(context, listen: false).customUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');

    _selectedBloodType = user?.bloodType;
    _lastDonationDate = user?.lastDonationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return; // Only allow picking if editing

    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _lastDonationDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authManager = Provider.of<AuthManager>(context, listen: false);

    // Convert age text to int safely
    int? ageInt = int.tryParse(_ageController.text.trim());

    final success = await authManager.updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodType: _selectedBloodType!,
      age: ageInt,
      lastDonationDate: _lastDonationDate,
    );

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);

    // Format date for display
    String donationDateText = "No donation recorded";
    if (_lastDonationDate != null) {
      donationDateText =
          "${_lastDonationDate!.day}/${_lastDonationDate!.month}/${_lastDonationDate!.year}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        _selectedBloodType ?? '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildField(
                label: "Full Name",
                icon: Icons.person,
                isEditing: _isEditing,
                controller: _nameController,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: "Phone Number",
                icon: Icons.phone,
                isEditing: _isEditing,
                controller: _phoneController,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: "Age",
                      icon: Icons.calendar_month, // Calendar icon for Age
                      isEditing: _isEditing,
                      controller: _ageController,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBloodTypeField(_isEditing)),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isEditing ? _selectDate : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isEditing ? Colors.white : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEditing ? Colors.grey : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Constants.primaryColor),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Last Donation Date",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            donationDateText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_isEditing)
                        const Icon(Icons.calendar_today, color: Colors.blue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authManager.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authManager.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save Changes",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

              // Reserved and Interested Requests Sections
              if (!_isEditing) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                // Donation History Section
                Row(
                  children: [
                    Icon(Icons.history, color: Constants.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Donation History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDonationHistory(authManager),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                // My Reserved Request Section
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'My Reserved Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReservedRequestsList(authManager),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                // Interested Requests Section
                Row(
                  children: [
                    Icon(Icons.favorite, color: Constants.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Requests I\'m Interested In',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInterestedRequestsList(authManager),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestedRequestsList(AuthManager authManager) {
    final currentUser = authManager.user;

    if (currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Please log in to see your interested requests.'),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('interestedDonors', arrayContains: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No interested requests yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Show interest in requests to see them here',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs.toList();

        // Sort by requestDate in descending order (most recent first)
        requests.sort((a, b) {
          final aDate = a.data() as Map<String, dynamic>;
          final bDate = b.data() as Map<String, dynamic>;
          final aTimestamp = aDate['requestDate'];
          final bTimestamp = bDate['requestDate'];

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          // Compare timestamps (descending order)
          if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
            return bTimestamp.compareTo(aTimestamp);
          }
          return 0;
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            final patientName = data['patientName'] as String? ?? 'Unknown';
            final bloodGroup = data['bloodGroup'] as String? ?? 'Unknown';
            final bagsNeeded = data['bagsNeeded'] as int? ?? 0;
            final hospitalLocation =
                data['hospitalLocation'] as String? ?? 'Unknown';
            final isEmergency = data['isEmergency'] as bool? ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetailsPage(
                        requestData: data,
                        requestId: docId,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isEmergency) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'EMERGENCY',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        patientName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Constants.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        bloodGroup,
                                        style: TextStyle(
                                          color: Constants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$bagsNeeded bag${bagsNeeded > 1 ? 's' : ''} needed',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        hospitalLocation,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper Widget for Text Fields
  Widget _buildField({
    required String label,
    required IconData icon,
    required bool isEditing,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
  }) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Constants.primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (v) {
          if (label == "Age") {
            if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
              return "Invalid number";
            }
          }
          if (label == "Full Name" || label == "Phone Number") {
            return (v == null || v.isEmpty) ? "Required" : null;
          }
          return null;
        },
      );
    } else {
      // View Mode
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Constants.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    controller.text.isEmpty ? 'Not set' : controller.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper Widget for Blood Type
  Widget _buildBloodTypeField(bool isEditing) {
    if (isEditing) {
      return DropdownButtonFormField<String>(
        initialValue: _selectedBloodType,
        decoration: InputDecoration(
          labelText: "Blood",
          prefixIcon: const Icon(
            Icons.bloodtype,
            color: Constants.primaryColor,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 16,
          ),
        ),
        items: Constants.bloodTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (val) => setState(() => _selectedBloodType = val),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.bloodtype, color: Constants.primaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Blood",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  _selectedBloodType ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Future<void> _unreserveRequest(String requestId) async {
    final authManager = Provider.of<AuthManager>(context, listen: false);
    final currentUser = authManager.user;

    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unreserve Request?"),
        content: const Text(
          "This will remove your reservation and also remove your interest from this request.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Unreserve", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final requestRef = FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId);

        // Remove from both reservedDonors and interestedDonors
        await requestRef.update({
          'reservedDonors': FieldValue.arrayRemove([currentUser.uid]),
          'interestedDonors': FieldValue.arrayRemove([currentUser.uid]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
  }

  Widget _buildReservedRequestsList(AuthManager authManager) {
    final currentUser = authManager.user;

    if (currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Please log in to see your reserved requests.'),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('reservedDonors', arrayContains: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No reserved requests',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You haven\'t been reserved for any requests yet',
                  style: TextStyle(color: Colors.green[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs.toList();

        // Sort by requestDate in descending order (most recent first)
        requests.sort((a, b) {
          final aDate = a.data() as Map<String, dynamic>;
          final bDate = b.data() as Map<String, dynamic>;
          final aTimestamp = aDate['requestDate'];
          final bTimestamp = bDate['requestDate'];

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          // Compare timestamps (descending order)
          if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
            return bTimestamp.compareTo(aTimestamp);
          }
          return 0;
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            final patientName = data['patientName'] as String? ?? 'Unknown';
            final bloodGroup = data['bloodGroup'] as String? ?? 'Unknown';
            final bagsNeeded = data['bagsNeeded'] as int? ?? 0;
            final hospitalLocation =
                data['hospitalLocation'] as String? ?? 'Unknown';
            final isEmergency = data['isEmergency'] as bool? ?? false;
            final contactNumber = data['contactNumber'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                  color: Colors.green[50],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailsPage(
                          requestData: data,
                          requestId: docId,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'RESERVED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isEmergency) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'EMERGENCY',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Constants.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          bloodGroup,
                                          style: TextStyle(
                                            color: Constants.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$bagsNeeded bag${bagsNeeded > 1 ? 's' : ''} needed',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          hospitalLocation,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (contactNumber.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          contactNumber,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _unreserveRequest(docId),
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text(
                              'Unreserve',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  String _formatDonationDate(dynamic timestamp) {
    if (timestamp == null) return 'Date not available';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
    return 'Date not available';
  }

  Widget _buildDonationHistory(AuthManager authManager) {
    final currentUser = authManager.user;

    if (currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Please log in to see your donation history.'),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('donationHistory')
          .orderBy('markAsCompletedDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No donation history yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed donations will appear here',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final donations = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final doc = donations[index];
            final data = doc.data() as Map<String, dynamic>;

            final patientName = data['patientName'] as String? ?? 'Unknown';
            final contactNumber = data['contactNumber'] as String? ?? '';
            final markAsCompletedDate = data['markAsCompletedDate'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Constants.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDonationDate(markAsCompletedDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (contactNumber.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.phone, color: Constants.primaryColor),
                        onPressed: () => _makeCall(contactNumber),
                        tooltip: 'Call',
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
