import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../widgets/settings_widgets.dart';
import 'contact.dart';

class _PolicySection {
  final String title;
  final String body;
  const _PolicySection(this.title, this.body);
}

const List<_PolicySection> _sections = [
  _PolicySection(
    'Information we collect',
    'We collect information you provide directly, such as your name, '
        'email address, and the pins, photos and comments you create. We '
        'also collect location information when you use map features, and '
        'basic device and usage information to help us improve the app.',
  ),
  _PolicySection(
    'How we use your information',
    'We use your information to provide and improve KindMap\'s services, '
        'show pins on the map, personalize your experience, communicate '
        'with you about your account, and respond to your support requests.',
  ),
  _PolicySection(
    'Sharing your information',
    'We do not sell your personal information. We may share information '
        'with service providers that help us operate KindMap, with law '
        'enforcement where required by law, or with your consent.',
  ),
  _PolicySection(
    'Data retention',
    'We retain your information for as long as necessary to provide our '
        'services and fulfil the purposes described in this policy, unless '
        'a longer retention period is required or permitted by law.',
  ),
  _PolicySection(
    'Security',
    'We take reasonable measures to protect your information from '
        'unauthorized access, use or disclosure. However, no method of '
        'transmission over the internet or electronic storage is completely '
        'secure.',
  ),
  _PolicySection(
    'Changes to this policy',
    'We may update this Privacy Policy from time to time. We will notify '
        'you of any changes by posting the new policy on this page.',
  ),
];

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: settingsAppBar(context, 'Privacy Policy'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            FadeSlideIn(
              child: const SettingsHeroHeader(
                icon: Icons.privacy_tip_outlined,
                title: 'Your privacy matters',
                subtitle:
                    'This page explains what information KindMap collects, '
                    'how it\'s used, and how it\'s protected.',
              ),
            ),
            for (var i = 0; i < _sections.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 60 + i * 30),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sections[i].title,
                        style: theme.titleLarge.copyWith(
                          fontFamily: 'Outfit',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sections[i].body,
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                          height: 1.6,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            FadeSlideIn(
              delay: Duration(milliseconds: 60 + _sections.length * 30),
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Questions about this policy?',
                    subtitle: 'Contact us at $kSupportEmail',
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
