// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:flutterflow_ui/flutterflow_ui.dart' as ff;
// // import 'package:geolocator/geolocator.dart';
// // import 'package:kindmap/Homepage/HomePage.dart';
// // import 'package:kindmap/components/DetailBox.dart';
// // import 'package:latlong2/latlong.dart';

// // class StaticMap extends StatefulWidget {
// //   StaticMap({super.key});

// //   @override
// //   State<StaticMap> createState() => StaticMapState();
// // }

// // class StaticMapState extends State<StaticMap> {
// //   LatLng? location;

// //   @override
// //   void initState() {
// //     getLocation();
// //     super.initState();
// //   }

// //   /// Determine the current position of the device.
// //   ///
// //   /// When the location services are not enabled or permissions
// //   /// are denied the `Future` will return an error.
// //   Future<Position> _determinePosition() async {
// //     bool serviceEnabled;
// //     LocationPermission permission;

// //     // Test if location services are enabled.
// //     serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     if (!serviceEnabled) {
// //       // Location services are not enabled don't continue
// //       // accessing the position and request users of the
// //       // App to enable the location services.
// //       return Future.error('Location services are disabled.');
// //     }

// //     permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       if (permission == LocationPermission.denied) {
// //         // Permissions are denied, next time you could try
// //         // requesting permissions again (this is also where
// //         // Android's shouldShowRequestPermissionRationale
// //         // returned true. According to Android guidelines
// //         // your App should show an explanatory UI now.
// //         return Future.error('Location permissions are denied');
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       // Permissions are denied forever, handle appropriately.
// //       return Future.error(
// //           'Location permissions are permanently denied, we cannot request permissions.');
// //     }

// //     // When we reach here, permissions are granted and we can
// //     // continue accessing the position of the device.
// //     return await Geolocator.getCurrentPosition(
// //         desiredAccuracy: LocationAccuracy.high);
// //   }

// //   Future getLocation() async {
// //     await Geolocator.checkPermission();
// //     await Geolocator.requestPermission();

// //     Position temp = await _determinePosition();
// //     setState(() {
// //       location = LatLng(temp.latitude, temp.longitude);
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return WillPopScope(
// //       onWillPop: () async => false,
// //       child: Scaffold(
// //         // appBar: AppBar(
// //         //   backgroundColor: Colors.transparent,
// //         //   leading:
// //         //   // title: const Text('Pinned Map'),
// //         // ),
// //         body: FutureBuilder<void>(
// //           future: _determinePosition(),
// //           builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
// //             if (snapshot.connectionState == ConnectionState.waiting) {
// //               return const Center(
// //                 child: CircularProgressIndicator(),
// //               );
// //             } else {
// //               return Column(
// //                 children: [
// //                   Expanded(
// //                       child: FlutterMap(
// //                     options: MapOptions(
// //                       minZoom: 0,
// //                       maxZoom: 18,
// //                       center: location ?? LatLng(0, 0), // Fallback to (0, 0)
// //                       zoom: 17,
// //                       interactiveFlags: InteractiveFlag.none,
// //                     ),
// //                   )),
// //                 ],
// //               );
// //             }
// //           },
// //         ),
// //       ),
// //     );
// //   }

// //   TileLayer get openStreetMapTileLayer => TileLayer(
// //         urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
// //         userAgentPackageName: 'dev.fleaflet.flutter_map.example',
// //       );
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';

// class StaticMap extends StatefulWidget {
//   @override
//   _StaticMapState createState() => _StaticMapState();
// }

// class _StaticMapState extends State<StaticMap> {
//   LatLng? location;
//   bool locationEnabled = false;

//   @override
//   void initState() {
//     super.initState();
//     _determinePosition();
//   }

//   Future<void> _determinePosition() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         locationEnabled = false;
//       });
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         setState(() {
//           locationEnabled = false;
//         });
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         locationEnabled = false;
//       });
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       location = LatLng(position.latitude, position.longitude);
//       locationEnabled = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
//         child: Column(
//           mainAxisSize: MainAxisSize.max,
//           children: [
//             Align(
//               alignment: const AlignmentDirectional(0, 0),
//               child: Padding(
//                 padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 20),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(18),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       boxShadow: const [
//                         BoxShadow(
//                           blurRadius: 2,
//                           color: Color(0x33000000),
//                           offset: Offset(4, 4),
//                         )
//                       ],
//                       border: Border.all(color: Colors.white, width: 3),
//                     ),
//                     child: GestureDetector(
//                       onTap: () => Navigator.pushNamed(context, '/map'),
//                       child: AbsorbPointer(
//                         child: SizedBox(
//                           height: MediaQuery.of(context).size.height * 0.3,
//                           width: MediaQuery.of(context).size.width * 0.9,
//                           child: locationEnabled
//                               ? FlutterMap(
//                                   options: MapOptions(
//                                     initialCenter: location ?? LatLng(0, 0),
//                                     initialZoom: 13,
//                                     interactionOptions:
//                                         const InteractionOptions(
//                                       flags: InteractiveFlag.none,
//                                     ),
//                                   ),
//                                   children: [
//                                     TileLayer(
//                                       urlTemplate:
//                                           'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                                       subdomains: const ['a', 'b', 'c'],
//                                     ),
//                                   ],
//                                 )
//                               : Center(
//                                   child: Text(
//                                     'Turn on your location',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.grey[700],
//                                     ),
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
