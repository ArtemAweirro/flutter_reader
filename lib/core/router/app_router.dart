import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_reader/features/book_list/presentation/pages/book_list_page.dart';


/// Имена маршрутов
abstract class AppRoutes {
  static const bookList = '/';
  static const reader = '/reader/:bookId';

  /// Хелпер для навигации к читалке
  static String readerPath(int bookId) => '/reader/$bookId';
}

@singleton
class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.bookList,
    debugLogDiagnostics: true,   // TODO убрать в release-сборке
    routes: [
      GoRoute(
        path: AppRoutes.bookList,
        name: 'book_list',
        builder: (context, state) => const BookListPage(),
      ),
      GoRoute(
        path: AppRoutes.reader,
        name: 'reader',
        builder: (context, state) {
          final bookId = int.parse(state.pathParameters['bookId']!);
          return _ReaderPlaceholder(bookId: bookId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Страница не найдена: ${state.error}')),
    ),
  );
}

// ---------------------------------------------------------------------------
// Временные заглушки
// ---------------------------------------------------------------------------

class _ReaderPlaceholder extends StatelessWidget {
  final int bookId;
  const _ReaderPlaceholder({required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Книга #$bookId')),
      body: const Center(child: Text('Читалка — скоро здесь')),
    );
  }
}