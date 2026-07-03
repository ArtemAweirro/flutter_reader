import 'package:injectable/injectable.dart';
import '../repositories/settings_repository.dart';

@injectable
class SetContrastUseCase {
  final SettingsRepository _repository;
  SetContrastUseCase(this._repository);
  Future<void> call(double value) => _repository.setContrast(value);
}
