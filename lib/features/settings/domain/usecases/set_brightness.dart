import 'package:injectable/injectable.dart';
import '../repositories/settings_repository.dart';

@injectable
class SetBrightnessUseCase {
  final SettingsRepository _repository;
  SetBrightnessUseCase(this._repository);
  Future<void> call(double value) => _repository.setBrightness(value);
}
