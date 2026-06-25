import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chapter.dart';
import '../bloc/reader_bloc.dart';
import 'highlighted_text.dart';

/// Отображает текст текущей главы.
/// Отслеживает позицию скролла и сообщает BLoC при изменении.
class ReaderContent extends StatefulWidget {
  final double fontSize;
  final Axis scrollDirection;
  final double brightness;
  final double contrast;

  const ReaderContent({
    super.key,
    required this.fontSize,
    required this.scrollDirection,
    required this.brightness,
    required this.contrast,
  });

  @override
  State<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<ReaderContent> {
  // Вертикальный режим
  ScrollController _verticalController = ScrollController();

  // Горизонтальный режим
  PageController _pageController = PageController();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_onVerticalScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
  }

  @override
  void didUpdateWidget(ReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // При смене направления — пересоздаём контроллеры и восстанавливаем позицию
    if (oldWidget.scrollDirection != widget.scrollDirection) {
      _debounceTimer?.cancel();

      _verticalController.removeListener(_onVerticalScroll);
      _verticalController.dispose();
      _verticalController = ScrollController();
      _verticalController.addListener(_onVerticalScroll);

      _pageController.dispose();
      _pageController = PageController();

      // Восстанавливаем позицию после пересоздания контроллера
      WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
    }
  }
 
