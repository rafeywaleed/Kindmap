
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/services/map_services.dart';
import 'package:provider/provider.dart';

import '../models/latlong.dart';


class Maps extends StatefulWidget {
  bool isInteractive;
  Maps({this.isInteractive=false,super.key});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late Stream<Position> positionStream;
  LatLong? _currentLocation;
  LatLong? _lastKnownLocation;
  bool _locationServiceEnabled = true;
  final MapController _mapController = MapController();
  bool _isUsingCurrentLocation = true;
  late final MapProvider mapProvider;
  

  @override
  void initState() {
    super.initState();
    _initLocation();
    setState(() {
      mapProvider = Provider.of<MapProvider>(context, listen: false);
    });
  }

  Future<void> _initLocation() async {
  }

  Future<void> _checkLocationService() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      _showLocationServiceDialog();
    }
  }

  Future<void> _loadLastKnownLocation() async {
    
  }

  Future<void> _saveLocation(LatLong location) async {
  
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
  
  // Future<void> _moveToCurrentLocation() async {
  //   if (!locationServiceEnabled) {
  //     _showLocationServiceDialog();
  //     return;
  //   }
  //   if (_currentLocation != null) {
  //     _mapController.move(_currentLocation!, 17);
  //     setState(() => _isUsingCurrentLocation = true);
  //     return;
  //   }
  //   try {
  //     final position = await Geolocator.getLastKnownPosition() ??
  //         await Geolocator.getCurrentPosition(
  //             desiredAccuracy: LocationAccuracy.high);
  //     _currentLocation = LatLong(position.latitude, position.longitude);
  //     final mapProvider = Provider.of<MapProvider>(context, listen: false);
  //     mapProvider.setLocation(_currentLocation!);
  //     _mapController.move(_currentLocation!, 17);
  //     setState(() => _isUsingCurrentLocation = true);
  //     await _saveLocation(_currentLocation!);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error getting location: $e')),
  //     );
  //   }
  // }
 
  // Future<void> loadMarkers() async {
  //   final pins = await FirebaseFirestore.instance.collection('Pins').get();
  //   final mapProvider = Provider.of<MapProvider>(context, listen: false);
  //   final markers = pins.docs.map((doc) {
  //     final latitude = doc['Latitude'];
  //     final longitude = doc['Longitude'];
  //     return Marker(
  //       point: LatLong(latitude, longitude),
  //       child: GestureDetector(
  //         onTap: () {
  //           showModalBottomSheet(
  //             isScrollControlled: true,
  //             context: context,
  //             builder: (BuildContext context) {
  //               return PinBox(
  //                 note: doc['Note'],
  //                 detail: doc['Details'],
  //                 image: doc['url'],
  //                 timeleft: doc['Timer'],
  //                 latitude: doc['Latitude'],
  //                 longitude: doc['Longitude'],
  //                 location: mapProvider.location ?? LatLong(0, 0),
  //                 onServe: () async {
  //                   final updatedMarkers = mapProvider.markers
  //                       .where((marker) =>
  //                           marker.point != LatLong(latitude, longitude))
  //                       .toList();
  //                   mapProvider.setMarkers(updatedMarkers);
  //                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //                       content: Text('Thank You for helping!')));
  //                   FirebaseFirestore.instance
  //                       .collection('Pins')
  //                       .doc(doc.id)
  //                       .delete();
  //                   var helped = await FirebaseFirestore.instance
  //                       .collection('users')
  //                       .doc(FirebaseAuth.instance.currentUser?.uid)
  //                       .get();
  //                   FirebaseFirestore.instance
  //                       .collection('users')
  //                       .doc(FirebaseAuth.instance.currentUser?.uid)
  //                       .update({'helped': helped.data()!['helped'] + 1});
  //                   Navigator.pop(context);
  //                 },
  //               );
  //             },
  //           );
  //         },
  //         child: Image.asset(
  //           'assets/images/MapMarker.png',
  //           width: 50,
  //           height: 50,
  //         ),
  //       ),
  //     );
  //   }).toList();
  //   mapProvider.setMarkers(markers)();
  // }

  @override
  Widget build(BuildContext context) {
    
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
               
            
          if (mapProvider.location == null)
            const Center(child: CircularProgressIndicator.adaptive()),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location_fab',
              onPressed: () {
                
              },
              backgroundColor: Colors.white,
              elevation: 4,
              // tooltip: _isUsingCurrentLocation
              //     ? 'You are viewing your live location'
              //     : 'You are viewing your last saved location',
              child: Icon(
                Icons.my_location,
               
              ),
            ),
          ),
        ]
        )
        ],
      ),
    );
  }

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
}
