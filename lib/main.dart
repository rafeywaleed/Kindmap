import 'package:flutter/material.dart';
import 'package:kindmap/config/routes.dart';

import 'config/app_theme.dart';

void main() {
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
      routes: appRoutes,
    );
  }
}
