import 'package:equatable/equatable.dart';
import 'chapter.dart';

// ---------------------------------------------------------------------------
// ReaderBookEntity — книга, открытая в читалке
// ---------------------------------------------------------------------------

class ReaderBookEntity extends Equatable {
  final int bookId;
  final String title;
  final String? author;

  /// Главы — используются в горизонтальном режиме (страница = глава)
  final List<ChapterEntity> chapters;

  /// Весь текст книги одной строкой — используется в вертикальном режиме
  final String fullText;

  int get totalChapters => chapters.length;

  const ReaderBookEntity({
    required this.bookId,
    required this.title,
    this.author,
    required this.chapters,
    required this.fullText,
  });

  @override
  List<Object?> get props => [bookId, title, author, chapters, fullText];
}
