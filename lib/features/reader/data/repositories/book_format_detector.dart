import 'package:injectable/injectable.dart';

@injectable
class BookFormatDetector {
  BookFormat detect(String filePath) {
    final lower = filePath.toLowerCase();

    if (lower.endsWith('.epub')) {
      return BookFormat.epub;
    }

    if (lower.endsWith('.fb2')) {
      return BookFormat.fb2;
    }

    if (lower.endsWith('.pdf')) {
      return BookFormat.pdf;
    }

    return BookFormat.unknown;
  }
}

enum BookFormat {
  epub,
  fb2,
  pdf,
  unknown,
}