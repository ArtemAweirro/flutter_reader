import '../../domain/entities/chapter.dart';
import '../../domain/entities/reader_book.dart';
import '../../domain/entities/reader_item.dart';

class ReaderBookMapper {
  static const int defaultMaxBlockLength = 900;

  static ReaderBookEntity toEntity({
    required int bookId,
    required String title,
    String? author,
    required List<ChapterEntity> chapters,
    int maxBlockLength = defaultMaxBlockLength,
  }) {
    final List<ReaderItem> items = [];
    int totalCharOffset = 0;

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];

      // 1. Добавляем заголовок главы как отдельный элемент
      if (chapter.title.isNotEmpty) {
        items.add(ReaderItem(
          chapterIndex: i,
          text: chapter.title,
          isHeader: true,
          charOffset: totalCharOffset,
        ));
      }

      final paragraphs = chapter.content.split('\n');
      int chapterCharOffset = 0;

      StringBuffer currentBlock = StringBuffer();
      int? blockStartParagraphIndex;
      int blockStartCharOffset = 0;

      for (int j = 0; j < paragraphs.length; j++) {
        final rawParagraph = paragraphs[j];
        final pText = rawParagraph.trim();

        if (pText.isNotEmpty) {
          if (currentBlock.isEmpty) {
            blockStartParagraphIndex = j;
            blockStartCharOffset = chapterCharOffset;
          } else {
            currentBlock.write('\n\n');
          }
          currentBlock.write(pText);
        }

        // Увеличиваем смещение внутри главы
        chapterCharOffset += rawParagraph.length;
        if (j < paragraphs.length - 1) {
          chapterCharOffset += 1; // Учитываем символ переноса строки \n
        }

        // Если блок набрал достаточно символов или это последний абзац главы
        final isLastParagraph = j == paragraphs.length - 1;
        if (currentBlock.isNotEmpty &&
            (currentBlock.length > maxBlockLength || isLastParagraph)) {
          items.add(ReaderItem(
            chapterIndex: i,
            paragraphIndex: blockStartParagraphIndex,
            text: currentBlock.toString(),
            charOffset: totalCharOffset + blockStartCharOffset,
          ));
          currentBlock.clear();
        }
      }
      
      // Используем фактическую длину контента главы для точности смещения следующей главы
      totalCharOffset += chapter.content.length;
    }

    return ReaderBookEntity(
      bookId: bookId,
      title: title,
      author: author,
      chapters: chapters,
      items: List.unmodifiable(items),
      totalCharacters: totalCharOffset,
    );
  }
}
