import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../domain/entities/reader_item.dart';
import '../bloc/reader_bloc.dart';
import 'reader_content.dart';

class HorizontalReaderContent extends StatefulWidget {
  final double fontSize;
  final double brightness;
  final double contrast;

  const HorizontalReaderContent({
    super.key,
    required this.fontSize,
    required this.brightness,
    required this.contrast,
  });

  @override
  State<HorizontalReaderContent> createState() => _HorizontalReaderContentState();
}

class _HorizontalReaderContentState extends State<HorizontalReaderContent> {
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

  void _restorePosition({int? offset, double alignment = 0.0}) {
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

    // В горизонтальном режиме берем элемент, который занимает левую часть экрана
    final minIndex = positions
        .where((p) => p.itemTrailingEdge > 0.1)
        .reduce((min, p) => p.itemLeadingEdge.abs() < min.itemLeadingEdge.abs() ? p : min)
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

    final size = MediaQuery.of(context).size;

    return BlocListener<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) =>
          prev.position.charOffset != curr.position.charOffset,
      listener: (context, state) {
        if (state.position.charOffset != _lastReportedOffset) {
          // В горизонтальном режиме обычно выравниваем по левому краю (alignment: 0.0)
          _restorePosition(offset: state.position.charOffset);
        }
      },
      child: BlocBuilder<ReaderBloc, ReaderState>(
        buildWhen: (prev, curr) => prev.highlightQuery != curr.highlightQuery,
        builder: (context, state) {
          return ScrollablePositionedList.builder(
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(),
            itemCount: _flatItems.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemBuilder: (context, index) {
              final item = _flatItems[index];

              return Container(
                width: size.width,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  child: item.isHeader
                      ? Padding(
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
                        )
                      : _buildTextItem(
                          item,
                          textColor,
                          state.highlightQuery,
                          colorScheme,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
