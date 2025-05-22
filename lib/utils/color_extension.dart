import 'package:flutter/material.dart';
import 'dart:ui';

extension ColorExtension on Color {
  int toARGB32() {
    return value;
  }
}
