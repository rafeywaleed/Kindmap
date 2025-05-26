import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kindmap/Pin/PinPage.dart';
import 'package:kindmap/themes/kmTheme.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ValueNotifier<bool> _isTorchOn = ValueNotifier(false);
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
          _controller.setFocusMode(FocusMode.auto);
          _controller.setExposureMode(ExposureMode.auto);
        }
      }).catchError((error) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize camera: $error';
        });
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error accessing camera: $e';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isCameraReady) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _handleImageCapture() async {
    try {
      if (!_controller.value.isInitialized) return;

      final image = await _controller.takePicture();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PinPage(imagePath: image.path),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isCameraReady) {
          await _controller.dispose();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        backgroundColor: KMTheme.of(context).primaryBackground,
        body: _hasError ? _buildErrorWidget() : _buildNativeCamera(),
      ),
    );
  }

  Widget _buildNativeCamera() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _isCameraReady) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller),
              _buildCameraOverlay(),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildCameraOverlay() {
    return SafeArea(
      child: Stack(
        children: [
          // Torch button top left
          Positioned(
            top: 24,
            left: 24,
            child: _buildTorchButton(),
          ),
          // Capture button bottom center
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _handleImageCapture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: KMTheme.of(context).primaryText,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTorchButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isTorchOn,
      builder: (context, isTorchOn, child) {
        return IconButton(
          onPressed: _toggleTorch,
          icon: Icon(
            isTorchOn ? Icons.flash_on : Icons.flash_off,
            color: KMTheme.of(context).primaryText,
            size: 40,
          ),
        );
      },
    );
  }

  Future<void> _toggleTorch() async {
    try {
      if (!_controller.value.isInitialized) return;

      _isTorchOn.value = !_isTorchOn.value;
      await _controller.setFlashMode(
        _isTorchOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: KMTheme.of(context).primaryText),
            ),
          ],
        ),
      ),
    );
  }
}
