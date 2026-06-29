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
                      return _BookmarkTile(
                        bookmark: bookmark,
                      );
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
              showDialog(
                context: context,
                builder: (dialogContext) => _BookmarkAddDialog(
                  onConfirm: (label) {
                    context
                        .read<ReaderBloc>()
                        .add(ReaderBookmarkAdded(label: label));
                    Navigator.pop(context); // close bottom sheet
                  },
                ),
              );
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

class _BookmarkAddDialog extends StatefulWidget {
  final void Function(String label) onConfirm;

  const _BookmarkAddDialog({required this.onConfirm});

  @override
  State<_BookmarkAddDialog> createState() => _BookmarkAddDialogState();
}

class _BookmarkAddDialogState extends State<_BookmarkAddDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая закладка'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Описание закладки',
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onConfirm(value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              widget.onConfirm(text);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarkEntity bookmark;

  const _BookmarkTile({
    required this.bookmark,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReaderBloc>();

    return ListTile(
      leading: const Icon(Icons.bookmark),
      title: Text(
        bookmark.label ?? 'Закладка',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => bloc.add(ReaderBookmarkDeleted(bookmark.id)),
        tooltip: 'Удалить закладку',
      ),
      onTap: () {
        bloc.add(ReaderBookmarkJumped(bookmark));
        Navigator.pop(context);
      },
    );
  }
}
