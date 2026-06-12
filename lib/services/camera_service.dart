import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera_pkg;

class CameraService {
  static final CameraService _instance = CameraService._internal();

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  camera_pkg.CameraController? _mobileController;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  camera_pkg.CameraController? get controller => _mobileController;

  /// Initialize camera for the platform
  Future<bool> initializeCamera() async {
    try {
      if (kIsWeb) {
        return await _initializeCameraWeb();
      }

      return await _initializeCameraMobile();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return false;
    }
  }

  /// Mobile camera initialization
  Future<bool> _initializeCameraMobile() async {
    try {
      final cameras = await camera_pkg.availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == camera_pkg.CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _mobileController = camera_pkg.CameraController(
        backCamera,
        camera_pkg.ResolutionPreset.high,
        enableAudio: false,
      );

      await _mobileController?.initialize();
      _isInitialized = true;
      debugPrint('Mobile camera initialized');
      return true;
    } catch (e) {
      debugPrint('Mobile camera init error: $e');
      return false;
    }
  }

  /// Web camera initialization using MediaDevices API
  Future<bool> _initializeCameraWeb() async {
    try {
      debugPrint('Initializing web camera using MediaDevices API');

      // Check if browser supports getUserMedia
      if (!_isMediaDevicesSupported()) {
        debugPrint('MediaDevices API not supported');
        return false;
      }

      // Enumerate devices to check for camera
      final hasCamera = await _hasWebCamera();
      if (!hasCamera) {
        debugPrint('No camera device found');
        return false;
      }

      _isInitialized = true;
      debugPrint('Web camera initialized');
      return true;
    } catch (e) {
      debugPrint('Web camera init error: $e');
      return false;
    }
  }

  /// Check if browser supports MediaDevices
  bool _isMediaDevicesSupported() {
    // This would be implemented with JS interop
    // For now, return true if on web
    return kIsWeb;
  }

  /// Check if web camera is available
  Future<bool> _hasWebCamera() async {
    try {
      // This would use JS interop to call:
      // navigator.mediaDevices.enumerateDevices()
      // and check for devices with kind === 'videoinput'
      return true; // Placeholder
    } catch (e) {
      debugPrint('Error checking for web camera: $e');
      return false;
    }
  }

  /// Capture photo on web
  /// Returns image data as Uint8List
  Future<Uint8List?> capturePhotoWeb() async {
    try {
      if (!kIsWeb) {
        debugPrint('capturePhotoWeb called on non-web platform');
        return null;
      }

      debugPrint('Capturing photo from web camera');

      // This would use JS interop to:
      // 1. Get stream from navigator.mediaDevices.getUserMedia
      // 2. Create video element and display stream
      // 3. Create canvas and draw video frame
      // 4. Convert canvas to blob/Uint8List

      // Placeholder implementation
      return null;
    } catch (e) {
      debugPrint('Error capturing web photo: $e');
      return null;
    }
  }

  /// Toggle flash/torch on mobile
  Future<void> toggleTorch(bool enable) async {
    if (kIsWeb) {
      debugPrint('Torch toggle not supported on web');
      return;
    }

    try {
      await _mobileController?.setFlashMode(
        enable ? camera_pkg.FlashMode.torch : camera_pkg.FlashMode.off,
      );
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    if (kIsWeb) {
      _disposeWebCamera();
    } else {
      _disposeMobileCamera();
    }
    _isInitialized = false;
  }

  void _disposeMobileCamera() {
    _mobileController?.dispose();
    _mobileController = null;
  }

  void _disposeWebCamera() {
    // This would stop the media stream:
    // stream.getTracks().forEach(track => track.stop());
    debugPrint('Web camera disposed');
  }
}
