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
}
