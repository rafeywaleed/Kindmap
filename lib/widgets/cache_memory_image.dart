// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:kindmap/config/app_theme.dart';

// class _CachedMemoryImage extends StatefulWidget {
//   final String? base64;
//   final double size;
//   final KMTheme theme;

//   const _CachedMemoryImage({
//     required this.base64,
//     required this.size,
//     required this.theme,
//   });

//   @override
//   State<_CachedMemoryImage> createState() => _CachedMemoryImageState();
// }

// class _CachedMemoryImageState extends State<_CachedMemoryImage> {
//   Uint8List? _bytes;
//   bool _hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     _decode();
//   }

//   void _decode() {
//     if (widget.base64 == null || widget.base64!.isEmpty) return;
//     try {
//       _bytes = base64Decode(widget.base64!);
//     } catch (_) {
//       _hasError = true;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.base64 == null || _hasError) {
//       return _ImagePlaceholder(size: widget.size, theme: widget.theme);
//     }
//     if (_bytes == null) {
//       // Still decoding (should be instant, but just in case)
//       return _ImagePlaceholder(size: widget.size, theme: widget.theme, loading: true);
//     }
//     return Image.memory(
//       _bytes!,
//       fit: BoxFit.cover,
//       width: widget.size,
//       height: widget.size,
//     );
//   }
// }
