import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/pages/home_page.dart';
import 'package:blood_linker/pages/register_page.dart';
import 'package:blood_linker/widgets/gradient_scaffold.dart';

class LoginPage extends StatefulWidget {
  static const route = '/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> onPressedLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final success = await authManager.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
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
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Login to continue',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

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

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: Constants.roundedInputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icons.lock,
                      ),
                      validator: (value) =>
                          Constants.requiredValidator(value, 'Password'),
                    ),
                    const SizedBox(height: 30),

                    Consumer<AuthManager>(
                      builder: (context, authManager, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authManager.isLoading
                                ? null
                                : onPressedLogin,
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
                                    'Login',
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
                          RegisterPage.route,
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register",
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
