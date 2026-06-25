import 'package:flutter/material.dart';

/// Отображает текст с анимированной подсветкой найденного слова.
/// Подсветка плавно затухает за [highlightDuration].
class HighlightedText extends StatefulWidget {
  final String text;
  final String? highlightQuery;
  final TextStyle? style;
  final Duration highlightDuration;
  final VoidCallback? onHighlightEnd;

  const HighlightedText({
    super.key,
    required this.text,
    this.highlightQuery,
    this.style,
    this.highlightDuration = const Duration(milliseconds: 1500),
    this.onHighlightEnd,
  });

  @override
  State<HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<HighlightedText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  // Смещение первого вхождения для скролла
  String? _activeQuery;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.highlightDuration,
    );

    // Плавное затухание: 1.0 → 0.0
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onHighlightEnd?.call();
      }
    });

    if (widget.highlightQuery != null) {
      _startHighlight(widget.highlightQuery!);
    }
  }

  @override
  void didUpdateWidget(HighlightedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Новый поисковый запрос — перезапускаем анимацию
    if (widget.highlightQuery != null &&
        widget.highlightQuery != oldWidget.highlightQuery) {
      _startHighlight(widget.highlightQuery!);
    }
  }

  void _startHighlight(String query) {
    setState(() => _activeQuery = query);
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _activeQuery?.toLowerCase();
    if (query == null || query.isEmpty) {
      return SelectableText(widget.text, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        // Пересобираем спаны с актуальной прозрачностью подсветки
        final animatedSpans = _buildSpans(context, query, opacity: _opacity.value);
        return SelectableText.rich(
          TextSpan(children: animatedSpans, style: widget.style),
        );
      },
    );
  }

  List<TextSpan> _buildSpans(BuildContext context, String query,
      {double opacity = 1.0}) {
    final spans = <TextSpan>[];
    final lowerText = widget.text.toLowerCase();
    final highlightColor = Theme.of(context)
        .colorScheme
        .primaryContainer
        .withOpacity(opacity);

    int start = 0;
    while (start < widget.text.length) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        // Остаток текста без подсветки
        spans.add(TextSpan(text: widget.text.substring(start)));
        break;
      }

      // Текст до вхождения
      if (index > start) {
        spans.add(TextSpan(text: widget.text.substring(start, index)));
      }

      // Подсвеченное вхождение
      spans.add(TextSpan(
        text: widget.text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: highlightColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }
}