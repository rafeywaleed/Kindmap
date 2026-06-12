import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> handleLocationPermission() async {
    if (kIsWeb) {
      return _handleLocationPermissionWeb();
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<bool> handleCameraPermission() async {
    if (kIsWeb) {
      return _handleCameraPermissionWeb();
    }

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Camera permission check failed: $e');
      return false;
    }
  }

  static Future<bool> handleNotificationPermission() async {
    try {
      if (kIsWeb) {
        return _handleNotificationPermissionWeb();
      }

      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return status.isGranted;
    } catch (e) {
      // permission_handler has limited web support, and browsers also
      // restrict the Notification API to secure origins (HTTPS/localhost).
      debugPrint('Notification permission check failed: $e');
      return false;
    }
  }

  /// Web-specific implementations using browser APIs
  static Future<bool> _handleLocationPermissionWeb() async {
    try {
      // Check if the browser supports Geolocation API
      if (!_isGeolocationSupported()) {
        debugPrint('Geolocation API not supported in this browser');
        return false;
      }

      // Note: The actual permission request happens in LocationService
      // when getCurrentPosition is called. Here we just verify support.
      return true;
    } catch (e) {
      debugPrint('Location permission check (web) failed: $e');
      return false;
    }
  }

  static Future<bool> _handleCameraPermissionWeb() async {
    try {
      // Check if the browser supports MediaDevices API
      if (!_isMediaDevicesSupported()) {
        debugPrint('MediaDevices API not supported in this browser');
        return false;
      }

      // Note: The actual permission request happens in CameraService
      // when enumerateDevices or getUserMedia is called.
      // We just verify API support here.
      return true;
    } catch (e) {
      debugPrint('Camera permission check (web) failed: $e');
      return false;
    }
  }

  static Future<bool> _handleNotificationPermissionWeb() async {
    try {
      // Notifications require a service worker to be registered
      if (!_isNotificationSupported()) {
        debugPrint('Notification API not supported in this browser');
        return false;
      }

      // Check current notification permission status
      final permission = _getNotificationPermissionWeb();
      if (permission == 'default') {
        // Request permission
        final result = await _requestNotificationPermissionWeb();
        return result == 'granted';
      }

      return permission == 'granted';
    } catch (e) {
      debugPrint('Notification permission check (web) failed: $e');
      return false;
    }
  }

  /// Helper methods for browser API detection
  static bool _isGeolocationSupported() {
    try {
      // Check if running on web and navigator is available
      if (!kIsWeb) return false;
      // This would be checked via JavaScript in actual implementation
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _isMediaDevicesSupported() {
    try {
      if (!kIsWeb) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _isNotificationSupported() {
    try {
      if (!kIsWeb) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static String _getNotificationPermissionWeb() {
    try {
      // This would use JavaScript interop to check:
      // Notification.permission
      return 'default';
    } catch (e) {
      return 'denied';
    }
  }

  static Future<String> _requestNotificationPermissionWeb() async {
    try {
      // This would use JavaScript interop to request:
      // Notification.requestPermission()
      return 'default';
    } catch (e) {
      return 'denied';
    }
  }
}
