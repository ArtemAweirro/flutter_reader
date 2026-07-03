import '../../../../core/database/app_database.dart';
import '../../domain/entities/bookmark.dart';

extension BookmarkMapper on Bookmark {
  BookmarkEntity toEntity() {
    return BookmarkEntity(
      id: id,
      bookId: bookId,
      charOffset: int.tryParse(position) ?? 0,
      label: label,
      createdAt: createdAt,
    );
  }
}
