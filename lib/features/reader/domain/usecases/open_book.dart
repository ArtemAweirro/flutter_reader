import 'package:injectable/injectable.dart';

import '../entities/reader_book.dart';
import '../repositories/reader_repository.dart';

@injectable
class OpenBookUseCase {
  final ReaderRepository _repository;
  OpenBookUseCase(this._repository);

  Future<ReaderBookEntity> call(int bookId, String filePath) =>
      _repository.openBook(bookId, filePath);
}