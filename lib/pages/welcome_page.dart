import 'package:blood_linker/pages/login_page.dart';
import 'package:blood_linker/pages/register_page.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  static const route = '/welcome';

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BloodLinker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, LoginPage.route);
              },
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RegisterPage.route);
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
