import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import 'box_handle.dart';

class PinBox extends StatefulWidget {
  final String timeleft;
  final double latitude;
  final double longitude;
  final String note;
  final String image;
  final String detail;
  final VoidCallback onServe;
  final LatLng location;

  const PinBox({
    super.key,
    required this.timeleft,
    required this.latitude,
    required this.longitude,
    required this.note,
    required this.image,
    required this.detail,
    required this.onServe,
    required this.location,
  });

  @override
  State<PinBox> createState() => _PinBoxState();
}

class _PinBoxState extends State<PinBox> {
  late final int distance;

  @override
  void initState() {
    super.initState();
    distance = Geolocator.distanceBetween(
      widget.latitude,
      widget.longitude,
      widget.location.latitude,
      widget.location.longitude,
    ).round();
  }

  Future<void> _navigateToLocation() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: KMTheme.of(context).secondaryBackground,
          boxShadow: const [
            BoxShadow(
                blurRadius: 5,
                color: Color(0x3B1D2429),
                offset: Offset(0.0, -3))
          ],
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        child: Column(
          children: [
            BoxHandle(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.image.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: widget.image,
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.width * 0.4,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : Image.memory(
                            base64Decode(widget.image),
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.width * 0.4,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text('$distance meters away',
                      style: KMTheme.of(context)
                          .bodyMedium
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('${widget.timeleft} left',
                      style: KMTheme.of(context)
                          .bodyMedium
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(
                      'Note: ${widget.note}\n\nLocation Detail: ${widget.detail}',
                      style: KMTheme.of(context)
                          .bodyMedium
                          .copyWith(fontSize: 15)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _navigateToLocation,
                    child: const Text('Navigate',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: widget.onServe,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: KMTheme.of(context).primary),
                    child: const Text('SERVED',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
