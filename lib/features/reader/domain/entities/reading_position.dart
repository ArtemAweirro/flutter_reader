import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// ReadingPosition — позиция чтения внутри книги
// ---------------------------------------------------------------------------

class ReadingPosition extends Equatable {
  /// Индекс текущей главы
  final int chapterIndex;

  /// Смещение скролла внутри главы (0.0 — начало, 1.0 — конец)
  final double scrollOffset;

  const ReadingPosition({
    required this.chapterIndex,
    this.scrollOffset = 0.0,
  });

  /// Сериализация для хранения в БД: "chapterIndex:scrollOffset"
  String toStorageString() => '$chapterIndex:$scrollOffset';

  factory ReadingPosition.fromStorageString(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return const ReadingPosition(chapterIndex: 0);
    return ReadingPosition(
      chapterIndex: int.tryParse(parts[0]) ?? 0,
      scrollOffset: double.tryParse(parts[1]) ?? 0.0,
    );
  }

  factory ReadingPosition.start() => const ReadingPosition(chapterIndex: 0);

  @override
  List<Object?> get props => [chapterIndex, scrollOffset];
}
