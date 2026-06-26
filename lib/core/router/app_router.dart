import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_reader/features/book_list/presentation/pages/book_list_page.dart';
import 'package:flutter_reader/features/reader/presentation/pages/reader_page.dart';


/// Имена маршрутов
abstract class AppRoutes {
  static const bookList = '/';
  static const reader = '/reader/:bookId';

  /// Хелпер для навигации к читалке
  static String readerPath(int bookId, String filePath) =>
      '/reader/$bookId?filePath=${Uri.encodeComponent(filePath)}';
}

@singleton
class AppRouter {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.bookList,
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
          final filePath = state.uri.queryParameters['filePath'] ?? '';
          return ReaderPage(bookId: bookId, filePath: filePath);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Страница не найдена: ${state.error}')),
    ),
  );
}
