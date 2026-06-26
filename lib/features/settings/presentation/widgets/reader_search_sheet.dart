import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../reader/presentation/bloc/reader_bloc.dart';

/// Bottom sheet поиска по словам в тексте.
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

class _ReaderSearchSheetState extends State<ReaderSearchSheet> {
  final _searchController = TextEditingController();

  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return _buildTextSearch(context, scrollController);
        },
      ),
    );
  }

  Widget _buildTextSearch(
      BuildContext context, ScrollController scrollController) {
    return Column(
      children: [
        _buildHeader(context),
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
                    context.read<ReaderBloc>().add(ReaderSearchResultJumped(
                          chapterIndex: result.chapterIndex,
                          query: _searchController.text.trim(),
                        ));
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
      ],
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

        final snippetStart = (index - 40).clamp(0, content.length);
        final snippetEnd = (index + query.length + 40).clamp(0, content.length);
        final snippet = chapter.content.substring(snippetStart, snippetEnd);

        results.add(_SearchResult(
          chapterIndex: chapter.index,
          snippet: snippet,
        ));

        start = index + query.length;
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
