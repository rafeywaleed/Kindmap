import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../components/PinBox.dart';

class MapProvider with ChangeNotifier {
  LatLng? _location;
  List<Marker> _markers = [];
  bool _isLoading = false;
  String? _error;

  LatLng? get location => _location;
  List<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLocation(LatLng location) {
    _location = location;
    _error = null;
    notifyListeners();
  }

  void setMarkers(List<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }

  Future<void> reloadMarkers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final pins = await FirebaseFirestore.instance.collection('Pins').get();

      final markers = pins.docs.map((doc) {
        final data = doc.data();
        final latitude = data['Latitude'] as double;
        final longitude = data['Longitude'] as double;

        return _createMarker(
          latitude: latitude,
          longitude: longitude,
          docId: doc.id,
          data: data,
        );
      }).toList();

      setMarkers(markers);
    } catch (e) {
      _error = 'Failed to load markers: $e';
      _markers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenForMarkerUpdates(BuildContext context) {
    FirebaseFirestore.instance.collection('Pins').snapshots().listen(
      (snapshot) {
        final markers = snapshot.docs.map((doc) {
          final data = doc.data();
          final latitude = data['Latitude'] as double;
          final longitude = data['Longitude'] as double;

          return _createMarker(
            latitude: latitude,
            longitude: longitude,
            docId: doc.id,
            data: data,
            context: context,
          );
        }).toList();

        setMarkers(markers);
      },
      onError: (error) {
        _error = 'Error listening to updates: $error';
        notifyListeners();
      },
    );
  }

  Marker _createMarker({
    required double latitude,
    required double longitude,
    required String docId,
    required Map<String, dynamic> data,
    BuildContext? context,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      child: GestureDetector(
        onTap: () async {
          if (context == null) return;

          // Show pin details in bottom sheet
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (BuildContext context) {
              return PinBox(
                note: data['Note'],
                detail: data['Details'],
                image: data['url'],
                timeleft: data['Timer'],
                latitude: latitude,
                longitude: longitude,
                location: location ?? LatLng(0, 0),
                onServe: () async {
                  try {
                    // Remove the marker locally
                    final updatedMarkers = _markers
                        .where((marker) =>
                            marker.point != LatLng(latitude, longitude))
                        .toList();
                    setMarkers(updatedMarkers);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank You for helping!')),
                    );

                    // Delete the pin
                    await FirebaseFirestore.instance
                        .collection('Pins')
                        .doc(docId)
                        .delete();

                    // Update user's helped count
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get();

                      final currentHelped = userDoc.data()?['helped'] ?? 0;

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({'helped': currentHelped + 1});
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    _error = 'Error processing help action: $e';
                    notifyListeners();
                  }
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
  }
}
