import 'package:equatable/equatable.dart';
import 'reading_position.dart';

// ---------------------------------------------------------------------------
// BookmarkEntity — закладка
// ---------------------------------------------------------------------------

class BookmarkEntity extends Equatable {
  final int id;
  final int bookId;
  final int chapterIndex;
  final double scrollOffset;
  final String? label;
  final DateTime createdAt;

  const BookmarkEntity({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.scrollOffset,
    this.label,
    required this.createdAt,
  });

  /// Позиция закладки
  ReadingPosition get position => ReadingPosition(
        chapterIndex: chapterIndex,
        scrollOffset: scrollOffset,
      );

  @override
  List<Object?> get props =>
      [id, bookId, chapterIndex, scrollOffset, label, createdAt];
}