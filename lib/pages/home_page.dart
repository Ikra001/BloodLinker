import 'package:blood_linker/pages/welcome_page.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  static const route = '/home';

  const HomePage({super.key});

  Future<void> onPressedLogout(BuildContext context) async {
    final authManager = Provider.of<AuthManager>(context, listen: false);
    await authManager.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, WelcomePage.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<AuthManager>(
              builder: (context, authManager, child) {
                if (authManager.user != null) {
                  return Column(
                    children: [
                      Text('Welcome, ${authManager.user!.email ?? 'User'}'),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Text('Home'),
            Consumer<AuthManager>(
              builder: (context, authManager, child) {
                return ElevatedButton(
                  onPressed: authManager.isLoading
                      ? null
                      : () => onPressedLogout(context),
                  child: authManager.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Logout'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
