import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/utils/app_theme.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  // Инициализируем SharedPreferences до регистрации в DI
  final prefs = await SharedPreferences.getInstance();
  // Регистрируем вручную, т.к. SharedPreferences требует async-инициализацию
  getIt.registerSingleton<SharedPreferences>(prefs);
 
  // Запускаем кодогенерированный DI-граф
  await configureDependencies();
 
  runApp(const ReaderApp());
}

class ReaderApp extends StatelessWidget {
  const ReaderApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    // SettingsBloc живёт на уровне всего приложения —
    // управляет темой, поэтому должен быть выше MaterialApp.
    return BlocProvider<SettingsBloc>(
      create: (_) => getIt<SettingsBloc>()..add(const SettingsLoaded()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        // Перестраиваем только при изменении themeMode
        buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'Reader',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            routerConfig: getIt<AppRouter>().router,
          );
        },
      ),
    );
  }
}
