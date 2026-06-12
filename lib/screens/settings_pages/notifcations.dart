import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../widgets/settings_widgets.dart';

const String _kNotifNearby = 'notif_nearby_requests';
const String _kNotifPinActivity = 'notif_pin_activity';
const String _kNotifMilestones = 'notif_milestones';
const String _kNotifUpdates = 'notif_app_updates';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _systemEnabled = false;

  bool _nearby = true;
  bool _pinActivity = true;
  bool _milestones = true;
  bool _updates = true;

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSystemStatus();
    }
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final status = await Permission.notification.status;

    setState(() {
      _systemEnabled = status.isGranted;
      _nearby = _prefs.getBool(_kNotifNearby) ?? true;
      _pinActivity = _prefs.getBool(_kNotifPinActivity) ?? true;
      _milestones = _prefs.getBool(_kNotifMilestones) ?? true;
      _updates = _prefs.getBool(_kNotifUpdates) ?? true;
      _loading = false;
    });
  }

  Future<void> _refreshSystemStatus() async {
    final status = await Permission.notification.status;
    if (mounted) setState(() => _systemEnabled = status.isGranted);
  }

  Future<void> _toggleMaster(bool value) async {
    if (!value) {
      await openAppSettings();
      await _refreshSystemStatus();
      return;
    }

    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      if (mounted) _showOpenSettingsDialog();
    }
    await _refreshSystemStatus();
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Notifications are turned off for KindMap in your device '
          'settings. Open settings to turn them back on.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _setPref(String key, bool value, VoidCallback apply) {
    setState(apply);
    _prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: settingsAppBar(context, 'Notifications'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  FadeSlideIn(
                    child: SettingsHeroHeader(
                      icon: Icons.notifications_active_outlined,
                      title: 'Stay in the loop',
                      subtitle: _systemEnabled
                          ? 'Notifications are on. Choose what KindMap can '
                              'let you know about.'
                          : 'Notifications are currently off for KindMap. '
                              'Turn them on to hear about nearby requests '
                              'and updates on your pins.',
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: SettingsCard(
                      children: [
                        SettingsSwitchTile(
                          icon: Icons.notifications_outlined,
                          title: 'Push Notifications',
                          subtitle: _systemEnabled
                              ? 'Enabled for this device'
                              : 'Tap to enable in device settings',
                          value: _systemEnabled,
                          onChanged: _toggleMaster,
                        ),
                      ],
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: const SettingsSectionLabel('Notification types'),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: SettingsCard(
                      children: [
                        SettingsSwitchTile(
                          icon: Icons.location_on_outlined,
                          title: 'Nearby help requests',
                          subtitle:
                              'New pins are added in your area or grids you follow',
                          value: _nearby,
                          onChanged: _systemEnabled
                              ? (v) => _setPref(
                                  _kNotifNearby, v, () => _nearby = v)
                              : null,
                        ),
                        const SettingsDivider(),
                        SettingsSwitchTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Pin activity & replies',
                          subtitle:
                              'Someone responds to or helps with a pin you created',
                          value: _pinActivity,
                          onChanged: _systemEnabled
                              ? (v) => _setPref(_kNotifPinActivity, v,
                                  () => _pinActivity = v)
                              : null,
                        ),
                        const SettingsDivider(),
                        SettingsSwitchTile(
                          icon: Icons.emoji_events_outlined,
                          title: 'Community milestones',
                          subtitle:
                              'Celebrate when you reach a new "people helped" milestone',
                          value: _milestones,
                          onChanged: _systemEnabled
                              ? (v) => _setPref(_kNotifMilestones, v,
                                  () => _milestones = v)
                              : null,
                        ),
                        const SettingsDivider(),
                        SettingsSwitchTile(
                          icon: Icons.campaign_outlined,
                          title: 'App updates & tips',
                          subtitle:
                              'Occasional news, new features and tips from KindMap',
                          value: _updates,
                          onChanged: _systemEnabled
                              ? (v) => _setPref(
                                  _kNotifUpdates, v, () => _updates = v)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Text(
                        'You can change notification permissions for KindMap '
                        'any time from your device settings.',
                        textAlign: TextAlign.center,
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
