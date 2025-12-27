import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/pages/last_donation_page.dart';
import 'package:blood_linker/pages/login_page.dart';
import 'package:blood_linker/widgets/gradient_scaffold.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> onPressedRegister() async {
    if ((_formKey.currentState?.validate() ?? false) &&
        _selectedBloodType != null) {
      final authManager = Provider.of<AuthManager>(context, listen: false);

      final success = await authManager.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodType: _selectedBloodType!,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LastDonationPage()),
        );
      } else if (authManager.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authManager.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
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
                        color: Constants.primaryColor,
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
                      decoration: Constants.roundedInputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icons.person,
                      ),
                      validator: (value) =>
                          Constants.requiredValidator(value, 'Name'),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: Constants.roundedInputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icons.email,
                      ),
                      validator: Constants.emailValidator,
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: Constants.roundedInputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icons.phone,
                      ),
                      validator: (value) =>
                          Constants.requiredValidator(value, 'Phone'),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: Constants.roundedInputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icons.lock,
                      ),
                      validator: (value) {
                        final required = Constants.requiredValidator(
                          value,
                          'Password',
                        );
                        if (required != null) return required;
                        if (value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Blood Type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBloodType,
                      decoration: Constants.roundedInputDecoration(
                        labelText: 'Blood Type',
                        prefixIcon: Icons.bloodtype,
                      ),
                      items: Constants.bloodTypes.map((bloodType) {
                        return DropdownMenuItem(
                          value: bloodType,
                          child: Text(bloodType),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                      validator: (value) =>
                          Constants.requiredValidator(value, 'Blood type'),
                    ),

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
                                : onPressedRegister,
                            style: Constants.primaryButtonStyle(),
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
                        style: TextStyle(color: Constants.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
