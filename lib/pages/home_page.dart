import 'package:blood_linker/pages/welcome_page.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/models/user.dart';
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
                if (authManager.customUser != null) {
                  final customUser = authManager.customUser!;
                  return Column(
                    children: [
                      Text('Welcome, ${customUser.name}'),
                      Text('Email: ${customUser.email}'),
                      Text('Phone: ${customUser.phone}'),
                      Text(
                        'Blood Type: ${customUser.bloodType.name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim().split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')}',
                      ),
                      Text('Type: ${customUser.userType.toUpperCase()}'),
                      if (customUser is Donor)
                        Text(
                          'Last Donation: ${customUser.lastDonationDate.toString().split(' ')[0]}',
                        ),
                      if (customUser is Recipient) ...[
                        Text(
                          'Need Date: ${customUser.needDate.toString().split(' ')[0]}',
                        ),
                        Text('Bags Needed: ${customUser.bagsNeeded}'),
                      ],
                      const SizedBox(height: 20),
                    ],
                  );
                } else if (authManager.user != null) {
                  return Column(
                    children: [
                      Text('Welcome, ${authManager.user!.email ?? 'User'}'),
                      const Text('Loading user data...'),
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
