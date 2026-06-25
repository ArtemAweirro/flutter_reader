import 'package:flutter_reader/features/reader/data/datasources/pdf_datasource.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/reader_repository.dart';
import '../datasources/epub_datasource.dart';
import '../datasources/reader_local_datasource.dart';
import '../datasources/fb2_datasource.dart';
import '../mappers/bookmark_mapper.dart';
import 'book_format_detector.dart';

@Injectable(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final EpubDataSource _epubDataSource;
  final Fb2DataSource _fb2DataSource;
  final PdfDataSource _pdfDataSource;
  final ReaderLocalDataSource _localDataSource;
  final BookFormatDetector _formatDetector;

  ReaderRepositoryImpl(
    this._epubDataSource,
    this._fb2DataSource,
    this._pdfDataSource,
    this._localDataSource,
    this._formatDetector,
  );

  @override
  Future<ReaderBookEntity> openBook(int bookId, String filePath) async {
    final format = _formatDetector.detect(filePath);
    switch (format) {
      case BookFormat.epub:
        return _epubDataSource.openEpub(bookId, filePath);

      case BookFormat.fb2:
        return _fb2DataSource.openFb2(bookId, filePath);

      case BookFormat.pdf:
        return _pdfDataSource.openPdf(bookId, filePath);

      case BookFormat.unknown:
        throw UnsupportedError('Unsupported book format: $filePath');
    }
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