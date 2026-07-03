sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Ошибка работы с базой данных
class DatabaseFailure extends Failure {
  const DatabaseFailure() : super('Ошибка базы данных');
}

/// Ошибка файловой системы (файл не найден, нет доступа)
class FileFailure extends Failure {
  const FileFailure() : super('Ошибка файловой системы');
}

/// Ошибка парсинга книги (битый файл, неподдерживаемый формат)
class ParseFailure extends Failure {
  const ParseFailure() : super('Ошибка парсинга книги');
}

/// Неподдерживаемый формат файла
class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure() : super('Неподдерживаемый формат файла');
}

/// Пользователь отменил действие (например, закрыл файловый менеджер)
class CancelledFailure extends Failure {
  const CancelledFailure() : super('Отменено пользователем');
}

/// Неизвестная ошибка
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}