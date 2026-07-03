import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/chapter.dart';
import '../mappers/reader_book_mapper.dart';
 
class _EpubParseParams {
  final int bookId;
  final String filePath;
 
  const _EpubParseParams({required this.bookId, required this.filePath});
}
 
@injectable
class EpubDataSource {
  Future<ReaderBookEntity> openEpub(int bookId, String filePath) async {
    // Весь парсинг — в отдельном isolate, UI не блокируется
    return compute(
      _parseEpubInIsolate,
      _EpubParseParams(bookId: bookId, filePath: filePath),
    );
  }
}

Future<ReaderBookEntity> _parseEpubInIsolate(_EpubParseParams params) async {
  final file = File(params.filePath);
  final bytes = await file.readAsBytes();
  final epubBook = await EpubReader.readBook(bytes);
 
  final title = epubBook.Title ?? 'Без названия';
  final author = epubBook.Author;
  final chapters = _extractChapters(epubBook);

  return ReaderBookMapper.toEntity(
    bookId: params.bookId,
    title: title,
    author: author,
    chapters: chapters,
  );
}
 
List<ChapterEntity> _extractChapters(EpubBook book) {
  final chapters = <ChapterEntity>[];
  final epubChapters = book.Chapters;
  if (epubChapters == null || epubChapters.isEmpty) return chapters;
  _collectChapters(epubChapters, chapters);
  return chapters;
}
 
void _collectChapters(
    List<EpubChapter> epubChapters, List<ChapterEntity> result) {
  for (final chapter in epubChapters) {
    final html = chapter.HtmlContent ?? '';
    final plainText = _htmlToPlainText(html);
 
    if (plainText.trim().isNotEmpty) {
      result.add(ChapterEntity(
        index: result.length,
        title: chapter.Title ?? 'Глава ${result.length + 1}',
        content: plainText,
      ));
    }
 
    if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
      _collectChapters(chapter.SubChapters!, result);
    }
  }
}
 
String _htmlToPlainText(String html) {
  var text = html
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
 
  text = text
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'<p[^>]*>'), '\n')
      .replaceAll(RegExp(r'</p>'), '\n')
      .replaceAll(RegExp(r'<h[1-6][^>]*>'), '\n')
      .replaceAll(RegExp(r'</h[1-6]>'), '\n');
 
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
 
  text = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ');
 
  text = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n\n');
 
  return text;
}