import 'package:flutter/material.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:kindmap/widgets/box_handle.dart';
import 'package:kindmap/widgets/social_tile.dart';

class FollowBox extends StatefulWidget {
  final String s_media;
  FollowBox({super.key, required this.s_media});

  @override
  State<FollowBox> createState() => FollowBoxState();
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

class FollowBoxState extends State<FollowBox> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: KMTheme.of(context).secondaryBackground,
          boxShadow: const [
            BoxShadow(
              blurRadius: 5,
              color: Color(0x3B1D2429),
              offset: Offset(
                0.0,
                -3,
              ),
            )
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            BoxHandle(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.s_media == "instagram") ...[
                    socialTile(context, "Abdul Rafey Waleed", "instagram",
                        "https://www.instagram.com/rafeywaleed_a5"),
                    socialTile(context, "Mohammed Azim Moula", "instagram",
                        "https://www.instagram.com/Azim"),
                  ] else if (widget.s_media == "facebook") ...[
                    socialTile(context, "Abdul Rafey Waleed", "facebook",
                        "https://www.facebook.com/rafeywaleed_a5"),
                    socialTile(context, "Mohammed Azim Moula", "facebook",
                        "https://www.facebook.com/azimM"),
                  ] else ...[
                    socialTile(context, "Abdul Rafey Waleed", "linkedin",
                        "https://www.linkedin.com/in/abdul-rafey-waleed-516052282/"),
                    socialTile(context, "Mohammed Azim Moula", "linkedin",
                        "https://www.linkedin.com/in/mohammed-azim-moula-7b07b4279/"),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
