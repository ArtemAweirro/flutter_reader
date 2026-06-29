import 'package:injectable/injectable.dart';
import '../repositories/settings_repository.dart';
import '../entities/settings_data.dart';

@injectable
class GetSettingsUseCase {
  final SettingsRepository _repository;
  GetSettingsUseCase(this._repository);

  SettingsData call() {
    return SettingsData(
      fontSize: _repository.getFontSize(),
      brightness: _repository.getBrightness(),
      contrast: _repository.getContrast(),
      scrollDirection: _repository.getScrollDirection(),
      themeMode: _repository.getThemeMode(),
    );
  }
}
