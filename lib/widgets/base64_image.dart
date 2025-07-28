import 'package:flutter/material.dart';
import 'dart:convert';

class Base64Image extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const Base64Image({
    super.key,
    required this.base64String,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error),
      );
    }
  }
}
