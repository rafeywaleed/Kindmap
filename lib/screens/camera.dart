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
      backgroundColor: KMTheme.of(context).primaryBackground,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview with Hero
                Hero(
                  tag: 'camera_preview',
                  child: CameraPreview(_controller),
                ),

                // App bar with back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Hero(
                      tag: 'camera_icon',
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

                // Camera controls
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Hero(
                    tag: 'pin_button',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
