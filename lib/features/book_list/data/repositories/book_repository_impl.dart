import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:flutter_reader/core/database/app_database.dart' hide Book;
import 'package:flutter_reader/core/database/books_dao.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/data/models/book_model.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: BookRepository)
class BookRepositoryImpl implements BookRepository {
  final BooksDao booksDao;

  BookRepositoryImpl(this.booksDao);

  @override
  Stream<Either<Failure, List<Book>>> watchAllBooks() {
    try {
      return booksDao.watchAllBooks().map((books) {
        return Right(BookModel.fromDriftBooks(books));
      });
    } catch (e) {
      return Stream.value(Left(DatabaseFailure()));
    }
  }

  @override
  Stream<Either<Failure, List<Book>>> watchFavoriteBooks() {
    try {
      return booksDao.watchFavoriteBooks().map((books) {
        return Right(BookModel.fromDriftBooks(books));
      });
    } catch (e) {
      return Stream.value(Left(DatabaseFailure()));
    }
  }

  @override
  Stream<Either<Failure, List<Book>>> watchReadBooks() {
    try {
      return booksDao.watchReadBooks().map((books) {
        return Right(BookModel.fromDriftBooks(books));
      });
    } catch (e) {
      return Stream.value(Left(DatabaseFailure()));
    }
  }

  @override
  Future<Either<Failure, Book?>> getBookById(int id) async {
    try {
      final book = await booksDao.getBookById(id);
      return Right(book != null ? BookModel.fromDriftBook(book) : null);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, int>> addBook(Book book) async {
    try {
      final id = await booksDao.insertBook(
        // Преобразуем Book в BooksCompanion
        _bookToBooksCompanion(book),
      );
      return Right(id);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> updateBook(Book book) async {
    try {
      final result = await booksDao.updateBook(
        _bookToBooksCompanion(book),
      );
      return Right(result);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteBook(int id) async {
    try {
      await booksDao.deleteBook(id);
      return const Right(null);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(int id, bool value) async {
    try {
      await booksDao.updateFavorite(id, value);
      return const Right(null);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleRead(int id, bool value) async {
    try {
      await booksDao.updateIsRead(id, value);
      return const Right(null);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateSortOrder(int id, int sortOrder) async {
    try {
      await booksDao.updateSortOrder(id, sortOrder);
      return const Right(null);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateSortOrders(Map<int, int> idToOrder) async {
    try {
      await booksDao.updateSortOrders(idToOrder);
      return const Right(null);
    } on DatabaseFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure());
    }
  }

  /// Преобразует Book в BooksCompanion для Drift
  BooksCompanion _bookToBooksCompanion(Book book) {
    return BooksCompanion(
      id: book.id == 0 ? const Value.absent() : Value(book.id),
      title: Value(book.title),
      author: book.author != null ? Value(book.author!) : const Value.absent(),
      filePath: Value(book.filePath),
      format: Value(book.format),
      isFavorite: Value(book.isFavorite),
      isRead: Value(book.isRead),
      readingPosition: book.readingPosition != null
          ? Value(book.readingPosition!)
          : const Value.absent(),
      totalCharacters: book.totalCharacters != null
          ? Value(book.totalCharacters!)
          : const Value.absent(),
      sortOrder: Value(book.sortOrder),
      addedAt: Value(book.addedAt),
    );
  }
}
