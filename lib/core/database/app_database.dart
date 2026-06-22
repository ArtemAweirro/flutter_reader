import 'dart:io';
 
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Таблица книг
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(max: 512)();
  TextColumn get author => text().withLength(max: 256).nullable()();
 
  /// Абсолютный путь к файлу книги на устройстве
  TextColumn get filePath => text()();
 
  /// 'epub' | 'fb2' | 'pdf'
  TextColumn get format => text().withLength(max: 8)();
 
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
 
  /// Текущая позиция (номер страницы или CFI для epub)
  TextColumn get readingPosition => text().nullable()();
 
  /// Общее количество страниц (может быть null до первого открытия)
  IntColumn get totalPages => integer().nullable()();
 
  /// Порядок в списке (для drag-and-drop)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
 
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Таблица закладок
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id)();
 
  /// Номер страницы (для PDF/FB2) или CFI (для EPUB)
  TextColumn get position => text()();
 
  /// Опциональное название закладки
  TextColumn get label => text().withLength(max: 256).nullable()();
 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Таблица комментариев на полях (опционально)
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id)();
 
  /// Страница или CFI
  TextColumn get position => text()();
 
  TextColumn get comment => text()();
 
  /// Смещение внутри страницы (для отображения на полях)
  RealColumn get offsetY => real().nullable()();
 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}



@DriftDatabase(tables: [Books, Bookmarks, Comments])
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
 
  int get schemaVersion => 1;
 
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Будущие миграции добавляются здесь по схеме:
          // if (from < 2) { await m.addColumn(books, books.someNewColumn); }
        },
      );
}



LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'reader.db'));
    return NativeDatabase.createInBackground(file);
  });
}