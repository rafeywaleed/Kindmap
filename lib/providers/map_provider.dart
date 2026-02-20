import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/controllers/pin_controller.dart';
import 'package:kindmap/widgets/pin_box.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../controllers/user_controller.dart';

class MapProvider with ChangeNotifier {
  LatLng? _location;
  List<Marker> _markers = [];

  LatLng? get location => _location;
  List<Marker> get markers => _markers;

  void setLocation(LatLng location) {
    _location = location;
    notifyListeners();
  }

  void setMarkers(List<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }

  Future<void> reloadMarkers() async {
    debugPrint("Reloading markers...");
    final pins = await PinController().fetchAllPins();
    debugPrint("Fetched ${pins.length} markers from Firestore");
    final markers = pins.map((pin) {
      final latitude = pin.latitude;
      final longitude = pin.longitude;
      debugPrint("Marker: ($latitude, $longitude)");
      return Marker(
        point: LatLng(latitude, longitude),
        child: GestureDetector(
          onTap: () {},
          child: Image.asset(
            'assets/images/MapMarker.png',
            width: 50,
            height: 50,
          ),
        ),
      );
    }).toList();
    setMarkers(markers);
  }

  // Listen for real-time updates from Firestore
  void listenForMarkerUpdates(BuildContext context) {
    debugPrint("Listening for marker updates...");
    PinController().streamAllPins().listen((snapshot) {
      debugPrint("Received ${snapshot.length} markers from Firestore stream");
      final markers = snapshot.map((pin) {
        final latitude = pin.latitude;
        final longitude = pin.longitude;
        debugPrint("Marker: ($latitude, $longitude)");
        return Marker(
          point: LatLng(latitude, longitude),
          child: GestureDetector(
            onTap: () async {
              // Reload markers when tapped
              final mapProvider =
                  Provider.of<MapProvider>(context, listen: false);
              await mapProvider.reloadMarkers();

              // Show bottom sheet with marker details
              if (context.mounted) {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return PinBox(
                      pin: pin,
                      location: mapProvider.location ?? const LatLng(0, 0),
                      onServe: () async {
                        // Remove marker from the map
                        final updatedMarkers = mapProvider.markers
                            .where((marker) =>
                                marker.point != LatLng(latitude, longitude))
                            .toList();
                        mapProvider.setMarkers(updatedMarkers);

                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Thank You for helping!')));

                        // Delete the pin
                        await PinController().deletePin(pin.pinId);

                        // Update user's helped count
                        await UserController()
                            .addHelped(FirebaseAuth.instance.currentUser!.uid);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                );
              }
            },
            child: Image.asset(
              'assets/images/MapMarker.png',
              width: 50,
              height: 50,
            ),
          ),
        );
      }).toList();
      setMarkers(markers);
    });
  }
}
