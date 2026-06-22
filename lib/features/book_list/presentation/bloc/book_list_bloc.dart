import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/domain/usecases/add_book.dart';
import 'package:flutter_reader/features/book_list/domain/usecases/add_book_from_file.dart';
import 'package:flutter_reader/features/book_list/domain/usecases/delete_book.dart';
import 'package:flutter_reader/features/book_list/domain/usecases/get_books.dart';
import 'package:flutter_reader/features/book_list/domain/usecases/toggle_favorite.dart';
import 'package:flutter_reader/features/book_list/domain/usecases/toggle_read.dart';

enum BookFilter { all, favorites, read }

final class BookListState extends Equatable {
  final List<Book> books;
  final BookFilter filter;
  final bool isLoading;
  final String? errorMessage;

  const BookListState({
    this.books = const [],
    this.filter = BookFilter.all,
    this.isLoading = false,
    this.errorMessage,
  });

  BookListState copyWith({
    List<Book>? books,
    BookFilter? filter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BookListState(
      books: books ?? this.books,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [books, filter, isLoading, errorMessage];
}

sealed class BookListEvent extends Equatable {
  const BookListEvent();

  @override
  List<Object?> get props => [];
}

final class BookListInit extends BookListEvent {
  const BookListInit();
}

final class BookFilterChanged extends BookListEvent {
  final BookFilter filter;

  const BookFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

final class BookAdded extends BookListEvent {
  final Book book;

  const BookAdded(this.book);

  @override
  List<Object?> get props => [book];
}

final class BookAddedFromFile extends BookListEvent {
  const BookAddedFromFile();
}

final class BookDeleted extends BookListEvent {
  final int bookId;

  const BookDeleted(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

final class BookFavoriteToggled extends BookListEvent {
  final int bookId;
  final bool isFavorite;

  const BookFavoriteToggled(this.bookId, this.isFavorite);

  @override
  List<Object?> get props => [bookId, isFavorite];
}

final class BookReadToggled extends BookListEvent {
  final int bookId;
  final bool isRead;

  const BookReadToggled(this.bookId, this.isRead);

  @override
  List<Object?> get props => [bookId, isRead];
}

final class _BooksStreamUpdated extends BookListEvent {
  final List<Book> books;

  const _BooksStreamUpdated(this.books);

  @override
  List<Object?> get props => [books];
}

final class _BookListError extends BookListEvent {
  final String message;

  const _BookListError(this.message);

  @override
  List<Object?> get props => [message];
}

@injectable
class BookListBloc extends Bloc<BookListEvent, BookListState> {
  final GetBooks getBooks;
  final AddBook addBook;
  final AddBookFromFile addBookFromFile;
  final DeleteBook deleteBook;
  final ToggleFavorite toggleFavorite;
  final ToggleRead toggleRead;

  BookListBloc({
    required this.getBooks,
    required this.addBook,
    required this.addBookFromFile,
    required this.deleteBook,
    required this.toggleFavorite,
    required this.toggleRead,
  }) : super(const BookListState()) {
    on<BookListInit>(_onInit);
    on<BookFilterChanged>(_onFilterChanged);
    on<BookAdded>(_onBookAdded);
    on<BookAddedFromFile>(_onBookAddedFromFile);
    on<BookDeleted>(_onBookDeleted);
    on<BookFavoriteToggled>(_onFavoriteToggled);
    on<BookReadToggled>(_onReadToggled);
    on<_BooksStreamUpdated>(_onBooksStreamUpdated);
    on<_BookListError>(_onError);
  }

  void _onInit(BookListInit event, Emitter<BookListState> emit) {
    emit(state.copyWith(isLoading: true));
    _subscribeToBooks(emit, state.filter);
  }

  void _onFilterChanged(BookFilterChanged event, Emitter<BookListState> emit) {
    emit(state.copyWith(filter: event.filter, isLoading: true));
    _subscribeToBooks(emit, event.filter);
  }

  void _subscribeToBooks(Emitter<BookListState> emit, BookFilter filter) {
    getBooks(
      showFavorites: filter == BookFilter.favorites,
      showRead: filter == BookFilter.read,
    ).listen(
      (either) => either.fold(
        (failure) => add(_BookListError(failure.message)),
        (books) => add(_BooksStreamUpdated(books)),
      ),
    );
  }

  void _onBooksStreamUpdated(
    _BooksStreamUpdated event,
    Emitter<BookListState> emit,
  ) {
    emit(state.copyWith(books: event.books, isLoading: false));
  }

  void _onError(_BookListError event, Emitter<BookListState> emit) {
    emit(state.copyWith(
      isLoading: false,
      errorMessage: event.message,
    ));
  }

  Future<void> _onBookAdded(BookAdded event, Emitter<BookListState> emit) async {
    final result = await addBook(event.book);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {}, // Данные обновятся через stream
    );
  }

  Future<void> _onBookAddedFromFile(
    BookAddedFromFile event,
    Emitter<BookListState> emit,
  ) async {
    final result = await addBookFromFile();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {}, // Данные обновятся через stream
    );
  }

  Future<void> _onBookDeleted(
    BookDeleted event,
    Emitter<BookListState> emit,
  ) async {
    final result = await deleteBook(event.bookId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {}, // Данные обновятся через stream
    );
  }

  Future<void> _onFavoriteToggled(
    BookFavoriteToggled event,
    Emitter<BookListState> emit,
  ) async {
    final result = await toggleFavorite(event.bookId, event.isFavorite);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {}, // Данные обновятся через stream
    );
  }

  Future<void> _onReadToggled(
    BookReadToggled event,
    Emitter<BookListState> emit,
  ) async {
    final result = await toggleRead(event.bookId, event.isRead);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {}, // Данные обновятся через stream
    );
  }
}
