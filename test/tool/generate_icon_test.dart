// Run with: flutter test test/tool/generate_icon_test.dart
// Writes 7 PNG files to macos/Runner/Assets.xcassets/AppIcon.appiconset/

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('generate app icon PNGs', () async {
    final master = await _render1024();
    const outDir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';

    for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
      final output = size == 1024
          ? master
          : img.copyResize(master, width: size, height: size, interpolation: img.Interpolation.cubic);
      await File('$outDir/app_icon_$size.png').writeAsBytes(img.encodePng(output));
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

/// Renders the 1024×1024 master icon using dart:ui.
Future<img.Image> _render1024() async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Dark rounded-square background
  final bgPaint = ui.Paint()..color = const ui.Color(0xFF111111);
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size, size),
      const ui.Radius.circular(224), // ~22% of 1024
    ),
    bgPaint,
  );

  // Subtle top-left highlight
  final gradPaint = ui.Paint()
    ..shader = ui.Gradient.linear(ui.Offset.zero, ui.Offset(size, size), [
      const ui.Color(0x22FFFFFF),
      const ui.Color(0x00000000),
    ]);
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(0, 0, size, size), const ui.Radius.circular(224)),
    gradPaint,
  );

  // </> glyph — coordinates from 32-unit viewport scaled ×32
  const s = 32.0;
  final glyphPaint = ui.Paint()
    ..color = const ui.Color(0xFF4EC9B0)
    ..strokeWidth = 2.2 * s
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke;

  canvas.drawLine(ui.Offset(5 * s, 16 * s), ui.Offset(11 * s, 10 * s), glyphPaint);
  canvas.drawLine(ui.Offset(5 * s, 16 * s), ui.Offset(11 * s, 22 * s), glyphPaint);
  canvas.drawLine(ui.Offset(27 * s, 16 * s), ui.Offset(21 * s, 10 * s), glyphPaint);
  canvas.drawLine(ui.Offset(27 * s, 16 * s), ui.Offset(21 * s, 22 * s), glyphPaint);
  canvas.drawLine(ui.Offset(19 * s, 9 * s), ui.Offset(13 * s, 23 * s), glyphPaint);

  final picture = recorder.endRecording();
  final uiImage = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) throw StateError('canvas toByteData returned null');

  return img.Image.fromBytes(
    width: size.toInt(),
    height: size.toInt(),
    bytes: byteData.buffer,
    format: img.Format.uint8,
    numChannels: 4,
  );
}
