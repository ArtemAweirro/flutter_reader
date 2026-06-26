import 'package:equatable/equatable.dart';
import 'chapter.dart';

// ---------------------------------------------------------------------------
// ReaderBookEntity — книга, открытая в читалке
// ---------------------------------------------------------------------------

class ReaderBookEntity extends Equatable {
  final int bookId;
  final String title;
  final String? author;

  /// Главы — используются во всех режимах
  final List<ChapterEntity> chapters;

  int get totalChapters => chapters.length;

  const ReaderBookEntity({
    required this.bookId,
    required this.title,
    this.author,
    required this.chapters,
  });

  @override
  List<Object?> get props => [bookId, title, author];
}
