import 'package:injectable/injectable.dart';
import '../repositories/reader_repository.dart';

@injectable
class UpdateTotalCharactersUseCase {
  final ReaderRepository _repository;

  UpdateTotalCharactersUseCase(this._repository);

  Future<void> call(int bookId, int totalCharacters) =>
      _repository.updateTotalCharacters(bookId, totalCharacters);
}
