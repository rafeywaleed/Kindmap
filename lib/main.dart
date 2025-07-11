import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kindmap/IntroScreens/IntroScreens.dart';
import 'package:kindmap/IntroScreens/avatars.dart';
import 'package:kindmap/Otherpages/About.dart';
import 'package:kindmap/Otherpages/Contact.dart';
import 'package:kindmap/Otherpages/Donate.dart';
import 'package:kindmap/Otherpages/Help.dart';
import 'package:kindmap/Otherpages/Notifcations.dart';
import 'package:kindmap/Otherpages/Permissions.dart';
import 'package:kindmap/Otherpages/PrivacyPolicy.dart';
import 'package:kindmap/components/DetailBox.dart';
import 'package:kindmap/components/PinBox.dart';
import 'package:kindmap/fcm.dart';
import 'package:kindmap/firebase_options.dart';
import 'package:kindmap/map.dart';
import 'package:kindmap/new_Auth/nAuth.dart';
import 'package:kindmap/new_Auth/user.dart';
import 'package:kindmap/themes/kmTheme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/Camera.dart';
import 'package:kindmap/Homepage/HomePage.dart';
import 'package:kindmap/Profile/ProfilePage.dart';
import 'package:kindmap/Settings/SettingsPage.dart';
import 'package:kindmap/utils/color_extension.dart';
import 'package:provider/provider.dart';
import 'Services/map_services.dart';
// import 'Services/platform_service.dart';
//import 'package:km/themes/old_theme.dart';

//import 'package:km/IntroScreens/Introscreen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Firebase.app(); // Throws if not initialized
  } on FirebaseException catch (_) {
    await Firebase.initializeApp(
      name: "kindmap-999d3",
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBBIuwNrITwg_fmeIkMGz2CZbkoNVKvP4g',
        appId: '1:403643543889:android:d9f0b2bf35c12e2d3ae370',
        messagingSenderId: '403643543889',
        projectId: 'kindmap-999d3',
        storageBucket: 'gs://kindmap-999d3.appspot.com',
      ),
    );
  }

  await FCM().initNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MapProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KindMap',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const LoginForm();
          }
        },
      ),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      routes: {
        '/auth': (context) => const LoginForm(),
        '/home': (context) => const HomePage(),
        '/camera': (context) => CameraPage(),
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/map': (context) => const Maps(),
        '/introScreens': (context) => const IntroScreens(),
        '/donate': (context) => const Donate(),
        '/contact': (context) => const Contact(),
        '/about': (context) => const About(),
        '/help': (context) => const Help(),
        '/permissions': (context) => const Permissions(),
        '/privacypolicy': (context) => const PrivacyPolicy(),
        '/notifications': (context) => const Notifications(),
        '/avatars': (context) => const Avatars(),
      },
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
