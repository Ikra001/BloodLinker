import 'package:blood_linker/pages/home_page.dart';
import 'package:blood_linker/pages/login_page.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/models/blood_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  static const route = '/register';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedUserType;
  DateTime? _lastDonationDate;
  DateTime? _needDate;
  int? _bagsNeeded;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> onPressedRegister(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final success = await authManager.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodType: _selectedBloodType,
        userType: _selectedUserType,
        lastDonationDate: _lastDonationDate,
        needDate: _needDate,
        bagsNeeded: _bagsNeeded,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, HomePage.route);
      } else if (mounted && authManager.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authManager.errorMessage!)));
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDonationDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDonationDate) {
          _lastDonationDate = picked;
        } else {
          _needDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  decoration: const InputDecoration(labelText: 'Blood Type'),
                  items: BloodType.values.map((bloodType) {
                    final displayName = bloodType.name
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (match) => ' ${match.group(1)}',
                        )
                        .trim()
                        .split(' ')
                        .map(
                          (word) => word[0].toUpperCase() + word.substring(1),
                        )
                        .join(' ');
                    return DropdownMenuItem(
                      value: bloodType.name,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Blood type is required';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(labelText: 'User Type'),
                  items: const [
                    DropdownMenuItem(value: 'donor', child: Text('Donor')),
                    DropdownMenuItem(
                      value: 'recipient',
                      child: Text('Recipient'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value;
                      // Clear conditional fields when switching
                      if (value == 'donor') {
                        _needDate = null;
                        _bagsNeeded = null;
                      } else {
                        _lastDonationDate = null;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'User type is required';
                    }
                    return null;
                  },
                ),
                if (_selectedUserType == 'donor')
                  ListTile(
                    title: Text(
                      _lastDonationDate == null
                          ? 'Select Last Donation Date'
                          : 'Last Donation: ${_lastDonationDate!.toString().split(' ')[0]}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                if (_selectedUserType == 'recipient') ...[
                  ListTile(
                    title: Text(
                      _needDate == null
                          ? 'Select Need Date'
                          : 'Need Date: ${_needDate!.toString().split(' ')[0]}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Bags Needed'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _bagsNeeded = int.tryParse(value);
                      });
                    },
                    validator: (value) {
                      if (_selectedUserType == 'recipient') {
                        if (value == null || value.isEmpty) {
                          return 'Bags needed is required';
                        }
                        final bags = int.tryParse(value);
                        if (bags == null || bags <= 0) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Consumer<AuthManager>(
                  builder: (context, authManager, child) {
                    return ElevatedButton(
                      onPressed: authManager.isLoading
                          ? null
                          : () => onPressedRegister(context),
                      child: authManager.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register'),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, LoginPage.route);
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
