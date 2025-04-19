import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kindmap/services/location_service.dart';
import 'package:kindmap/Homepage/HomePage.dart';
import 'package:kindmap/components/DetailBox.dart';
import 'package:latlong2/latlong.dart';

class PinConfirmation extends StatefulWidget {
  final String docName;

  const PinConfirmation({super.key, required this.docName});

  @override
  State<PinConfirmation> createState() => _PinConfirmationState();
}

class _PinConfirmationState extends State<PinConfirmation> {
  LatLng? _location;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _location = location;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMap() {
    return FlutterMap(
      options: MapOptions(
        minZoom: 0,
        maxZoom: 18,
        initialCenter: _location ?? const LatLng(0, 0),
        initialZoom: 17,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        _buildTileLayer(),
        if (_location != null) _buildMarkerLayer(),
      ],
    );
  }

  MarkerLayer _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _location!,
          width: 30,
          height: 30,
          child: Image.asset(
            'assets/images/MapMarker.png',
            width: 50,
            height: 50,
          ),
        ),
      ],
    );
  }

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      Expanded(child: _buildMap()),
                      if (_location != null)
                        DetailBox(
                          docName: widget.docName,
                          location: _location!,
                        ),
                    ],
                  ),
      ),
    );
  }
}
