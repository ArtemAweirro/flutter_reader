import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddBook {
  final BookRepository repository;

  AddBook(this.repository);

  Future<Either<Failure, int>> call(Book book) => repository.addBook(book);
}
