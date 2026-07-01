import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/data/datasources/book_picker_service.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddBookFromFile {
  final BookRepository repository;
  final BookPickerService pickerService;

  AddBookFromFile(this.repository, this.pickerService);

  Future<Either<Failure, int>> call() async {
    // Открываем файловый менеджер и получаем метаданные
    final metadataResult = await pickerService.pickAndParseBook();

    return metadataResult.fold(
      (failure) => Left(failure),
      (metadata) async {
        if (metadata == null) return Left(const CancelledFailure());

        // Создаем объект книги
        final book = Book(
          id: 0, // будет заменен БД на автоинкремент
          title: metadata.title,
          author: metadata.author,
          filePath: metadata.filePath,
          format: metadata.format,
          isFavorite: false,
          isRead: false,
          readingPosition: null,
          totalCharacters: null,
          sortOrder: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          addedAt: DateTime.now(),
        );

        // Добавляем в репозиторий
        return repository.addBook(book);
      },
    );
  }
}
