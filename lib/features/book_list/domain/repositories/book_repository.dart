import 'package:flutter_reader/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';

abstract class BookRepository {
  /// Получить поток всех книг
  Stream<Either<Failure, List<Book>>> watchAllBooks();

  /// Получить поток только избранных книг
  Stream<Either<Failure, List<Book>>> watchFavoriteBooks();

  /// Получить поток только прочитанных книг
  Stream<Either<Failure, List<Book>>> watchReadBooks();

  /// Получить книгу по ID
  Future<Either<Failure, Book?>> getBookById(int id);

  /// Добавить новую книгу
  Future<Either<Failure, int>> addBook(Book book);

  /// Обновить книгу
  Future<Either<Failure, bool>> updateBook(Book book);

  /// Удалить книгу по ID
  Future<Either<Failure, void>> deleteBook(int id);

  /// Переключить статус "избранное"
  Future<Either<Failure, void>> toggleFavorite(int id, bool value);

  /// Переключить статус "прочитано"
  Future<Either<Failure, void>> toggleRead(int id, bool value);

  /// Обновить порядок книги
  Future<Either<Failure, void>> updateSortOrder(int id, int sortOrder);

  /// Обновить порядок нескольких книг (для Drag-and-drop)
  Future<Either<Failure, void>> updateSortOrders(Map<int, int> idToOrder);
}
