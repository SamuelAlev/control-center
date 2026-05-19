import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_mark_inlining.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// Every engine ships TWO logos: `<engine>_color.svg`, the vendor's own
// artwork, and `<engine>.svg`, the flat silhouette a tinted label wants. Both
// are rendered from the asset bundle, which widget tests never populate, so
// nothing else would notice a truncated or garbled file — BrowserEngineLogo
// would quietly degrade every engine to the same globe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  File assetFor(RigBrowserEngine engine, {required bool color}) =>
      File('assets/browser_logos/${engine.wire}${color ? '_color' : ''}.svg');

  test('both variants exist and survive the vector compiler', () async {
    for (final engine in RigBrowserEngine.values) {
      for (final color in [false, true]) {
        final file = assetFor(engine, color: color);
        expect(
          file.existsSync(),
          isTrue,
          reason: '${file.path} is a path BrowserEngineLogo renders',
        );
        final bytes = await SvgStringLoader(
          file.readAsStringSync(),
        ).loadBytes(null);
        expect(
          bytes.lengthInBytes,
          greaterThan(0),
          reason: '${file.path} must survive the vector compiler',
        );
      }
    }
  });

  // A logo with no viewBox does not scale: it renders the top-left N units of
  // its own coordinate space and everything else is clipped away. Firefox's
  // official file ships width/height only, and at 14px that is a grey corner
  // rather than a fox — a failure that looks like a rendering bug, not a
  // missing attribute.
  test('every logo declares a viewBox, or it cannot be drawn small', () {
    for (final engine in RigBrowserEngine.values) {
      for (final color in [false, true]) {
        final file = assetFor(engine, color: color);
        expect(
          file.readAsStringSync(),
          contains('viewBox="'),
          reason: '${file.path} is drawn at 14px in the tab strip',
        );
      }
    }
  });

  // The guest's new-tab page cannot read a Flutter asset — it is written into
  // a VM — so the same artwork has to exist as a Dart const too. Two copies of
  // a logo is exactly how the boot screen and the page it settles into came to
  // show different marks, so the const is GENERATED from the asset and this
  // re-derives it rather than trusting whoever edits one to remember the
  // other.
  test('the generated marks are the colour assets, freshly derived', () {
    for (final engine in RigBrowserEngine.values) {
      expect(
        browserRigEngineMark(engine),
        inlineBrowserMark(assetFor(engine, color: true).readAsStringSync()),
        reason:
            '${engine.wire}_color.svg changed without the generator running — '
            'fvm dart run tool/gen_browser_marks.dart',
      );
    }
  });

  // A standalone .svg file needs the namespace; the guest page must NOT have
  // one, because that page is pinned free of every `http` substring (an xmlns
  // is one) so it provably depends on nothing external.
  test('the inlined marks drop the namespace the files carry', () {
    for (final engine in RigBrowserEngine.values) {
      expect(browserRigEngineMark(engine), isNot(contains('xmlns')));
      expect(browserRigEngineMark(engine), isNot(contains('http')));
      for (final color in [false, true]) {
        expect(
          assetFor(engine, color: color).readAsStringSync(),
          contains('xmlns='),
        );
      }
    }
  });
}
