import 'package:equatable/equatable.dart';

class ReadingPosition extends Equatable {
  final int charOffset;

  const ReadingPosition({this.charOffset = 0});

  ReadingPosition copyWith({int? charOffset}) =>
      ReadingPosition(charOffset: charOffset ?? this.charOffset);

  String toStorageString() => '$charOffset';

  factory ReadingPosition.fromStorageString(String s) =>
      ReadingPosition(charOffset: int.tryParse(s) ?? 0);

  factory ReadingPosition.start() => const ReadingPosition();

  @override
  List<Object?> get props => [charOffset];
}
