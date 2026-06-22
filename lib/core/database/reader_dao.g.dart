// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_dao.dart';

// ignore_for_file: type=lint
mixin _$ReaderDaoMixin on DatabaseAccessor<AppDatabase> {
  $BooksTable get books => attachedDatabase.books;
  $BookmarksTable get bookmarks => attachedDatabase.bookmarks;
  $CommentsTable get comments => attachedDatabase.comments;
  ReaderDaoManager get managers => ReaderDaoManager(this);
}

class ReaderDaoManager {
  final _$ReaderDaoMixin _db;
  ReaderDaoManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db.attachedDatabase, _db.books);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db.attachedDatabase, _db.bookmarks);
  $$CommentsTableTableManager get comments =>
      $$CommentsTableTableManager(_db.attachedDatabase, _db.comments);
}
