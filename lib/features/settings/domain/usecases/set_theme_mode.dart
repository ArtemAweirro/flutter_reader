import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../repositories/settings_repository.dart';

@injectable
class SetThemeModeUseCase {
  final SettingsRepository _repository;
  SetThemeModeUseCase(this._repository);
  Future<void> call(ThemeMode mode) => _repository.setThemeMode(mode);
}
