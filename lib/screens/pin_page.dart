import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/widgets/page_icon_button.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/pin_controller.dart';
import '../models/pin_model.dart';
import '../services/get_cell_info.dart';
import '../config/app_theme.dart';

class PinPage extends StatefulWidget {
  final XFile image;
  const PinPage({super.key, required this.image});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> with TickerProviderStateMixin {
  final FocusNode _unfocusNode = FocusNode();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  String? _selectedTimer;
  bool _isLoading = false;
  bool _isDone = false;
  LatLng? _location;
  Uint8List? _imageBytes;

  // Entrance animations
  late AnimationController _entranceCtrl;
  late Animation<double> _imageFade;
  late Animation<double> _imageScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  // Success animation
  late AnimationController _successCtrl;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  // Pin button press
  late AnimationController _pinBtnCtrl;
  late Animation<double> _pinBtnScale;

  final List<_TimerOption> _timerOptions = const [
    _TimerOption('1 hr', 1, Icons.hourglass_top_rounded),
    _TimerOption('3 hrs', 3, Icons.hourglass_bottom_rounded),
    _TimerOption('5 hrs', 5, Icons.hourglass_full_rounded),
    _TimerOption('10 hrs', 10, Icons.schedule_rounded),
    _TimerOption('24 hrs', 24, Icons.today_rounded),
  ];
  String _selectedTimerLabel = '3 hrs';

  @override
  void initState() {
    super.initState();
    getLocation();
    _loadImageBytes();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _imageFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _formFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
    ));
    _btnFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );
    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
    ));

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successFade = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut);

    _pinBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _pinBtnScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pinBtnCtrl, curve: Curves.easeOut),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _successCtrl.dispose();
    _pinBtnCtrl.dispose();
    _unfocusNode.dispose();
    _noteCtrl.dispose();
    _locationCtrl.dispose();
    _noteFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted)
        setState(() => _location = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadImageBytes() async {
    final bytes = await widget.image.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  Future<String> _compressAndConvert(Uint8List bytes) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 800,
        minWidth: 800,
        quality: 85,
      );
      return base64Encode(compressed);
    } catch (_) {
      return base64Encode(bytes);
    }
  }

  Future<void> _submitPin() async {
    if (_location == null) {
      _showSnack('Still fetching location…', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final base64Image = await _compressAndConvert(_imageBytes!);
      final cellInfo = getCellInfo(_location!.latitude, _location!.longitude);
      final cellId = cellInfo['cellId'];
      final topic = cellInfo['topic'];
      final pinId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final timerVal = _timerOptions
          .firstWhere((t) => t.label == _selectedTimerLabel,
              orElse: () => _timerOptions[1])
          .hours;

      final pin = Pin(
        pinId: pinId,
        gridId: cellId,
        createdAt: DateTime.now(),
        details: _locationCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        imageBase64: base64Image,
        timer: timerVal,
        createdBy: userId,
      );

      await PinController().addPin(pin);
      await _sendNotification(topic);

      setState(() {
        _isLoading = false;
        _isDone = true;
      });

      await _successCtrl.forward();
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted)
        Navigator.of(context)
          ..pop() // pin page
          ..pop(); // camera page
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error creating pin: $e', isError: true);
    }
  }

  /// Asks the backend to push a "new pin nearby" notification to [topic].
  /// The actual FCM send (and the service-account credentials it requires)
  /// lives server-side — the client never holds that key.
  Future<void> _sendNotification(String topic) async {
    try {
      // Topic subscriptions aren't supported on web clients.
      if (!kIsWeb) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      }
      await http
          .post(
            Uri.parse(
                'https://kindmap.onrender.com/api/v1/notifications/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'topic': topic}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? const Color(0xFFE5151E) : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Stack(
          children: [
            // ── Main content ──────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(theme),

                  // Scrollable form
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image preview
                          FadeTransition(
                            opacity: _imageFade,
                            child: ScaleTransition(
                              scale: _imageScale,
                              child: _buildImageCard(theme, size),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Form fields
                          SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: _buildFormCard(theme),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Timer selector
                          SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: _buildTimerSelector(theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pin button ────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _btnSlide,
                child: FadeTransition(
                  opacity: _btnFade,
                  child: _buildPinButton(theme, size),
                ),
              ),
            ),

            // ── Success overlay ───────────────────────────────
            if (_isDone) _buildSuccessOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(KMTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back
          PageIconButton(
            icon: Icons.arrow_back_ios_rounded,
            theme: theme,
            onTap: () => Navigator.of(context).pop(),
          ),

          const Spacer(),

          Column(
            children: [
              Text(
                'Create Pin',
                style: theme.bodyMedium.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: theme.primaryText,
                ),
              ),
              // Location status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _location != null ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _location != null ? 'Location ready' : 'Getting location…',
                    style: theme.bodySmall.copyWith(
                      fontSize: 11,
                      color: theme.secondaryText.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Placeholder for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildImageCard(KMTheme theme, Size size) {
    return Hero(
      tag: 'camera',
      child: Container(
        width: double.infinity,
        height: size.height * 0.32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _imageBytes == null
                  ? Container(color: Colors.black12)
                  : Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
              ),
              // Inner subtle vignette
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
              // Photo badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_rounded,
                          size: 12, color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 5),
                      Text(
                        'Photo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(KMTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryText.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note field
          _buildFieldSection(
            theme: theme,
            icon: Icons.edit_note_rounded,
            label: 'Add a note',
            child: _buildTextField(
              controller: _noteCtrl,
              focusNode: _noteFocus,
              hint: 'e.g. Food, medical help, money…',
              maxLines: 3,
              theme: theme,
            ),
            isFirst: true,
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Divider(
              color: theme.primaryText.withOpacity(0.07),
              height: 1,
            ),
          ),

          // Location details
          _buildFieldSection(
            theme: theme,
            icon: Icons.place_outlined,
            label: 'Location details',
            child: _buildTextField(
              controller: _locationCtrl,
              focusNode: _locationFocus,
              hint: 'Near the blue gate, opposite…',
              maxLines: 2,
              theme: theme,
            ),
            isFirst: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSection({
    required KMTheme theme,
    required IconData icon,
    required String label,
    required Widget child,
    required bool isFirst,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, isFirst ? 18 : 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.primary.withOpacity(0.8)),
              const SizedBox(width: 7),
              Text(
                label,
                style: theme.bodyMedium.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText.withOpacity(0.75),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required int maxLines,
    required KMTheme theme,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      style: theme.bodyMedium.copyWith(
        fontFamily: 'Readex Pro',
        fontSize: 14,
        color: theme.primaryText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.bodyMedium.copyWith(
          fontFamily: 'Readex Pro',
          fontSize: 14,
          color: theme.secondaryText.withOpacity(0.45),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.primaryText.withOpacity(0.1),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.primary.withOpacity(0.55),
            width: 1.5,
          ),
        ),
        fillColor: theme.primaryBackground.withOpacity(0.5),
        filled: true,
      ),
    );
  }

  Widget _buildTimerSelector(KMTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBgColor = isDark ? theme.tertiary : theme.primary;
    final selectedTextColor = Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryText.withOpacity(0.06),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 16, color: theme.primary.withOpacity(0.8)),
              const SizedBox(width: 7),
              Text(
                'Pin expires after',
                style: theme.bodyMedium.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText.withOpacity(0.75),
                ),
              ),
              const Spacer(),
              Text(
                'Tap to select',
                style: theme.bodySmall.copyWith(
                  fontSize: 11,
                  color: theme.secondaryText.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timerOptions.map((opt) {
              final isSelected = _selectedTimerLabel == opt.label;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTimerLabel = opt.label);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedBgColor
                        : theme.primaryText.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.primary
                          : theme.primaryText.withOpacity(0.08),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: selectedBgColor.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opt.icon,
                        size: 13,
                        color: isSelected
                            ? Colors.white
                            : theme.primaryText.withOpacity(0.45),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        opt.label,
                        style: theme.bodySmall.copyWith(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.primaryText.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'The pin auto-removes after the selected time.',
            style: theme.bodySmall.copyWith(
              fontSize: 11,
              color: theme.secondaryText.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinButton(KMTheme theme, Size size) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(
          top: BorderSide(
            color: theme.primaryText.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: ScaleTransition(
        scale: _pinBtnScale,
        child: GestureDetector(
          onTapDown: (_) => _pinBtnCtrl.forward(),
          onTapUp: (_) {
            _pinBtnCtrl.reverse();
            _submitPin();
          },
          onTapCancel: () => _pinBtnCtrl.reverse(),
          child: Hero(
            tag: 'camera-bottom',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 58,
              decoration: BoxDecoration(
                color:
                    _isLoading ? Colors.black.withOpacity(0.75) : Colors.black,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.32),
                    blurRadius: 3,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 29,
                      child: Container(
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    // Content
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.85, end: 1.0)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                key: const ValueKey('idle'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.pin_drop_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Create Pin',
                                    style: theme.bodyMedium.copyWith(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(KMTheme theme) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _successFade,
        child: Container(
          color: theme.primaryBackground.withOpacity(0.92),
          child: Center(
            child: ScaleTransition(
              scale: _successScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pin Created!',
                    style: theme.bodyMedium.copyWith(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Help is on the way',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText.withOpacity(0.55),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timer option model ────────────────────────────────────────────────────────

class _TimerOption {
  final String label;
  final int hours;
  final IconData icon;
  const _TimerOption(this.label, this.hours, this.icon);
}
