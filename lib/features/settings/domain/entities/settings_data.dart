import 'package:flutter/material.dart';

class SettingsData {
  final double fontSize;
  final double brightness;
  final double contrast;
  final Axis scrollDirection;
  final ThemeMode themeMode;

  SettingsData({
    required this.fontSize,
    required this.brightness,
    required this.contrast,
    required this.scrollDirection,
    required this.themeMode,
  });
}
