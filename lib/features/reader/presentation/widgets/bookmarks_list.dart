import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bookmark.dart';
import '../bloc/reader_bloc.dart';

/// Bottom sheet со списком закладок.
/// Открывается из [ReaderTopBar].
class BookmarksList extends StatelessWidget {
  const BookmarksList({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderBloc>(),
        child: const BookmarksList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<ReaderBloc, ReaderState>(
                buildWhen: (prev, curr) => prev.bookmarks != curr.bookmarks,
                builder: (context, state) {
                  if (state.bookmarks.isEmpty) {
                    return const Center(
                      child: Text('Закладок пока нет'),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: state.bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = state.bookmarks[index];
                      return _BookmarkTile(bookmark: bookmark);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Text(
            'Закладки',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ReaderBloc>()
                  .add(const ReaderBookmarkAdded());
            },
            tooltip: 'Добавить закладку',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarkEntity bookmark;

  const _BookmarkTile({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReaderBloc>();

    return ListTile(
      leading: const Icon(Icons.bookmark),
      title: Text(
        bookmark.label ?? 'Глава ${bookmark.chapterIndex + 1}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Глава ${bookmark.chapterIndex + 1}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () =>
            bloc.add(ReaderBookmarkDeleted(bookmark.id)),
        tooltip: 'Удалить закладку',
      ),
      onTap: () {
        bloc.add(ReaderBookmarkJumped(bookmark));
        Navigator.pop(context);
      },
    );
  }
}