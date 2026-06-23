import '../../../../core/database/app_database.dart';
import '../../domain/entities/bookmark.dart';

extension BookmarkMapper on Bookmark {
  BookmarkEntity toEntity() {
    final parts = position.split(':');
    final chapterIndex = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final scrollOffset =
        double.tryParse(parts.length > 1 ? parts[1] : '0.0') ?? 0.0;

    return BookmarkEntity(
      id: id,
      bookId: bookId,
      chapterIndex: chapterIndex,
      scrollOffset: scrollOffset,
      label: label,
      createdAt: createdAt,
    );
  }
}