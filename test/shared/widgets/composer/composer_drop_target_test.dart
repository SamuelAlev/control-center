import 'package:control_center/shared/widgets/composer/attachments/composer_drop_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  // Conversation tabs keep their composers alive behind an IndexedStack, laid
  // out at the same spot. A host drop matched every one of them by bounds, so
  // a screenshot dropped on the visible conversation showed up in the drafts
  // of all the others too.
  testWidgets('a host drop lands only in the visible composer', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final received = <String, int>{'shown': 0, 'hidden': 0};
    Widget target(String name) => ComposerDropTarget(
      onDrop: (drop) async => received[name] = received[name]! + 1,
      child: const SizedBox(width: 300, height: 120),
    );
    await tester.pumpWidget(
      testWrap(
        Center(
          child: IndexedStack(children: [target('shown'), target('hidden')]),
        ),
      ),
    );

    final at = tester.getCenter(find.byType(ComposerDropTarget).first);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'com.controlcenter/filedrop',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('drop', {
          'viewId': tester.view.viewId,
          'x': at.dx,
          'y': at.dy,
          'paths': const <String>[],
          'images': [
            Uint8List.fromList(const [0x89, 0x50, 0x4e, 0x47]),
          ],
        }),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(received, {'shown': 1, 'hidden': 0});
  });
}
