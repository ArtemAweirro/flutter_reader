import 'package:flutter/material.dart';

abstract class SettingsRepository {
  double getFontSize();
  Future<void> setFontSize(double size);

  double getBrightness();
  Future<void> setBrightness(double value);

  double getContrast();
  Future<void> setContrast(double value);

  Axis getScrollDirection();
  Future<void> setScrollDirection(Axis direction);

  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}
