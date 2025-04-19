import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'Services/map_services.dart';
import 'components/PinBox.dart';

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late Stream<Position> positionStream;
  LatLng? location;
  @override
  void initState() {
    super.initState();
    getLocation();
    loadMarkers();
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get initial position
    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    mapProvider.setLocation(LatLng(position.latitude, position.longitude));

    // Listen for location updates
    positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update only when user moves 10 meters
    ));

    positionStream.listen((Position position) {
      mapProvider.setLocation(LatLng(position.latitude, position.longitude));
    });
  }

  Future<void> loadMarkers() async {
    final pins = await FirebaseFirestore.instance.collection('Pins').get();
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final markers = pins.docs.map((doc) {
      final latitude = doc['Latitude'];
      final longitude = doc['Longitude'];
      return Marker(
        point: LatLng(latitude, longitude),
        child: GestureDetector(
          onTap: () {
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
    mapProvider.setMarkers(markers);
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          if (mapProvider.location != null)
            FlutterMap(
              options: MapOptions(
                minZoom: 0,
                maxZoom: 18,
                initialCenter: location ?? LatLng(0, 0), // Fallback to (0, 0)
                initialZoom: 17,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                openStreetMapTileLayer,
                if (location != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                          point: location!,
                          width: 30,
                          height: 30,
                          // Removed rotateAlignment as it is not a valid parameter
                          child: Image.asset(
                            'assets/images/MapMarker.png', // Replace with your image path
                            width: 50,
                            height: 50,
                          )),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
