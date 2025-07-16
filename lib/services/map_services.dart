import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/widgets/pin_box.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

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
    print("Reloading markers...");
    final pins = await FirebaseFirestore.instance.collection('Pins').get();
    print("Fetched ${pins.docs.length} markers from Firestore");
    final markers = pins.docs.map((doc) {
      final latitude = doc['Latitude'];
      final longitude = doc['Longitude'];
      print("Marker: ($latitude, $longitude)");
      return Marker(
        point: LatLng(latitude, longitude),
        child: GestureDetector(
          onTap: () {
            // Handle marker tap
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
  }

  // Listen for real-time updates from Firestore
  void listenForMarkerUpdates(BuildContext context) {
    print("Listening for marker updates...");
    FirebaseFirestore.instance
        .collection('Pins')
        .snapshots()
        .listen((snapshot) {
      print("Received ${snapshot.docs.length} markers from Firestore stream");
      final markers = snapshot.docs.map((doc) {
        final latitude = doc['Latitude'];
        final longitude = doc['Longitude'];
        print("Marker: ($latitude, $longitude)");
        return Marker(
          point: LatLng(latitude, longitude),
          child: GestureDetector(
            onTap: () async {
              // Reload markers when tapped
              final mapProvider =
                  Provider.of<MapProvider>(context, listen: false);
              await mapProvider.reloadMarkers();

              // Show bottom sheet with marker details
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return PinBox(
                    note: doc['Note'],
                    detail: doc['Details'],
                    image: doc['url'],
                    timeleft: doc['Timer'],
                    latitude: doc['Latitude'],
                    longitude: doc['Longitude'],
                    location: mapProvider.location ?? LatLng(0, 0),
                    onServe: () async {
                      // Remove marker from the map
                      final updatedMarkers = mapProvider.markers
                          .where((marker) =>
                              marker.point != LatLng(latitude, longitude))
                          .toList();
                      mapProvider.setMarkers(updatedMarkers);

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Thank You for helping!')));
                      FirebaseFirestore.instance
                          .collection('Pins')
                          .doc(doc.id)
                          .delete();
                      var helped = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get();
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .update({'helped': helped.data()!['helped'] + 1});
                      Navigator.pop(context);
                    },
                  );
                },
              );
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
