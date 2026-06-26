import '../../../../core/database/app_database.dart';
import '../../domain/entities/bookmark.dart';

extension BookmarkMapper on Bookmark {
  BookmarkEntity toEntity() {
    final parts = position.split(':');
    final charOffset = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;

    return BookmarkEntity(
      id: id,
      bookId: bookId,
      charOffset: charOffset,
      label: label,
      createdAt: createdAt,
    );
  }
}
