import 'package:file_picker/file_picker.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

abstract class BookMetadata {
  final String filePath;
  final String format;
  final String title;
  final String? author;

  BookMetadata({
    required this.filePath,
    required this.format,
    required this.title,
    this.author,
  });
}

@injectable
class BookPickerService {
  Future<Either<Failure, BookMetadata?>> pickAndParseBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'fb2', 'pdf'],
        withData: false,
      );

      if (result == null) {
        return const Left(CancelledFailure());
      }

      final file = result.files.single;
      final filePath = file.path;

      if (filePath == null) {
        return Left(FileFailure());
      }

      final extension = file.extension?.toLowerCase();
      if (extension == null || !['epub', 'fb2', 'pdf'].contains(extension)) {
        return Left(FileFailure());
      }

      // Извлекаем метаданные в зависимости от формата
      final metadata = await _parseMetadata(filePath, extension);

      return Right(metadata);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Парсит метаданные из файла на основе его формата
  Future<BookMetadata> _parseMetadata(
    String filePath,
    String format,
  ) async {
    try {
      switch (format) {
        case 'epub':
          return _parseEpubMetadata(filePath);
        case 'fb2':
          return _parseFb2Metadata(filePath);
        case 'pdf':
          return _parsePdfMetadata(filePath);
        default:
          return _defaultMetadata(filePath, format);
      }
    } catch (e) {
      return _defaultMetadata(filePath, format);
    }
  }

  /// EPUB парсинг (простой вариант)
  Future<BookMetadata> _parseEpubMetadata(String filePath) async {
    // TODO: Реализовать полный EPUB парсинг с использованием epubx пакета
    // Пока возвращаем простое имя файла
    return _defaultMetadata(filePath, 'epub');
  }

  /// FB2 парсинг
  Future<BookMetadata> _parseFb2Metadata(String filePath) async {
    // TODO: Реализовать FB2 парсинг (XML)
    return _defaultMetadata(filePath, 'fb2');
  }

  /// PDF парсинг
  Future<BookMetadata> _parsePdfMetadata(String filePath) async {
    // TODO: Реализовать PDF метаданные извлечение
    return _defaultMetadata(filePath, 'pdf');
  }

  /// Возвращает метаданные по умолчанию (только имя файла)
  BookMetadata _defaultMetadata(String filePath, String format) {
    // Извлекаем имя файла без расширения
    final fileName = filePath.split('/').last;
    final title = fileName.replaceAll(RegExp(r'\.(epub|fb2|pdf)$'), '');

    return _SimpleBookMetadata(
      filePath: filePath,
      format: format,
      title: title.isEmpty ? 'Unknown' : title,
      author: null,
    );
  }
}

class _SimpleBookMetadata extends BookMetadata {
  _SimpleBookMetadata({
    required super.filePath,
    required super.format,
    required super.title,
    super.author,
  });
}
