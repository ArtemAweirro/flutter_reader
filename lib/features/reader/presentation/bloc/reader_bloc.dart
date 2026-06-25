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

/// Обновить позицию скролла в горизонтальном режиме (offset внутри главы)
final class ReaderScrolled extends ReaderEvent {
  final double scrollOffset;
  const ReaderScrolled(this.scrollOffset);

  @override
  List<Object?> get props => [scrollOffset];
}

/// Обновить позицию скролла в вертикальном режиме (offset по всему тексту)
final class ReaderVerticalScrolled extends ReaderEvent {
  final double verticalOffset;
  const ReaderVerticalScrolled(this.verticalOffset);

  @override
  List<Object?> get props => [verticalOffset];
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

/// Перейти к результату поиска и подсветить найденный текст
final class ReaderSearchResultJumped extends ReaderEvent {
  final int chapterIndex;
  final String query;

  const ReaderSearchResultJumped({
    required this.chapterIndex,
    required this.query,
  });

  @override
  List<Object?> get props => [chapterIndex, query];
}

/// Сбросить подсветку поиска
final class ReaderHighlightCleared extends ReaderEvent {
  const ReaderHighlightCleared();
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

  /// Текст для подсветки после перехода из поиска.
  /// null — подсветки нет.
  final String? highlightQuery;

  const ReaderState({
    this.status = ReaderStatus.initial,
    this.book,
    this.position = const ReadingPosition(),
    this.bookmarks = const [],
    this.errorMessage,
    this.highlightQuery,
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
    String? highlightQuery,
    bool clearHighlight = false,
  }) {
    return ReaderState(
      status: status ?? this.status,
      book: book ?? this.book,
      position: position ?? this.position,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage,
      highlightQuery: clearHighlight
          ? null
          : (highlightQuery ?? this.highlightQuery),
    );
  }

  @override
  List<Object?> get props => [
    status,
    book?.bookId,
    position,
    bookmarks,
    errorMessage,
    highlightQuery,
  ];
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
  }) : super(const ReaderState()) {
    on<ReaderOpened>(_onOpened);
    on<ReaderChapterChanged>(_onChapterChanged);
    on<ReaderScrolled>(_onScrolled);
    on<ReaderVerticalScrolled>(_onVerticalScrolled);
    on<ReaderPositionSaveRequested>(_onPositionSaveRequested);
    on<ReaderBookmarkAdded>(_onBookmarkAdded);
    on<ReaderBookmarkDeleted>(_onBookmarkDeleted);
    on<ReaderBookmarkJumped>(_onBookmarkJumped);
    on<ReaderSearchResultJumped>(_onSearchResultJumped);
    on<ReaderHighlightCleared>(_onHighlightCleared);
    on<_BookmarksUpdated>(_onBookmarksUpdated);
  }

  // --- Handlers ---

  Future<void> _onOpened(ReaderOpened event, Emitter<ReaderState> emit) async {
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
      _bookmarksSubscription = watchBookmarks(
        event.bookId,
      ).listen((bookmarks) => add(_BookmarksUpdated(bookmarks)));

      emit(
        state.copyWith(
          status: ReaderStatus.success,
          book: book,
          position: position,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReaderStatus.failure,
          errorMessage: 'Не удалось открыть книгу: $e',
        ),
      );
    }
  }

  void _onChapterChanged(
    ReaderChapterChanged event,
    Emitter<ReaderState> emit,
  ) {
    emit(
      state.copyWith(
        position: state.position.copyWith(
          chapterIndex: event.chapterIndex,
          scrollOffset: 0.0,
        ),
      ),
    );
  }

  void _onScrolled(ReaderScrolled event, Emitter<ReaderState> emit) {
    // Горизонтальный режим — обновляем offset внутри текущей главы
    emit(
      state.copyWith(
        position: state.position.copyWith(scrollOffset: event.scrollOffset),
      ),
    );
  }

  void _onVerticalScrolled(
    ReaderVerticalScrolled event,
    Emitter<ReaderState> emit,
  ) {
    // Вертикальный режим — обновляем offset по всему тексту
    emit(
      state.copyWith(
        position: state.position.copyWith(verticalOffset: event.verticalOffset),
      ),
    );
  }

  Future<void> _onPositionSaveRequested(
    ReaderPositionSaveRequested event,
    Emitter<ReaderState> emit,
  ) async {
    final bookId = state.book?.bookId;
    if (bookId == null) return;
    await savePosition(bookId, state.position);
  }

  Future<void> _onBookmarkAdded(
    ReaderBookmarkAdded event,
    Emitter<ReaderState> emit,
  ) async {
    final bookId = state.book?.bookId;
    if (bookId == null) return;
    await addBookmark(bookId, state.position, label: event.label);
    // Список обновится автоматически через стрим
  }

  Future<void> _onBookmarkDeleted(
    ReaderBookmarkDeleted event,
    Emitter<ReaderState> emit,
  ) async {
    await deleteBookmark(event.bookmarkId);
  }

  void _onBookmarkJumped(
    ReaderBookmarkJumped event,
    Emitter<ReaderState> emit,
  ) {
    emit(state.copyWith(position: event.bookmark.position));
  }

  void _onSearchResultJumped(
    ReaderSearchResultJumped event,
    Emitter<ReaderState> emit,
  ) {
    emit(
      state.copyWith(
        position: state.position.copyWith(chapterIndex: event.chapterIndex),
        highlightQuery: event.query,
      ),
    );
  }

  void _onHighlightCleared(
    ReaderHighlightCleared event,
    Emitter<ReaderState> emit,
  ) {
    emit(state.copyWith(clearHighlight: true));
  }

  void _onBookmarksUpdated(_BookmarksUpdated event, Emitter<ReaderState> emit) {
    emit(state.copyWith(bookmarks: event.bookmarks));
  }

  @override
  Future<void> close() {
    _bookmarksSubscription?.cancel(); // предотвращаем утечку памяти
    return super.close();
  }
}
