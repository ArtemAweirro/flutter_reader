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

import '../../features/book_list/data/datasources/book_picker_service.dart'
    as _i265;
import '../../features/book_list/data/repositories/book_repository_impl.dart'
    as _i149;
import '../../features/book_list/domain/repositories/book_repository.dart'
    as _i689;
import '../../features/book_list/domain/usecases/add_book.dart' as _i155;
import '../../features/book_list/domain/usecases/add_book_from_file.dart'
    as _i867;
import '../../features/book_list/domain/usecases/delete_book.dart' as _i90;
import '../../features/book_list/domain/usecases/get_books.dart' as _i1031;
import '../../features/book_list/domain/usecases/toggle_favorite.dart' as _i386;
import '../../features/book_list/domain/usecases/toggle_read.dart' as _i1040;
import '../../features/book_list/presentation/bloc/book_list_bloc.dart'
    as _i897;
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
    gh.factory<_i265.BookPickerService>(() => _i265.BookPickerService());
    gh.singleton<_i982.AppDatabase>(() => _i982.AppDatabase());
    gh.singleton<_i81.AppRouter>(() => _i81.AppRouter());
    gh.factory<_i864.BooksDao>(() => _i864.BooksDao(gh<_i982.AppDatabase>()));
    gh.factory<_i1016.ReaderDao>(
      () => _i1016.ReaderDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i689.BookRepository>(
      () => _i149.BookRepositoryImpl(gh<_i864.BooksDao>()),
    );
    gh.factory<_i585.SettingsBloc>(
      () => _i585.SettingsBloc(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i867.AddBookFromFile>(
      () => _i867.AddBookFromFile(
        gh<_i689.BookRepository>(),
        gh<_i265.BookPickerService>(),
      ),
    );
    gh.factory<_i155.AddBook>(() => _i155.AddBook(gh<_i689.BookRepository>()));
    gh.factory<_i90.DeleteBook>(
      () => _i90.DeleteBook(gh<_i689.BookRepository>()),
    );
    gh.factory<_i1031.GetBooks>(
      () => _i1031.GetBooks(gh<_i689.BookRepository>()),
    );
    gh.factory<_i386.ToggleFavorite>(
      () => _i386.ToggleFavorite(gh<_i689.BookRepository>()),
    );
    gh.factory<_i1040.ToggleRead>(
      () => _i1040.ToggleRead(gh<_i689.BookRepository>()),
    );
    gh.factory<_i897.BookListBloc>(
      () => _i897.BookListBloc(
        getBooks: gh<_i1031.GetBooks>(),
        addBook: gh<_i155.AddBook>(),
        addBookFromFile: gh<_i867.AddBookFromFile>(),
        deleteBook: gh<_i90.DeleteBook>(),
        toggleFavorite: gh<_i386.ToggleFavorite>(),
        toggleRead: gh<_i1040.ToggleRead>(),
      ),
    );
    return this;
  }
}
