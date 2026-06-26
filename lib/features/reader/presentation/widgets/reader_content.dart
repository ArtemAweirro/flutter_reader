import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chapter.dart';
import '../bloc/reader_bloc.dart';


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
  final ScrollController _verticalController = ScrollController();
  final PageController _pageController = PageController();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_onVerticalScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<ReaderBloc>().state;
      if (state.status == ReaderStatus.success) {
        _restorePosition(state);
      }
    });
  }

  @override
  void didUpdateWidget(ReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollDirection != widget.scrollDirection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final state = context.read<ReaderBloc>().state;
        if (state.status == ReaderStatus.success) {
          _restorePosition(state);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _verticalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalScroll() {
    if (!_verticalController.hasClients) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_verticalController.hasClients) return;
      final max = _verticalController.position.maxScrollExtent;
      if (max <= 0) return;
      final ratio = _verticalController.offset / max;
      final chapters =
          context.read<ReaderBloc>().state.book?.chapters ?? [];
      if (chapters.isEmpty) return;
      final totalLength =
          chapters.fold<int>(0, (sum, ch) => sum + ch.content.length);
      final charOffset = (ratio * totalLength).round();
      context.read<ReaderBloc>().add(ReaderVerticalScrolled(charOffset));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) => prev.chapterIndex != curr.chapterIndex,
      listener: (context, state) => _restorePosition(state),
      child: widget.scrollDirection == Axis.vertical
          ? _buildVertical()
          : _buildHorizontal(),
    );
  }

  void _restorePosition(ReaderState state) {
    if (!mounted) return;
    if (widget.scrollDirection == Axis.vertical) {
      final chapters = state.book?.chapters ?? [];
      if (chapters.isEmpty || !_verticalController.hasClients) return;
      final totalLength =
          chapters.fold<int>(0, (sum, ch) => sum + ch.content.length);
      if (totalLength <= 0) return;
      final ratio =
          (state.position.charOffset / totalLength).clamp(0.0, 1.0);
      _verticalController
          .jumpTo(_verticalController.position.maxScrollExtent * ratio);
    } else {
      if (!_pageController.hasClients) return;
      final savedOffset = state.position.charOffset;
      _pageController.jumpToPage(state.chapterIndex);
      context.read<ReaderBloc>().add(ReaderScrolled(savedOffset));
    }
  }

  Widget _buildVertical() {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) => prev.book?.bookId != curr.book?.bookId,
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

        return ListView.builder(
          controller: _verticalController,
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chapter.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: widget.fontSize * 1.2,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  Text(
                    chapter.content,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          },
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
            return _HorizontalPage(
              chapter: chapter,
              fontSize: widget.fontSize,
              color: textColor,
            );
          },
        );
      },
    );
  }
}

class _HorizontalPage extends StatefulWidget {
  final ChapterEntity chapter;
  final double fontSize;
  final Color color;

  const _HorizontalPage({
    required this.chapter,
    required this.fontSize,
    required this.color,
  });

  @override
  State<_HorizontalPage> createState() => _HorizontalPageState();
}

class _HorizontalPageState extends State<_HorizontalPage> {
  late final ScrollController _scrollController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _restorePosition());
  }

  void _restorePosition() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = context.read<ReaderBloc>().state;
    if (state.status != ReaderStatus.success) return;
    final chapterOffset = _chapterRelativeOffset(state);
    final length = widget.chapter.content.length;
    if (length <= 0) return;
    final ratio = (chapterOffset / length).clamp(0.0, 1.0);
    _scrollController
        .jumpTo(_scrollController.position.maxScrollExtent * ratio);
  }

  int _chapterRelativeOffset(ReaderState state) {
    final chapters = state.book?.chapters ?? [];
    int base = 0;
    for (int i = 0; i < widget.chapter.index && i < chapters.length; i++) {
      base += chapters[i].content.length;
    }
    return state.position.charOffset - base;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final ratio = _scrollController.offset / max;
      final chapterOffset = (ratio * widget.chapter.content.length).round();
      final state = context.read<ReaderBloc>().state;
      final chapters = state.book?.chapters ?? [];
      int base = 0;
      for (int i = 0; i < widget.chapter.index && i < chapters.length; i++) {
        base += chapters[i].content.length;
      }
      final absoluteOffset = base + chapterOffset;
      if (!mounted) return;
      context.read<ReaderBloc>().add(ReaderScrolled(absoluteOffset));
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          widget.chapter.content,
          style: TextStyle(
            fontSize: widget.fontSize,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

Color applyContrast(Color baseColor, double contrast, Brightness brightness) {
  final target = brightness == Brightness.dark ? Colors.white : Colors.black;

  return Color.lerp(baseColor.withValues(alpha: 0.5), target, contrast)!;
}