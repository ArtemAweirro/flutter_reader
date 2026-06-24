import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/widgets/reader_settings_sheet.dart';
import '../../../settings/presentation/widgets/reader_search_sheet.dart';
import '../bloc/reader_bloc.dart';
import '../widgets/bookmarks_list.dart';
import '../widgets/reader_bars.dart';
import '../widgets/reader_content.dart';

class ReaderPage extends StatelessWidget {
  final int bookId;
  final String filePath;

  const ReaderPage({
    super.key,
    required this.bookId,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReaderBloc>(
      create: (_) => getIt<ReaderBloc>()
        ..add(ReaderOpened(bookId: bookId, filePath: filePath)),
      child: const _ReaderView(),
    );
  }
}

class _ReaderView extends StatefulWidget {
  const _ReaderView();

  @override
  State<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<_ReaderView> with WidgetsBindingObserver {
  bool _barsVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Сохраняем позицию когда приложение уходит в фон
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _savePosition();
    }
  }

  void _savePosition() {
    context
        .read<ReaderBloc>()
        .add(const ReaderPositionSaveRequested());
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    // Скрываем системные бары для иммерсивного чтения
    if (_barsVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderBloc, ReaderState>(
      // Сохраняем позицию при любом изменении главы
      listenWhen: (prev, curr) =>
          prev.position.chapterIndex != curr.position.chapterIndex,
      listener: (context, state) => _savePosition(),
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _savePosition();
            // Восстанавливаем системные бары при выходе
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }
        },
        child: BlocBuilder<ReaderBloc, ReaderState>(
          builder: (context, state) {
            return Scaffold(
              appBar: _barsVisible
                  ? ReaderTopBar(
                      onBookmarksPressed: () => BookmarksList.show(context),
                      onSettingsPressed: () => _showSettings(context),
                      onSearchPressed: () => ReaderSearchSheet.show(context),
                    )
                  : null,
              body: _buildBody(context, state),
              bottomNavigationBar:
                  _barsVisible ? const ReaderBottomBar() : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReaderState state) {
    return switch (state.status) {
      ReaderStatus.initial || ReaderStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      ReaderStatus.failure => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(state.errorMessage ?? 'Ошибка загрузки книги'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      ReaderStatus.success => GestureDetector(
          onTap: _toggleBars,
          child: BlocBuilder<SettingsBloc, SettingsState>(
            buildWhen: (prev, curr) =>
                prev.fontSize != curr.fontSize ||
                prev.scrollDirection != curr.scrollDirection ||
                prev.brightness != curr.brightness ||
                prev.contrast != curr.contrast,
            builder: (context, settings) {
              return ReaderContent(
                fontSize: settings.fontSize,
                scrollDirection: settings.scrollDirection,
                brightness: settings.brightness,
                contrast: settings.contrast,
              );
            },
          ),
        ),
    };
  }

  void _showSettings(BuildContext context) {
    ReaderSettingsSheet.show(context);
  }
}
