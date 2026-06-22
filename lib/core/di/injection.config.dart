// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/settings/presentation/bloc/settings_bloc.dart' as _i585;
import '../database/app_database.dart' as _i982;
import '../database/books_dao.dart' as _i864;
import '../database/reader_dao.dart' as _i1016;
import '../router/app_router.dart' as _i81;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i982.AppDatabase>(() => _i982.AppDatabase());
    gh.singleton<_i81.AppRouter>(() => _i81.AppRouter());
    gh.factory<_i864.BooksDao>(() => _i864.BooksDao(gh<_i982.AppDatabase>()));
    gh.factory<_i1016.ReaderDao>(
      () => _i1016.ReaderDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i585.SettingsBloc>(
      () => _i585.SettingsBloc(gh<_i460.SharedPreferences>()),
    );
    return this;
  }
}
