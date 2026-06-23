import 'package:injectable/injectable.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/reader_repository.dart';
import '../datasources/epub_datasource.dart';
import '../datasources/reader_local_datasource.dart';
import '../mappers/bookmark_mapper.dart';

@Injectable(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final EpubDataSource _epubDataSource;
  final ReaderLocalDataSource _localDataSource;

  ReaderRepositoryImpl(this._epubDataSource, this._localDataSource);

  @override
  Future<ReaderBookEntity> openBook(int bookId, String filePath) {
    // В будущем здесь будет switch по формату (epub/fb2/pdf)
    return _epubDataSource.openEpub(bookId, filePath);
  }

  @override
  Future<ReadingPosition> getSavedPosition(int bookId) async {
    final saved = await _localDataSource.getSavedPositionString(bookId);
    if (saved == null || saved.isEmpty) return ReadingPosition.start();
    return ReadingPosition.fromStorageString(saved);
  }

  @override
  Future<void> savePosition(int bookId, ReadingPosition position) =>
      _localDataSource.savePositionString(
        bookId,
        position.toStorageString(),
      );

  @override
  Stream<List<BookmarkEntity>> watchBookmarks(int bookId) =>
      _localDataSource.watchBookmarks(bookId).map(
            (list) => list.map((b) => b.toEntity()).toList(),
          );

  @override
  Future<BookmarkEntity> addBookmark(
    int bookId,
    ReadingPosition position, {
    String? label,
  }) async {
    final id = await _localDataSource.insertBookmark(
      bookId: bookId,
      position: position.toStorageString(),
      label: label,
    );

    return BookmarkEntity(
      id: id,
      bookId: bookId,
      chapterIndex: position.chapterIndex,
      scrollOffset: position.scrollOffset,
      label: label,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteBookmark(int bookmarkId) =>
      _localDataSource.deleteBookmark(bookmarkId);
}