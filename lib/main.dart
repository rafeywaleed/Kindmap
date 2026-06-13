import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/route_observer.dart';
import 'config/routes.dart';
import 'firebase_options.dart';
import 'providers/profile_provider.dart';
import 'services/fcm_service.dart';
import 'providers/map_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/responsive_web_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait orientation on mobile devices.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MapProvider()),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProxyProvider<User?, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, user, profileProvider) {
            final provider = profileProvider ?? ProfileProvider();
            provider.updateUserId(user?.uid);
            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await FCM().initNotifications();
      } catch (e) {
        debugPrint('FCM init failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
            title: 'Kindmap',
            debugShowCheckedModeBanner: false,
            theme: LightModeTheme().toThemeData(),
            darkTheme: DarkModeTheme().toThemeData(),
            themeMode: themeProvider.themeMode,
            routes: appRoutes,
            navigatorKey: kNavigatorKey,
            navigatorObservers: [kRouteObserver],
            initialRoute: '/splash',
            builder: (context, child) => ResponsiveWebGate(child: child!));
      },
    );
  }
}
