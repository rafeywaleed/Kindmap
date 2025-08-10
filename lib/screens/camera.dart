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
          MaterialPageRoute(
              builder: (context) => PinPage(imagePath: image.path)),
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
                SizedBox(
                    height: 400, width: 400, child: CameraPreview(_controller)),
                Positioned(
                  bottom: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _isTorchOn,
                        builder: (context, isTorchOn, child) {
                          return GestureDetector(
                            onTap: _toggleTorch,
                            child: Icon(
                              isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: KMTheme.of(context).primaryText,
                              size: 40,
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Icon(
                          Icons.camera,
                          color: KMTheme.of(context).primaryText,
                          size: 60,
                        ),
                      ),
                    ],
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
