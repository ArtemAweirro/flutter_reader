import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../repositories/settings_repository.dart';

@injectable
class SetScrollDirectionUseCase {
  final SettingsRepository _repository;
  SetScrollDirectionUseCase(this._repository);
  Future<void> call(Axis direction) => _repository.setScrollDirection(direction);
}
