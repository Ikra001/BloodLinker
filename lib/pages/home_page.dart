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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB71C1C), Color(0xFFE57373)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<AuthManager>(
                builder: (context, authManager, child) {
                  return Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bloodtype,
                            size: 60,
                            color: Color(0xFFB71C1C),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (authManager.customUser != null) ...[
                            Text(
                              'Welcome, ${authManager.customUser!.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow(
                              'Email',
                              authManager.customUser!.email,
                            ),
                            _buildInfoRow(
                              'Phone',
                              authManager.customUser!.phone,
                            ),
                            _buildInfoRow(
                              'Blood Type',
                              authManager.customUser!.bloodType.name
                                  .replaceAllMapped(
                                    RegExp(r'([A-Z])'),
                                    (match) => ' ${match.group(1)}',
                                  )
                                  .trim()
                                  .split(' ')
                                  .map(
                                    (word) =>
                                        word[0].toUpperCase() +
                                        word.substring(1),
                                  )
                                  .join(' '),
                            ),
                            // Removed: User Type row
                            // Removed: Donor/Recipient specific details (Last Donation, Need Date, etc.)
                          ] else if (authManager.user != null) ...[
                            Text(
                              'Welcome, ${authManager.user!.email ?? 'User'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Loading user data...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: authManager.isLoading
                                  ? null
                                  : () => onPressedLogout(context),
                              icon: authManager.isLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              label: authManager.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
