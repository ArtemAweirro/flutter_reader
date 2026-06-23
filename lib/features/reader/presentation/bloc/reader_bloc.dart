import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/reader_book.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/usecases/add_bookmark.dart';
import '../../domain/usecases/delete_bookmark.dart';
import '../../domain/usecases/get_saved_position.dart';
import '../../domain/usecases/open_book.dart';
import '../../domain/usecases/save_position.dart';
import '../../domain/usecases/watch_bookmarks.dart';


// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

/// Открыть книгу: загрузить главы и восстановить позицию
final class ReaderOpened extends ReaderEvent {
  final int bookId;
  final String filePath;
  const ReaderOpened({required this.bookId, required this.filePath});

  @override
  List<Object?> get props => [bookId, filePath];
}

/// Перейти к главе по индексу
final class ReaderChapterChanged extends ReaderEvent {
  final int chapterIndex;
  const ReaderChapterChanged(this.chapterIndex);

  @override
  List<Object?> get props => [chapterIndex];
}

/// Обновить позицию скролла (вызывается при прокрутке)
final class ReaderScrolled extends ReaderEvent {
  final double scrollOffset;
  const ReaderScrolled(this.scrollOffset);

  @override
  List<Object?> get props => [scrollOffset];
}

/// Сохранить текущую позицию (при уходе с экрана)
final class ReaderPositionSaveRequested extends ReaderEvent {
  const ReaderPositionSaveRequested();
}

/// Добавить закладку на текущей позиции
final class ReaderBookmarkAdded extends ReaderEvent {
  final String? label;
  const ReaderBookmarkAdded({this.label});

  @override
  List<Object?> get props => [label];
}

/// Удалить закладку
final class ReaderBookmarkDeleted extends ReaderEvent {
  final int bookmarkId;
  const ReaderBookmarkDeleted(this.bookmarkId);

  @override
  List<Object?> get props => [bookmarkId];
}

/// Перейти к позиции закладки
final class ReaderBookmarkJumped extends ReaderEvent {
  final BookmarkEntity bookmark;
  const ReaderBookmarkJumped(this.bookmark);

  @override
  List<Object?> get props => [bookmark];
}

// Внутренние события
final class _BookmarksUpdated extends ReaderEvent {
  final List<BookmarkEntity> bookmarks;
  const _BookmarksUpdated(this.bookmarks);

  @override
  List<Object?> get props => [bookmarks];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum ReaderStatus { initial, loading, success, failure }

final class ReaderState extends Equatable {
  final ReaderStatus status;
  final ReaderBookEntity? book;
  final ReadingPosition position;
  final List<BookmarkEntity> bookmarks;
  final String? errorMessage;

  const ReaderState({
    this.status = ReaderStatus.initial,
    this.book,
    this.position = const ReadingPosition(chapterIndex: 0),
    this.bookmarks = const [],
    this.errorMessage,
  });

  /// Текущая глава
  ChapterEntity? get currentChapter {
    final chapters = book?.chapters;
    if (chapters == null || chapters.isEmpty) return null;
    if (position.chapterIndex >= chapters.length) return chapters.last;
    return chapters[position.chapterIndex];
  }

  bool get hasNextChapter =>
      book != null && position.chapterIndex < book!.totalChapters - 1;

  bool get hasPreviousChapter => position.chapterIndex > 0;

  ReaderState copyWith({
    ReaderStatus? status,
    ReaderBookEntity? book,
    ReadingPosition? position,
    List<BookmarkEntity>? bookmarks,
    String? errorMessage,
  }) {
    return ReaderState(
      status: status ?? this.status,
      book: book ?? this.book,
      position: position ?? this.position,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, book, position, bookmarks, errorMessage];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

@injectable
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final OpenBookUseCase openBook;
  final GetSavedPositionUseCase getSavedPosition;
  final SavePositionUseCase savePosition;
  final WatchBookmarksUseCase watchBookmarks;
  final AddBookmarkUseCase addBookmark;
  final DeleteBookmarkUseCase deleteBookmark;

  StreamSubscription<List<BookmarkEntity>>? _bookmarksSubscription;

  ReaderBloc({
    required this.openBook,
    required this.getSavedPosition,
    required this.savePosition,
    required this.watchBookmarks,
    required this.addBookmark,
    required this.deleteBookmark,
  })  : super(const ReaderState()) {
    on<ReaderOpened>(_onOpened);
    on<ReaderChapterChanged>(_onChapterChanged);
    on<ReaderScrolled>(_onScrolled);
    on<ReaderPositionSaveRequested>(_onPositionSaveRequested);
    on<ReaderBookmarkAdded>(_onBookmarkAdded);
    on<ReaderBookmarkDeleted>(_onBookmarkDeleted);
    on<ReaderBookmarkJumped>(_onBookmarkJumped);
    on<_BookmarksUpdated>(_onBookmarksUpdated);
  }

  // --- Handlers ---

  Future<void> _onOpened(
      ReaderOpened event, Emitter<ReaderState> emit) async {
    emit(state.copyWith(status: ReaderStatus.loading));
    try {
      // Загружаем книгу и сохранённую позицию параллельно
      final results = await Future.wait([
        openBook(event.bookId, event.filePath),
        getSavedPosition(event.bookId),
      ]);

      final book = results[0] as ReaderBookEntity;
      final position = results[1] as ReadingPosition;

      // Подписываемся на закладки
      _bookmarksSubscription?.cancel();
      _bookmarksSubscription = watchBookmarks(event.bookId).listen(
        (bookmarks) => add(_BookmarksUpdated(bookmarks)),
      );

      emit(state.copyWith(
        status: ReaderStatus.success,
        book: book,
        position: position,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReaderStatus.failure,
        errorMessage: 'Не удалось открыть книгу: $e',
      ));
    }
  }

  void _onChapterChanged(
      ReaderChapterChanged event, Emitter<ReaderState> emit) {
    emit(state.copyWith(
      position: ReadingPosition(chapterIndex: event.chapterIndex),
    ));
  }

  void _onScrolled(ReaderScrolled event, Emitter<ReaderState> emit) {
    // Обновляем offset без emit в БД — сохраняем только при уходе с экрана
    emit(state.copyWith(
      position: ReadingPosition(
        chapterIndex: state.position.chapterIndex,
        scrollOffset: event.scrollOffset,
      ),
    ));
  }

  Future<void> _onPositionSaveRequested(
      ReaderPositionSaveRequested event, Emitter<ReaderState> emit) async {
    final bookId = state.book?.bookId;
    if (bookId == null) return;
    await savePosition(bookId, state.position);
  }

  Future<void> _onBookmarkAdded(
      ReaderBookmarkAdded event, Emitter<ReaderState> emit) async {
    final bookId = state.book?.bookId;
    if (bookId == null) return;
    await addBookmark(bookId, state.position, label: event.label);
    // Список обновится автоматически через стрим
  }

  Future<void> _onBookmarkDeleted(
      ReaderBookmarkDeleted event, Emitter<ReaderState> emit) async {
    await deleteBookmark(event.bookmarkId);
  }

  void _onBookmarkJumped(
      ReaderBookmarkJumped event, Emitter<ReaderState> emit) {
    emit(state.copyWith(position: event.bookmark.position));
  }

  void _onBookmarksUpdated(
      _BookmarksUpdated event, Emitter<ReaderState> emit) {
    emit(state.copyWith(bookmarks: event.bookmarks));
  }

  @override
  Future<void> close() {
    _bookmarksSubscription?.cancel(); // предотвращаем утечку памяти
    return super.close();
  }
}
