import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<LatLng?> getCurrentLocation() async {
    try {
      if (kIsWeb) {
        return await _getCurrentLocationWeb();
      }

      await _checkLocationPermission();
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  static Future<void> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  /// Web implementation using browser Geolocation API
  static Future<LatLng?> _getCurrentLocationWeb() async {
    try {
      debugPrint('Requesting location from browser Geolocation API');

      // Use a completer to handle the callback-based Geolocation API
      final completer = Completer<LatLng?>();
      final timeoutDuration = const Duration(seconds: 15);

      // Set up timeout
      final timeoutTimer = Timer(timeoutDuration, () {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Location request timed out'),
          );
        }
      });

      // Handle the geolocation through JavaScript interop would happen here
      // For now, we'll add the implementation
      _requestGeolocationWeb(completer, timeoutTimer);

      return await completer.future;
    } catch (e) {
      debugPrint('Error getting location from web API: $e');
      return null;
    }
  }

  /// Helper to request geolocation on web
  /// This simulates what would happen via JavaScript interop
  static void _requestGeolocationWeb(
      Completer<LatLng?> completer, Timer timeoutTimer) {
    // Note: In a real implementation, this would use dart:js_interop or
    // dart:js to call the browser's navigator.geolocation.getCurrentPosition
    // For now, we'll document the expected behavior:
    //
    // Example with js interop (not included yet):
    // import 'dart:js_interop' as js;
    //
    // js.context['navigator'].callMethod('geolocation', []).callMethod(
    //   'getCurrentPosition',
    //   [
    //     (position) {
    //       timeoutTimer.cancel();
    //       final coords = position['coords'];
    //       completer.complete(LatLng(
    //         coords['latitude'],
    //         coords['longitude'],
    //       ));
    //     },
    //     (error) {
    //       timeoutTimer.cancel();
    //       completer.completeError(
    //         Exception('Geolocation error: ${error['message']}'),
    //       );
    //     },
    //   ],
    // );

    // Placeholder error for now - will be replaced with actual JS interop
    timeoutTimer.cancel();
    completer.completeError(
      Exception(
        'Location not available on web. Use JS interop implementation.',
      ),
    );
  }
}
