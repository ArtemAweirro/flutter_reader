import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reader_bloc.dart';

/// Отображает текст текущей главы.
/// Отслеживает позицию скролла и сообщает BLoC при изменении.
class ReaderContent extends StatefulWidget {
  final double fontSize;
  final Axis scrollDirection;

  const ReaderContent({
    super.key,
    required this.fontSize,
    required this.scrollDirection,
  });

  @override
  State<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<ReaderContent> {
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final offset = _scrollController.offset / max;
      context.read<ReaderBloc>().add(ReaderScrolled(offset.clamp(0.0, 1.0)));
    });

  }

  void _restorePosition() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    // Если контент ещё не отрендерился — повторяем попытку
    if (max <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
      return;
    }
    final position = context.read<ReaderBloc>().state.position;
    final target = (position.scrollOffset * max).clamp(0.0, max);
    if (target > 0) {
      _scrollController.jumpTo(target);
    }
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReaderBloc>().state;
    final chapter = state.currentChapter;
    final colorScheme = Theme.of(context).colorScheme;

    if (chapter == null) {
      return const Center(child: Text('Нет содержимого'));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // При горизонтальном скролле фиксируем ширину экрана
          maxWidth: widget.scrollDirection == Axis.horizontal
              ? MediaQuery.of(context).size.width - 40
              : double.infinity,
        ),
        child: SelectableText(
          chapter.content,
          style: TextStyle(
            fontSize: widget.fontSize,
            height: 1.6,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}