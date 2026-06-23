import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:flutter_reader/features/book_list/domain/entities/book.dart';
import 'package:flutter_reader/features/book_list/presentation/bloc/book_list_bloc.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (book.author != null) ...[
                        const Gap(4),
                        Text(
                          book.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    final bloc = context.read<BookListBloc>();
                    switch (value) {
                      case 'delete':
                        bloc.add(BookDeleted(book.id));
                        break;
                      case 'favorite':
                        bloc.add(
                          BookFavoriteToggled(book.id, !book.isFavorite),
                        );
                        break;
                      case 'read':
                        bloc.add(BookReadToggled(book.id, !book.isRead));
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            book.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          const Gap(12),
                          Text(book.isFavorite ? 'Убрать из избранного' : 'Добавить в избранное'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(
                            book.isRead
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                          ),
                          const Gap(12),
                          Text(book.isRead ? 'Отметить как непрочитанное' : 'Отметить как прочитанное'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          Gap(12),
                          Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Chip(
                  label: Text(book.format.toUpperCase()),
                  visualDensity: VisualDensity.compact,
                ),
                const Gap(8),
                if (book.totalPages != null)
                  Chip(
                    label: Text('${book.totalPages} страниц'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (book.readingPosition != null) ...[
              const Gap(8),
              Text(
                'Позиция: ${book.readingPosition}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    )
    );
  }
}
