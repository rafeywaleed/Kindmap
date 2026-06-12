import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../widgets/settings_widgets.dart';
import 'contact.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: settingsAppBar(context, 'Help'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const FadeSlideIn(
              child: SettingsHeroHeader(
                icon: Icons.help_outline_rounded,
                title: 'How can we help?',
                subtitle: 'Quick answers to common questions about pinning, '
                    'your profile, permissions and more.',
              ),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 60),
              child: SettingsSectionLabel('Getting started'),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 70),
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.travel_explore_rounded,
                    title: 'Replay app walkthrough',
                    subtitle: 'See the quick tour of KindMap again',
                    onTap: () => Navigator.of(context).pushNamed('/walkthrough'),
                  ),
                ],
              ),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 80),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ExpandableInfoCard(
                      icon: Icons.add_location_alt_outlined,
                      title: 'How do I create a pin?',
                      body: 'Tap the pin button on the map to open the camera, '
                          'take a photo of the situation, then drop a pin at '
                          'your current location. Your pin appears on the map '
                          'for others nearby to see.',
                    ),
                    ExpandableInfoCard(
                      icon: Icons.map_outlined,
                      title: 'How do the map and grids work?',
                      body: 'The map is divided into grids — small areas that '
                          'group nearby pins together. Tap a grid to see how '
                          'many active pins are inside it, and use the filters '
                          'on the map to narrow down what you see.',
                    ),
                  ],
                ),
              ),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 120),
              child: SettingsSectionLabel('Your profile'),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 140),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ExpandableInfoCard(
                      icon: Icons.face_retouching_natural_outlined,
                      title: 'How do I change my avatar?',
                      body: 'Open Profile from the side menu, then double-tap '
                          'your avatar. Confirm "Yes" and pick a new avatar '
                          'from the gallery that opens.',
                    ),
                    ExpandableInfoCard(
                      icon: Icons.badge_outlined,
                      title: 'How do I change my name?',
                      body: 'On the Profile page, type your new name in the '
                          '"Change name" field and press done/enter on the '
                          'keyboard to save it.',
                    ),
                    ExpandableInfoCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'How do I change my password?',
                      body: 'On the Profile page, open the "Change Password" '
                          'section, enter your current password followed by '
                          'the new password twice, then tap "Change Password".',
                    ),
                  ],
                ),
              ),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 180),
              child: SettingsSectionLabel('Notifications & permissions'),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 200),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ExpandableInfoCard(
                      icon: Icons.notifications_outlined,
                      title: 'How do I manage notifications?',
                      body:
                          'Go to Notifications from the Settings page to turn '
                          'push notifications on or off, and choose which '
                          'types of alerts you want to receive.',
                    ),
                    ExpandableInfoCard(
                      icon: Icons.shield_outlined,
                      title: 'Why does KindMap need permissions?',
                      body: 'Location is used to show your position and place '
                          'pins accurately. Camera is used to take a photo '
                          'when creating a pin. You can review and manage '
                          'these any time from the Permissions page.',
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 240),
              child: SettingsSectionLabel('Still need help?'),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact support',
                    subtitle: 'Email us at $kSupportEmail',
                    onTap: () => Navigator.of(context).pushNamed('/contact'),
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
