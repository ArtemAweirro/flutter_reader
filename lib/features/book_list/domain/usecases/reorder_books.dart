import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ReorderBooks {
  final BookRepository repository;

  ReorderBooks(this.repository);

  Future<Either<Failure, void>> call(List<Book> books) {
    final Map<int, int> idToOrder = {};
    for (int i = 0; i < books.length; i++) {
      idToOrder[books[i].id] = i;
    }
    return repository.updateSortOrders(idToOrder);
  }
}
