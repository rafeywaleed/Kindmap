import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/detail_box.dart';

class PinConfirmation extends StatefulWidget {
  PinConfirmation({super.key, required this.docName});

  String docName;

  @override
  State<PinConfirmation> createState() => _PinConfirmationState();
}

class _PinConfirmationState extends State<PinConfirmation> {
  LatLng? location;

  @override
  void initState() {
    getLocation();
    super.initState();
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future getLocation() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();

    Position temp = await _determinePosition();
    setState(() {
      location = LatLng(temp.latitude, temp.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: FutureBuilder<void>(
          future: _determinePosition(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                          minZoom: 0,
                          maxZoom: 18,
                          initialCenter:
                              location ?? LatLng(0, 0), // Fallback to (0, 0)
                          initialZoom: 17,
                          interactionOptions:
                              InteractionOptions(flags: InteractiveFlag.none)),
                      children: [
                        openStreetMapTileLayer,
                        if (location != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                  point: location!,
                                  width: 30,
                                  height: 30,
                                  child: Image.asset(
                                    'assets/images/MapMarker.png', // Replace with your image path
                                    width: 50,
                                    height: 50,
                                  )),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (location != null)
                    Align(
                      //alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        child: DetailBox(
                          docName: widget.docName,
                          location: location!,
                        ),
                      ),
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      );
}
