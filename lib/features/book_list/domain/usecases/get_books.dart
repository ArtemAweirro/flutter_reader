import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBooks {
  final BookRepository repository;

  GetBooks(this.repository);

  Stream<Either<Failure, List<Book>>> call({
    required bool showFavorites,
    required bool showRead,
  }) {
    if (showFavorites) {
      return repository.watchFavoriteBooks();
    } else if (showRead) {
      return repository.watchReadBooks();
    } else {
      return repository.watchAllBooks();
    }
  }
}
