import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:blood_linker/pages/welcome_page.dart';
import 'package:blood_linker/pages/login_page.dart';
import 'package:blood_linker/pages/register_page.dart';
import 'package:blood_linker/pages/home_page.dart';
import 'package:blood_linker/pages/request_blood_page.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/auth/auth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthManager(),
      child: MaterialApp(
        title: Constants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Constants.primaryColor),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          WelcomePage.route: (context) => const WelcomePage(),
          LoginPage.route: (context) => const LoginPage(),
          RegisterPage.route: (context) => const RegisterPage(),
          HomePage.route: (context) => const HomePage(),
          RequestBloodPage.route: (context) => const RequestBloodPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Listen to Firebase Auth (Authentication State)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // A. Waiting for Firebase to initialize...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // B. User is Logged In
        if (snapshot.hasData) {
          // 2. Listen to AuthManager (Database Data State)
          return Consumer<AuthManager>(
            builder: (context, authManager, child) {
              // If we are logged in, but the custom data (Name, BloodType) isn't loaded yet...
              // Show the loading screen to prevent "glitchy" empty text.
              if (authManager.customUser == null) {
                return const _LoadingScreen();
              }

              // Data is ready! Show the dashboard.
              return const HomePage();
            },
          );
        }

        // C. User is NOT Logged In
        return const WelcomePage();
      },
    );
  }
}

// A simple, elegant loading screen to mask the data fetch
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 140),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
