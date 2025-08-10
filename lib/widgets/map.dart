import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/map_services.dart';
import 'pin_box.dart';
import '../screens/pin_page.dart'; // Make sure getCellInfo is accessible

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late Stream<Position> positionStream;
  LatLng? _currentLocation;
  LatLng? _lastKnownLocation;
  bool _locationServiceEnabled = true;
  final MapController _mapController = MapController();
  bool _isUsingCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
    loadMarkers();
  }

  Future<void> _initLocation() async {
    await _checkLocationService();
    await _loadLastKnownLocation();
    await _setupLocationStream();
    loadMarkers();
  }

  Future<void> _checkLocationService() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      _showLocationServiceDialog();
    }
  }

  Future<void> _loadLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLat = prefs.getDouble('last_latitude');
    final lastLng = prefs.getDouble('last_longitude');

    if (lastLat != null && lastLng != null) {
      _lastKnownLocation = LatLng(lastLat, lastLng);
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_lastKnownLocation!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_lastKnownLocation!, 17);
      });
      _isUsingCurrentLocation = false;
    }
  }

  Future<void> _saveLocation(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', location.latitude);
    await prefs.setDouble('last_longitude', location.longitude);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'last_location': GeoPoint(location.latitude, location.longitude),
        'last_updated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Required'),
          ],
        ),
        content: const Text(
          'Please enable location services to show your position on the map.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Enable'),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              await _initLocation();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    if (!_locationServiceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 17);
      setState(() => _isUsingCurrentLocation = true);
      return;
    }

    try {
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

      _currentLocation = LatLng(position.latitude, position.longitude);
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_currentLocation!);
      _mapController.move(_currentLocation!, 17);
      setState(() => _isUsingCurrentLocation = true);

      await _saveLocation(_currentLocation!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _setupLocationStream() async {
    if (!_locationServiceEnabled) return;

    try {
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

      _currentLocation = LatLng(position.latitude, position.longitude);
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_currentLocation!);
      _mapController.move(_currentLocation!, 17);
      await _saveLocation(_currentLocation!);

      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      positionStream.listen((Position position) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        mapProvider.setLocation(_currentLocation!);
        _saveLocation(_currentLocation!);
      });
    } catch (e) {
      print('Error setting up location stream: $e');
    }
  }

  Future<void> loadMarkers() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    List<Marker> allMarkers = [];

    // Use current location to get cellId
    final LatLng? loc = mapProvider.location ?? _currentLocation;
    if (loc == null) return;

    final cellInfo = getCellInfo(loc.latitude, loc.longitude);
    final cellId = cellInfo['cellId'];

    log("The Cell Id for current location is $cellId");

    // Fetch only the markers in the current cell
    final markersSnapshot = await FirebaseFirestore.instance
        .collection('pins')
        .doc(cellId)
        .collection('markers')
        .get();

    for (var markerDoc in markersSnapshot.docs) {
      final data = markerDoc.data();
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      allMarkers.add(
        Marker(
          point: LatLng(latitude, longitude),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return PinBox(
                    note: data['note'],
                    detail: data['details'],
                    image: data['imageBase64'],
                    timeleft: data['timer'],
                    latitude: latitude,
                    longitude: longitude,
                    location: mapProvider.location ?? LatLng(0, 0),
                    onServe: () async {
                      final updatedMarkers = mapProvider.markers
                          .where((marker) =>
                              marker.point != LatLng(latitude, longitude))
                          .toList();
                      mapProvider.setMarkers(updatedMarkers);

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Thank You for helping!')));
                      await markerDoc.reference.delete();
                      await loadMarkers(); // <-- Add this line
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
        ),
      );
    }
    mapProvider.setMarkers(allMarkers);
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          if (mapProvider.location != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                minZoom: 0,
                maxZoom: 18,
                initialCenter: mapProvider.location!,
                initialZoom: 17,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                openStreetMapTileLayer,
                MarkerLayer(
                  markers: [
                    if ((_isUsingCurrentLocation && _currentLocation != null) ||
                        (!_isUsingCurrentLocation &&
                            _lastKnownLocation != null))
                      Marker(
                        point: _isUsingCurrentLocation
                            ? _currentLocation!
                            : _lastKnownLocation!,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.my_location,
                          color: _isUsingCurrentLocation
                              ? Colors.blue
                              : Color(0xFF424242),
                          size: 40,
                        ),
                      ),
                    ...mapProvider.markers,
                  ],
                ),
              ],
            ),
          if (mapProvider.location == null)
            const Center(child: CircularProgressIndicator.adaptive()),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location_fab',
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              tooltip: _isUsingCurrentLocation
                  ? 'You are viewing your live location'
                  : 'You are viewing your last saved location',
              child: Icon(
                Icons.my_location,
                color:
                    _isUsingCurrentLocation ? Colors.blue : Color(0xFF424242),
              ),
            ),
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
