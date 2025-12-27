import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';

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
              // --- AVATAR ---
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

              // --- NAME ---
              _buildField(
                label: "Full Name",
                icon: Icons.person,
                isEditing: _isEditing,
                controller: _nameController,
              ),
              const SizedBox(height: 16),

              // --- PHONE ---
              _buildField(
                label: "Phone Number",
                icon: Icons.phone,
                isEditing: _isEditing,
                controller: _phoneController,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // --- ROW: AGE & BLOOD TYPE ---
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

              // --- LAST DONATION DATE PICKER ---
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
            ],
          ),
        ),
      ),
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
            if (v != null && v.isNotEmpty && int.tryParse(v) == null)
              return "Invalid number";
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
        value: _selectedBloodType,
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
}
