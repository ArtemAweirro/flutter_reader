import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/books_dao.dart';
import '../../../../core/database/reader_dao.dart';

@injectable
class ReaderLocalDataSource {
  final BooksDao _booksDao;
  final ReaderDao _readerDao;

  ReaderLocalDataSource(this._booksDao, this._readerDao);

  // --- Position ---

  Future<String?> getSavedPositionString(int bookId) async {
    final book = await _booksDao.getBookById(bookId);
    return book?.readingPosition;
  }

  Future<void> savePositionString(int bookId, String position) =>
      _booksDao.updateReadingPosition(bookId, position);

  Future<void> updateTotalCharacters(int bookId, int totalCharacters) =>
      _booksDao.updateTotalCharacters(bookId, totalCharacters);

  // --- Bookmarks ---

  Stream<List<Bookmark>> watchBookmarks(int bookId) =>
      _readerDao.watchBookmarks(bookId);

  Future<int> insertBookmark({
    required int bookId,
    required String position,
    String? label,
  }) =>
      _readerDao.insertBookmark(BookmarksCompanion.insert(
        bookId: bookId,
        position: position,
        label: Value(label),
      ));

  Future<Bookmark?> getBookmarkById(int id) =>
      _readerDao.getBookmarkById(id);

  Future<void> deleteBookmark(int id) => _readerDao.deleteBookmark(id);
}