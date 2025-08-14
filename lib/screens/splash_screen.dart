import 'package:flutter/material.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _started = false;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = 'assets/images/${isDark ? 'kindmap_splash_dark.mp4' : 'kindmap_splash.mp4'}';

    final controller = VideoPlayerController.asset(asset);
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      controller.play();
      controller.addListener(_onTick);
    }).catchError((_) => _goHome());
  }

  void _onTick() {
    final c = _controller;
    if (c == null) return;
    if (c.value.hasError) {
      _goHome();
      return;
    }
    if (!_navigated &&
        c.value.isInitialized &&
        !c.value.isPlaying &&
        c.value.position >= c.value.duration) {
      _goHome();
    }
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: KMTheme.of(context).splashBackground,
      body: Center(
        child: (c == null || !_initialized)
            ? const CircularProgressIndicator()
            : SizedBox(
                height: 200,
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
              ),
      ),
    );
  }
}
