import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reader/features/book_list/presentation/bloc/book_list_bloc.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookListBloc, BookListState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: state.filter == BookFilter.all,
                  onSelected: () {
                    context.read<BookListBloc>().add(
                      const BookFilterChanged(BookFilter.all),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Избранное',
                  selected: state.filter == BookFilter.favorites,
                  onSelected: () {
                    context.read<BookListBloc>().add(
                      const BookFilterChanged(BookFilter.favorites),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Прочитано',
                  selected: state.filter == BookFilter.read,
                  onSelected: () {
                    context.read<BookListBloc>().add(
                      const BookFilterChanged(BookFilter.read),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
