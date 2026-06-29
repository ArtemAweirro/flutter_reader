import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../domain/entities/reader_item.dart';
import '../bloc/reader_bloc.dart';
import 'reader_content.dart';

class VerticalReaderContent extends StatefulWidget {
  final double fontSize;
  final double brightness;
  final double contrast;

  const VerticalReaderContent({
    super.key,
    required this.fontSize,
    required this.brightness,
    required this.contrast,
  });

  @override
  State<VerticalReaderContent> createState() => _VerticalReaderContentState();
}

class _VerticalReaderContentState extends State<VerticalReaderContent> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  List<ReaderItem> _flatItems = [];
  Timer? _debounceTimer;
  int? _lastReportedOffset;

  @override
  void initState() {
    super.initState();
    _prepareItems();
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _restorePosition();
      }
    });
  }

  void _prepareItems() {
    _flatItems = context.read<ReaderBloc>().state.book?.items ?? [];
  }

  void _restorePosition({int? offset, double alignment = 0}) {
    if (_flatItems.isEmpty || !_itemScrollController.isAttached) return;

    final targetOffset =
        offset ?? context.read<ReaderBloc>().state.position.charOffset;

    int targetIndex = 0;
    for (int i = 0; i < _flatItems.length; i++) {
      if (_flatItems[i].charOffset <= targetOffset) {
        targetIndex = i;
      } else {
        break;
      }
    }

    _itemScrollController.jumpTo(index: targetIndex, alignment: alignment);
    _lastReportedOffset = _flatItems[targetIndex].charOffset;
  }

  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Находим первый видимый элемент (у которого верхняя граница ближе всего к 0)
    final minIndex = positions
        .where((p) => p.itemTrailingEdge > 0)
        .reduce((min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min)
        .index;

    if (minIndex >= 0 && minIndex < _flatItems.length) {
      final item = _flatItems[minIndex];

      if (item.charOffset == _lastReportedOffset) return;

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _lastReportedOffset = item.charOffset;
        context.read<ReaderBloc>().add(ReaderScrolled(item.charOffset));
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  Widget _buildTextItem(
    ReaderItem item,
    Color textColor,
    String? highlightQuery,
    ColorScheme colorScheme,
  ) {
    final style = TextStyle(
      fontSize: widget.fontSize,
      color: textColor,
      height: 1.5,
      // Используем одинаковый шрифт всегда для стабильности верстки
      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    );

    if (highlightQuery == null || highlightQuery.isEmpty) {
      return Text(item.text, style: style);
    }

    final String text = item.text;
    final String lowerText = text.toLowerCase();
    final String lowerQuery = highlightQuery.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + highlightQuery.length),
        style: TextStyle(
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.7),
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + highlightQuery.length;
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    if (_flatItems.isEmpty) {
      return const Center(child: Text('Нет содержимого'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textColor = applyContrast(
      colorScheme.onSurface,
      widget.contrast,
      colorScheme.brightness,
    );

    return BlocListener<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) =>
          prev.position.charOffset != curr.position.charOffset,
      listener: (context, state) {
        if (state.position.charOffset != _lastReportedOffset) {
          // Если есть поисковый запрос, центрируем (alignment 0.2 - чуть выше центра)
          final isSearchJump = state.highlightQuery != null;
          _restorePosition(
            offset: state.position.charOffset,
            alignment: isSearchJump ? 0.2 : 0.0,
          );
        }
      },
      child: BlocBuilder<ReaderBloc, ReaderState>(
        buildWhen: (prev, curr) => prev.highlightQuery != curr.highlightQuery,
        builder: (context, state) {
          return ScrollablePositionedList.builder(
            itemCount: _flatItems.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            itemBuilder: (context, index) {
              final item = _flatItems[index];

              if (item.isHeader) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 24),
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: widget.fontSize * 1.3,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextItem(
                  item,
                  textColor,
                  state.highlightQuery,
                  colorScheme,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
