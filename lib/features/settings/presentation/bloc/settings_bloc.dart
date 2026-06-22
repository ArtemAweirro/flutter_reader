import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class _PrefKeys {
  static const fontSize = 'reader_font_size';
  static const brightness = 'reader_brightness';
  static const contrast = 'reader_contrast';
  static const scrollDirection = 'reader_scroll_direction'; // 'vertical' | 'horizontal'
  static const themeMode = 'app_theme_mode'; // 'system' | 'light' | 'dark'
}


final class SettingsState extends Equatable {
  final double fontSize;
  final double brightness;
  final double contrast;
  final Axis scrollDirection;
  final ThemeMode themeMode;

  const SettingsState({
    this.fontSize = 16.0,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.scrollDirection = Axis.horizontal,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    double? fontSize,
    double? brightness,
    double? contrast,
    Axis? scrollDirection,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      fontSize: fontSize ?? this.fontSize,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props =>
      [fontSize, brightness, contrast, scrollDirection, themeMode];
}


sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class FontSizeChanged extends SettingsEvent {
  final double value;
  const FontSizeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

final class BrightnessChanged extends SettingsEvent {
  final double value;
  const BrightnessChanged(this.value);

  @override
  List<Object?> get props => [value];
}

final class ContrastChanged extends SettingsEvent {
  final double value;
  const ContrastChanged(this.value);

  @override
  List<Object?> get props => [value];
}

final class ScrollDirectionChanged extends SettingsEvent {
  final Axis direction;
  const ScrollDirectionChanged(this.direction);

  @override
  List<Object?> get props => [direction];
}

final class ThemeModeChanged extends SettingsEvent {
  final ThemeMode mode;
  const ThemeModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}


@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences _prefs;

  SettingsBloc(this._prefs) : super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<FontSizeChanged>(_onFontSize);
    on<BrightnessChanged>(_onBrightness);
    on<ContrastChanged>(_onContrast);
    on<ScrollDirectionChanged>(_onScrollDirection);
    on<ThemeModeChanged>(_onThemeMode);
  }

  void _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) {
    emit(SettingsState(
      fontSize: _prefs.getDouble(_PrefKeys.fontSize) ?? 16.0,
      brightness: _prefs.getDouble(_PrefKeys.brightness) ?? 1.0,
      contrast: _prefs.getDouble(_PrefKeys.contrast) ?? 1.0,
      scrollDirection:
          _prefs.getString(_PrefKeys.scrollDirection) == 'vertical'
              ? Axis.vertical
              : Axis.horizontal,
      themeMode: _themeModeFromString(
          _prefs.getString(_PrefKeys.themeMode) ?? 'system'),
    ));
  }

  Future<void> _onFontSize(
      FontSizeChanged event, Emitter<SettingsState> emit) async {
    await _prefs.setDouble(_PrefKeys.fontSize, event.value);
    emit(state.copyWith(fontSize: event.value));
  }

  Future<void> _onBrightness(
      BrightnessChanged event, Emitter<SettingsState> emit) async {
    await _prefs.setDouble(_PrefKeys.brightness, event.value);
    emit(state.copyWith(brightness: event.value));
  }

  Future<void> _onContrast(
      ContrastChanged event, Emitter<SettingsState> emit) async {
    await _prefs.setDouble(_PrefKeys.contrast, event.value);
    emit(state.copyWith(contrast: event.value));
  }

  Future<void> _onScrollDirection(
      ScrollDirectionChanged event, Emitter<SettingsState> emit) async {
    await _prefs.setString(
      _PrefKeys.scrollDirection,
      event.direction == Axis.vertical ? 'vertical' : 'horizontal',
    );
    emit(state.copyWith(scrollDirection: event.direction));
  }

  Future<void> _onThemeMode(
      ThemeModeChanged event, Emitter<SettingsState> emit) async {
    await _prefs.setString(_PrefKeys.themeMode, _themeModeToString(event.mode));
    emit(state.copyWith(themeMode: event.mode));
  }


  ThemeMode _themeModeFromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _themeModeToString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}