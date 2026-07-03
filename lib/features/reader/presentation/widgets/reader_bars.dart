import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/presentation/bloc/settings_bloc.dart';
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
// Нижняя панель навигации по страницам
// ---------------------------------------------------------------------------

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) => prev.scrollDirection != curr.scrollDirection,
      builder: (context, settings) {
        final isVertical = settings.scrollDirection == Axis.vertical;

        return BlocBuilder<ReaderBloc, ReaderState>(
          buildWhen: (prev, curr) =>
              prev.currentPage != curr.currentPage ||
              prev.totalPages != curr.totalPages ||
              prev.chapterIndex != curr.chapterIndex ||
              prev.book?.chapters.length != curr.book?.chapters.length,
          builder: (context, state) {
            final bloc = context.read<ReaderBloc>();

            if (isVertical) {
              final chapterIndex = state.chapterIndex;
              final totalChapters = state.book?.chapters.length ?? 0;

              return _BottomBarContainer(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: chapterIndex > 0
                          ? () =>
                                bloc.add(ReaderChapterChanged(chapterIndex - 1))
                          : null,
                      tooltip: 'Предыдущая глава',
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showChapterDialog(context, totalChapters),
                        child: Text(
                          totalChapters > 0
                              ? 'Глава ${chapterIndex + 1} / $totalChapters'
                              : '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: chapterIndex < totalChapters - 1
                          ? () =>
                                bloc.add(ReaderChapterChanged(chapterIndex + 1))
                          : null,
                      tooltip: 'Следующая глава',
                    ),
                  ],
                ),
              );
            }

            final totalPages = state.totalPages;
            final currentIndex = state.currentPage;

            return _BottomBarContainer(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: currentIndex > 0
                        ? () => bloc.add(
                            ReaderPageJumpRequested(currentIndex - 1),
                          )
                        : null,
                    tooltip: 'Предыдущая страница',
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showPageDialog(context, totalPages),
                      child: Text(
                        totalPages > 0
                            ? '${currentIndex + 1} / $totalPages'
                            : '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: currentIndex < totalPages - 1
                        ? () => bloc.add(
                            ReaderPageJumpRequested(currentIndex + 1),
                          )
                        : null,
                    tooltip: 'Следующая страница',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BottomBarContainer extends StatelessWidget {
  final Widget child;

  const _BottomBarContainer({required this.child});

  @override
  Widget build(BuildContext context) {
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
        child: child,
      ),
    );
  }
}

void _showPageDialog(BuildContext context, int totalPages) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Перейти к странице'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '1 – $totalPages',
          prefixIcon: const Icon(Icons.menu_book_outlined),
        ),
        autofocus: true,
        onSubmitted: (value) {
          _jumpToPage(context, controller.text, totalPages);
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
            _jumpToPage(context, controller.text, totalPages);
            Navigator.pop(ctx);
          },
          child: const Text('Перейти'),
        ),
      ],
    ),
  );
}

void _jumpToPage(BuildContext context, String input, int totalPages) {
  final number = int.tryParse(input);
  if (number == null || number < 1 || number > totalPages) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Введите число от 1 до $totalPages')),
    );
    return;
  }
  context.read<ReaderBloc>().add(ReaderPageJumpRequested(number - 1));
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
          prefixIcon: const Icon(Icons.list),
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
