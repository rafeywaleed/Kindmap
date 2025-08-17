import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'pin_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ValueNotifier<bool> _isTorchOn = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.low,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _initializeControllerFuture;
      _isTorchOn.value = !_isTorchOn.value;
      await _controller.setFlashMode(
        _isTorchOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      if (_controller.value.isTakingPicture) return;

      final image = await _controller.takePicture();
      if (image != null) {
        Navigator.of(context).push(
          PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 800),
              reverseTransitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PinPage(imagePath: image.path),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              }),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      backgroundColor: KMTheme.of(context).primaryBackground,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'camera-preview-to-pin',
                  flightShuttleBuilder: (flightContext, animation,
                      flightDirection, fromHeroContext, toHeroContext) {
                    final scaleAnimation =
                        Tween<double>(begin: 1.0, end: 0.5).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.fastOutSlowIn,
                      ),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: scaleAnimation.value,
                          child: Opacity(
                            opacity: Curves.easeInOutCubic
                                .transform(animation.value),
                            child: child,
                          ),
                        );
                      },
                      child: fromHeroContext.widget,
                    );
                  },
                  child: SizedBox(
                    height: 400,
                    width: 400,
                    child: CameraPreview(_controller),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  child: Hero(
                    tag: 'pin',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      spacing: 20,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _isTorchOn,
                          builder: (context, isTorchOn, child) {
                            return GestureDetector(
                              onTap: _toggleTorch,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      KMTheme.of(context).secondaryBackground,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                                  color: KMTheme.of(context).primaryText,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: _capturePhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KMTheme.of(context).secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera,
                              color: KMTheme.of(context).primaryText,
                              size: 70,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KMTheme.of(context).secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              color: KMTheme.of(context).primaryText,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
