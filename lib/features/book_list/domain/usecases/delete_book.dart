import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteBook {
  final BookRepository repository;

  DeleteBook(this.repository);

  Future<Either<Failure, void>> call(int bookId) =>
      repository.deleteBook(bookId);
}
