import 'package:injectable/injectable.dart';

import '../repositories/reader_repository.dart';
import '../entities/reading_position.dart';

@injectable
class SavePositionUseCase {
  final ReaderRepository _repository;
  SavePositionUseCase(this._repository);

  Future<void> call(int bookId, ReadingPosition position) =>
      _repository.savePosition(bookId, position);
}