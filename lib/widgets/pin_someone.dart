import 'package:flutter/material.dart';
import 'package:kindmap/screens/camera.dart';

import '../config/app_theme.dart';

Widget PinSomeone(Size size, BuildContext context) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Hero(
        tag: 'pin_button',
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                reverseTransitionDuration: const Duration(milliseconds: 600),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const CameraPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Fade and slide animation
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var slideTween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  var fadeTween = Tween(begin: 0.0, end: 1.0)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(slideTween),
                    child: FadeTransition(
                      opacity: animation.drive(fadeTween),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          child: Container(
            height: size.height * 0.08,
            decoration: BoxDecoration(
              color: KMTheme.of(context).secondary,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: Color(0x33000000),
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Pin Someone',
                    style: KMTheme.of(context).bodyMedium.copyWith(
                          fontFamily: 'Plus Jakarta Sans',
                          color: KMTheme.of(context).primaryText,
                          fontSize: 20,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.share_location,
                    color: KMTheme.of(context).primaryText,
                    size: 40,
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
