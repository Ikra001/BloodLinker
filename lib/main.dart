import 'package:blood_linker/pages/home_page.dart';
import 'package:blood_linker/pages/login_page.dart';
import 'package:blood_linker/pages/register_page.dart';
import 'package:blood_linker/pages/welcome_page.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      create: (context) => AuthManager(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const WelcomePage(),
        routes: {
          LoginPage.route: (context) => const LoginPage(),
          HomePage.route: (context) => const HomePage(),
          RegisterPage.route: (context) => const RegisterPage(),
        },
      ),
    );
  }
}
