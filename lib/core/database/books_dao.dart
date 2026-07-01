import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'app_database.dart';

part 'books_dao.g.dart';

@DriftAccessor(tables: [Books])
@injectable
class BooksDao extends DatabaseAccessor<AppDatabase> with _$BooksDaoMixin {
  BooksDao(super.db);

  // Queries

  /// Реактивный стрим всех книг, отсортированных по полю sortOrder
  Stream<List<Book>> watchAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.asc(b.sortOrder)])).watch();

  /// Только любимые
  Stream<List<Book>> watchFavoriteBooks() => (select(books)
        ..where((b) => b.isFavorite.equals(true))
        ..orderBy([(b) => OrderingTerm.asc(b.sortOrder)]))
      .watch();

  /// Только прочитанные
  Stream<List<Book>> watchReadBooks() => (select(books)
        ..where((b) => b.isRead.equals(true))
        ..orderBy([(b) => OrderingTerm.asc(b.sortOrder)]))
      .watch();

  Future<Book?> getBookById(int id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();


  // Mutations

  Future<int> insertBook(BooksCompanion entry) => into(books).insert(entry);

  Future<bool> updateBook(BooksCompanion entry) => update(books).replace(entry);

  Future<void> updateFavorite(int id, bool value) =>
      (update(books)..where((b) => b.id.equals(id)))
          .write(BooksCompanion(isFavorite: Value(value)));

  Future<void> updateIsRead(int id, bool value) =>
      (update(books)..where((b) => b.id.equals(id)))
          .write(BooksCompanion(isRead: Value(value)));

  Future<void> updateReadingPosition(int id, String position) =>
      (update(books)..where((b) => b.id.equals(id)))
          .write(BooksCompanion(readingPosition: Value(position)));

  Future<void> updateTotalCharacters(int id, int total) =>
      (update(books)..where((b) => b.id.equals(id)))
          .write(BooksCompanion(totalCharacters: Value(total)));

  Future<void> updateSortOrder(int id, int order) =>
      (update(books)..where((b) => b.id.equals(id)))
          .write(BooksCompanion(sortOrder: Value(order)));

  Future<int> deleteBook(int id) =>
      (delete(books)..where((b) => b.id.equals(id))).go();
}