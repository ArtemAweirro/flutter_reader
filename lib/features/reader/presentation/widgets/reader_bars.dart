import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reader_bloc.dart';

/// Верхняя панель читалки с заголовком и кнопками навигации.
/// Скрывается при скролле (реализуется через [ReaderPage]).
class ReaderTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBookmarksPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onSearchPressed;

  const ReaderTopBar({
    super.key,
    required this.onBookmarksPressed,
    required this.onSettingsPressed,
    required this.onSearchPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.book?.bookId != curr.book?.bookId ||
          prev.chapterIndex != curr.chapterIndex,
      builder: (context, state) {
        final chapter = state.currentChapter;
        return AppBar(
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.book?.title ?? '',
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (chapter != null)
                Text(
                  chapter.title,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: onSearchPressed,
              tooltip: 'Поиск',
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_outline),
              onPressed: onBookmarksPressed,
              tooltip: 'Закладки',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettingsPressed,
              tooltip: 'Настройки',
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Нижняя панель навигации по главам
// ---------------------------------------------------------------------------

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.position != curr.position || prev.book != curr.book,
      builder: (context, state) {
        final bloc = context.read<ReaderBloc>();
        final totalChapters = state.book?.totalChapters ?? 0;
        final currentIndex = state.chapterIndex;

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: state.hasPreviousChapter
                      ? () => bloc.add(
                            ReaderChapterChanged(currentIndex - 1),
                          )
                      : null,
                  tooltip: 'Предыдущая глава',
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showChapterDialog(context, totalChapters),
                    child: Text(
                      totalChapters > 0
                          ? '${currentIndex + 1} / $totalChapters'
                          : '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: state.hasNextChapter
                      ? () => bloc.add(
                            ReaderChapterChanged(currentIndex + 1),
                          )
                      : null,
                  tooltip: 'Следующая глава',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChapterDialog(BuildContext context, int totalChapters) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Перейти к главе'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '1 – $totalChapters',
            prefixIcon: const Icon(Icons.menu_book_outlined),
          ),
          autofocus: true,
          onSubmitted: (value) {
            _jumpToChapter(context, controller.text, totalChapters);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              _jumpToChapter(context, controller.text, totalChapters);
              Navigator.pop(ctx);
            },
            child: const Text('Перейти'),
          ),
        ],
      ),
    );
  }

  void _jumpToChapter(BuildContext context, String input, int totalChapters) {
    final number = int.tryParse(input);
    if (number == null || number < 1 || number > totalChapters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите число от 1 до $totalChapters')),
      );
      return;
    }
    context.read<ReaderBloc>().add(ReaderChapterChanged(number - 1));
  }
}
