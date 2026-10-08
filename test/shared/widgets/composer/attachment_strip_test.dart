import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  // A pasted screenshot arrives as bytes. Hovering rebuilds the card, and a
  // fresh MemoryImage per build missed the image cache, so the thumbnail
  // blanked while it decoded again.
  testWidgets('hovering a picture card keeps its thumbnail image', (
    tester,
  ) async {
    const attachment = ComposerAttachment(
      id: 'a1',
      kind: 'image',
      label: 'shot.png',
      mimeType: 'image/png',
      bytes: [0x89, 0x50, 0x4e, 0x47],
    );
    await tester.pumpWidget(
      testWrap(
        AttachmentStrip(attachments: const [attachment], onRemove: (_) {}),
      ),
    );
    ImageProvider provider() => tester.widget<Image>(find.byType(Image)).image;
    final before = provider();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('shot.png')));
    await tester.pump();
    await mouse.moveTo(Offset.zero);
    await tester.pump();

    expect(identical(provider(), before), isTrue);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.gaplessPlayback, isTrue);
  });

  group('overflowing cards scroll', () {
    final attachments = [
      for (var i = 0; i < 8; i++)
        ComposerAttachment(id: 'a$i', kind: 'file', label: 'file_$i.txt'),
    ];

    Future<ScrollPosition> pumpStrip(
      WidgetTester tester, {
      TextDirection? textDirection,
    }) async {
      await tester.pumpWidget(
        testWrap(
          Center(
            child: SizedBox(
              width: 400,
              child: AttachmentStrip(
                attachments: attachments,
                onRemove: (_) {},
              ),
            ),
          ),
          textDirection: textDirection,
        ),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(position.pixels, 0);
      return position;
    }

    // Desktop scrollables ignore mouse drags by default, which left every card
    // past the third unreachable without a trackpad.
    testWidgets('a mouse drag scrolls the row', (tester) async {
      final position = await pumpStrip(tester);
      await tester.dragFrom(
        tester.getCenter(find.byType(AttachmentStrip)),
        const Offset(-200, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
    });

    testWidgets('a vertical wheel scrolls the row sideways', (tester) async {
      final position = await pumpStrip(tester);
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      final center = tester.getCenter(find.byType(AttachmentStrip));
      await tester.sendEventToBinding(mouse.hover(center));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 120)));
      await tester.pump();
      expect(position.pixels, 120);

      await tester.sendEventToBinding(mouse.scroll(const Offset(0, -500)));
      await tester.pump();
      expect(position.pixels, 0);
    });

    testWidgets('a vertical wheel scrolls toward the end under RTL', (
      tester,
    ) async {
      final position = await pumpStrip(
        tester,
        textDirection: TextDirection.rtl,
      );
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      final center = tester.getCenter(find.byType(AttachmentStrip));
      await tester.sendEventToBinding(mouse.hover(center));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 120)));
      await tester.pump();
      expect(position.pixels, 120);
      expect(position.axisDirection, AxisDirection.left);
    });
  });
}
