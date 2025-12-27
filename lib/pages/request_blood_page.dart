import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/pages/map_location_page.dart';

class RequestBloodPage extends StatefulWidget {
  static const route = '/request_blood';

  const RequestBloodPage({super.key});

  @override
  State<RequestBloodPage> createState() => _RequestBloodPageState();
}

class _RequestBloodPageState extends State<RequestBloodPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bagsController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBloodGroup;
  String? _selectedGender;
  DateTime? _whenNeeded;
  TimeOfDay? _whenNeededTime;
  bool _isEmergency = false;
  Map<String, dynamic>? _selectedLocation;

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _bagsController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const MapLocationPage()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _selectWhenNeeded() async {
    // First select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _whenNeeded ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select When Blood is Needed',
    );

    if (pickedDate != null) {
      // Then select time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _whenNeededTime ?? TimeOfDay.now(),
        helpText: 'Select Time',
      );

      if (pickedTime != null) {
        setState(() {
          _whenNeeded = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _whenNeededTime = pickedTime;
        });
      } else if (pickedDate != _whenNeeded) {
        // If time was cancelled but date was selected, use current time
        setState(() {
          final now = DateTime.now();
          _whenNeeded = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            now.hour,
            now.minute,
          );
          _whenNeededTime = TimeOfDay.fromDateTime(now);
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      final authManager = Provider.of<AuthManager>(context, listen: false);

      final success = await authManager.createBloodRequest(
        patientName: _patientNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup!,
        bagsNeeded: int.parse(_bagsController.text.trim()),
        whenNeeded: _whenNeeded,
        contactNumber: _contactController.text.trim(),
        latitude: _selectedLocation!['latitude'] as double?,
        longitude: _selectedLocation!['longitude'] as double?,
        hospitalName: _selectedLocation!['hospitalName'] as String?,
        address: _selectedLocation!['address'] as String?,
        isEmergency: _isEmergency,
        additionalNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blood request posted successfully!')),
        );
        Navigator.pop(context);
      } else if (authManager.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authManager.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Blood'),
        backgroundColor: Constants.primaryColor,
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
                  color: Constants.primaryColor,
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

              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Age', Icons.calendar_today),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter age';
                  final age = int.tryParse(v);
                  if (age == null || age < 0 || age > 150) {
                    return 'Enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration('Gender', Icons.person_outline),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _selectedGender = val),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Gender is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Blood Group Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Blood group is required';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  'Blood Group Needed',
                  Icons.bloodtype,
                ),
                items: Constants.bloodTypes.map((bloodType) {
                  return DropdownMenuItem(
                    value: bloodType,
                    child: Text(bloodType),
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

              // When Needed
              InkWell(
                onTap: _selectWhenNeeded,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Constants.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _whenNeeded == null
                              ? 'When is blood needed?'
                              : '${_whenNeeded!.day}/${_whenNeeded!.month}/${_whenNeeded!.year} ${_whenNeededTime?.format(context) ?? ""}',
                          style: TextStyle(
                            color: _whenNeeded == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_whenNeeded == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'Please select when blood is needed',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 15),

              // Hospital/Location Selection
              InkWell(
                onTap: _selectLocation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Constants.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLocation != null
                                  ? (_selectedLocation!['hospitalName']
                                                ?.toString()
                                                .isNotEmpty ==
                                            true
                                        ? _selectedLocation!['hospitalName']
                                              as String
                                        : 'Custom Location')
                                  : 'Hospital / Location',
                              style: TextStyle(
                                color: _selectedLocation != null
                                    ? Colors.black
                                    : Colors.grey,
                                fontWeight: _selectedLocation != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            if (_selectedLocation != null &&
                                _selectedLocation!['address'] != null)
                              Text(
                                _selectedLocation!['address'] as String,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedLocation == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'Please select a location',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 15),

              // Contact Number
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Contact Number', Icons.phone),
                validator: (v) => v!.isEmpty ? 'Enter contact number' : null,
              ),
              const SizedBox(height: 15),

              // Additional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  prefixIcon: Icon(Icons.note, color: Constants.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Constants.primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                ),
              ),
              const SizedBox(height: 15),

              // Emergency Checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _isEmergency = !_isEmergency;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _isEmergency,
                      onChanged: (value) {
                        setState(() {
                          _isEmergency = value ?? false;
                        });
                      },
                      activeColor: Constants.primaryColor,
                    ),
                    const Text(
                      'Mark as Emergency',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
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
      prefixIcon: Icon(icon, color: Constants.primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Constants.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
