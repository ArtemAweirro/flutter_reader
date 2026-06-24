import 'dart:io';

import 'package:xml/xml.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/chapter.dart';

@injectable
class Fb2DataSource {
  Future<ReaderBookEntity> openFb2(int bookId, String filePath) async {
    final file = File(filePath);
    final xmlString = await file.readAsString();

    final document = XmlDocument.parse(xmlString);

    final title = _parseTitle(document);
    final author = _parseAuthor(document);

    final chapters = _extractChapters(document);

    final fullText = chapters.map((c) => c.content).join('\n\n\n');

    return ReaderBookEntity(
      bookId: bookId,
      title: title,
      author: author,
      chapters: chapters,
      fullText: fullText,
    );
  }

  // ---------------------------
  // TITLE / AUTHOR
  // ---------------------------

  String _parseTitle(XmlDocument doc) {
    return doc
        .findAllElements('book-title')
        .map((e) => e.innerText.trim())
        .firstWhere(
          (t) => t.isNotEmpty,
          orElse: () => 'Без названия',
        );
  }

  String? _parseAuthor(XmlDocument doc) {
    final author = doc.findAllElements('author').firstOrNull;
    if (author == null) return null;

    final first = author.findAllElements('first-name').map((e) => e.innerText);
    final last = author.findAllElements('last-name').map((e) => e.innerText);

    final name = [...first, ...last].join(' ').trim();
    return name.isEmpty ? null : name;
  }

  // ---------------------------
  // CHAPTERS
  // ---------------------------

  List<ChapterEntity> _extractChapters(XmlDocument doc) {
    final result = <ChapterEntity>[];

    final bodies = doc.findAllElements('body');

    for (final body in bodies) {
      final sections = body.findElements('section');
      for (final section in sections) {
        _collectSections(section, result);
      }
    }

    return result;
  }

  void _collectSections(
    XmlElement section,
    List<ChapterEntity> result,
  ) {
    final title = _extractSectionTitle(section);

    final buffer = StringBuffer();

    _extractParagraphs(section, buffer);

    final content = buffer.toString().trim();

    if (content.isNotEmpty || title.isNotEmpty) {
      result.add(
        ChapterEntity(
          index: result.length,
          title: title.isEmpty ? 'Глава ${result.length + 1}' : title,
          content: content,
        ),
      );
    }

    // рекурсия по вложенным section
    for (final child in section.findElements('section')) {
      _collectSections(child, result);
    }
  }

  String _extractSectionTitle(XmlElement section) {
    final titleEl = section.findElements('title').firstOrNull;
    return titleEl?.innerText.trim() ?? '';
  }

  void _extractParagraphs(XmlElement section, StringBuffer buffer) {
    for (final p in section.findElements('p')) {
      final text = p.innerText.trim();
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }
  }
}