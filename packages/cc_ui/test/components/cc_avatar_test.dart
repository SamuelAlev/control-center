import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcAvatar', () {
    testWidgets('falls back to uppercased initials', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcAvatar(initials: 'sa')));

      expect(find.text('SA'), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('falls back to an icon when no image or initials', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(const CcAvatar(icon: IconData(0x1, fontFamily: 'test'))),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('honors the requested size', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcAvatar(size: 48, initials: 'AB')),
      );

      final box = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(CcAvatar),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, 48);
      expect(box.height, 48);
    });

    testWidgets('renders the image branch and falls back on load error', (
      tester,
    ) async {
      // A bogus MemoryImage triggers ImageFade's errorBuilder, exercising the
      // image decode path (ResizeImage + ImageFade) and the initials fallback.
      await tester.pumpWidget(
        ccTestApp(
          CcAvatar(size: 40, image: MemoryImage(_kBadBytes), initials: 'AB'),
        ),
      );
      // Pump through the image error: errorBuilder renders the initials disc.
      await tester.pumpAndSettle();
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('with no initials/icon renders an empty tinted disc', (
      tester,
    ) async {
      await tester.pumpWidget(ccTestApp(const CcAvatar(size: 32)));
      // No text, no icon — just the colored disc + clip.
      expect(find.byType(Text), findsNothing);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(ColoredBox), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('a custom background fills the disc', (tester) async {
      const bg = Color(0xFF123456);
      await tester.pumpWidget(
        ccTestApp(const CcAvatar(size: 24, background: bg)),
      );
      final disc = tester.widget<ColoredBox>(find.byType(ColoredBox));
      expect(disc.color, bg);
    });
  });
}

// Empty byte buffer — guaranteed to fail image decode so errorBuilder runs.
final Uint8List _kBadBytes = Uint8List(0);
