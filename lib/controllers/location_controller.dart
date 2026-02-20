import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kindmap/controllers/user_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/get_cell_info.dart';

class LocationController {
  Future<void> saveLastLocation(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', location.latitude);
    await prefs.setDouble('last_longitude', location.longitude);
    final cellInfo = getCellInfo(location.latitude, location.longitude);
    final cellId = cellInfo['cellId'];
    FirebaseMessaging.instance.subscribeToTopic('grid_$cellId');
    UserController()
        .subscribeToGrid(FirebaseAuth.instance.currentUser!.uid, cellId);
  }

  Future<LatLng?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_latitude');
    final lng = prefs.getDouble('last_longitude');
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }
}
