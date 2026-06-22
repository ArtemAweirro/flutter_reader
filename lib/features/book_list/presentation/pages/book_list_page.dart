import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:flutter_reader/core/di/injection.dart';
import 'package:flutter_reader/features/book_list/presentation/bloc/book_list_bloc.dart';
import 'package:flutter_reader/features/book_list/presentation/widgets/book_card.dart';
import 'package:flutter_reader/features/book_list/presentation/widgets/filter_bar.dart';

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
        body: BlocBuilder<BookListBloc, BookListState>(
          builder: (context, state) {
            if (state.isLoading && state.books.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.errorMessage != null && state.books.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const Gap(16),
                    Text(
                      'Ошибка: ${state.errorMessage}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            final book = state.books[index];
                            return BookCard(book: book);
                          },
                        ),
                ),
              ],
            );
          },
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
