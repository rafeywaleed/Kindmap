import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageProcessingExample extends StatefulWidget {
  const ImageProcessingExample({Key? key}) : super(key: key);

  @override
  State<ImageProcessingExample> createState() => _ImageProcessingExampleState();
}

class _ImageProcessingExampleState extends State<ImageProcessingExample> {
  ui.Image? _originalImage;
  ui.Image? _processedImage;

  @override
  void initState() {
    super.initState();
    _loadAndProcessImage();
  }

  Future<void> _loadAndProcessImage() async {
    // Load image from assets
    final ByteData data = await rootBundle.load('assets/sample.png');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode image from bytes
    final ui.Image original = await decodeImageFromList(bytes);
    final ByteData? byteData =
        await original.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return;

    Uint8List pixels = byteData.buffer.asUint8List();
    int width = original.width;
    int height = original.height;

    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image newImage) {
        setState(() {
          _originalImage = original;
          _processedImage = newImage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Int/Double Conversion')),
      body: Center(
        child: _originalImage == null
            ? const CircularProgressIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RawImage(image: _originalImage, scale: 1.0),
                  const SizedBox(width: 20),
                  RawImage(image: _processedImage, scale: 1.0),
                ],
              ),
      ),
    );
  }
}
