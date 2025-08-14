import 'dart:developer';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/services/get_cell_info.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/map_services.dart';
import 'pin_box.dart';
import '../screens/pin_page.dart';

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Stream<Position>? positionStream;
  LatLng? _currentLocation;
  LatLng? _lastKnownLocation;
  LatLng? _selectedMarkerLocation;

  LocationPermission? _locationPermission;
  bool _locationServiceEnabled = false;
  bool _isLoadingLocation = true;
  bool _isUsingCurrentLocation = false;
  bool _hasLocationPermission = false;

  final MapController _mapController = MapController();

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _markerAnimationController;
  late AnimationController _pulseAnimationController;

  late Animation<double> _fabScaleAnimation;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _markerSlideAnimation;

  Timer? _locationCheckTimer;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initializeMap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    _markerAnimationController.dispose();
    _pulseAnimationController.dispose();
    _locationCheckTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService();
    }
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _markerScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.elasticOut,
    ));

    _markerSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.2),
    ).animate(CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeMap() async {
    await _checkAndRequestPermissions();
    await _loadLastKnownLocation();
    await _setupLocationTracking();
    await loadMarkers();

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    // Check location service
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    // Check location permission
    _locationPermission = await Geolocator.checkPermission();
    _hasLocationPermission = _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;

    if (!_hasLocationPermission &&
        _locationPermission != LocationPermission.deniedForever) {
      await _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_locationPermission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      return;
    }

    final permission = await Geolocator.requestPermission();
    setState(() {
      _locationPermission = permission;
      _hasLocationPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });

    if (!_hasLocationPermission) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _checkLocationService() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (_locationServiceEnabled != isEnabled) {
      setState(() {
        _locationServiceEnabled = isEnabled;
      });

      if (isEnabled && _hasLocationPermission) {
        await _setupLocationTracking();
      }
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
        if (mounted) {
          _animateToLocation(_lastKnownLocation!);
        }
      });
    }
  }

  Future<void> _saveLocation(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', location.latitude);
    await prefs.setDouble('last_longitude', location.longitude);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'last_location': GeoPoint(location.latitude, location.longitude),
          'last_updated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        log('Error saving location to Firestore: $e');
      }
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_off,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Location Permission Required'),
          ],
        ),
        content: const Text(
          'To show your current location and provide the best experience, please grant location permission in your device settings.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showLastKnownLocationFallback();
            },
            child: const Text('Continue Without Location'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              await _checkAndRequestPermissions();
            },
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_disabled,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Location Services Disabled'),
          ],
        ),
        content: const Text(
          'Please enable location services to show your current position on the map.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Enable Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              _startLocationServiceCheck();
            },
          ),
        ],
      ),
    );
  }

  void _startLocationServiceCheck() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        timer.cancel();
        setState(() {
          _locationServiceEnabled = true;
        });
        await _setupLocationTracking();
        _showLocationEnabledSnackBar();
      }
    });
  }

  void _showLocationEnabledSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Location services enabled!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLastKnownLocationFallback() {
    if (_locationServiceEnabled && _hasLocationPermission) {
      // If location is available, try to get current location instead
      _moveToCurrentLocation();
      return;
    }

    if (_lastKnownLocation != null) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_lastKnownLocation!);
      _animateToLocation(_lastKnownLocation!);

      // Show a snackbar to inform user they're seeing last known location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Enable location services to see your current position'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Enable',
            textColor: Colors.white,
            onPressed: () => _moveToCurrentLocation(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _moveToCurrentLocation() async {
    HapticFeedback.lightImpact();
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });

    if (!_locationServiceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    if (!_hasLocationPermission) {
      await _requestLocationPermission();
      if (!_hasLocationPermission) return;
    }

    if (_currentLocation != null) {
      _animateToLocation(_currentLocation!);
      setState(() => _isUsingCurrentLocation = true);
      return;
    }

    try {
      _showLocationLoadingSnackBar();

      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );

      _currentLocation = LatLng(position.latitude, position.longitude);
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_currentLocation!);

      _animateToLocation(_currentLocation!);
      setState(() => _isUsingCurrentLocation = true);

      await _saveLocation(_currentLocation!);
      _hideLocationLoadingSnackBar();
    } catch (e) {
      _hideLocationLoadingSnackBar();
      _showErrorSnackBar('Unable to get current location. Please try again.');
      log('Error getting location: $e');
    }
  }

  void _animateToLocation(LatLng location, {double zoom = 17}) {
    _mapController.move(location, zoom);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      _locationLoadingSnackBar;

  void _showLocationLoadingSnackBar() {
    _locationLoadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Getting your location...'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _hideLocationLoadingSnackBar() {
    _locationLoadingSnackBar?.close();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _setupLocationTracking() async {
    if (!_locationServiceEnabled || !_hasLocationPermission) return;

    try {
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );

      _currentLocation = LatLng(position.latitude, position.longitude);
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_currentLocation!);

      if (_lastKnownLocation == null) {
        _animateToLocation(_currentLocation!);
        setState(() => _isUsingCurrentLocation = true);
      }

      await _saveLocation(_currentLocation!);

      // Set up continuous location tracking
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          final newLocation = LatLng(position.latitude, position.longitude);
          _currentLocation = newLocation;

          final mapProvider = Provider.of<MapProvider>(context, listen: false);
          mapProvider.setLocation(newLocation);
          _saveLocation(newLocation);

          if (_isUsingCurrentLocation) {
            // Smooth follow current location
            _mapController.move(newLocation, _mapController.camera.zoom);
          }
        },
        onError: (error) {
          log('Location stream error: $error');
        },
      );
    } catch (e) {
      log('Error setting up location tracking: $e');
    }
  }

  Future<void> loadMarkers() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    List<Marker> allMarkers = [];

    final LatLng? loc =
        mapProvider.location ?? _currentLocation ?? _lastKnownLocation;
    if (loc == null) return;

    try {
      final cellInfo = getCellInfo(loc.latitude, loc.longitude);
      final cellId = cellInfo['cellId'];

      log("Loading markers for cell: $cellId");

      final markersSnapshot = await FirebaseFirestore.instance
          .collection('pins')
          .doc(cellId)
          .collection('markers')
          .get();

      for (var markerDoc in markersSnapshot.docs) {
        final data = markerDoc.data();
        final latitude = data['latitude'];
        final longitude = data['longitude'];
        final markerLocation = LatLng(latitude, longitude);

        allMarkers.add(
          Marker(
            point: markerLocation,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _onMarkerTap(markerLocation, data, markerDoc);
              },
              child: AnimatedBuilder(
                animation: _selectedMarkerLocation == markerLocation
                    ? _markerAnimationController
                    : _pulseAnimationController,
                builder: (context, child) {
                  final isSelected = _selectedMarkerLocation == markerLocation;
                  final scale = isSelected
                      ? _markerScaleAnimation.value
                      : _pulseAnimation.value * 0.1 + 0.95;
                  final offset =
                      isSelected ? _markerSlideAnimation.value : Offset.zero;

                  return Transform.translate(
                    offset: Offset(offset.dx * 50, offset.dy * 50),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isSelected ? 0.3 : 0.15),
                              blurRadius: isSelected ? 8 : 4,
                              offset: Offset(0, isSelected ? 4 : 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/MapMarker.png',
                          width: isSelected ? 60 : 50,
                          height: isSelected ? 60 : 50,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }

      mapProvider.setMarkers(allMarkers);
    } catch (e) {
      log('Error loading markers: $e');
    }
  }

  void _onMarkerTap(LatLng markerLocation, Map<String, dynamic> data,
      DocumentSnapshot markerDoc) {
    setState(() {
      _selectedMarkerLocation = markerLocation;
    });

    _markerAnimationController.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PinBox(
          note: data['note'],
          detail: data['details'],
          image: data['imageBase64'],
          timeleft: data['timer'],
          latitude: markerLocation.latitude,
          longitude: markerLocation.longitude,
          location: Provider.of<MapProvider>(context, listen: false).location ??
              LatLng(0, 0),
          onServe: () async {
            try {
              // First close the bottom sheet
              Navigator.pop(context);

              // Show loading indicator
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Removing pin...'),
              //     duration: Duration(seconds: 1),
              //   ),
              // );

              // Remove from Firestore
              await markerDoc.reference.delete();

              // Update local state
              final mapProvider =
                  Provider.of<MapProvider>(context, listen: false);
              final updatedMarkers = mapProvider.markers
                  .where((marker) => marker.point != markerLocation)
                  .toList();
              mapProvider.setMarkers(updatedMarkers);

              // Show success message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Thank you for helping!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              print('Error removing pin: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error removing pin: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    ).then((_) {
      setState(() {
        _selectedMarkerLocation = null;
      });
      _markerAnimationController.reverse();
    });
  }

  Widget _buildLocationMarker() {
    // Only show marker if we have current location and location is enabled
    if (!_locationServiceEnabled ||
        !_hasLocationPermission ||
        _currentLocation == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring for current location
            Container(
              width: 60 * _pulseAnimation.value,
              height: 60 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue
                    .withOpacity(0.3 - (_pulseAnimation.value - 0.8) * 0.5),
              ),
            ),
            // Main location icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
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
                minZoom: 2,
                maxZoom: 18,
                initialCenter: mapProvider.location!,
                initialZoom: 17,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapEvent: (MapEvent mapEvent) {
                  if (mapEvent is MapEventMoveEnd && _isUsingCurrentLocation) {
                    // User manually moved the map, stop following current location
                    final center = mapEvent.camera.center;
                    final currentLoc = _currentLocation;
                    if (currentLoc != null) {
                      final distance = const Distance()
                          .as(LengthUnit.Meter, center, currentLoc);
                      if (distance > 50) {
                        setState(() {
                          _isUsingCurrentLocation = false;
                        });
                      }
                    }
                  }
                },
              ),
              children: [
                openStreetMapTileLayer,
                MarkerLayer(
                  markers: [
                    if (_locationServiceEnabled &&
                        _hasLocationPermission &&
                        _currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 80,
                        height: 80,
                        child: _buildLocationMarker(),
                      ),
                    ...mapProvider.markers,
                  ],
                ),
              ],
            ),

          if (_isLoadingLocation)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator.adaptive(),
                    SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Enhanced FAB with animation
          Positioned(
            bottom: 100,
            right: 16,
            child: AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FloatingActionButton.small(
                      heroTag: 'my_location_fab',
                      onPressed: _moveToCurrentLocation,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: _isUsingCurrentLocation
                            ? Colors.blue
                            : const Color(0xFF757575),
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
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
      maxNativeZoom: 18,
      maxZoom: 20,
      additionalOptions: const {
        'attribution': '© OpenStreetMap contributors',
      },
    );
