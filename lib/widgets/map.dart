import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/controllers/location_controller.dart';
import 'package:kindmap/screens/pin_list_view.dart';
import 'package:kindmap/widgets/grid_info_card.dart';
import 'package:kindmap/widgets/grid_info_skeleton.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_theme.dart';
import '../controllers/grid_controller.dart';
import '../controllers/pin_controller.dart';
import '../controllers/user_controller.dart';
import '../models/pin_model.dart';
import '../providers/map_provider.dart';
import '../services/get_cell_info.dart';
import 'pin_box.dart';

// =============================================
// MapStyle Model
// =============================================
class MapStyle {
  final String name;
  final String urlTemplate;
  final List<String>? subdomains;
  final String attribution;
  final bool hasRetinaSupport;
  final double maxZoom;
  final int maxNativeZoom;

  const MapStyle({
    required this.name,
    required this.urlTemplate,
    this.subdomains,
    required this.attribution,
    this.hasRetinaSupport = false,
    this.maxZoom = 20,
    this.maxNativeZoom = 18,
  });

  TileLayer toTileLayer() {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'com.kindmap.kindmap',
      subdomains: subdomains ?? const [],
      maxZoom: maxZoom,
      maxNativeZoom: maxNativeZoom,
      retinaMode: true,
      // hasRetinaSupport ? RetinaMode.isHighDensity : RetinaMode.disabled,
      additionalOptions: {
        'attribution': attribution,
      },
    );
  }
}

class Maps extends StatefulWidget {
  final bool isGridSelectionMode;
  final VoidCallback? toggleGridSelectionMode;
  final Function(bool)? setGridSelectionMode;
  const Maps({
    super.key,
    this.isGridSelectionMode = false,
    this.toggleGridSelectionMode,
    this.setGridSelectionMode,
  });

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // =============================================
  // Location & Map State
  // =============================================
  late Stream<Position>? positionStream;
  LatLng? _currentLocation;
  LatLng? _lastKnownLocation;
  LatLng? _selectedMarkerLocation;
  LatLng? _currentGridLocation;

  LocationPermission? _locationPermission;
  bool _locationServiceEnabled = false;
  bool _isLoadingLocation = true;
  bool _isUsingCurrentLocation = false;
  bool _hasLocationPermission = false;
  bool _isSubscribedToCurrentGrid = false;

  double _currentZoom = 17;
  LatLng? _currentCenter;
  String? _currentCellId;
  int _pinsInCurrentGrid = 0;
  List<Pin> _pinsInCurrentGridList = [];

  List<String> _subscribedGridIds = [];

  final MapController _mapController = MapController();

  // =============================================
  // Map Style Configuration
  // =============================================
  final List<MapStyle> _mapStyles = const [
    MapStyle(
      name: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap',
    ),
    MapStyle(
      name: 'CartoDB Voyager',
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CartoDB',
      hasRetinaSupport: true,
    ),
    MapStyle(
      name: 'CartoDB Positron',
      urlTemplate:
          'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CartoDB',
    ),
    MapStyle(
      name: 'CartoDB Dark Matter',
      urlTemplate:
          'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CartoDB',
    ),
    MapStyle(
      name: 'OpenTopoMap',
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      attribution: '© OpenStreetMap contributors, SRTM',
    ),
    MapStyle(
      name: 'Esri Satellite',
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      attribution: '© Esri',
    ),
    MapStyle(
      name: 'Humanitarian',
      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      subdomains: ['a', 'b'],
      attribution: '© OpenStreetMap contributors',
    ),
  ];

  late MapStyle _currentMapStyle;

  // =============================================
  // Animation Controllers
  // =============================================
  late AnimationController _locationFabAnimationController;
  late AnimationController _gridFabAnimationController;
  late AnimationController _markerAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _listViewAnimationController;

  late Animation<double> _locationFabScaleAnimation;
  late Animation<double> _gridFabScaleAnimation;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _markerSlideAnimation;

