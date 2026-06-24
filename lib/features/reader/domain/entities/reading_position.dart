import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// ReadingPosition — позиция чтения внутри книги
// 
// Хранит два независимых значения:
//   - chapterIndex + scrollOffset → горизонтальный режим (страница = глава)
//   - verticalOffset              → вертикальный режим (смещение в fullText)
//
// Формат в БД: "chapterIndex:scrollOffset:verticalOffset"
// ---------------------------------------------------------------------------

class ReadingPosition extends Equatable {
  /// Индекс текущей главы (горизонтальный режим)
  final int chapterIndex;

  /// Смещение скролла внутри главы (0.0 — начало, 1.0 — конец) (горизонтальный режим)
  final double scrollOffset;

  /// Смещение скролла 0.0–1.0 по всему тексту (вертикальный режим)
  final double verticalOffset;

  const ReadingPosition({
    this.chapterIndex = 0,
    this.scrollOffset = 0.0,
    this.verticalOffset = 0.0,
  });

  ReadingPosition copyWith({
    int? chapterIndex,
    double? scrollOffset,
    double? verticalOffset,
  }) {
    return ReadingPosition(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
    );
  }

  String toStorageString() =>
      '$chapterIndex:$scrollOffset:$verticalOffset';

  factory ReadingPosition.fromStorageString(String s) {
    final parts = s.split(':');
    return ReadingPosition(
      chapterIndex: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      scrollOffset: double.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0.0,
      verticalOffset: double.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0.0,
    );
  }

  factory ReadingPosition.start() => const ReadingPosition();

  @override
  List<Object?> get props => [chapterIndex, scrollOffset, verticalOffset];
}
