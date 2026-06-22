import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final int id;
  final String title;
  final String? author;
  final String filePath;
  final String format;
  final bool isFavorite;
  final bool isRead;
  final String? readingPosition;
  final int? totalPages;
  final int sortOrder;
  final DateTime addedAt;

  const Book({
    required this.id,
    required this.title,
    this.author,
    required this.filePath,
    required this.format,
    required this.isFavorite,
    required this.isRead,
    this.readingPosition,
    this.totalPages,
    required this.sortOrder,
    required this.addedAt,
  });

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? filePath,
    String? format,
    bool? isFavorite,
    bool? isRead,
    String? readingPosition,
    int? totalPages,
    int? sortOrder,
    DateTime? addedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      isFavorite: isFavorite ?? this.isFavorite,
      isRead: isRead ?? this.isRead,
      readingPosition: readingPosition ?? this.readingPosition,
      totalPages: totalPages ?? this.totalPages,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    filePath,
    format,
    isFavorite,
    isRead,
    readingPosition,
    totalPages,
    sortOrder,
    addedAt,
  ];
}
