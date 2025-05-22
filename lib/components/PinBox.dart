import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/components/BoxHandle.dart';
import 'package:kindmap/themes/kmTheme.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kindmap/Services/web_utils_stub.dart';

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
    _calculateDistance();
  }

  void _calculateDistance() {
    try {
      distance = Geolocator.distanceBetween(
        widget.latitude,
        widget.longitude,
        widget.location.latitude,
        widget.location.longitude,
      ).round();
    } catch (e) {
      print('Error calculating distance: $e');
      // Fallback distance if calculation fails
      distance = 0;
    }
  }

  Future<void> _navigateToLocation() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';

    try {
      if (kIsWeb) {
        await getWebUtils().openUrl(url);
      } else {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch navigation';
        }
      }
    } catch (e) {
      // Show error in UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation failed: $e')),
      );
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
                  _buildImagePreview(),
                  const SizedBox(height: 10),
                  _buildDistanceText(),
                  _buildTimeLeftText(),
                  const SizedBox(height: 10),
                  _buildDetailsText(),
                  const SizedBox(height: 12),
                  _buildNavigationButton(),
                  const SizedBox(height: 12),
                  _buildServeButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: widget.image,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.width * 0.4,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Container(
          color: KMTheme.of(context).alternate,
          child: Icon(
            Icons.error,
            color: KMTheme.of(context).error,
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceText() {
    return Text(
      '$distance meters away',
      style: KMTheme.of(context)
          .bodyMedium
          .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTimeLeftText() {
    return Text(
      '${widget.timeleft} left',
      style: KMTheme.of(context)
          .bodyMedium
          .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDetailsText() {
    return Text(
      'Note: ${widget.note}\n\nLocation Detail: ${widget.detail}',
      style: KMTheme.of(context).bodyMedium.copyWith(fontSize: 15),
    );
  }

  Widget _buildNavigationButton() {
    return ElevatedButton(
      onPressed: _navigateToLocation,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Navigate',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildServeButton() {
    return ElevatedButton(
      onPressed: widget.onServe,
      style: ElevatedButton.styleFrom(
        backgroundColor: KMTheme.of(context).primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'SERVED',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}
