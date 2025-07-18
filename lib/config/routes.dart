import 'package:flutter/material.dart';

import '../screens/IntroScreens.dart';
import '../screens/auth_pages.dart/login_form.dart';
import '../screens/avatars.dart';
import '../screens/camera.dart';
import '../screens/homescreen.dart';
import '../screens/settings_pages/about.dart';
import '../screens/settings_pages/contact.dart';
import '../screens/settings_pages/donate.dart';
import '../screens/settings_pages/help.dart';
import '../screens/settings_pages/notifcations.dart';
import '../screens/settings_pages/permissions.dart';
import '../screens/settings_pages/privacy_policy_screen.dart';
import '../screens/settings_pages/profile_page.dart';
import '../screens/settings_screen.dart';
import '../widgets/map.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/auth': (context) => const LoginForm(),
  // '/home': (context) => const HomePage(),
  '/camera': (context) => CameraPage(),
  '/settings': (context) => const SettingsPage(),
  '/profile': (context) => const ProfilePage(),
  '/map': (context) => Maps(),
  '/introScreens': (context) => const IntroScreens(),
  '/donate': (context) => const Donate(),
  '/contact': (context) => const Contact(),
  '/about': (context) => const About(),
  '/help': (context) => const Help(),
  '/permissions': (context) => const Permissions(),
  '/privacypolicy': (context) => const PrivacyPolicy(),
  '/notifications': (context) => const Notifications(),
  '/avatars': (context) => const Avatars(),
};
