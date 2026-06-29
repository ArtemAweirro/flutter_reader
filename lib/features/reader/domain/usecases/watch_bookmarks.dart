import 'package:injectable/injectable.dart';

import '../repositories/reader_repository.dart';
import '../entities/bookmark.dart';

@injectable
class WatchBookmarksUseCase {
  final ReaderRepository _repository;
  WatchBookmarksUseCase(this._repository);

  Stream<List<BookmarkEntity>> call(int bookId) =>
      _repository.watchBookmarks(bookId);
}