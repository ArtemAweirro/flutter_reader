import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/chapter.dart';

@injectable
class EpubDataSource {
  /// Открывает EPUB-файл и возвращает список глав с plaintext содержимым.
  Future<ReaderBookEntity> openEpub(int bookId, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);
 
    final title = epubBook.Title ?? 'Без названия';
    final author = epubBook.Author;
 
    final chapters = _extractChapters(epubBook);
 
    return ReaderBookEntity(
      bookId: bookId,
      title: title,
      author: author,
      chapters: chapters,
    );
  }
 
  List<ChapterEntity> _extractChapters(EpubBook book) {
    final chapters = <ChapterEntity>[];
    final epubChapters = book.Chapters;
 
    if (epubChapters == null || epubChapters.isEmpty) {
      return chapters;
    }
 
    // Рекурсивно обходим главы и подглавы
    _collectChapters(epubChapters, chapters);
 
    return chapters;
  }
 
  void _collectChapters(
      List<EpubChapter> epubChapters, List<ChapterEntity> result) {
    for (final chapter in epubChapters) {
      final html = chapter.HtmlContent ?? '';
      final plainText = _htmlToPlainText(html);
 
      // Пропускаем пустые главы (обложка, nav и т.д.)
      if (plainText.trim().isNotEmpty) {
        result.add(ChapterEntity(
          index: result.length,
          title: chapter.Title ?? 'Глава ${result.length + 1}',
          content: plainText,
        ));
      }
 
      // Рекурсивно добавляем подглавы
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        _collectChapters(chapter.SubChapters!, result);
      }
    }
  }
 
  /// Простое извлечение текста из HTML без внешних зависимостей.
  /// Убираем теги, декодируем базовые HTML-сущности.
  String _htmlToPlainText(String html) {
    // Убираем теги <script> и <style> вместе с содержимым
    var text = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
 
    // Заменяем блочные теги на переносы строк
    text = text
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<h[1-6][^>]*>'), '\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n');
 
    // Убираем все оставшиеся теги
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
 
    // Декодируем базовые HTML-сущности
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ');
 
    // Убираем лишние пробелы и пустые строки
    text = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n');
 
    return text;
  }
}