  void _onVerticalScroll() {
    if (!_verticalController.hasClients) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_verticalController.hasClients) return;
      final max = _verticalController.position.maxScrollExtent;
      if (max <= 0) return;
      final offset = _verticalController.offset / max;
      context
          .read<ReaderBloc>()
          .add(ReaderVerticalScrolled(offset.clamp(0.0, 1.0)));
    });
  }


  void _restorePosition() {
    if (!mounted) return;
    final position = context.read<ReaderBloc>().state.position;
 
    if (widget.scrollDirection == Axis.vertical) {
      _restoreVertical(position.verticalOffset);
    } else {
      // PageController — просто прыгаем на нужную страницу
      if (_pageController.hasClients) {
        _pageController.jumpToPage(position.chapterIndex);
      }
    }
  }

    void _restoreVertical(double targetOffset) {
    if (!mounted) return;
    if (!_verticalController.hasClients) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _restoreVertical(targetOffset));
      return;
    }
    final max = _verticalController.position.maxScrollExtent;
    if (max <= 0) {
      // Контент ещё не отрендерился
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _restoreVertical(targetOffset));
      return;
    }
    final target = (targetOffset * max).clamp(0.0, max);
    if (target > 0) _verticalController.jumpTo(target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Восстанавливаем позицию после смены главы
    WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();  // предотвращаем утечку памяти
    _verticalController.removeListener(_onVerticalScroll);
    _verticalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollDirection = widget.scrollDirection;
 
    return scrollDirection == Axis.vertical
        ? _buildVertical()
        : _buildHorizontal();
  }

  // ---------------------------------------------------------------------------
  // Вертикальный режим
  // Разделяем на два BlocBuilder — текст и подсветка — чтобы не перестраивать
  // огромный текст при каждом изменении highlightQuery
  // ---------------------------------------------------------------------------
 
  Widget _buildVertical() {
    return BlocBuilder<ReaderBloc, ReaderState>(
      // Перестраиваем только когда меняется сама книга
      buildWhen: (prev, curr) => prev.book?.bookId != curr.book?.bookId,
      builder: (context, state) {
        final text = state.book?.fullText ?? '';
        if (text.isEmpty) return const Center(child: Text('Нет содержимого'));
 
        final colorScheme = Theme.of(context).colorScheme;
        final textColor = applyContrast(
          colorScheme.onSurface,
          widget.contrast,
          colorScheme.brightness,
        );
 
        return SingleChildScrollView(
          controller: _verticalController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          // Вложенный BlocBuilder только для highlightQuery
          child: BlocBuilder<ReaderBloc, ReaderState>(
            buildWhen: (prev, curr) =>
                prev.highlightQuery != curr.highlightQuery,
            builder: (context, state) {
              return HighlightedText(
                text: text,
                highlightQuery: state.highlightQuery,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  height: 1.6,
                  color: textColor,
                ),
                onHighlightEnd: () => context
                    .read<ReaderBloc>()
                    .add(const ReaderHighlightCleared()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHorizontal() {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.book?.bookId != curr.book?.bookId ||
          prev.highlightQuery != curr.highlightQuery,
      builder: (context, state) {
        final chapters = state.book?.chapters ?? [];
        if (chapters.isEmpty) {
          return const Center(child: Text('Нет содержимого'));
        }
 
        final colorScheme = Theme.of(context).colorScheme;
        final textColor = applyContrast(
          colorScheme.onSurface,
          widget.contrast,
          colorScheme.brightness,
        );
 
        return PageView.builder(
          controller: _pageController,
          itemCount: chapters.length,
          onPageChanged: (index) {
            context.read<ReaderBloc>().add(ReaderChapterChanged(index));
          },
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final isCurrentPage = index == state.position.chapterIndex;
            return _HorizontalPage(
              chapter: chapter,
              fontSize: widget.fontSize,
              color: textColor,
              highlightQuery: isCurrentPage ? state.highlightQuery : null,
              onHighlightEnd: isCurrentPage
                  ? () => context
                      .read<ReaderBloc>()
                      .add(const ReaderHighlightCleared())
                  : null,
              onScroll: (offset) => context
                  .read<ReaderBloc>()
                  .add(ReaderScrolled(offset)),
              initialScrollOffset: isCurrentPage
                  ? state.position.scrollOffset
                  : 0.0,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Страница в горизонтальном режиме — скроллируемый текст одной главы
// ---------------------------------------------------------------------------
 
class _HorizontalPage extends StatefulWidget {
  final ChapterEntity chapter;
  final double fontSize;
  final Color color;
  final String? highlightQuery;
  final VoidCallback? onHighlightEnd;
  final ValueChanged<double> onScroll;
  final double initialScrollOffset;
 
  const _HorizontalPage({
    required this.chapter,
    required this.fontSize,
    required this.color,
    required this.onScroll,
    required this.initialScrollOffset,
    this.highlightQuery,
    this.onHighlightEnd,
  });

  @override
  State<_HorizontalPage> createState() => _HorizontalPageState();
 
  // @override
  // Widget build(BuildContext context) {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //     child: HighlightedText(
  //       text: chapter.content,
  //       highlightQuery: highlightQuery,
  //       style: TextStyle(
  //         fontSize: fontSize,
  //         height: 1.6,
  //         color: color,
  //       ),
  //       onHighlightEnd: onHighlightEnd,
  //     ),
  //   );
  // }
}

class _HorizontalPageState extends State<_HorizontalPage> {
  late final ScrollController _scrollController;
  Timer? _debounceTimer;
 
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Восстанавливаем позицию скролла внутри страницы
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _restoreScroll());
  }
 
  void _restoreScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScroll());
      return;
    }
    final target = (widget.initialScrollOffset * max).clamp(0.0, max);
    if (target > 0) _scrollController.jumpTo(target);
  }
 
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final offset = _scrollController.offset / max;
      widget.onScroll(offset.clamp(0.0, 1.0));
    });
  }
 
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: HighlightedText(
        text: widget.chapter.content,
        highlightQuery: widget.highlightQuery,
        style: TextStyle(
          fontSize: widget.fontSize,
          height: 1.6,
          color: widget.color,
        ),
        onHighlightEnd: widget.onHighlightEnd,
      ),
    );
  }
}

Color applyContrast(
  Color baseColor,
  double contrast,
  Brightness brightness,
) {
  final target =
      brightness == Brightness.dark ? Colors.white : Colors.black;

  return Color.lerp(
    baseColor.withValues(alpha: 0.5),
    target,
    contrast,
  )!;
}