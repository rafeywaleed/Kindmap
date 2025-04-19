import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kindmap/themes/kmTheme.dart';

class ImagePreview extends StatelessWidget {
  final String imagePath;
  final bool isWeb;

  const ImagePreview({
    Key? key,
    required this.imagePath,
    required this.isWeb,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: KMTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: isWeb
          ? Image.network(
              imagePath,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            ),
    );
  }
}
