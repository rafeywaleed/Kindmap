import 'package:flutter/material.dart';

import '../config/app_theme.dart';

Widget PinSomeone(Size size, BuildContext context) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () async {
          Navigator.of(context).pushNamed('/camera');
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
                        color: KMTheme.of(context).primaryBtnText,
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
                  color: KMTheme.of(context).primaryBtnText,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
