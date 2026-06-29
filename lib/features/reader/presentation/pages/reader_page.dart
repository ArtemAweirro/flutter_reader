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

/// Ловит сырые pointer events, не участвуя в gesture arena Flutter.
/// Позволяет надёжно различать тап (down→up без move) и скролл (down→move).
class _PointerDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onScroll;

  const _PointerDetector({
    required this.child,
    required this.onTap,
    required this.onScroll,
  });

  @override
  State<_PointerDetector> createState() => _PointerDetectorState();
}

class _PointerDetectorState extends State<_PointerDetector> {
  bool _wasMoved = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _wasMoved = false,
      onPointerMove: (_) => _wasMoved = true,
      onPointerUp: (_) {
        if (_wasMoved) {
          widget.onScroll();
        } else {
          widget.onTap();
        }
      },
      child: widget.child,
    );
  }
}

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

  void _hideBars() {
    setState(() => _barsVisible = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _toggleBars() {
    if (_barsVisible) {
      _hideBars();
    } else {
      setState(() => _barsVisible = true);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    // При любом тапе по экрану сбрасываем подсветку поиска
    context.read<ReaderBloc>().add(const ReaderHighlightCleared());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderBloc, ReaderState>(
      // Сохраняем позицию при любом изменении главы
      listenWhen: (prev, curr) =>
          prev.chapterIndex != curr.chapterIndex,
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
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  _buildBody(context, state),
                  if (_barsVisible)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ReaderTopBar(
                        onBookmarksPressed: () => BookmarksList.show(context),
                        onSettingsPressed: () => _showSettings(context),
                        onSearchPressed: () => ReaderSearchSheet.show(context),
                      ),
                    ),
                  if (_barsVisible)
                    BlocBuilder<SettingsBloc, SettingsState>(
                      buildWhen: (prev, curr) =>
                          prev.scrollDirection != curr.scrollDirection,
                      builder: (context, settings) {
                        if (settings.scrollDirection == Axis.vertical) {
                          return const SizedBox.shrink();
                        }
                        return const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: ReaderBottomBar(),
                        );
                      },
                    ),
                ],
              ),
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
      ReaderStatus.success => _PointerDetector(
          onTap: _toggleBars,
          onScroll: () {
            if (_barsVisible) _hideBars();
          },
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
