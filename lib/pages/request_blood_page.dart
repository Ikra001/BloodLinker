import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/models/blood_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RequestBloodPage extends StatefulWidget {
  static const route = '/request_blood';

  const RequestBloodPage({super.key});

  @override
  State<RequestBloodPage> createState() => _RequestBloodPageState();
}

class _RequestBloodPageState extends State<RequestBloodPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _bagsController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();

  // Default to A+ or generic placeholder
  String _selectedBloodGroup = 'A Positive';

  @override
  void dispose() {
    _patientNameController.dispose();
    _bagsController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Helper to format enum names nicely (e.g., "oPositive" -> "O Positive")
  String _formatBloodType(String name) {
    return name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final authManager = Provider.of<AuthManager>(context, listen: false);

      final success = await authManager.createBloodRequest(
        patientName: _patientNameController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        bagsNeeded: int.parse(_bagsController.text.trim()),
        contactNumber: _contactController.text.trim(),
        hospitalLocation: _locationController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blood request posted successfully!')),
        );
        Navigator.pop(context); // Go back to Home
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authManager.errorMessage ?? 'Error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Blood'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Patient Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(height: 20),

              // Patient Name
              TextFormField(
                controller: _patientNameController,
                decoration: _inputDecoration('Patient Name', Icons.person),
                validator: (v) => v!.isEmpty ? 'Enter patient name' : null,
              ),
              const SizedBox(height: 15),

              // Blood Group Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: _inputDecoration(
                  'Blood Group Needed',
                  Icons.bloodtype,
                ),
                items: BloodType.values.map((type) {
                  final formattedName = _formatBloodType(type.name);
                  return DropdownMenuItem(
                    value: formattedName,
                    child: Text(formattedName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedBloodGroup = val!),
              ),
              const SizedBox(height: 15),

              // Bags Needed
              TextFormField(
                controller: _bagsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  'Number of Bags',
                  Icons.local_hospital,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter quantity';
                  if (int.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Hospital/Location
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(
                  'Hospital / Location',
                  Icons.location_on,
                ),
                validator: (v) => v!.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 15),

              // Contact Number
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Contact Number', Icons.phone),
                validator: (v) => v!.isEmpty ? 'Enter contact number' : null,
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFB71C1C)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
