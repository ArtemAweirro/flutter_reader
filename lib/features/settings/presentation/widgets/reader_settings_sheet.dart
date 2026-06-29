import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../bloc/settings_bloc.dart';

/// Bottom sheet настроек читалки.
/// Открывается из ReaderTopBar по кнопке настроек.
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: const ReaderSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildHandle(context),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: const [
                  _FontSizeSection(),
                  Divider(height: 32),
                  _BrightnessSection(),
                  Divider(height: 32),
                  _ContrastSection(),
                  Divider(height: 32),
                  _ScrollDirectionSection(),
                  Divider(height: 32),
                  _ThemeModeSection(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Text(
            'Настройки чтения',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Размер шрифта
// ---------------------------------------------------------------------------

class _FontSizeSection extends StatelessWidget {
  const _FontSizeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) => prev.fontSize != curr.fontSize,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Размер шрифта',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${state.fontSize.round()} пт',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              children: [
                // Кнопка уменьшения
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: state.fontSize > 10
                      ? () => context
                          .read<SettingsBloc>()
                          .add(FontSizeChanged(state.fontSize - 1))
                      : null,
                ),
                Expanded(
                  child: Slider(
                    value: state.fontSize,
                    min: 10,
                    max: 32,
                    divisions: 22,
                    onChanged: (value) => context
                        .read<SettingsBloc>()
                        .add(FontSizeChanged(value)),
                  ),
                ),
                // Кнопка увеличения
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: state.fontSize < 32
                      ? () => context
                          .read<SettingsBloc>()
                          .add(FontSizeChanged(state.fontSize + 1))
                      : null,
                ),
              ],
            ),
            // Превью текста
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Пример текста книги',
                style: TextStyle(fontSize: state.fontSize, height: 1.6),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Яркость
// ---------------------------------------------------------------------------

class _BrightnessSection extends StatelessWidget {
  const _BrightnessSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) => prev.brightness != curr.brightness,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Яркость',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${(state.brightness * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.brightness_low),
                Expanded(
                  child: Slider(
                    value: state.brightness,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) => context
                        .read<SettingsBloc>()
                        .add(BrightnessChanged(value)),
                  ),
                ),
                const Icon(Icons.brightness_high),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Контрастность
// ---------------------------------------------------------------------------

class _ContrastSection extends StatelessWidget {
  const _ContrastSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) => prev.contrast != curr.contrast,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Контрастность',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${(state.contrast * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.contrast),
                Expanded(
                  child: Slider(
                    value: state.contrast,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (value) => context
                        .read<SettingsBloc>()
                        .add(ContrastChanged(value)),
                  ),
                ),
                const Icon(Icons.contrast, color: Colors.black),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Направление скролла
// ---------------------------------------------------------------------------

class _ScrollDirectionSection extends StatelessWidget {
  const _ScrollDirectionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) => prev.scrollDirection != curr.scrollDirection,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Направление скролла',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Gap(12),
            SegmentedButton<Axis>(
              segments: const [
                ButtonSegment(
                  value: Axis.vertical,
                  label: Text('Вертикальный'),
                  icon: Icon(Icons.swap_vert),
                ),
                ButtonSegment(
                  value: Axis.horizontal,
                  label: Text('Горизонтальный'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {state.scrollDirection},
              onSelectionChanged: (value) => context
                  .read<SettingsBloc>()
                  .add(ScrollDirectionChanged(value.first)),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Тема приложения
// ---------------------------------------------------------------------------

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тема',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Gap(12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Светлая'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Система'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Тёмная'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (value) => context
                  .read<SettingsBloc>()
                  .add(ThemeModeChanged(value.first)),
            ),
          ],
        );
      },
    );
  }
}