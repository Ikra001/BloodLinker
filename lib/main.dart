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
import 'package:blood_linker/pages/health_tips_page.dart';
import 'package:blood_linker/pages/appointment_page.dart';
import 'package:blood_linker/pages/certificate_page.dart';
import 'package:blood_linker/pages/certificates_page.dart';
import 'package:blood_linker/pages/health_dashboard_page.dart';
import 'package:blood_linker/constants.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/auth/blood_request_manager.dart';
import 'package:blood_linker/services/auth_service.dart';
import 'package:blood_linker/services/user_service.dart' as user_services;
import 'package:blood_linker/services/appointment_service.dart';
import 'package:blood_linker/services/notification_service.dart';
import 'package:blood_linker/services/certificate_service.dart';
import 'package:blood_linker/data/repositories/user_repository.dart';
import 'package:blood_linker/data/repositories/blood_request_repository.dart';
import 'package:blood_linker/data/repositories/appointment_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependencies
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // Repositories
  final userRepo = FirestoreUserRepository(firestore);
  final requestRepo = FirestoreBloodRequestRepository(firestore);
  final appointmentRepo = FirestoreAppointmentRepository(firestore);

  // Services
  final authService = FirebaseAuthService(auth);
  final notificationService = SimpleNotificationService();
  final certificateService = CertificateServiceImpl();

  final userService = user_services.UserServiceImpl(
    userRepo,
    auth.currentUser?.uid ?? '',
  );
  final requestService = user_services.BloodRequestServiceImpl(
    requestRepo,
    auth.currentUser?.uid ?? '',
  );
  final appointmentService = AppointmentServiceImpl(
    appointmentRepo,
    auth.currentUser?.uid ?? '',
    certificateService: certificateService,
  );

  runApp(
    MyApp(
      authService: authService,
      userService: userService,
      requestService: requestService,
      appointmentService: appointmentService,
      notificationService: notificationService,
      certificateService: certificateService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final user_services.UserService userService;
  final user_services.BloodRequestService requestService;
  final AppointmentService appointmentService;
  final NotificationService notificationService;
  final CertificateService certificateService;

  const MyApp({
    super.key,
    required this.authService,
    required this.userService,
    required this.requestService,
    required this.appointmentService,
    required this.notificationService,
    required this.certificateService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthManager(authService, userService),
        ),
        ChangeNotifierProvider(
          create: (_) => BloodRequestManager(requestService),
        ),
        Provider<AppointmentService>.value(value: appointmentService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<CertificateService>.value(value: certificateService),
      ],
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
          HealthTipsPage.route: (context) => const HealthTipsPage(),
          AppointmentPage.route: (context) => const AppointmentPage(),
          CertificatesPage.route: (context) => const CertificatesPage(),
          HealthDashboardPage.route: (context) => const HealthDashboardPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, authManager, child) {
        if (authManager.isLoading) {
          return const _LoadingScreen();
        }

        if (authManager.isAuthenticated && authManager.customUser != null) {
          return const HomePage();
        }

        return const WelcomePage();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
