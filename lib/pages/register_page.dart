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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB71C1C), Color(0xFFE57373)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Join BloodLinker today',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
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
                      const SizedBox(height: 20),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
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
                      const SizedBox(height: 20),

                      // Blood Type
                      DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        decoration: InputDecoration(
                          labelText: 'Blood Type',
                          prefixIcon: const Icon(Icons.bloodtype),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        items: BloodType.values.map((bloodType) {
                          final displayName = bloodType.name
                              .replaceAllMapped(
                                RegExp(r'([A-Z])'),
                                (match) => ' ${match.group(1)}',
                              )
                              .trim()
                              .split(' ')
                              .map(
                                (word) =>
                                    word[0].toUpperCase() + word.substring(1),
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
                      const SizedBox(height: 20),

                      // User Type
                      DropdownButtonFormField<String>(
                        value: _selectedUserType,
                        decoration: InputDecoration(
                          labelText: 'User Type',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
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
                      const SizedBox(height: 20),

                      // Conditional fields for Donor
                      if (_selectedUserType == 'donor')
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Color(0xFFB71C1C)),
                                    const SizedBox(width: 10),
                                    Text(
                                      _lastDonationDate == null
                                          ? 'Select Last Donation Date'
                                          : 'Last Donation: ${_lastDonationDate!.toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color: _lastDonationDate == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                      // Conditional fields for Recipient
                      if (_selectedUserType == 'recipient') ...[
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Color(0xFFB71C1C)),
                                    const SizedBox(width: 10),
                                    Text(
                                      _needDate == null
                                          ? 'Select Need Date'
                                          : 'Need Date: ${_needDate!.toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color: _needDate == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Bags Needed',
                            prefixIcon: const Icon(Icons.inventory),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
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

                      const SizedBox(height: 30),

                      // Register Button
                      Consumer<AuthManager>(
                        builder: (context, authManager, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authManager.isLoading
                                  ? null
                                  : () => onPressedRegister(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: authManager.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            LoginPage.route,
                          );
                        },
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(color: Color(0xFFB71C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
