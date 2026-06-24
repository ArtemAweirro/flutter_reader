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
    final state = context.watch<ReaderBloc>().state;
    final colorScheme = Theme.of(context).colorScheme;
    final readerTextColor = applyContrast(
      colorScheme.onSurface,
      widget.contrast,
      colorScheme.brightness,
    );

    return widget.scrollDirection == Axis.vertical
          ? _buildVertical(state, readerTextColor)
          : _buildHorizontal(state, readerTextColor);
  }

  Widget _buildVertical(ReaderState state, Color readerTextColor) {
    final text = state.book?.fullText ?? '';
    if (text.isEmpty) return const Center(child: Text('Нет содержимого'));
 
    return SingleChildScrollView(
      controller: _verticalController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: widget.fontSize,
          height: 1.6,
          color: readerTextColor,
        ),
      ),
    );
  }

  Widget _buildHorizontal(ReaderState state, Color readerTextColor) {
    final chapters = state.book?.chapters ?? [];
    if (chapters.isEmpty) return const Center(child: Text('Нет содержимого'));
 
    return PageView.builder(
      controller: _pageController,
      itemCount: chapters.length,
      onPageChanged: (index) {
        // Сбрасываем scrollOffset при смене страницы и уведомляем BLoC
        context.read<ReaderBloc>().add(ReaderChapterChanged(index));
      },
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return _HorizontalPage(
          chapter: chapter,
          fontSize: widget.fontSize,
          color: readerTextColor,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Страница в горизонтальном режиме — скроллируемый текст одной главы
// ---------------------------------------------------------------------------
 
class _HorizontalPage extends StatelessWidget {
  final ChapterEntity chapter;
  final double fontSize;
  final Color color;
 
  const _HorizontalPage({
    required this.chapter,
    required this.fontSize,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SelectableText(
        chapter.content,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          color: color,
        ),
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