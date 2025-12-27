import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/pages/map_location_page.dart';

class RequestBloodPage extends StatefulWidget {
  static const route = '/request_blood';

  // OPTIONAL: If these are provided, we are in "Edit Mode"
  final String? requestId;
  final Map<String, dynamic>? initialData;

  const RequestBloodPage({super.key, this.requestId, this.initialData});

  @override
  State<RequestBloodPage> createState() => _RequestBloodPageState();
}

class _RequestBloodPageState extends State<RequestBloodPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _patientNameController;
  late TextEditingController _ageController;
  late TextEditingController _bagsController;
  late TextEditingController _contactController;
  late TextEditingController _notesController;

  // State Variables
  String? _selectedBloodGroup;
  String? _selectedGender;
  DateTime? _whenNeeded;
  TimeOfDay? _whenNeededTime;
  bool _isEmergency = false;
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // 1. Initialize Controllers
    _patientNameController = TextEditingController();
    _ageController = TextEditingController();
    _bagsController = TextEditingController();
    _contactController = TextEditingController();
    _notesController = TextEditingController();

    // 2. CHECK FOR EDIT MODE: Pre-fill data if available
    if (widget.initialData != null) {
      final data = widget.initialData!;

      _patientNameController.text = data['patientName'] ?? '';
      _ageController.text = (data['age'] ?? '').toString();
      _contactController.text = data['contactNumber'] ?? '';
      _bagsController.text = (data['bagsNeeded'] ?? 0).toString();
      _notesController.text = data['additionalNotes'] ?? '';

      _selectedBloodGroup = data['bloodGroup'];
      _selectedGender = data['gender'];
      _isEmergency = data['isEmergency'] ?? false;

      // Restore Location
      if (data['latitude'] != null && data['longitude'] != null) {
        _selectedLocation = {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'hospitalName': data['hospitalName'] ?? '',
          'address': data['address'] ?? '',
        };
      } else {
        // Fallback for legacy data
        _selectedLocation = {
          'hospitalName': data['hospitalLocation'],
          'address': '',
        };
      }

      // Restore Date/Time (Firestore Timestamp -> DateTime)
      if (data['whenNeeded'] != null) {
        // Check if it's a Firestore Timestamp or just a DateTime
        // (Usually Firestore returns Timestamp, so we convert it)
        try {
          // If using cloud_firestore package, data['whenNeeded'] is Timestamp
          // If passed from local Map, might differ.
          // We assume it behaves like a standard Firestore Timestamp or DateTime object.
          final dynamic rawDate = data['whenNeeded'];
          if (rawDate.runtimeType.toString().contains('Timestamp')) {
            _whenNeeded = rawDate.toDate();
          } else if (rawDate is DateTime) {
            _whenNeeded = rawDate;
          }

          if (_whenNeeded != null) {
            _whenNeededTime = TimeOfDay.fromDateTime(_whenNeeded!);
          }
        } catch (e) {
          print("Error parsing date: $e");
        }
      }
    }
  }

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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _whenNeeded ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select When Blood is Needed',
    );

    if (pickedDate != null && mounted) {
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
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      // Basic location check
      if (_selectedLocation == null && widget.requestId == null) {
        // Require location on Create. Relax on Edit if needed, but let's keep strict.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      final authManager = Provider.of<AuthManager>(context, listen: false);

      // Determine the string to show on card
      final String hospitalLocation;
      if (_selectedLocation != null) {
        hospitalLocation =
            _selectedLocation!['hospitalName']?.isNotEmpty == true
            ? _selectedLocation!['hospitalName']
            : _selectedLocation!['address'] ?? 'Custom Location';
      } else {
        hospitalLocation = widget.initialData?['hospitalLocation'] ?? 'Unknown';
      }

      bool success;

      // --- LOGIC BRANCH: EDIT vs CREATE ---
      if (widget.requestId != null) {
        // UPDATE EXISTING
        success = await authManager.updateBloodRequest(
          requestId: widget.requestId!,
          patientName: _patientNameController.text.trim(),
          bloodGroup: _selectedBloodGroup!,
          bagsNeeded: int.parse(_bagsController.text.trim()),
          contactNumber: _contactController.text.trim(),
          hospitalLocation: hospitalLocation,
          age: int.tryParse(_ageController.text.trim()),
          gender: _selectedGender,
          whenNeeded: _whenNeeded,
          isEmergency: _isEmergency,
          additionalNotes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          latitude: _selectedLocation?['latitude'],
          longitude: _selectedLocation?['longitude'],
          hospitalName: _selectedLocation?['hospitalName'],
          address: _selectedLocation?['address'],
        );
      } else {
        // CREATE NEW
        success = await authManager.createBloodRequest(
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
          hospitalLocation: hospitalLocation,
          isEmergency: _isEmergency,
          additionalNotes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.requestId != null
                  ? 'Request updated!'
                  : 'Request posted successfully!',
            ),
          ),
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
    final isEditing = widget.requestId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Request' : 'Request Blood'),
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
              Text(
                isEditing ? 'Update Details' : 'Enter Patient Details',
                style: const TextStyle(
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
                  if (age == null || age < 0 || age > 150)
                    return 'Enter a valid age';
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
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Gender is required'
                    : null,
              ),
              const SizedBox(height: 15),

              // Blood Group Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup, // Handles pre-fill
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Blood group is required'
                    : null,
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
                      const Icon(
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
                              _getLocationDisplayString(),
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
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
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
                    borderSide: const BorderSide(
                      color: Constants.primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
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
                      onChanged: (value) =>
                          setState(() => _isEmergency = value ?? false),
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
                child: Text(
                  isEditing ? 'Update Request' : 'Submit Request',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get location text
  String _getLocationDisplayString() {
    if (_selectedLocation == null) return 'Hospital / Location';

    if (_selectedLocation!['hospitalName']?.toString().isNotEmpty == true) {
      return _selectedLocation!['hospitalName'] as String;
    }
    if (_selectedLocation!['address']?.toString().isNotEmpty == true) {
      return 'Custom Location';
    }
    if (widget.initialData != null &&
        widget.initialData!['hospitalLocation'] != null) {
      return widget.initialData!['hospitalLocation'];
    }
    return 'Custom Location';
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Constants.primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Constants.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
