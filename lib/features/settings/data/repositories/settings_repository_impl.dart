import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../domain/repositories/settings_repository.dart';

@Injectable(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  static const _kFontSize = 'reader_font_size';
  static const _kBrightness = 'reader_brightness';
  static const _kContrast = 'reader_contrast';
  static const _kScrollDirection = 'reader_scroll_direction';
  static const _kThemeMode = 'app_theme_mode';

  @override
  double getFontSize() => _prefs.getDouble(_kFontSize) ?? 16.0;

  @override
  Future<void> setFontSize(double size) => _prefs.setDouble(_kFontSize, size);

  @override
  double getBrightness() => _prefs.getDouble(_kBrightness) ?? 1.0;

  @override
  Future<void> setBrightness(double value) async {
    await ScreenBrightness().setApplicationScreenBrightness(value);
    await _prefs.setDouble(_kBrightness, value);
  }

  @override
  double getContrast() => _prefs.getDouble(_kContrast) ?? 1.0;

  @override
  Future<void> setContrast(double value) => _prefs.setDouble(_kContrast, value);

  @override
  Axis getScrollDirection() {
    final val = _prefs.getString(_kScrollDirection);
    return val == 'vertical' ? Axis.vertical : Axis.horizontal;
  }

  @override
  Future<void> setScrollDirection(Axis direction) => _prefs.setString(
        _kScrollDirection,
        direction == Axis.vertical ? 'vertical' : 'horizontal',
      );

  @override
  ThemeMode getThemeMode() {
    final val = _prefs.getString(_kThemeMode);
    return switch (val) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(
        _kThemeMode,
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );
}
