import 'package:injectable/injectable.dart';
import '../repositories/settings_repository.dart';

@injectable
class SetFontSizeUseCase {
  final SettingsRepository _repository;
  SetFontSizeUseCase(this._repository);
  Future<void> call(double size) => _repository.setFontSize(size);
}
