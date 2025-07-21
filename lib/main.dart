import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/config/routes.dart';
import 'package:kindmap/firebase_options.dart';
import 'package:kindmap/screens/homescreen.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
      home: HomePage(),
      routes: appRoutes,
    );
  }
}
