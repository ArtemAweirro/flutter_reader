import 'package:equatable/equatable.dart';
import 'chapter.dart';
import 'reader_item.dart';

// ---------------------------------------------------------------------------
// ReaderBookEntity — книга, открытая в читалке
// ---------------------------------------------------------------------------

class ReaderBookEntity extends Equatable {
  final int bookId;
  final String title;
  final String? author;

  /// Главы — используются во всех режимах
  final List<ChapterEntity> chapters;

  /// Плоский список элементов (абзацев и заголовков) для навигации
  final List<ReaderItem> items;

  int get totalChapters => chapters.length;
  int get totalItems => items.length;

  const ReaderBookEntity({
    required this.bookId,
    required this.title,
    this.author,
    required this.chapters,
    this.items = const [],
  });

  factory ReaderBookEntity.create({
    required int bookId,
    required String title,
    String? author,
    required List<ChapterEntity> chapters,
  }) {
    final List<ReaderItem> items = [];
    int totalCharOffset = 0;

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];

      // Добавляем заголовок главы как отдельный элемент
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
        final pText = paragraphs[j].trim();
        
        if (pText.isNotEmpty) {
          if (currentBlock.isEmpty) {
            blockStartParagraphIndex = j;
            blockStartCharOffset = chapterCharOffset;
          } else {
            currentBlock.write('\n\n');
          }
          currentBlock.write(pText);
        }

        // Увеличиваем смещение внутри главы (учитываем удаленный '\n')
        chapterCharOffset += paragraphs[j].length + 1;

        // Если блок набрал достаточно символов или это последний абзац главы
        if (currentBlock.isNotEmpty && 
            (currentBlock.length > 900 || j == paragraphs.length - 1)) {
          items.add(ReaderItem(
            chapterIndex: i,
            paragraphIndex: blockStartParagraphIndex,
            text: currentBlock.toString(),
            charOffset: totalCharOffset + blockStartCharOffset,
          ));
          currentBlock.clear();
        }
      }
      totalCharOffset += chapter.content.length;
    }

    return ReaderBookEntity(
      bookId: bookId,
      title: title,
      author: author,
      chapters: chapters,
      items: items,
    );
  }

  @override
  List<Object?> get props => [bookId, title, author, chapters, items];
}
