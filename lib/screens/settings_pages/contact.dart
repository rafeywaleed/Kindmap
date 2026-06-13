import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/settings_widgets.dart';
import '../../widgets/social_tile.dart';

const String kSupportEmail = 'kindmap02@gmail.com';
const String kQuickSupportEmail = 'a.rafeywaleeda5@gmail.com';

class Contact extends StatefulWidget {
  const Contact({super.key});

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  Future<void> _sendEmail(String subject,
      {String email = kSupportEmail}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open mail app for $email')),
      );
    }
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email address copied')),
    );
  }

  void _showFollowBox(String media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FollowBox(s_media: media),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: settingsAppBar(context, 'Contact'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            FadeSlideIn(
              child: const SettingsHeroHeader(
                icon: Icons.support_agent_rounded,
                title: 'We\'re here to help',
                subtitle: 'Have a question, found a bug, or want to suggest '
                    'something new? Reach out — we read every message.',
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.email_outlined,
                    title: kSupportEmail,
                    subtitle: 'Tap to email us directly',
                    onTap: () => _sendEmail('KindMap - Contact'),
                    showChevron: false,
                    trailing: IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: theme.secondaryText,
                      ),
                      onPressed: _copyEmail,
                    ),
                  ),
                ],
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: const SettingsSectionLabel('How can we help'),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a problem',
                    subtitle: 'Tell us what went wrong and we\'ll look into it',
                    iconColor: theme.error,
                    onTap: () => _sendEmail('KindMap - Bug Report'),
                  ),
                  const SettingsDivider(),
                  SettingsTile(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Suggest a feature',
                    subtitle: 'Share an idea to make KindMap better',
                    iconColor: theme.success,
                    onTap: () => _sendEmail('KindMap - Feature Suggestion'),
                  ),
                ],
              ),
            ),
            Divider(
              endIndent: 20,
              indent: 20,
              height: 32,
              thickness: 1,
              color: theme.primary.withOpacity(0.08),
            ),
            // const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _sendEmail(
                    'KindMap - Quick Assistance',
                    email: kQuickSupportEmail,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: theme.primary.withOpacity(0.12)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 18, color: theme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.labelSmall.copyWith(
                                color: theme.secondaryText,
                                height: 1.45,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'For urgent or time-sensitive issues, '
                                      'you can reach out directly to ',
                                ),
                                TextSpan(
                                  text: kQuickSupportEmail,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryText,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' for a quicker response.',
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

            //// -----Commenting the Follow us section for now
            // FadeSlideIn(
            //   delay: const Duration(milliseconds: 200),
            //   child: const SettingsSectionLabel('Follow us'),
            // ),
            // FadeSlideIn(
            //   delay: const Duration(milliseconds: 220),
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 16),
            //     child: Row(
            //       children: [
            //         SocialMediaIconButton(
            //           borderColor: theme.alternate,
            //           borderRadius: 12,
            //           borderWidth: 1,
            //           buttonSize: 48,
            //           fillColor: theme.secondaryBackground,
            //           icon: FaIcon(
            //             FontAwesomeIcons.instagram,
            //             color: theme.secondaryText,
            //             size: 24,
            //           ),
            //           onPressed: () => _showFollowBox('instagram'),
            //         ),
            //         SocialMediaIconButton(
            //           borderColor: theme.alternate,
            //           borderRadius: 12,
            //           borderWidth: 1,
            //           buttonSize: 48,
            //           fillColor: theme.secondaryBackground,
            //           icon: FaIcon(
            //             FontAwesomeIcons.facebookF,
            //             color: theme.secondaryText,
            //             size: 24,
            //           ),
            //           onPressed: () => _showFollowBox('facebook'),
            //         ),
            //         SocialMediaIconButton(
            //           borderColor: theme.alternate,
            //           borderRadius: 12,
            //           borderWidth: 1,
            //           buttonSize: 48,
            //           fillColor: theme.secondaryBackground,
            //           icon: FaIcon(
            //             FontAwesomeIcons.linkedin,
            //             color: theme.secondaryText,
            //             size: 24,
            //           ),
            //           onPressed: () => _showFollowBox('linkedin'),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'We typically respond within 2-3 business days.',
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
