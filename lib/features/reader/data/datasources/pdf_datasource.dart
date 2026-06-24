import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/chapter.dart';

@injectable
class PdfDataSource {
  Future<ReaderBookEntity> openPdf({
    required int bookId,
    required String filePath,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    final title = document.documentInformation.title;
    final author = document.documentInformation.author;

    final chapters = _extractChapters(document);

    final fullText = chapters.map((e) => e.content).join('\n\n\n');

    document.dispose();

    return ReaderBookEntity(
      bookId: bookId,
      title: title,
      author: author,
      chapters: chapters,
      fullText: fullText,
    );
  }

  List<ChapterEntity> _extractChapters(PdfDocument doc) {
    final chapters = <ChapterEntity>[];

    const pagesPerChapter = 5;
    int index = 0;

    for (int i = 0; i < doc.pages.count; i += pagesPerChapter) {
      final end = (i + pagesPerChapter > doc.pages.count)
          ? doc.pages.count
          : i + pagesPerChapter;

      final buffer = StringBuffer();

      for (int p = i; p < end; p++) {
        final extractor = PdfTextExtractor(doc);

        final text = extractor.extractText(startPageIndex: p, endPageIndex: p);

        if (text.isNotEmpty) {
          buffer.writeln(text);
        }
      }

      final content = buffer.toString().trim();

      if (content.isNotEmpty) {
        chapters.add(
          ChapterEntity(
            index: index++,
            title: 'Стр. ${i + 1}–$end',
            content: content,
          ),
        );
      }
    }

    return chapters;
  }
}