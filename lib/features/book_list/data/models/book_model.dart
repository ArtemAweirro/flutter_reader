import 'package:flutter_reader/features/book_list/domain/entities/book.dart';

class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    super.author,
    required super.filePath,
    required super.format,
    required super.isFavorite,
    required super.isRead,
    super.readingPosition,
    super.totalPages,
    required super.sortOrder,
    required super.addedAt,
  });

  factory BookModel.fromDriftBook(dynamic driftBook) {
    return BookModel(
      id: driftBook.id,
      title: driftBook.title,
      author: driftBook.author,
      filePath: driftBook.filePath,
      format: driftBook.format,
      isFavorite: driftBook.isFavorite,
      isRead: driftBook.isRead,
      readingPosition: driftBook.readingPosition,
      totalPages: driftBook.totalPages,
      sortOrder: driftBook.sortOrder,
      addedAt: driftBook.addedAt,
    );
  }

  static List<BookModel> fromDriftBooks(List<dynamic> driftBooks) =>
      driftBooks.map((b) => BookModel.fromDriftBook(b)).toList();
}
