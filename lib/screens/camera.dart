import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kindmap/widgets/location_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';
import 'pin_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  CameraController? _controller;
  late Future<void> _initFuture;
  final ValueNotifier<bool> _isTorchOn = ValueNotifier(false);
  bool _isCapturing = false;

  // Entrance animations
  late AnimationController _entranceCtrl;
  late Animation<double> _previewFade;
  late Animation<double> _previewScale;
  late Animation<double> _controlsFade;
  late Animation<Offset> _controlsSlide;

  // Capture flash animation
  late AnimationController _flashCtrl;
  late Animation<double> _flashOpacity;

  // Shutter animation
  late AnimationController _shutterCtrl;
  late Animation<double> _shutterScale;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _previewFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _previewScale = Tween<double>(begin: 1.04, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _controlsFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _controlsSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    ));

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );

    _shutterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _shutterScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _shutterCtrl, curve: Curves.easeOut),
    );
  }

  Future<void> _initCamera() async {
    PermissionStatus status;
    try {
      status = await Permission.camera.request();
    } catch (e) {
      // permission_handler has limited web support, and browsers also
      // restrict camera access to secure origins (HTTPS/localhost).
      debugPrint('Camera permission request failed: $e');
      status = PermissionStatus.denied;
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        showCameraPermissionDialog(
          context,
          onSkip: () => Navigator.of(context).pop(),
        );
      }
      return;
    }
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller?.initialize();
      if (mounted) {
        setState(() {});
        _entranceCtrl.forward();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _entranceCtrl.dispose();
    _flashCtrl.dispose();
    _shutterCtrl.dispose();
    _isTorchOn.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    if (_isCapturing || _controller == null) return;
    try {
      await _initFuture;
      _isTorchOn.value = !_isTorchOn.value;
      await _controller?.setFlashMode(
        _isTorchOn.value ? FlashMode.torch : FlashMode.off,
      );
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _controller == null) return;
    try {
      await _initFuture;
      if (_controller?.value.isTakingPicture == true) return;

      setState(() => _isCapturing = true);
      HapticFeedback.mediumImpact();

      // Shutter press animation
      await _shutterCtrl.forward();

      // Flash
      _flashCtrl.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 80), () {
          _flashCtrl.reverse();
        });
      });

      await _shutterCtrl.reverse();

      final image = await _controller?.takePicture();
      setState(() => _isCapturing = false);

      if (!mounted) return;

      if (image == null) return;

      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => PinPage(image: image),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _isCapturing = false);
      debugPrint('Capture error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoadingState(theme);
          }
          if (_controller == null) {
            return const SizedBox.shrink();
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Camera Preview ───────────────────────────────
              FadeTransition(
                opacity: _previewFade,
                child: ScaleTransition(
                  scale: _previewScale,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller?.value.previewSize?.height ?? 1,
                        height: _controller?.value.previewSize?.width ?? 1,
                        child: Hero(
                            tag: 'camera', child: CameraPreview(_controller!)),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Vignette overlay ─────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Top bar gradient ─────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom controls gradient ──────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 220,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Capture flash ────────────────────────────────
              AnimatedBuilder(
                animation: _flashCtrl,
                builder: (_, __) => Opacity(
                  opacity: _flashOpacity.value,
                  child: Container(color: Colors.white),
                ),
              ),

              // ── Top bar: back + title + torch ────────────────
              FadeTransition(
                opacity: _controlsFade,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Back
                        _CamIconBtn(
                          icon: Icons.arrow_back_ios_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                        ),

                        const Spacer(),

                        // Title
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pin Someone',
                              style: theme.bodyMedium.copyWith(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Take a photo to pin',
                              style: theme.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Torch toggle
                        ValueListenableBuilder<bool>(
                          valueListenable: _isTorchOn,
                          builder: (_, isTorchOn, __) => _CamIconBtn(
                            icon: isTorchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            onTap: _toggleTorch,
                            isActive: isTorchOn,
                            activeColor: const Color(0xFFFFC107),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Viewfinder corners ───────────────────────────
              FadeTransition(
                opacity: _previewFade,
                child: Center(
                  child: SizedBox(
                    width: size.width * 0.72,
                    height: size.width * 0.72,
                    child: CustomPaint(painter: _ViewfinderPainter()),
                  ),
                ),
              ),

              // ── Bottom controls ──────────────────────────────
              SlideTransition(
                position: _controlsSlide,
                child: FadeTransition(
                  opacity: _controlsFade,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Placeholder left (gallery / future)
                            const SizedBox(width: 54),

                            // Shutter button
                            _ShutterButton(
                              controller: _shutterCtrl,
                              scaleAnim: _shutterScale,
                              isCapturing: _isCapturing,
                              onTap: _capturePhoto,
                              theme: theme,
                            ),

                            // Flip / placeholder right
                            const SizedBox(width: 54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(KMTheme theme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Opening camera…',
              style: theme.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Viewfinder corner painter ─────────────────────────────────────────────────

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 22.0;
    const r = 6.0;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // TL
    canvas.drawLine(Offset(r, 0), Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, cornerLen), paint);
    // TR
    canvas.drawLine(
        Offset(size.width - cornerLen, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(
        Offset(size.width, r), Offset(size.width, cornerLen), paint);
    // BL
    canvas.drawLine(
        Offset(0, size.height - cornerLen), Offset(0, size.height - r), paint);
    canvas.drawLine(
        Offset(r, size.height), Offset(cornerLen, size.height), paint);
    // BR
    canvas.drawLine(Offset(size.width, size.height - cornerLen),
        Offset(size.width, size.height - r), paint);
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width - r, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Camera icon button ────────────────────────────────────────────────────────

class _CamIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  const _CamIconBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  State<_CamIconBtn> createState() => _CamIconBtnState();
}

class _CamIconBtnState extends State<_CamIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Hero(
          tag: 'camera-bottom',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? (widget.activeColor ?? Colors.white).withOpacity(0.18)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isActive
                    ? (widget.activeColor ?? Colors.white).withOpacity(0.4)
                    : Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon,
              color: widget.isActive
                  ? (widget.activeColor ?? Colors.white)
                  : Colors.white.withOpacity(0.85),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shutter button ────────────────────────────────────────────────────────────

class _ShutterButton extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> scaleAnim;
  final bool isCapturing;
  final VoidCallback onTap;
  final KMTheme theme;

  const _ShutterButton({
    required this.controller,
    required this.scaleAnim,
    required this.isCapturing,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(isCapturing ? 0.3 : 0.7),
                  width: 3,
                ),
              ),
            ),
            // Inner disc
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: isCapturing ? 54 : 62,
              height: isCapturing ? 54 : 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isCapturing ? Colors.black.withOpacity(0.9) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (isCapturing ? Colors.black : Colors.white)
                        .withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isCapturing
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
