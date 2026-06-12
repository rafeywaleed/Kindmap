import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_theme.dart';
import '../../widgets/settings_widgets.dart';

class Permissions extends StatefulWidget {
  const Permissions({super.key});

  @override
  State<Permissions> createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> with WidgetsBindingObserver {
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool _locationServiceEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final location = await Permission.locationWhenInUse.status;
    final camera = await Permission.camera.status;
    final notification = await Permission.notification.status;
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!mounted) return;
    setState(() {
      _locationStatus = location;
      _cameraStatus = camera;
      _notificationStatus = notification;
      _locationServiceEnabled = locationServiceEnabled;
      _loading = false;
    });
  }

  Future<void> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: settingsAppBar(context, 'Permissions'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  FadeSlideIn(
                    child: const SettingsHeroHeader(
                      icon: Icons.shield_outlined,
                      title: 'App permissions',
                      subtitle:
                          'KindMap only asks for what it needs to help you '
                          'pin and find help nearby. You\'re in control and '
                          'can change these any time.',
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _PermissionTile(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            description:
                                'Used to show your position on the map and '
                                'place pins at the right spot.',
                            status: _locationStatus,
                            extraWarning: _locationStatus.isGranted &&
                                    !_locationServiceEnabled
                                ? 'Location services are turned off on this device'
                                : null,
                            onAllow: () =>
                                _request(Permission.locationWhenInUse),
                            onExtraAction: !_locationServiceEnabled
                                ? Geolocator.openLocationSettings
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _PermissionTile(
                            icon: Icons.camera_alt_outlined,
                            title: 'Camera',
                            description:
                                'Used to take a photo when you create a new '
                                'pin for someone who needs help.',
                            status: _cameraStatus,
                            onAllow: () => _request(Permission.camera),
                          ),
                          const SizedBox(height: 12),
                          _PermissionTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            description:
                                'Used to let you know about nearby requests '
                                'and updates on pins you created.',
                            status: _notificationStatus,
                            onAllow: () => _request(Permission.notification),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Text(
                        'You can manage all permissions for KindMap from '
                        'your device\'s app settings at any time.',
                        textAlign: TextAlign.center,
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: SettingsPrimaryButton(
                        text: 'Open App Settings',
                        icon: Icons.settings_outlined,
                        onPressed: openAppSettings,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final String? extraWarning;
  final VoidCallback onAllow;
  final VoidCallback? onExtraAction;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onAllow,
    this.extraWarning,
    this.onExtraAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final granted = status.isGranted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryText.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: theme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.bodyMedium.copyWith(
                            fontFamily: 'Readex Pro',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(granted: granted),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (extraWarning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: theme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      extraWarning!,
                      style: theme.labelSmall.copyWith(
                        color: theme.primaryText,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!granted || onExtraAction != null) ...[
            const SizedBox(height: 12),
            SettingsPrimaryButton(
              text: onExtraAction != null
                  ? 'Turn on Location Services'
                  : status.isPermanentlyDenied
                      ? 'Open Settings'
                      : 'Allow $title',
              onPressed: onExtraAction ?? onAllow,
              color: granted ? theme.tertiary : theme.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool granted;
  const _StatusPill({required this.granted});

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final color = granted ? theme.success : theme.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            granted ? 'Granted' : 'Not granted',
            style: theme.labelSmall.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
