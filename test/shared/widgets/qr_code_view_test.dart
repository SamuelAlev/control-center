import 'dart:ui' as ui;

import 'package:control_center/shared/widgets/qr_code_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';

void main() {
  const data = 'https://example.test/#eyJzIjoid3NzOi8vaG9zdCIsImkiOiJkZXYifQ';

  testWidgets('sizes the code to the requested edge', (tester) async {
    await tester.pumpWidget(
      const Center(child: QrCodeView(data: data, size: 180)),
    );

    expect(tester.getSize(find.byType(QrCodeView)), const Size(180, 180));
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(QrCodeView),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.painter, isA<QrCodePainter>());
  });

  test('paints every module the encoder marks dark, and only those', () async {
    final image = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.low,
      ),
    );
    const modulePx = 4;
    final edge = image.moduleCount * modulePx;

    final recorder = ui.PictureRecorder();
    QrCodePainter(
      image: image,
      foregroundColor: const Color(0xFF000000),
      backgroundColor: const Color(0xFFFFFFFF),
    ).paint(Canvas(recorder), Size.square(edge.toDouble()));
    final raster = await recorder.endRecording().toImage(edge, edge);
    final bytes = (await raster.toByteData())!;

    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        final x = col * modulePx + modulePx ~/ 2;
        final y = row * modulePx + modulePx ~/ 2;
        final red = bytes.getUint8((y * edge + x) * 4);
        expect(red == 0, image.isDark(row, col), reason: 'module ($row, $col)');
      }
    }
  });
}
