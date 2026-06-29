import 'package:injectable/injectable.dart';

import '../repositories/reader_repository.dart';
import '../entities/bookmark.dart';
import '../entities/reading_position.dart';

@injectable
class AddBookmarkUseCase {
  final ReaderRepository _repository;
  AddBookmarkUseCase(this._repository);

  Future<BookmarkEntity> call(
    int bookId,
    ReadingPosition position, {
    String? label,
  }) =>
      _repository.addBookmark(bookId, position, label: label);
}