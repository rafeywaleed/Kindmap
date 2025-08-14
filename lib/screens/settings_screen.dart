import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kindmap/config/app_theme.dart';

import '../widgets/follow_button.dart';
import '../widgets/social_tile.dart';

// Custom IconButton to replace FlutterFlowIconButton
class CustomIconButton extends StatelessWidget {
  final Color borderColor;
  final double borderRadius;
  final double buttonSize;
  final Icon icon;
  final VoidCallback onPressed;

  const CustomIconButton({
    Key? key,
    required this.borderColor,
    required this.borderRadius,
    required this.buttonSize,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// Custom Button to replace FFButtonWidget
class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final ButtonStyle? style;
  final TextStyle? textStyle;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.style,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(text, style: textStyle),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? selectedTeamMember;
  String? selectedMedia;

  @override
  void initState() {
    super.initState();
  }

  void updateSelectedMedia(String media) {
    setState(() {
      selectedMedia = media;
    });
  }

  void showFollowBox(String media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FollowBox(s_media: media),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: KMTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: KMTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: false,
        leading: CustomIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30,
          buttonSize: 46,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: KMTheme.of(context).primaryText,
            size: 25,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
            child: Text(
              'Settings Page',
              style: KMTheme.of(context).headlineSmall.copyWith(
                    fontFamily: 'Outfit',
                    letterSpacing: 0,
                  ),
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.of(context).pushNamed('/profile');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: KMTheme.of(context).titleLarge.copyWith(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0,
                                ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: KMTheme.of(context).secondaryText,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.of(context).pushNamed('/notifications');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications',
                            style: KMTheme.of(context).titleLarge.copyWith(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0,
                                ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: KMTheme.of(context).secondaryText,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.of(context).pushNamed('/help');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Help',
                            style: KMTheme.of(context).titleLarge.copyWith(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0,
                                ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: KMTheme.of(context).secondaryText,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.of(context).pushNamed('/privacypolicy');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Privacy Policy',
                            style: KMTheme.of(context).titleLarge.copyWith(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0,
                                ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: KMTheme.of(context).secondaryText,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.of(context).pushNamed('/permissions');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Permissions ',
                            style: KMTheme.of(context).titleLarge.copyWith(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0,
                                ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: KMTheme.of(context).secondaryText,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 0, 8),
            child: Text(
              'Follow us on',
              style: KMTheme.of(context).labelMedium.copyWith(
                    fontFamily: 'Readex Pro',
                    letterSpacing: 0,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SocialMediaIconButton(
                  borderColor: KMTheme.of(context).alternate,
                  borderRadius: 12,
                  borderWidth: 1,
                  buttonSize: 48,
                  fillColor: KMTheme.of(context).secondaryBackground,
                  icon: FaIcon(
                    FontAwesomeIcons.instagram,
                    color: KMTheme.of(context).secondaryText,
                    size: 24,
                  ),
                  onPressed: () {
                    showFollowBox("instagram");
                  },
                ),
                SocialMediaIconButton(
                  borderColor: KMTheme.of(context).alternate,
                  borderRadius: 12,
                  borderWidth: 1,
                  buttonSize: 48,
                  fillColor: KMTheme.of(context).secondaryBackground,
                  icon: FaIcon(
                    FontAwesomeIcons.facebookF,
                    color: KMTheme.of(context).secondaryText,
                    size: 24,
                  ),
                  onPressed: () {
                    showFollowBox("facebook");
                  },
                ),
                SocialMediaIconButton(
                  borderColor: KMTheme.of(context).alternate,
                  borderRadius: 12,
                  borderWidth: 1,
                  buttonSize: 48,
                  fillColor: KMTheme.of(context).secondaryBackground,
                  icon: FaIcon(
                    FontAwesomeIcons.linkedin,
                    color: KMTheme.of(context).secondaryText,
                    size: 24,
                  ),
                  onPressed: () {
                    showFollowBox("linkedin");
                  },
                ),
                ...[
                  SocialMediaIconButton(
                    borderColor: KMTheme.of(context).alternate,
                    borderRadius: 12,
                    borderWidth: 1,
                    buttonSize: 48,
                    fillColor: KMTheme.of(context).secondaryBackground,
                    icon: FaIcon(
                      FontAwesomeIcons.instagram,
                      color: KMTheme.of(context).secondaryText,
                      size: 24,
                    ),
                    onPressed: () {
                      showFollowBox("instagram");
                    },
                  ),
                  const SizedBox(width: 8),
                  SocialMediaIconButton(
                    borderColor: KMTheme.of(context).alternate,
                    borderRadius: 12,
                    borderWidth: 1,
                    buttonSize: 48,
                    fillColor: KMTheme.of(context).secondaryBackground,
                    icon: FaIcon(
                      FontAwesomeIcons.facebookF,
                      color: KMTheme.of(context).secondaryText,
                      size: 24,
                    ),
                    onPressed: () {
                      showFollowBox("facebook");
                    },
                  ),
                  const SizedBox(width: 8),
                  SocialMediaIconButton(
                    borderColor: KMTheme.of(context).alternate,
                    borderRadius: 12,
                    borderWidth: 1,
                    buttonSize: 48,
                    fillColor: KMTheme.of(context).secondaryBackground,
                    icon: FaIcon(
                      FontAwesomeIcons.linkedin,
                      color: KMTheme.of(context).secondaryText,
                      size: 24,
                    ),
                    onPressed: () {
                      showFollowBox("linkedin");
                    },
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
            child: Text(
              'App Versions',
              style: KMTheme.of(context).titleLarge.copyWith(
                    fontFamily: 'Outfit',
                    letterSpacing: 0,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 0, 0),
            child: Text(
              'v0.0.1',
              style: KMTheme.of(context).labelMedium.copyWith(
                    fontFamily: 'Readex Pro',
                    letterSpacing: 0,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 0, 0),
            child: CustomButton(
              onPressed: logout,
              text: 'Log Out',
              style: ElevatedButton.styleFrom(
                backgroundColor: KMTheme.of(context).error,
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  side: BorderSide(
                    color: KMTheme.of(context).error,
                    width: 2,
                  ),
                ),
              ),
              textStyle: KMTheme.of(context).labelMedium.copyWith(
                    fontFamily: 'Readex Pro',
                    color: KMTheme.of(context).info,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ]..add(const SizedBox(height: 64)),
      ),
    );
  }
}
