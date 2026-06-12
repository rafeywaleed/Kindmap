import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../widgets/settings_widgets.dart';
import 'contact.dart';

const String kAppVersion = '1.0.0';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: settingsAppBar(context, 'About'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/KindMap-logo-f.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'KindMap',
                      style: theme.headlineSmall.copyWith(
                        fontFamily: 'Outfit',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Help is near · v$kAppVersion',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'KindMap turns kindness into something you can see on a '
                  'map. People in need can be pinned to real locations, so '
                  'help finds its way to the people who need it most — '
                  'whether that\'s food, shelter, clothing, or just someone '
                  'who notices.',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: const SettingsSectionLabel('What KindMap offers'),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 130),
              child: SettingsCard(
                children: const [
                  SettingsTile(
                    icon: Icons.location_on_outlined,
                    title: 'Pin real locations',
                    subtitle:
                        'Drop a pin with a photo to flag someone who needs help',
                    showChevron: false,
                  ),
                  SettingsDivider(),
                  SettingsTile(
                    icon: Icons.map_outlined,
                    title: 'Community map & grids',
                    subtitle:
                        'See active pins around you, organized by area',
                    showChevron: false,
                  ),
                  SettingsDivider(),
                  SettingsTile(
                    icon: Icons.emoji_events_outlined,
                    title: 'Track your impact',
                    subtitle:
                        'Your profile keeps count of how many people you\'ve helped',
                    showChevron: false,
                  ),
                  SettingsDivider(),
                  SettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy-first',
                    subtitle:
                        'Location and camera access are only used for pins you create',
                    showChevron: false,
                  ),
                ],
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: const SettingsSectionLabel('More'),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & FAQs',
                    onTap: () => Navigator.of(context).pushNamed('/help'),
                  ),
                  const SettingsDivider(),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/privacypolicy'),
                  ),
                  const SettingsDivider(),
                  SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact us',
                    onTap: () => Navigator.of(context).pushNamed('/contact'),
                  ),
                ],
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 250),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  children: [
                    Text(
                      'Made with care for our communities',
                      textAlign: TextAlign.center,
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kSupportEmail,
                      textAlign: TextAlign.center,
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
