import 'package:equatable/equatable.dart';
import 'chapter.dart';
import 'reader_item.dart';

// ---------------------------------------------------------------------------
// ReaderBookEntity — книга, открытая в читалке
// ---------------------------------------------------------------------------

class ReaderBookEntity extends Equatable {
  final int bookId;
  final String title;
  final String? author;

  /// Главы — используются во всех режимах
  final List<ChapterEntity> chapters;

  /// Плоский список элементов (абзацев и заголовков) для навигации
  final List<ReaderItem> items;

  int get totalChapters => chapters.length;
  int get totalItems => items.length;

  const ReaderBookEntity({
    required this.bookId,
    required this.title,
    this.author,
    required this.chapters,
    this.items = const [],
  });

  ReaderBookEntity copyWith({
    int? bookId,
    String? title,
    String? author,
    List<ChapterEntity>? chapters,
    List<ReaderItem>? items,
  }) {
    return ReaderBookEntity(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      chapters: chapters ?? this.chapters,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [bookId, title, author, chapters, items];
}
