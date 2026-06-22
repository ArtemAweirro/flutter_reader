sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Ошибка работы с базой данных
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Ошибка файловой системы (файл не найден, нет доступа)
class FileFailure extends Failure {
  const FileFailure(super.message);
}

/// Ошибка парсинга книги (битый файл, неподдерживаемый формат)
class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// Пользователь отменил действие (например, закрыл файловый менеджер)
class CancelledFailure extends Failure {
  const CancelledFailure() : super('Cancelled by user');
}

/// Неизвестная ошибка
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}