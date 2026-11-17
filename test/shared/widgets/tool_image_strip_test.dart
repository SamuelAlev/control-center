import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/transcript/widgets/tool_image_strip.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

/// The strip that renders a tool's screenshots in the transcript.
///
/// The behaviour worth pinning is what happens when an image CANNOT be shown.
/// The harness has carried tool-result images to the model since it was
/// written; the transcript used to drop them, so a run that screenshotted every
/// step showed a column of tool calls asserting a screenshot was taken and
/// nothing to look at. An empty gap would reproduce exactly that.
void main() {
  final tokens = DesignSystemTokens.light();

  ToolImageRef ref(String hash) =>
      ToolImageRef(ref: 'blob:sha256:$hash', mediaType: 'image/png');

  group('ToolImageStrip', () {
    testWidgets('renders nothing at all when the tool returned no images', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          ToolImageStrip(images: const [], tokens: tokens, workspaceId: 'ws'),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.textContaining('unavailable'), findsNothing);
    });

    testWidgets('says so when there is no workspace to sign a URL with', (
      tester,
    ) async {
      // Without a workspace there is no signable blob URL. Saying so beats
      // rendering broken frames, and beats an empty gap that is
      // indistinguishable from a tool that returned nothing.
      await tester.pumpWidget(
        testWrap(
          ToolImageStrip(images: [ref('aa'), ref('bb')], tokens: tokens),
        ),
      );
      await tester.pump();

      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('does not reach for global state to find its workspace', (
      tester,
    ) async {
      // It lives in `shared/`, which may not import a feature — and a widget
      // that fetches its own global state is one that cannot be rendered
      // anywhere else, including here.
      await tester.pumpWidget(
        testWrap(
          ToolImageStrip(
            images: [ref('cc')],
            tokens: tokens,
            workspaceId: 'ws-1',
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('decodes a screenshot at the height it is drawn, never at '
        'its own size', (tester) async {
      // A desktop screenshot is tens of megabytes of pixels at its own size,
      // and the strip holds every one it shows for as long as it is on
      // screen. The lightbox is where the whole picture is loaded.
      await tester.pumpWidget(
        testWrap(
          MediaProxyScope(
            config: MediaProxyConfig(
              httpBase: Uri.parse('http://127.0.0.1:1/cap'),
              deviceId: 'device',
              psk: 'psk',
            ),
            child: ToolImageStrip(
              images: [ref('d' * 64)],
              tokens: tokens,
              workspaceId: 'ws-1',
              thumbnailHeight: 100,
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image)).image;
      final ratio = tester.view.devicePixelRatio;
      expect(
        image,
        isA<ResizeImage>()
            .having((i) => i.height, 'height', (100 * ratio).round())
            .having((i) => i.width, 'width', isNull)
            // Only ever down: a small or very wide picture is not enlarged
            // to fill the height.
            .having((i) => i.policy, 'policy', ResizeImagePolicy.fit)
            .having((i) => i.allowUpscaling, 'allowUpscaling', isFalse),
      );
    });
  });
}
