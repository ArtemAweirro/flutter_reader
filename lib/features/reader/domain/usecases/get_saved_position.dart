import 'package:injectable/injectable.dart';

import '../repositories/reader_repository.dart';
import '../entities/reading_position.dart';

@injectable
class GetSavedPositionUseCase {
  final ReaderRepository _repository;
  GetSavedPositionUseCase(this._repository);

  Future<ReadingPosition> call(int bookId) =>
      _repository.getSavedPosition(bookId);
}
