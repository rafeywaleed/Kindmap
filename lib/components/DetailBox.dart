import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/themes/kmTheme.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DetailBox extends StatefulWidget {
  DetailBox({
    super.key,
    required this.docName,
    required this.location,
  });

  String docName;
  LatLng location;

  @override
  State<DetailBox> createState() => _DetailBoxState();
}

class _DetailBoxState extends State<DetailBox> {
  Future<Position> _determinePosition() async {
    try {
      if (kIsWeb) {
        // Web-specific location check
        final hasPermission = await _checkWebLocationPermission();
        if (!hasPermission) {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Location permission denied',
          );
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw PlatformException(
          code: 'SERVICE_DISABLED',
          message: 'Location services are disabled',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Location permissions are denied',
          );
        }
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  Future<bool> _checkWebLocationPermission() async {
    try {
      await Geolocator.getCurrentPosition();
      return true;
    } catch (e) {
      return false;
    }
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
  void initState() {
    getLocation();
    super.initState();
  }

  LatLng? location;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: KMTheme.of(context).secondaryBackground,
          boxShadow: const [
            BoxShadow(
              blurRadius: 5,
              color: Color(0x3B1D2429),
              offset: Offset(
                0.0,
                -3,
              ),
            )
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Container(
              //   width: size.width * 0.4,
              //   height: size.width * 0.4,
              //   decoration: BoxDecoration(
              //     color: const Color(0xFF2A2A2A),
              //     borderRadius: BorderRadius.circular(10),
              //   ),),
              StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Pins')
                      .doc(widget.docName)
                      .snapshots(),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        width: size.width * 0.4,
                        height: size.width * 0.4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            snapshot.data!['url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return const Center(child: LinearProgressIndicator());
                  })),

              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 10, 10, 0),
                      child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('Pins')
                            .doc(widget.docName)
                            .snapshots(),
                        builder: ((context, snapshot) {
                          if (snapshot.hasData) {
                            return FittedBox(
                              child: Text(
                                '${Geolocator.distanceBetween(snapshot.data!['Latitude'], snapshot.data!['Longitude'], widget.location.latitude, widget.location.longitude).round()}ms away',
                                style: KMTheme.of(context).bodyMedium.copyWith(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 22.5,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            );
                          }
                          return const Center(child: LinearProgressIndicator());
                        }),
                        // Text(
                        //   '5ms away',
                        //   style: FlutterFlowTheme.of(context).bodyMedium.override(
                        //         fontFamily: 'Poppins',
                        //         fontSize: 18,
                        //         letterSpacing: 0,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 10, 10, 10),
                      child: Text(
                        '3 hrs left',
                        style: KMTheme.of(context).bodyMedium.copyWith(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                  decoration: BoxDecoration(
                    color: KMTheme.of(context).secondaryText,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('Pins')
                          .doc(widget.docName)
                          .snapshots(),
                      builder: ((context, snapshot) {
                        if (snapshot.hasData) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              child: Text(
                                'Note: ${snapshot.data!['Note']}\n\nLocation Detail: ${snapshot.data!['Details']}',
                                style: KMTheme.of(context).bodyMedium.copyWith(
                                      fontFamily: 'Poppins',
                                      color: KMTheme.of(context).lineColor,
                                      fontSize: 15,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          );
                        }
                        return const Center(child: LinearProgressIndicator());
                      }),
                      // Text(
                      //   'Note: An elderly man seeking for Food\n\nLocation Detail: Beside MJCET Gate',
                      //   style: FlutterFlowTheme.of(context).bodyMedium.override(
                      //         fontFamily: 'Poppins',
                      //         color: FlutterFlowTheme.of(context).lineColor,
                      //         fontSize: 15,
                      //         letterSpacing: 0,
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      // ),
                    ),
                  )),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 20),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    // Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    backgroundColor: KMTheme.of(context).primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 80),
                  ),
                  child: Text(
                    'DONE',
                    style: KMTheme.of(context).titleSmall.copyWith(
                          fontFamily: 'Lexend Deca',
                          color: KMTheme.of(context).primaryBackground,
                          fontSize: 20,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
