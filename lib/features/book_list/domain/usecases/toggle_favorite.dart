import 'package:dartz/dartz.dart';
import 'package:flutter_reader/core/error/failures.dart';
import 'package:flutter_reader/features/book_list/domain/repositories/book_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ToggleFavorite {
  final BookRepository repository;

  ToggleFavorite(this.repository);

  Future<Either<Failure, void>> call(int bookId, bool isFavorite) =>
      repository.toggleFavorite(bookId, isFavorite);
}
