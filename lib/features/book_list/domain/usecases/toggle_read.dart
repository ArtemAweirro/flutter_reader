import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ToggleRead {
  final BookRepository repository;

  ToggleRead(this.repository);

  Future<Either<Failure, void>> call(int bookId, bool isRead) =>
      repository.toggleRead(bookId, isRead);
}
