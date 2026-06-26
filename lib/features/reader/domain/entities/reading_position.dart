import 'package:equatable/equatable.dart';

class ReadingPosition extends Equatable {
  final int charOffset;

  const ReadingPosition({this.charOffset = 0});

  ReadingPosition copyWith({int? charOffset}) =>
      ReadingPosition(charOffset: charOffset ?? this.charOffset);

  String toStorageString() => '$charOffset';

  factory ReadingPosition.fromStorageString(String s) {
    final parts = s.split(':');
    return ReadingPosition(charOffset: int.tryParse(parts[0]) ?? 0);
  }

  factory ReadingPosition.start() => const ReadingPosition();

  @override
  List<Object?> get props => [charOffset];
}
