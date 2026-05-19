import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every embedded markdown image is painted with `BoxFit.contain` over a
/// placeholder that stays behind the frame for the widget's whole life
/// (`ImageFade` keeps it in the Stack), so a box that does not match the
/// image's aspect ratio shows as coloured bands around it.
///
/// The regression this pins: a PR body carrying GitHub's own
/// `<img width="1976" height="726">` laid out in an 800x600 box — the width
/// clamped to the column while the height kept the raw attribute — and the
/// 2.72:1 screenshot letterboxed with ~118px of `surfaceContainerHighest`
/// above and below.
void main() {
  const column = 800.0;

  group('resolveMarkdownImageBox', () {
    test('a clamped width scales the height with it — no letterbox', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(width: 1976, height: 726),
        intrinsic: const Size(1976, 726),
        cappedWidth: column,
      );

      expect(box.width, column);
      expect(box.height, closeTo(column * 726 / 1976, 0.01));
      // The box IS the image: contain has no slack to fill.
      expect(box.width / box.height!, closeTo(1976 / 726, 0.001));
    });

    test('a declared height is never the box height on its own', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(width: 1976, height: 726),
        intrinsic: const Size(1976, 726),
        cappedWidth: column,
      );

      expect(box.height, isNot(726));
      expect(box.height, lessThan(_kLetterboxedHeight));
    });

    test('measured bytes win over a declared pair that disagrees', () {
      // The proxy downscaled the raster; the attributes still name the
      // original. Aspect must come from the bytes we hold.
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(width: 1976, height: 726),
        intrinsic: const Size(1600, 588),
        cappedWidth: column,
      );

      expect(box.width / box.height!, closeTo(1600 / 588, 0.001));
    });

    test('a tall image is capped by scaling both axes, not pillarboxed', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(),
        intrinsic: const Size(1200, 3000),
        cappedWidth: column,
      );

      expect(box.height, 600);
      expect(box.width, closeTo(600 * 1200 / 3000, 0.01));
      expect(box.width / box.height!, closeTo(1200 / 3000, 0.001));
    });

    test('an un-hinted badge keeps its intrinsic size', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(),
        intrinsic: const Size(120, 20),
        cappedWidth: column,
      );

      expect(box.width, 120);
      expect(box.height, closeTo(20, 0.01));
    });

    test('a height-only hint derives its width from the aspect', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(height: 300),
        intrinsic: const Size(1000, 500),
        cappedWidth: column,
      );

      expect(box.width, closeTo(600, 0.01));
      expect(box.height, closeTo(300, 0.01));
    });

    test('a percentage width still resolves a proportional height', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(widthPercent: 0.5),
        intrinsic: const Size(1000, 400),
        cappedWidth: column,
      );

      expect(box.width, 400);
      expect(box.height, closeTo(160, 0.01));
    });

    test('nothing knows the aspect — the image sizes itself', () {
      final box = resolveMarkdownImageBox(
        hint: const ImageDimensionHint(),
        intrinsic: null,
        cappedWidth: column,
      );

      expect(box.width, column);
      expect(box.height, isNull);
    });
  });
}

/// The height the buggy box pinned itself to (the `maxHeight` cap), which the
/// 2.72:1 screenshot then letterboxed inside.
const double _kLetterboxedHeight = 600;
