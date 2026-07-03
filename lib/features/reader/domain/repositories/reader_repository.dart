import '../entities/bookmark.dart';
import '../entities/reader_book.dart';
import '../entities/reading_position.dart';

abstract interface class ReaderRepository {
  /// Открыть книгу и вернуть все главы.
  /// Тяжёлая операция — вызывается один раз при открытии читалки.
  Future<ReaderBookEntity> openBook(int bookId, String filePath);

  /// Загрузить сохранённую позицию чтения.
  /// Возвращает [ReadingPosition.start()] если позиция не сохранена.
  Future<ReadingPosition> getSavedPosition(int bookId);

  /// Сохранить текущую позицию чтения.
  Future<void> savePosition(int bookId, ReadingPosition position);

  /// Обновить суммарное количество символов
  Future<void> updateTotalCharacters(int bookId, int totalCharacters);

  /// Реактивный стрим закладок книги.
  Stream<List<BookmarkEntity>> watchBookmarks(int bookId);

  /// Добавить закладку на текущей позиции.
  Future<BookmarkEntity> addBookmark(
    int bookId,
    ReadingPosition position, {
    String? label,
  });

  /// Удалить закладку.
  Future<void> deleteBookmark(int bookmarkId);
}