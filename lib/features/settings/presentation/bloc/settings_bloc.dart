import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/set_font_size.dart';
import '../../domain/usecases/set_brightness.dart';
import '../../domain/usecases/set_contrast.dart';
import '../../domain/usecases/set_scroll_direction.dart';
import '../../domain/usecases/set_theme_mode.dart';

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
  final GetSettingsUseCase _getSettings;
  final SetFontSizeUseCase _setFontSize;
  final SetBrightnessUseCase _setBrightness;
  final SetContrastUseCase _setContrast;
  final SetScrollDirectionUseCase _setScrollDirection;
  final SetThemeModeUseCase _setThemeMode;

  SettingsBloc(
    this._getSettings,
    this._setFontSize,
    this._setBrightness,
    this._setContrast,
    this._setScrollDirection,
    this._setThemeMode,
  ) : super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<FontSizeChanged>(_onFontSize);
    on<BrightnessChanged>(_onBrightness);
    on<ContrastChanged>(_onContrast);
    on<ScrollDirectionChanged>(_onScrollDirection);
    on<ThemeModeChanged>(_onThemeMode);
  }

  void _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) {
    final data = _getSettings();
    emit(SettingsState(
      fontSize: data.fontSize,
      brightness: data.brightness,
      contrast: data.contrast,
      scrollDirection: data.scrollDirection,
      themeMode: data.themeMode,
    ));
    // Применяем сохраненную яркость при загрузке
    _setBrightness(data.brightness);
  }

  Future<void> _onFontSize(
      FontSizeChanged event, Emitter<SettingsState> emit) async {
    await _setFontSize(event.value);
    emit(state.copyWith(fontSize: event.value));
  }

  Future<void> _onBrightness(
      BrightnessChanged event, Emitter<SettingsState> emit) async {
    await _setBrightness(event.value);
    emit(state.copyWith(brightness: event.value));
  }

  Future<void> _onContrast(
      ContrastChanged event, Emitter<SettingsState> emit) async {
    await _setContrast(event.value);
    emit(state.copyWith(contrast: event.value));
  }

  Future<void> _onScrollDirection(
      ScrollDirectionChanged event, Emitter<SettingsState> emit) async {
    await _setScrollDirection(event.direction);
    emit(state.copyWith(scrollDirection: event.direction));
  }

  Future<void> _onThemeMode(
      ThemeModeChanged event, Emitter<SettingsState> emit) async {
    await _setThemeMode(event.mode);
    emit(state.copyWith(themeMode: event.mode));
  }
}
