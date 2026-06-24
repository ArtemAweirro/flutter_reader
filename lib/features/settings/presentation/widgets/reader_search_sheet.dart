import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../reader/presentation/bloc/reader_bloc.dart';

/// Bottom sheet поиска — по номеру главы и по словам в тексте.
class ReaderSearchSheet extends StatefulWidget {
  const ReaderSearchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderBloc>(),
        child: const ReaderSearchSheet(),
      ),
    );
  }

  @override
  State<ReaderSearchSheet> createState() => _ReaderSearchSheetState();
}

class _ReaderSearchSheetState extends State<ReaderSearchSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _chapterController = TextEditingController();
  final _searchController = TextEditingController();

  // Результаты поиска по тексту: индекс главы + смещение вхождения
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chapterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Поднимаем sheet над клавиатурой
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHeader(context),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'По главе'),
                  Tab(text: 'По тексту'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChapterSearch(context),
                    _buildTextSearch(context, scrollController),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text('Поиск', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- Поиск по номеру главы ---

  Widget _buildChapterSearch(BuildContext context) {
    final totalChapters =
        context.read<ReaderBloc>().state.book?.totalChapters ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Перейти к главе (1 – $totalChapters)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chapterController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Номер главы',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  onSubmitted: (_) => _goToChapter(context, totalChapters),
                ),
              ),
              const Gap(12),
              FilledButton(
                onPressed: () => _goToChapter(context, totalChapters),
                child: const Text('Перейти'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToChapter(BuildContext context, int totalChapters) {
    final input = int.tryParse(_chapterController.text);
    if (input == null || input < 1 || input > totalChapters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите число от 1 до $totalChapters')),
      );
      return;
    }
    context.read<ReaderBloc>().add(ReaderChapterChanged(input - 1));
    Navigator.pop(context);
  }

  // --- Поиск по тексту ---

  Widget _buildTextSearch(
      BuildContext context, ScrollController scrollController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Поиск по тексту...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _runSearch(context),
                ),
              ),
              const Gap(12),
              FilledButton(
                onPressed: _isSearching ? null : () => _runSearch(context),
                child: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Найти'),
              ),
            ],
          ),
        ),
        if (_searchResults.isEmpty && !_isSearching)
          const Expanded(
            child: Center(child: Text('Введите слово для поиска')),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: Text('Гл. ${result.chapterIndex + 1}'),
                  title: _buildHighlightedText(
                    result.snippet,
                    _searchController.text,
                    context,
                  ),
                  onTap: () {
                    context
                        .read<ReaderBloc>()
                        .add(ReaderChapterChanged(result.chapterIndex));
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _runSearch(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    final chapters = context.read<ReaderBloc>().state.book?.chapters ?? [];
    final results = <_SearchResult>[];

    for (final chapter in chapters) {
      final content = chapter.content.toLowerCase();
      int start = 0;

      while (true) {
        final index = content.indexOf(query, start);
        if (index == -1) break;

        // Формируем сниппет вокруг вхождения
        final snippetStart = (index - 40).clamp(0, content.length);
        final snippetEnd = (index + query.length + 40).clamp(0, content.length);
        final snippet = chapter.content.substring(snippetStart, snippetEnd);

        results.add(_SearchResult(
          chapterIndex: chapter.index,
          snippet: snippet,
        ));

        start = index + query.length;
        // Не более 3 вхождений на главу для производительности
        if (results.where((r) => r.chapterIndex == chapter.index).length >= 3) {
          break;
        }
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  /// Подсвечивает найденное слово в сниппете
  Widget _buildHighlightedText(
      String snippet, String query, BuildContext context) {
    final lowerSnippet = snippet.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerSnippet.indexOf(lowerQuery);

    if (index == -1) return Text(snippet, maxLines: 2);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          if (index > 0) TextSpan(text: snippet.substring(0, index)),
          TextSpan(
            text: snippet.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (index + query.length < snippet.length)
            TextSpan(text: snippet.substring(index + query.length)),
        ],
      ),
    );
  }
}

class _SearchResult {
  final int chapterIndex;
  final String snippet;

  const _SearchResult({
    required this.chapterIndex,
    required this.snippet,
  });
}