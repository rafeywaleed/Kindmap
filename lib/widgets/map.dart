import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/controllers/location_controller.dart';
import 'package:kindmap/screens/pin_list_view.dart';
import 'package:kindmap/widgets/grid_info_card.dart';
import 'package:kindmap/widgets/grid_info_skeleton.dart';
import 'package:kindmap/widgets/location_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_theme.dart';
import '../config/route_observer.dart';
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
  final IconData icon;

  const MapStyle({
    required this.name,
    required this.urlTemplate,
    this.subdomains,
    required this.attribution,
    this.hasRetinaSupport = false,
    this.maxZoom = 20,
    this.maxNativeZoom = 18,
    this.icon = Icons.map_outlined,
  });

  TileLayer toTileLayer() {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'com.kindmap.kindmap',
      subdomains: subdomains ?? const [],
      maxZoom: maxZoom,
      maxNativeZoom: maxNativeZoom,
      retinaMode: true,
      additionalOptions: {'attribution': attribution},
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
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
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
      name: 'Standard',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap',
      icon: Icons.map_outlined,
    ),
    MapStyle(
      name: 'Voyager',
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CartoDB',
      hasRetinaSupport: true,
      icon: Icons.explore_outlined,
    ),
    MapStyle(
      name: 'Positron',
      urlTemplate:
          'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CartoDB',
      icon: Icons.light_mode_outlined,
    ),
    MapStyle(
      name: 'Dark Matter',
      urlTemplate:
          'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CartoDB',
      icon: Icons.dark_mode_outlined,
    ),
    MapStyle(
      name: 'Terrain',
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      attribution: '© OpenStreetMap contributors, SRTM',
      icon: Icons.terrain_outlined,
    ),
    MapStyle(
      name: 'Satellite',
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      attribution: '© Esri',
      icon: Icons.satellite_alt_outlined,
    ),
    MapStyle(
      name: 'Humanitarian',
      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      subdomains: ['a', 'b'],
      attribution: '© OpenStreetMap contributors',
      icon: Icons.volunteer_activism_outlined,
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
  late AnimationController _loadingController;

  late Animation<double> _locationFabScaleAnimation;
  late Animation<double> _gridFabScaleAnimation;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _markerSlideAnimation;
  late Animation<double> _loadingFadeAnimation;

  Timer? _locationCheckTimer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<Pin>>? _pinsSubscription;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      _locationLoadingSnackBar;

  bool _isListViewExpanded = false;
  bool _isLoadingGridData = false;
  bool _styleMenuOpen = false;

  // =============================================
  // Lifecycle
  // =============================================
  @override
  void initState() {
    super.initState();
    _currentMapStyle = _mapStyles[0];
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initializeMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      kRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    kRouteObserver.unsubscribe(this);
    _locationFabAnimationController.dispose();
    _gridFabAnimationController.dispose();
    _markerAnimationController.dispose();
    _pulseAnimationController.dispose();
    _listViewAnimationController.dispose();
    _loadingController.dispose();
    _locationCheckTimer?.cancel();
    _positionSubscription?.cancel();
    _pinsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkLocationService();
  }

  // Called when a pushed route (e.g. the camera/pin creation flow) is
  // popped and this screen becomes visible again.
  @override
  void didPopNext() {
    if (_currentCellId != null) loadMarkers();
  }

  // =============================================
  // Build
  // =============================================
  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final theme = KMTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ── Map ────────────────────────────────────────────────────
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
                      setState(() => _isUsingCurrentLocation = false);
                    }
                  }
                }
              },
            ),
            children: [
              _currentMapStyle.toTileLayer(),

              // Grid polygon
              if ((widget.isGridSelectionMode &&
                      _currentGridLocation != null) ||
                  (!widget.isGridSelectionMode &&
                      _currentGridLocation != null &&
                      _currentLocation != null))
                Builder(builder: (context) {
                  final loc = widget.isGridSelectionMode
                      ? _currentGridLocation!
                      : _currentLocation!;
                  final cell = getCellInfo(loc.latitude, loc.longitude);
                  final swLat =
                      (cell['row'] as int) * (cell['deltaLatDeg'] as double);
                  final swLng =
                      (cell['col'] as int) * (cell['deltaLongDeg'] as double);
                  final deltaLat = cell['deltaLatDeg'] as double;
                  final deltaLng = cell['deltaLongDeg'] as double;
                  final corners = [
                    LatLng(swLat, swLng),
                    LatLng(swLat, swLng + deltaLng),
                    LatLng(swLat + deltaLat, swLng + deltaLng),
                    LatLng(swLat + deltaLat, swLng),
                  ];
                  return PolygonLayer(polygons: [
                    Polygon(
                      points: corners,
                      color: Colors.blue.withOpacity(0.12),
                      borderColor: Colors.blue.withOpacity(0.5),
                      borderStrokeWidth: 1.5,
                    ),
                  ]);
                }),

              // Markers
              MarkerLayer(markers: [
                if (_locationServiceEnabled &&
                    _hasLocationPermission &&
                    _currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 80,
                    height: 80,
                    child: _buildLocationMarker(
                        location: _currentLocation!, color: Colors.blue),
                  )
                else if (_lastKnownLocation != null)
                  Marker(
                    point: _lastKnownLocation!,
                    width: 80,
                    height: 80,
                    child: _buildLocationMarker(
                        location: _lastKnownLocation!, color: Colors.grey),
                  ),
                ...mapProvider.markers,
              ]),
            ],
          ),

        // ── Loading Screen ──────────────────────────────────────────
        if (_isLoadingLocation) _buildLoadingScreen(theme, isDark),

        // ── Grid Info Card ──────────────────────────────────────────
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

        // ── Map Style Switcher ──────────────────────────────────────
        Positioned(
          top: 50,
          right: 16,
          child: _MapStyleSwitcher(
            styles: _mapStyles,
            currentStyle: _currentMapStyle,
            theme: theme,
            isDark: isDark,
            onStyleSelected: (style) async {
              setState(() => _currentMapStyle = style);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('map_style', style.name);
              HapticFeedback.lightImpact();
            },
          ),
        ),

        // ── Grid FAB ────────────────────────────────────────────────
        Positioned(
          bottom: widget.isGridSelectionMode ? 85 : 160,
          right: 16,
          child: AnimatedBuilder(
            animation: _gridFabScaleAnimation,
            builder: (_, __) => Transform.scale(
              scale: _gridFabScaleAnimation.value,
              child: _MapFab(
                heroTag: 'grid_selection_fab',
                onPressed: _toggleGridSelectionMode,
                icon: Icons.grid_on_rounded,
                isActive: widget.isGridSelectionMode,
                theme: theme,
                tooltip: 'Toggle grid selection',
              ),
            ),
          ),
        ),

        // ── Location FAB ─────────────────────────────────────────────
        Positioned(
          bottom: widget.isGridSelectionMode ? 35 : 110,
          right: 16,
          child: AnimatedBuilder(
            animation: _locationFabScaleAnimation,
            builder: (_, __) => Transform.scale(
              scale: _locationFabScaleAnimation.value,
              child: _MapFab(
                heroTag: 'my_location_fab',
                onPressed: _moveToCurrentLocation,
                icon: Icons.my_location_rounded,
                isActive: _isUsingCurrentLocation,
                theme: theme,
                tooltip: 'My location',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================
  // Loading Screen
  // =============================================
  Widget _buildLoadingScreen(KMTheme theme, bool isDark) {
    return AnimatedBuilder(
      animation: _loadingFadeAnimation,
      builder: (_, __) => Opacity(
        opacity: _loadingFadeAnimation.value,
        child: Container(
          color: theme.primaryBackground,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo area
                _LoadingPulse(theme: theme),
                const SizedBox(height: 32),
                Text(
                  'KindMap',
                  style: theme.displaySmall.copyWith(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Finding your location…',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: theme.primaryText.withOpacity(0.08),
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================
  // Helper Methods (unchanged logic)
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
      setState(() => _currentCellId = cellId);
    }
    checkIfSubscribedToCurrentGrid();
  }

  Widget _buildLocationMarker(
      {required LatLng location, required Color color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (_, __) => Container(
            width: 56 * _pulseAnimation.value * 0.5 + 28,
            height: 56 * _pulseAnimation.value * 0.5 + 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(
                  0.15 * (1 - (_pulseAnimation.value - 0.8) / 0.4)),
            ),
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
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.my_location_rounded,
              color: Colors.white, size: 20),
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
              : _pulseAnimation.value * 0.08 + 0.96;
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
    try {
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kIsWeb) {
        // geolocator_web's requestPermission() calls getCurrentPosition()
        // under the hood and maps ANY failure (timeout, position
        // unavailable, etc.) to LocationPermission.deniedForever — not just
        // an actual permission denial. Trusting that would permanently
        // disable the My Location button on devices/networks where a GPS
        // fix is slow. The browser shows its own permission prompt when
        // getCurrentPosition is called, so just let that happen and rely on
        // _moveToCurrentLocation's/_setupLocationTracking's own error
        // handling.
        _hasLocationPermission = true;
        return;
      }
      _locationPermission = await Geolocator.checkPermission();
      _hasLocationPermission =
          _locationPermission == LocationPermission.always ||
              _locationPermission == LocationPermission.whileInUse;
      if (!_hasLocationPermission &&
          _locationPermission != LocationPermission.deniedForever) {
        await _requestLocationPermission();
      }
    } catch (e) {
      // Geolocation can be unavailable — e.g. browsers block it on web
      // origins that aren't HTTPS or localhost. Fall back gracefully so
      // the rest of the map still loads without location features.
      log('Location permission check failed: $e');
      _locationServiceEnabled = false;
      _hasLocationPermission = false;
    }
  }

  Future<void> _checkLocationService() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (_locationServiceEnabled != isEnabled) {
      setState(() => _locationServiceEnabled = isEnabled);
      if (isEnabled && _hasLocationPermission) await _setupLocationTracking();
    }
  }

  void _hideLocationLoadingSnackBar() => _locationLoadingSnackBar?.close();

  void _initAnimations() {
    _locationFabAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _gridFabAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _listViewAnimationController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _markerAnimationController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _pulseAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat(reverse: true);
    _loadingController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this, value: 1.0);

    _locationFabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
            parent: _locationFabAnimationController, curve: Curves.elasticOut));
    _gridFabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
            parent: _gridFabAnimationController, curve: Curves.elasticOut));
    _markerScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(
            parent: _markerAnimationController, curve: Curves.elasticOut));
    _markerSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.2)).animate(
            CurvedAnimation(
                parent: _markerAnimationController, curve: Curves.easeInOut));
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(
            parent: _pulseAnimationController, curve: Curves.easeInOut));
    _loadingFadeAnimation =
        CurvedAnimation(parent: _loadingController, curve: Curves.easeOut);
  }

  Future<void> _initializeMap() async {
    try {
      await _checkAndRequestPermissions();
      await _loadLastKnownLocation();

      final prefs = await SharedPreferences.getInstance();
      final savedStyleName = prefs.getString('map_style');
      if (savedStyleName != null) {
        final style = _mapStyles.firstWhere(
          (s) => s.name == savedStyleName,
          orElse: () => _mapStyles[0],
        );
        setState(() => _currentMapStyle = style);
      }

      await _setupLocationTracking();
      await loadMarkers();
      await _moveToCurrentLocation();
    } catch (e) {
      log('Error initializing map: $e');
    } finally {
      // Always show the map, even without a real location — e.g. when
      // location services/permissions are unavailable (web over an
      // insecure/non-localhost origin, permission denied, etc.).
      if (mounted) {
        final mapProvider = Provider.of<MapProvider>(context, listen: false);
        if (mapProvider.location == null) {
          mapProvider.setLocation(const LatLng(0, 0));
        }
        setState(() => _isLoadingLocation = false);
      }
    }
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
        if (mounted) _animateToLocation(_lastKnownLocation!);
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    HapticFeedback.lightImpact();
    _locationFabAnimationController
        .forward()
        .then((_) => _locationFabAnimationController.reverse());

    if (!_locationServiceEnabled) {
      _showLocationServiceDialog();
      return;
    }
    if (!_hasLocationPermission) {
      await _requestLocationPermission();
      if (!_hasLocationPermission) return;
    }
    if (_currentLocation != null) {
      // Animate immediately to the location
      _animateToLocation(_currentLocation!);
      setState(() => _isUsingCurrentLocation = true);
      // Save location in the background (don't await)
      LocationController().saveLastLocation(_currentLocation!);
      return;
    }

    try {
      _showLocationLoadingSnackBar();
      final position = await _getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentGridLocation = LatLng(position.latitude, position.longitude);
      _currentCellId = getCellId(position.latitude, position.longitude);
      checkIfSubscribedToCurrentGrid();
      mapProvider.setLocation(_currentLocation!);
      _animateToLocation(_currentLocation!);
      setState(() => _isUsingCurrentLocation = true);
      // Save location in the background (don't await)
      LocationController().saveLastLocation(_currentLocation!);
      _saveLocation(_currentLocation!);
      _hideLocationLoadingSnackBar();
    } catch (e) {
      _hideLocationLoadingSnackBar();
      if (e is PermissionDeniedException) {
        // The browser/OS denied the permission prompt — guide the user to
        // re-enable it instead of showing a generic error.
        setState(() => _hasLocationPermission = false);
        _showPermissionDeniedDialog();
      } else if (e is LocationServiceDisabledException) {
        _showLocationServiceDialog();
      } else if (e is PositionUpdateException || e is TimeoutException) {
        // On web, isLocationServiceEnabled() always reports true, so a
        // position timeout/unavailable error is often actually caused by
        // device location services being off — point the user there.
        _showLocationServiceDialog();
      } else {
        _showErrorSnackBar('Unable to get current location. Please try again.');
      }
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
        markerLocation.latitude - offsetDegrees, markerLocation.longitude);
    _mapController.move(newCenter, camera.zoom);
  }

  void _onMarkerTap(LatLng markerLocation, Pin pin) {
    setState(() => _selectedMarkerLocation = markerLocation);
    HapticFeedback.selectionClick();
    _markerAnimationController.forward();
    _moveToMarker(markerLocation);

    showPinBox(
      context: context,
      pin: pin,
      userLocation: Provider.of<MapProvider>(context, listen: false).location ??
          const LatLng(0, 0),
      onServe: () {
        // Update the UI immediately — don't make the user wait on the
        // server round-trip (the backend can be slow to wake up).
        final mapProvider = Provider.of<MapProvider>(context, listen: false);
        final updatedMarkers = mapProvider.markers
            .where((m) => m.point != markerLocation)
            .toList();
        mapProvider.setMarkers(updatedMarkers);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.volunteer_activism_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Thank you for helping!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  )),
            ]),
            backgroundColor: const Color(0xFF0F6E56),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);

        // Delete on the server in the background. If it fails, re-sync the
        // markers so the pin reappears and the user can retry.
        PinController().deletePin(pin.pinId).catchError((e) {
          log('Error marking pin as served: $e');
          if (mounted) {
            loadMarkers();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Could not mark as served. Please try again.',
                          style: TextStyle(fontSize: 13))),
                ]),
                backgroundColor: const Color(0xFFA32D2D),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(12),
              ),
            );
          }
        });
      },
    ).then((_) {
      setState(() => _selectedMarkerLocation = null);
      _markerAnimationController.reverse();
    });
  }

  /// Wraps [Geolocator.getLastKnownPosition], which throws
  /// [UnimplementedError] on web (there's no "last known position" concept
  /// in the browser Geolocation API). Returning null lets callers fall back
  /// to [Geolocator.getCurrentPosition] instead of crashing the whole chain.
  Future<Position?> _getLastKnownPosition() async {
    if (kIsWeb) return null;
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      log('getLastKnownPosition failed: $e');
      return null;
    }
  }

  Future<void> _requestLocationPermission() async {
    if (kIsWeb) {
      // See _checkAndRequestPermissions: geolocator_web's requestPermission
      // conflates "couldn't get a position" with "permission denied
      // forever", so don't let it gate the My Location button. Let the
      // browser's own permission prompt (triggered by getCurrentPosition)
      // and _moveToCurrentLocation's error handling take it from here.
      setState(() => _hasLocationPermission = true);
      return;
    }
    final permission = await Geolocator.requestPermission();
    setState(() {
      _locationPermission = permission;
      _hasLocationPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
    if (!_hasLocationPermission) _showPermissionDeniedDialog();
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
      final position = await _getLastKnownPosition() ??
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
      setState(() => _subscribedGridIds = subscribedGrids);

      await LocationController().saveLastLocation(_currentLocation!);
      mapProvider.setLocation(_currentLocation!);
      if (_lastKnownLocation == null) {
        _animateToLocation(_currentLocation!);
        setState(() => _isUsingCurrentLocation = true);
      }
      await _saveLocation(_currentLocation!);

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
        onError: (error) => log('Location stream error: $error'),
      );
    } catch (e) {
      log('Error setting up location tracking: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.info_outline, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  'Enable location services to see your current position')),
        ]),
        action: SnackBarAction(
          label: 'Enable',
          textColor: Colors.white,
          onPressed: _moveToCurrentLocation,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showLocationEnabledSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 8),
        Text('Location services enabled!'),
      ]),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showLocationLoadingSnackBar() {
    _locationLoadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Getting your location…'),
        ]),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;
    showLocationServiceDialog(context).then((_) {
      _startLocationServiceCheck();
    });
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showLocationPermissionDialog(
      context,
      onSkip: _showLastKnownLocationFallback,
    );
  }

  void _startLocationServiceCheck() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        timer.cancel();
        setState(() => _locationServiceEnabled = true);
        await _setupLocationTracking();
        _showLocationEnabledSnackBar();
      }
    });
  }

  void _toggleGridSelectionMode() {
    HapticFeedback.lightImpact();
    _gridFabAnimationController
        .forward()
        .then((_) => _gridFabAnimationController.reverse());
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

// ═══════════════════════════════════════════════════════════════
// MAP FAB — refined floating action button
// ═══════════════════════════════════════════════════════════════

class _MapFab extends StatefulWidget {
  final String heroTag;
  final VoidCallback onPressed;
  final IconData icon;
  final bool isActive;
  final KMTheme theme;
  final String tooltip;

  const _MapFab({
    required this.heroTag,
    required this.onPressed,
    required this.icon,
    required this.isActive,
    required this.theme,
    required this.tooltip,
  });

  @override
  State<_MapFab> createState() => _MapFabState();
}

class _MapFabState extends State<_MapFab> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pressScale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressing = true);
          _pressCtrl.forward();
        },
        onTapUp: (_) {
          setState(() => _pressing = false);
          _pressCtrl.reverse();
          widget.onPressed();
        },
        onTapCancel: () {
          setState(() => _pressing = false);
          _pressCtrl.reverse();
        },
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (_, __) => Transform.scale(
            scale: _pressScale.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? theme.primary.withOpacity(0.15)
                    : theme.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isActive
                      ? theme.primary.withOpacity(0.5)
                      : theme.primaryText.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  // Add a subtle white outer glow when dark mode is active
                  if (Theme.of(context).brightness == Brightness.dark ||
                      (Theme.of(context).brightness == Brightness.light &&
                          widget.isActive))
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: -1,
                      offset: const Offset(0, 0),
                    ),
                ],
              ),
              child: AnimatedRotation(
                turns: widget.isActive ? 0.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isActive ? theme.primary : theme.secondaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MAP STYLE SWITCHER — elegant overlay panel
// ═══════════════════════════════════════════════════════════════

class _MapStyleSwitcher extends StatefulWidget {
  final List<MapStyle> styles;
  final MapStyle currentStyle;
  final KMTheme theme;
  final bool isDark;
  final Function(MapStyle) onStyleSelected;

  const _MapStyleSwitcher({
    required this.styles,
    required this.currentStyle,
    required this.theme,
    required this.isDark,
    required this.onStyleSelected,
  });

  @override
  State<_MapStyleSwitcher> createState() => _MapStyleSwitcherState();
}

class _MapStyleSwitcherState extends State<_MapStyleSwitcher>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Toggle button
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _open
                  ? theme.primary.withOpacity(0.12)
                  : theme.secondaryBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _open
                    ? theme.primary.withOpacity(0.4)
                    : theme.primaryText.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _open
                      ? theme.primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _open ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.layers_rounded,
                size: 20,
                color: _open ? theme.primary : theme.secondaryText,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Style panel
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.topRight,
              child: _open
                  ? Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.primaryText.withOpacity(0.07),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                              child: Row(children: [
                                Icon(Icons.layers_rounded,
                                    size: 14, color: theme.secondaryText),
                                const SizedBox(width: 6),
                                Text(
                                  'Map Style',
                                  style: theme.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ]),
                            ),
                            ...widget.styles.asMap().entries.map((entry) {
                              final i = entry.key;
                              final style = entry.value;
                              final isSelected =
                                  widget.currentStyle.name == style.name;
                              return _StyleRow(
                                style: style,
                                isSelected: isSelected,
                                theme: theme,
                                isLast: i == widget.styles.length - 1,
                                onTap: () {
                                  widget.onStyleSelected(style);
                                  _toggle();
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StyleRow extends StatefulWidget {
  final MapStyle style;
  final bool isSelected;
  final KMTheme theme;
  final bool isLast;
  final VoidCallback onTap;

  const _StyleRow({
    required this.style,
    required this.isSelected,
    required this.theme,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_StyleRow> createState() => _StyleRowState();
}

class _StyleRowState extends State<_StyleRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(
              left: 8, right: 8, bottom: widget.isLast ? 10 : 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.primary.withOpacity(0.1)
                : _hovered
                    ? theme.primaryText.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(children: [
            Icon(
              widget.style.icon,
              size: 16,
              color: widget.isSelected ? theme.primary : theme.secondaryText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.style.name,
                style: theme.labelMedium.copyWith(
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? theme.primary
                      : theme.primaryText.withOpacity(0.8),
                ),
              ),
            ),
            if (widget.isSelected)
              Icon(Icons.check_rounded, size: 14, color: theme.primary),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LOADING PULSE WIDGET
// ═══════════════════════════════════════════════════════════════

class _LoadingPulse extends StatefulWidget {
  final KMTheme theme;
  const _LoadingPulse({required this.theme});

  @override
  State<_LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<_LoadingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ringOpacity1;
  late Animation<double> _ringOpacity2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _ring1 = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ring2 = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _ringOpacity1 = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ringOpacity2 = Tween<double>(begin: 0.5, end: 0.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: 80,
        height: 80,
        child: Stack(alignment: Alignment.center, children: [
          // Ring 1
          Opacity(
            opacity: _ringOpacity1.value,
            child: Transform.scale(
              scale: _ring1.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.primary.withOpacity(0.4), width: 1.5),
                ),
              ),
            ),
          ),
          // Ring 2
          Opacity(
            opacity: _ringOpacity2.value,
            child: Transform.scale(
              scale: _ring2.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.primary.withOpacity(0.6), width: 1.5),
                ),
              ),
            ),
          ),
          // Center dot
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primary.withOpacity(0.12),
              border:
                  Border.all(color: theme.primary.withOpacity(0.6), width: 2),
            ),
            child:
                Icon(Icons.location_on_rounded, color: theme.primary, size: 20),
          ),
        ]),
      ),
    );
  }
}
