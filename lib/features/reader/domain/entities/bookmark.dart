import 'package:equatable/equatable.dart';
import 'reading_position.dart';

class BookmarkEntity extends Equatable {
  final int id;
  final int bookId;
  final int charOffset;
  final String? label;
  final DateTime createdAt;

  const BookmarkEntity({
    required this.id,
    required this.bookId,
    required this.charOffset,
    this.label,
    required this.createdAt,
  });

  ReadingPosition get position => ReadingPosition(charOffset: charOffset);

  @override
  List<Object?> get props => [id, bookId, charOffset, label, createdAt];
}
