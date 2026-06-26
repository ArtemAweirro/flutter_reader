import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'app_database.dart';

part 'reader_dao.g.dart';

@DriftAccessor(tables: [Bookmarks, Comments])
@injectable
class ReaderDao extends DatabaseAccessor<AppDatabase> with _$ReaderDaoMixin {
  ReaderDao(super.db);

  // Bookmarks

  Stream<List<Bookmark>> watchBookmarks(int bookId) => (select(bookmarks)
        ..where((b) => b.bookId.equals(bookId))
        ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
      .watch();

  Future<int> insertBookmark(BookmarksCompanion entry) =>
      into(bookmarks).insert(entry);

  Future<Bookmark?> getBookmarkById(int id) =>
      (select(bookmarks)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<int> deleteBookmark(int id) =>
      (delete(bookmarks)..where((b) => b.id.equals(id))).go();

  Future<void> deleteAllBookmarksForBook(int bookId) =>
      (delete(bookmarks)..where((b) => b.bookId.equals(bookId))).go();

  // Comments
  
  Stream<List<Comment>> watchComments(int bookId) => (select(comments)
        ..where((c) => c.bookId.equals(bookId))
        ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
      .watch();

  Future<int> insertComment(CommentsCompanion entry) =>
      into(comments).insert(entry);

  Future<bool> updateComment(CommentsCompanion entry) =>
      update(comments).replace(entry);

  Future<int> deleteComment(int id) =>
      (delete(comments)..where((c) => c.id.equals(id))).go();

  Future<void> deleteAllCommentsForBook(int bookId) =>
      (delete(comments)..where((c) => c.bookId.equals(bookId))).go();
}