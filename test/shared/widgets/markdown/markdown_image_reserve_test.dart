import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_media_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A raw `github.com/user-attachments/*` URL: unfetchable by construction (it
/// resolves only against a browser session cookie), so [MarkdownImage] never
/// opens a socket for one. That makes it the honest subject for testing what
/// the widget reserves BEFORE any byte arrives — no network, no flake.
final _attachment = Uri.parse(
  'https://github.com/user-attachments/assets/'
  '3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
);

/// Vertical padding the block-level branch adds around the box, top + bottom.
const double _blockPadding = 16;

const double _column = 700;

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(
      body: SizedBox(
        width: _column,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

void main() {
  setUp(() {
    MarkdownMediaMetrics.reset();
    resetMarkdownMediaPayloadCache();
  });

  testWidgets('a pending attachment reserves the box its image will fill', (
    tester,
  ) async {
    // The regression: a screenshot loaded through a 20px spinner and then
    // snapped to ~350px, shoving the rest of the description down the page —
    // and did it again when the refreshed JWT reset the widget. Once the shape
    // is known, every state has to hold that exact box.
    MarkdownMediaMetrics.record(_attachment, const Size(1400, 700));

    await tester.pumpWidget(_app(MarkdownImage(uri: _attachment)));
    await tester.pump();

    final expected = resolveMarkdownImageBox(
      hint: const ImageDimensionHint(),
      intrinsic: const Size(1400, 700),
      cappedWidth: _column,
    );
    expect(expected.height, 350);

    final size = tester.getSize(find.byType(MarkdownImage));
    expect(size.width, expected.width);
    expect(size.height, expected.height! + _blockPadding);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an unmeasured attachment reserves a content box, not a spinner', (
    tester,
  ) async {
    await tester.pumpWidget(_app(MarkdownImage(uri: _attachment)));
    await tester.pump();

    final height = tester.getSize(find.byType(MarkdownImage)).height;
    // The default aspect at this column width, plus the block padding. What
    // matters is that it is a screenshot-shaped hole rather than the 28px strip
    // a bare spinner reserved.
    expect(height, closeTo(_column * (9 / 16) + _blockPadding, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the failure card inherits the reserved box', (tester) async {
    // A failure that resizes the page is the same defect as a load that
    // resizes it. After the grace period the deferred image gives up, and the
    // open-in-browser card has to take over the geometry rather than impose
    // its own 140px strip.
    MarkdownMediaMetrics.record(_attachment, const Size(1400, 700));

    await tester.pumpWidget(_app(MarkdownImage(uri: _attachment)));
    await tester.pump();
    final reserved = tester.getSize(find.byType(MarkdownImage));

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.byType(MarkdownAttachmentCard), findsOneWidget);
    expect(tester.getSize(find.byType(MarkdownImage)), reserved);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a raw attachment asks the host to splice a usable URL', (
    tester,
  ) async {
    // It used to learn this by FETCHING: the request came back as GitHub's
    // sign-in page, threw, painted the failure card and only then asked for the
    // refresh. Three of the four layout passes were known to be pointless
    // before the first byte.
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        MarkdownImage(
          uri: _attachment,
          onAttachmentLoadFailed: () => refreshes++,
        ),
      ),
    );
    await tester.pump();

    expect(refreshes, 1);
    // No failure card while the host is still working on it.
    expect(find.byType(MarkdownAttachmentCard), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a host already fetching body_html is not asked again', (
    tester,
  ) async {
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        MarkdownImage(
          uri: _attachment,
          attachmentPending: true,
          onAttachmentLoadFailed: () => refreshes++,
        ),
      ),
    );
    await tester.pump();

    expect(refreshes, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
