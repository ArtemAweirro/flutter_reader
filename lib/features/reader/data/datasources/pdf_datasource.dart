import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/chapter.dart';
import '../mappers/reader_book_mapper.dart';

class _PdfParseParams {
  final int bookId;
  final String filePath;

  const _PdfParseParams({required this.bookId, required this.filePath});
}

@injectable
class PdfDataSource {
  Future<ReaderBookEntity> openPdf(int bookId, String filePath) async {
    // Весь парсинг — в отдельном isolate, UI не блокируется
    return compute(
      _parsePdfInIsolate,
      _PdfParseParams(bookId: bookId, filePath: filePath),
    );
  }
}

Future<ReaderBookEntity> _parsePdfInIsolate(_PdfParseParams params) async {
  final bytes = await File(params.filePath).readAsBytes();
  final document = PdfDocument(inputBytes: bytes);

  final title = document.documentInformation.title;
  final author = document.documentInformation.author;

  final chapters = _extractChapters(document);

  document.dispose();

  return ReaderBookMapper.toEntity(
    bookId: params.bookId,
    title: title,
    author: author,
    chapters: chapters,
  );
}

List<ChapterEntity> _extractChapters(PdfDocument doc) {
  final chapters = <ChapterEntity>[];

  const pagesPerChapter = 5;
  int index = 0;

  final extractor = PdfTextExtractor(doc);

  for (int i = 0; i < doc.pages.count; i += pagesPerChapter) {
    final end = (i + pagesPerChapter > doc.pages.count)
        ? doc.pages.count
        : i + pagesPerChapter;

    final buffer = StringBuffer();

    for (int p = i; p < end; p++) {
      final text = extractor.extractText(startPageIndex: p, endPageIndex: p);

      final cleaned = _normalizePdfText(text);

      if (cleaned.isNotEmpty) {
        buffer.writeln(cleaned);
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

String _normalizePdfText(String text) {
  var result = text;

  // 1. нормализация переносов
  result = result.replaceAll('\r', '\n');

  // 2. склейка переносов слов (hyphenation)
  result = result.replaceAll(RegExp(r'-\n'), '');

  // 3. убираем одиночные переносы внутри предложений
  result = _fixLineBreaks(result);

  // 4. чистим лишние пробелы
  result = result.replaceAll(RegExp(r'[ \t]+'), ' ');

  // 5. нормализуем множественные переносы
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return result.trim();
}

String _fixLineBreaks(String text) {
  final lines = text.split('\n');
  final buffer = StringBuffer();

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final isLast = i == lines.length - 1;
    final next = isLast ? '' : lines[i + 1].trim();

    // не ломаем диалоги и предложения
    final endsWithSentenceBreak =
        line.endsWith('.') ||
        line.endsWith('!') ||
        line.endsWith('?') ||
        line.endsWith('—') ||
        line.endsWith(':');

    final shouldJoin = !endsWithSentenceBreak && next.isNotEmpty;

    if (shouldJoin) {
      buffer.write('$line ');
    } else {
      buffer.writeln(line);
    }
  }

  return buffer.toString();
}
