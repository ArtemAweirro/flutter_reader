import 'package:flutter/material.dart';
import 'vertical_reader_content.dart';

class ReaderContent extends StatelessWidget {
  final double fontSize;
  final Axis scrollDirection;
  final double brightness;
  final double contrast;

  const ReaderContent({
    super.key,
    required this.fontSize,
    required this.scrollDirection,
    required this.brightness,
    required this.contrast,
  });

  @override
  Widget build(BuildContext context) {
    //if (scrollDirection == Axis.vertical) {
      return VerticalReaderContent(
        fontSize: fontSize,
        brightness: brightness,
        contrast: contrast,
      );
    //}

    // return HorizontalReaderContent(
    //   fontSize: fontSize,
    //   brightness: brightness,
    //   contrast: contrast,
    // );
  }
}

Color applyContrast(Color baseColor, double contrast, Brightness brightness) {
  final target = brightness == Brightness.dark ? Colors.white : Colors.black;
  return Color.lerp(baseColor.withValues(alpha: 0.5), target, contrast)!;
}