  Timer? _locationCheckTimer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<Pin>>? _pinsSubscription;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      _locationLoadingSnackBar;

  bool _isListViewExpanded = false;
  bool _isLoadingGridData = false;

  // =============================================
  // Lifecycle Methods
  // =============================================
  @override
  void initState() {
    super.initState();
    _currentMapStyle = _mapStyles[0]; // default
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initializeMap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationFabAnimationController.dispose();
    _gridFabAnimationController.dispose();
    _markerAnimationController.dispose();
    _pulseAnimationController.dispose();
    _listViewAnimationController.dispose();
    _locationCheckTimer?.cancel();
    _positionSubscription?.cancel();
    _pinsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService();
    }
  }

  // =============================================
  // Build Method
  // =============================================
  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Stack(
      children: [
        // ---------- FlutterMap ----------
        if (mapProvider.location != null)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              minZoom: 2,
              maxZoom: 18,
              initialCenter: mapProvider.location!,
              initialZoom: 17,
              onTap: (tapPosition, point) async {
                if (widget.isGridSelectionMode) {
                  if (mounted) {
                    setState(() {
                      _isListViewExpanded = false;
                      _isLoadingGridData = true;
                    });
                  }
                  _pinsSubscription?.cancel();
                  mapProvider.setMarkers([]);
                  setState(() {
                    _currentGridLocation = point;
                    _currentCellId = getCellId(point.latitude, point.longitude);
                    checkIfSubscribedToCurrentGrid();
                  });
                  if (_currentCellId != null) {
                    _pinsSubscription?.cancel();
                    await loadMarkers(customCellId: _currentCellId!);
                  }
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapEvent: (MapEvent mapEvent) {
                if (mapEvent is MapEventMoveEnd && _isUsingCurrentLocation) {
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
              // ----- Dynamic Tile Layer -----
              _currentMapStyle.toTileLayer(),

              // ----- Grid Polygon Layer -----
              if ((widget.isGridSelectionMode &&
                      _currentGridLocation != null) ||
                  (!widget.isGridSelectionMode &&
                      _currentGridLocation != null &&
                      _currentLocation != null))
                Builder(
                  builder: (context) {
                    LatLng loc = widget.isGridSelectionMode
                        ? _currentGridLocation!
                        : _currentLocation!;
                    final cell = getCellInfo(loc.latitude, loc.longitude);
                    final double swLat =
                        (cell['row'] as int) * (cell['deltaLatDeg'] as double);
                    final double swLng =
                        (cell['col'] as int) * (cell['deltaLongDeg'] as double);
                    final double deltaLat = cell['deltaLatDeg'] as double;
                    final double deltaLng = cell['deltaLongDeg'] as double;
                    final List<LatLng> corners = [
                      LatLng(swLat, swLng), // SW
                      LatLng(swLat, swLng + deltaLng), // SE
                      LatLng(swLat + deltaLat, swLng + deltaLng), // NE
                      LatLng(swLat + deltaLat, swLng), // NW
                    ];
                    return PolygonLayer(
                      polygons: [
                        Polygon(
                          points: corners,
                          color: Colors.blue.withOpacity(0.18),
                          borderColor: Colors.blue.withOpacity(0.08),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    );
                  },
                ),

              // ----- Markers Layer -----
              MarkerLayer(
                markers: [
                  if (_locationServiceEnabled &&
                      _hasLocationPermission &&
                      _currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 80,
                      height: 80,
                      child: _buildLocationMarker(
                        location: _currentLocation!,
                        color: Colors.blue,
                      ),
                    )
                  else if (_lastKnownLocation != null)
                    Marker(
                      point: _lastKnownLocation!,
                      width: 80,
                      height: 80,
                      child: _buildLocationMarker(
                        location: _lastKnownLocation!,
                        color: Colors.grey,
                      ),
                    ),
                  ...mapProvider.markers,
                ],
              ),
            ],
          ),

        // ---------- Loading Overlay ----------
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

        // ---------- Grid Info Card ----------
        Visibility(
          visible: widget.isGridSelectionMode && _currentCellId != null,
          child: Positioned(
            bottom: 35,
            left: 6,
            child: _isLoadingGridData
                ? const GridInfoCardSkeleton()
                : GridInfoCard(
                    currentCellId: _currentCellId,
                    isSubscribedToCurrentGrid: _isSubscribedToCurrentGrid,
                    pinsInCurrentGrid: _pinsInCurrentGrid,
                    pinsInCurrentGridList: _pinsInCurrentGridList,
                    onToggleSubscription: toggleSubscription,
                    onMarkerTap: _onMarkerTap,
                    currentLocation: _currentLocation,
                  ),
          ),
        ),

        // ---------- Map Style Switcher Button ----------
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: KMTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PopupMenuButton<MapStyle>(
              icon:
                  Icon(Icons.layers, color: KMTheme.of(context).secondaryText),
              tooltip: 'Change map style',
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (MapStyle style) async {
                setState(() {
                  _currentMapStyle = style;
                });
                // Save preference
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('map_style', style.name);
                HapticFeedback.lightImpact();
              },
              itemBuilder: (BuildContext context) {
                return _mapStyles.map((MapStyle style) {
                  return PopupMenuItem<MapStyle>(
                    value: style,
                    child: Row(
                      children: [
                        Icon(
                          _currentMapStyle.name == style.name
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: KMTheme.of(context).primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            style.name,
                            style: TextStyle(
                              fontWeight: _currentMapStyle.name == style.name
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),

        // ---------- Grid Selection FAB ----------
        Positioned(
          bottom: widget.isGridSelectionMode ? 85 : 150,
          right: 16,
          child: AnimatedBuilder(
            animation: _gridFabScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _gridFabScaleAnimation.value,
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
                    heroTag: 'grid_selection_fab',
                    onPressed: _toggleGridSelectionMode,
                    backgroundColor: KMTheme.of(context).secondaryBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tooltip: widget.isGridSelectionMode.toString(),
                    child: Icon(
                      Icons.grid_on_rounded,
                      color: widget.isGridSelectionMode
                          ? KMTheme.of(context).primary
                          : KMTheme.of(context).secondaryText,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ---------- My Location FAB ----------
        Positioned(
          bottom: widget.isGridSelectionMode ? 35 : 100,
          right: 16,
          child: AnimatedBuilder(
            animation: _locationFabScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _locationFabScaleAnimation.value,
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
                    backgroundColor: KMTheme.of(context).secondaryBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tooltip: _isUsingCurrentLocation.toString(),
                    child: Icon(
                      Icons.my_location,
                      color: _isUsingCurrentLocation
                          ? KMTheme.of(context).primary
                          : KMTheme.of(context).secondaryText,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =============================================
  // Helper Methods
  // =============================================
  void checkIfSubscribedToCurrentGrid() {
    setState(() {
      _isSubscribedToCurrentGrid = _subscribedGridIds.contains(_currentCellId);
    });
  }

  Future<void> loadMarkers({String? customCellId}) async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    List<Marker> allMarkers = [];

    setState(() {
      _isLoadingGridData = true;
      _pinsInCurrentGrid = 0;
      _pinsInCurrentGridList = [];
    });

    final LatLng? loc =
        mapProvider.location ?? _currentLocation ?? _lastKnownLocation;
    if (loc == null) {
      setState(() => _isLoadingGridData = false);
      return;
    }

    try {
      final List<Pin> markersSnapshot;
      if (customCellId == null) {
        markersSnapshot =
            await GridController().fetchPinsByGridId(_currentCellId!);
      } else {
        markersSnapshot =
            await GridController().fetchPinsByGridId(customCellId);
      }

      log("Loaded ${markersSnapshot.length} pins for grid: ${customCellId ?? _currentCellId}");

      mapProvider.setMarkers([]);

      for (Pin pin in markersSnapshot) {
        final data = pin.toJson();
        final latitude = data['latitude'];
        final longitude = data['longitude'];
        final markerLocation = LatLng(latitude, longitude);

        allMarkers.add(Marker(
          point: markerLocation,
          child: _buildPinMarker(location: markerLocation, pin: pin),
        ));
      }

      setState(() {
        _pinsInCurrentGrid = markersSnapshot.length;
        _pinsInCurrentGridList = markersSnapshot;
        _isLoadingGridData = false;
      });

      mapProvider.setMarkers(allMarkers);
    } catch (e) {
      log('Error loading markers: $e');
      setState(() {
        _pinsInCurrentGrid = 0;
        _pinsInCurrentGridList = [];
        _isLoadingGridData = false;
      });
    }
  }

  void toggleSubscription() async {
    setState(() {
      if (_isSubscribedToCurrentGrid) {
        _subscribedGridIds.remove(_currentCellId);
      } else {
        _subscribedGridIds.add(_currentCellId!);
      }
      checkIfSubscribedToCurrentGrid();
    });
  }

  void _animateToLocation(LatLng location, {double zoom = 17}) {
    if (widget.isGridSelectionMode) {
      _mapController.move(location, 14);
    } else {
      _mapController.move(location, zoom);
    }
    if (_currentLocation != null) {
      final cellId =
          getCellId(_currentLocation!.latitude, _currentLocation!.longitude);
      setState(() {
        _currentCellId = cellId;
      });
    }
    checkIfSubscribedToCurrentGrid();
  }

  Widget _buildLocationMarker(
      {required LatLng location, required Color color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
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
  }

  Widget _buildPinMarker({required LatLng location, required Pin pin}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _onMarkerTap(location, pin);
      },
      child: AnimatedBuilder(
        animation: _selectedMarkerLocation == location
            ? _markerAnimationController
            : _pulseAnimationController,
        builder: (context, child) {
          final isSelected = _selectedMarkerLocation == location;
          final scale = isSelected
              ? _markerScaleAnimation.value
              : _pulseAnimation.value * 0.1 + 0.95;
          final offset = isSelected ? _markerSlideAnimation.value : Offset.zero;

          return Transform.translate(
            offset: Offset(offset.dx * 50, offset.dy * 50),
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isSelected ? 83 : 38),
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
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    _locationPermission = await Geolocator.checkPermission();
    _hasLocationPermission = _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;

    if (!_hasLocationPermission &&
        _locationPermission != LocationPermission.deniedForever) {
      await _requestLocationPermission();
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

  void _hideLocationLoadingSnackBar() {
    _locationLoadingSnackBar?.close();
  }

  void _initAnimations() {
    _locationFabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _gridFabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listViewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _locationFabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _locationFabAnimationController,
      curve: Curves.elasticOut,
    ));
    _gridFabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _gridFabAnimationController,
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

    // Load saved map style
    final prefs = await SharedPreferences.getInstance();
    final savedStyleName = prefs.getString('map_style');
    if (savedStyleName != null) {
      final style = _mapStyles.firstWhere(
        (s) => s.name == savedStyleName,
        orElse: () => _mapStyles[0],
      );
      setState(() {
        _currentMapStyle = style;
      });
    }

    await _setupLocationTracking();
    await loadMarkers();
    await _moveToCurrentLocation();
    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _loadLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLat = prefs.getDouble('last_latitude');
    final lastLng = prefs.getDouble('last_longitude');

    if (lastLat != null && lastLng != null && mounted) {
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

  Future<void> _moveToCurrentLocation() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    HapticFeedback.lightImpact();
    _locationFabAnimationController.forward().then((_) {
      _locationFabAnimationController.reverse();
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
      await LocationController().saveLastLocation(_currentLocation!);
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
      _currentGridLocation = LatLng(position.latitude, position.longitude);
      _currentCellId = getCellId(position.latitude, position.longitude);
      checkIfSubscribedToCurrentGrid();
      mapProvider.setLocation(_currentLocation!);
      await LocationController().saveLastLocation(_currentLocation!);
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

  void _moveToMarker(LatLng markerLocation) {
    final screenSize = MediaQuery.of(context).size;
    const offsetFraction = 0.3;
    final offsetPixels = screenSize.height * offsetFraction;

    final camera = _mapController.camera;
    final visibleBounds = camera.visibleBounds;
    final latDiff = visibleBounds.north - visibleBounds.south;
    final offsetDegrees = (offsetPixels / screenSize.height) * latDiff;

    final newCenter = LatLng(
      markerLocation.latitude - offsetDegrees,
      markerLocation.longitude,
    );

    _mapController.move(newCenter, camera.zoom);
  }

  void _onMarkerTap(LatLng markerLocation, Pin pin) {
    setState(() {
      _selectedMarkerLocation = markerLocation;
    });

    HapticFeedback.selectionClick();
    _markerAnimationController.forward();
    _moveToMarker(markerLocation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PinBox(
          pin: pin,
          location: Provider.of<MapProvider>(context, listen: false).location ??
              const LatLng(0, 0),
          onServe: () async {
            try {
              await PinController().deletePin(pin.pinId);
              final mapProvider =
                  Provider.of<MapProvider>(context, listen: false);
              final updatedMarkers = mapProvider.markers
                  .where((marker) => marker.point != markerLocation)
                  .toList();
              mapProvider.setMarkers(updatedMarkers);

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
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              debugPrint('Error removing pin: $e');
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

  Future<void> _requestLocationPermission() async {
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

  Future<void> _saveLocation(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', location.latitude);
    await prefs.setDouble('last_longitude', location.longitude);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await LocationController().saveLastLocation(_currentLocation!);
      } catch (e) {
        log('Error saving location to Firestore: $e');
      }
    }
  }

  Future<void> _setupLocationTracking() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    if (!_locationServiceEnabled || !_hasLocationPermission) return;

    try {
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentGridLocation = LatLng(position.latitude, position.longitude);
      _currentCellId = getCellId(position.latitude, position.longitude);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final subscribedGrids =
          await UserController().fetchSubscribedGrids(user.uid);
      setState(() {
        _subscribedGridIds = subscribedGrids;
      });
      await LocationController().saveLastLocation(_currentLocation!);
      mapProvider.setLocation(_currentLocation!);

      if (_lastKnownLocation == null) {
        _animateToLocation(_currentLocation!);
        setState(() => _isUsingCurrentLocation = true);
      }

      await _saveLocation(_currentLocation!);

      final cellInfo =
          getCellInfo(_currentLocation!.latitude, _currentLocation!.longitude);
      final cellId = cellInfo['cellId'];
      _pinsSubscription?.cancel();

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

  void _showLastKnownLocationFallback() {
    if (_locationServiceEnabled && _hasLocationPermission) {
      _moveToCurrentLocation();
      return;
    }

    if (_lastKnownLocation != null) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setLocation(_lastKnownLocation!);
      _animateToLocation(_lastKnownLocation!);

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
            onPressed: _moveToCurrentLocation,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
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

  void _showLocationServiceDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: KMTheme.of(context).primaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.location_disabled, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Services Disabled',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please enable location services to show your current position on the map.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Enable'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
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
                color: Colors.orange.withAlpha(25),
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

  void _toggleGridSelectionMode() {
    HapticFeedback.lightImpact();
    _gridFabAnimationController.forward().then((_) {
      _gridFabAnimationController.reverse();
    });
    widget.toggleGridSelectionMode!();
    if (widget.isGridSelectionMode) {
      _mapController.move(_currentCenter!, _currentZoom);
    } else {
      final currentCenter = _mapController.camera.center;
      final currentZoom = _mapController.camera.zoom;
      setState(() {
        _currentCenter = currentCenter;
        _currentZoom = currentZoom;
      });
      _mapController.move(currentCenter, 14);
    }
  }
}
