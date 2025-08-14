import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/config/routes.dart';
import 'package:kindmap/firebase_options.dart';
import 'package:kindmap/screens/auth_pages.dart/login_form.dart';
import 'package:kindmap/screens/homescreen.dart';
import 'package:kindmap/screens/splash_screen.dart';
import 'package:kindmap/services/fcm_service.dart';
import 'package:kindmap/services/theme_services.dart';
import 'config/app_theme.dart';
import 'package:provider/provider.dart';
import 'services/map_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MapProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FCM().initNotifications();
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kindmap',
      debugShowCheckedModeBanner: false,
      theme: LightModeTheme().toThemeData(),
      darkTheme: DarkModeTheme().toThemeData(),
      themeMode: ThemeMode.system,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomePage();
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          } else {
            return const LoginForm();
          }
        },
      ),
      routes: appRoutes,
    );
  }
}
