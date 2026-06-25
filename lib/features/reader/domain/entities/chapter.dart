import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// ChapterEntity — одна глава книги (один HTML-файл внутри EPUB)
// ---------------------------------------------------------------------------

class ChapterEntity extends Equatable {
  /// Порядковый номер главы (0-based)
  final int index;
  final String title;

  /// Извлечённый plaintext содержимого главы
  final String content;

  const ChapterEntity({
    required this.index,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [index, title];
}
