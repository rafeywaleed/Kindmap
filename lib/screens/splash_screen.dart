import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  void _goHome() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.user == null && !profileProvider.isLoading) {
        await profileProvider.loadProfile();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KMTheme.of(context).secondaryBackground,
      body: Center(
        child: GifView.asset(
          'assets/images/kindmap-animation-4.gif',
          width: double.infinity,
          height: 200,
          fit: BoxFit.contain,
          loop: false,
          onFinish: _goHome,
        ),
      ),
    );
  }
}
