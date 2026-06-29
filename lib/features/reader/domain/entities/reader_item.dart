import 'package:equatable/equatable.dart';

/// Элемент списка для отображения в читалке.
/// Может быть либо заголовком главы, либо абзацем текста.
class ReaderItem extends Equatable {
  final int chapterIndex;
  final int? paragraphIndex;
  final String text;
  final bool isHeader;
  final int charOffset;

  const ReaderItem({
    required this.chapterIndex,
    this.paragraphIndex,
    required this.text,
    this.isHeader = false,
    required this.charOffset,
  });

  @override
  List<Object?> get props => [
        chapterIndex,
        paragraphIndex,
        text,
        isHeader,
        charOffset,
      ];
}
