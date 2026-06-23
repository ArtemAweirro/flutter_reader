import 'package:injectable/injectable.dart';

import '../repositories/reader_repository.dart';

@injectable
class DeleteBookmarkUseCase {
  final ReaderRepository _repository;
  DeleteBookmarkUseCase(this._repository);

  Future<void> call(int bookmarkId) => _repository.deleteBookmark(bookmarkId);
}