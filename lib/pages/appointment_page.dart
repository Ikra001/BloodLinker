import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blood_linker/auth/blood_request_manager.dart';
import 'package:blood_linker/models/appointment.dart';
import 'package:blood_linker/widgets/common_widgets.dart';
import 'package:blood_linker/widgets/app_theme.dart';

class AppointmentPage extends StatefulWidget {
  static const route = '/appointment';

  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  AppointmentType _appointmentType = AppointmentType.donation;
  bool _isScheduling = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _scheduleAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() {
      _isScheduling = true;
    });

    try {
      final requestManager = Provider.of<BloodRequestManager>(
        context,
        listen: false,
      );

      await requestManager.createBloodRequest(
        patientName: _titleController.text,
        bloodGroup: 'General', // This could be improved
        bagsNeeded: 1,
        contactNumber: 'Scheduled', // This could be improved
        hospitalLocation: _locationController.text,
        whenNeeded: appointmentDateTime,
        additionalNotes: _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment scheduled successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule appointment: $e')),
        );
      }
    } finally {
      setState(() {
        _isScheduling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Appointment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Appointment Type
              const Text(
                'Appointment Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<AppointmentType>(
                value: _appointmentType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: AppointmentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getAppointmentTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _appointmentType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              AppTextField(
                controller: _titleController,
                labelText: 'Appointment Title',
                hintText: 'e.g., Blood Donation Appointment',
                prefixIcon: Icons.title,
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              AppTextField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                hintText: 'Additional details about the appointment',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.md),

              // Location
              AppTextField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'Blood bank or hospital location',
                prefixIcon: Icons.location_on,
                validator: (value) =>
                    value?.isEmpty == true ? 'Location is required' : null,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Date and Time Selection
              const Text(
                'Date & Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Select Date',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Schedule Button
              PrimaryButton(
                text: 'Schedule Appointment',
                onPressed: _scheduleAppointment,
                isLoading: _isScheduling,
                width: double.infinity,
                height: 50,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Info Text
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: AppBorderRadius.md,
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Appointments are typically scheduled during business hours (9 AM - 6 PM). You will receive a confirmation once your appointment is approved.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppointmentTypeText(AppointmentType type) {
    switch (type) {
      case AppointmentType.donation:
        return 'Blood Donation';
      case AppointmentType.bloodRequest:
        return 'Blood Request';
      case AppointmentType.followUp:
        return 'Follow-up Visit';
    }
  }
}
