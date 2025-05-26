import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kindmap/themes/kmTheme.dart';

class ImagePreview extends StatelessWidget {
  final Uint8List imageBytes;

  const ImagePreview({
    Key? key,
    required this.imageBytes,
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
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
      ),
    );
  }
}
