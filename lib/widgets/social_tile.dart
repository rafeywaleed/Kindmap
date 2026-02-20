import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';

Widget socialTile(
    BuildContext context, String name, String platform, String link) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: KMTheme.of(context).secondaryBackground,
      ),
      child: Row(
        children: [
          Icon(
            platform == "instagram"
                ? FontAwesomeIcons.instagram
                : platform == "facebook"
                    ? FontAwesomeIcons.facebook
                    : FontAwesomeIcons.linkedin,
            color: KMTheme.of(context).primaryText,
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              if (await canLaunchUrl(Uri.parse(link))) {
                await launchUrl(Uri.parse(link));
              } else {
                throw 'Could not launch $link';
              }
            },
            child: Text(
              name,
              style: KMTheme.of(context).bodyMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class SocialMediaIconButton extends StatelessWidget {
  final Color _borderColor;
  final double _borderRadius;
  final double _borderWidth;
  final double _buttonSize;
  final Color _fillColor;
  final Widget _icon;
  final VoidCallback _onPressed;

  const SocialMediaIconButton({
    super.key,
    required Color borderColor,
    required double borderRadius,
    required double borderWidth,
    required double buttonSize,
    required Color fillColor,
    required Widget icon,
    required void Function() onPressed,
  })  : _onPressed = onPressed,
        _icon = icon,
        _fillColor = fillColor,
        _buttonSize = buttonSize,
        _borderWidth = borderWidth,
        _borderRadius = borderRadius,
        _borderColor = borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: _fillColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _borderColor, width: _borderWidth),
      ),
      child: IconButton(
        icon: _icon,
        iconSize: _buttonSize,
        onPressed: _onPressed,
      ),
    );
  }
}
