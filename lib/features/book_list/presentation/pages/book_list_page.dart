import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reader/core/di/injection.dart';
import 'package:flutter_reader/core/router/app_router.dart';
import 'package:flutter_reader/features/book_list/presentation/bloc/book_list_bloc.dart';
import 'package:flutter_reader/features/book_list/presentation/widgets/book_card.dart';
import 'package:flutter_reader/features/book_list/presentation/widgets/filter_bar.dart';
import 'package:go_router/go_router.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  late BookListBloc _bookListBloc;

  @override
  void initState() {
    super.initState();
    _bookListBloc = getIt<BookListBloc>();
    _bookListBloc.add(const BookListInit());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookListBloc>.value(
      value: _bookListBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои книги'),
          elevation: 0,
        ),
        body: BlocListener<BookListBloc, BookListState>(
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.grey.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _bookListBloc.add(const ErrorCleared());
            }
          },
          child: BlocBuilder<BookListBloc, BookListState>(
            builder: (context, state) {
              if (state.isLoading && state.books.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Column(
                children: [
                  const FilterBar(),
                  Expanded(
                    child: state.books.isEmpty
                        ? Center(
                            child: Text(
                              'Книги не найдены',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : state.filter == BookFilter.all
                            ? ReorderableListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: state.books.length,
                                itemBuilder: (context, index) {
                                  final book = state.books[index];
                                  return BookCard(
                                    key: ValueKey(book.id),
                                    book: book,
                                    onTap: () => context.push(
                                        AppRoutes.readerPath(
                                            book.id, book.filePath)),
                                  );
                                },
                                onReorder: (oldIndex, newIndex) {
                                  context
                                      .read<BookListBloc>()
                                      .add(BookReordered(oldIndex, newIndex));
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: state.books.length,
                                itemBuilder: (context, index) {
                                  final book = state.books[index];
                                  return BookCard(
                                    key: ValueKey(book.id),
                                    book: book,
                                    onTap: () => context.push(
                                        AppRoutes.readerPath(
                                            book.id, book.filePath)),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _bookListBloc.add(const BookAddedFromFile());
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bookListBloc.close();
    super.dispose();
  }
}
