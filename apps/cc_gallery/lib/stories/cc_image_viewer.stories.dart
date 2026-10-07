import 'package:cc_gallery/showcase.dart';
import 'package:cc_gallery/stories/support/sample_image.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_image_viewer.stories.g.dart';

/// Stories for [CcImageViewer] and [CcExpandableImage] — the product-wide "see
/// this image bigger" pair.
///
/// The thing worth looking at is the CONTRACT between them: the inline
/// rendition is whatever the surface could afford (a column-width decode), the
/// expanded one is the full picture, and scale 1 in the viewer always means
/// "the whole image fits" rather than "one image pixel per screen pixel".
///
/// The sample is painted rather than fetched (see `support/sample_image.dart`).

const _path = '[Components]';

const component = ComponentMeta(name: 'CcImageViewer', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcImageViewerPlayground.new,
);

final $Viewer = _PlaygroundStory(
  args: _PlaygroundArgs(
    maxScale: DoubleArg(
      8,
      name: 'Max scale',
      style: const SliderDoubleArgStyle(min: 2, max: 16, divisions: 14),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccImageViewerStory(context, args)),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcImageViewerPlayground {
  CcImageViewerPlayground({required this.maxScale});

  final double maxScale;
}

/// The viewer body on its own, so the zoom toolbar, the scroll/zoom split and
/// the double-tap toggle can be exercised without a dialog in the way.
///
/// The split is the part worth trying by hand: a plain scroll PANS, and zoom is
/// on ⌥ / ⌘ / Ctrl + scroll — `InteractiveViewer`'s default (wheel always
/// zooms) makes a lightbox lurch under a two-finger flick.
Widget ccImageViewerStory(
  BuildContext context,
  CcImageViewerPlaygroundArgs args,
) {
  final maxScale = args.maxScale;
  return Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: CcImageViewer(
      labels: sampleImageViewerLabels,
      maxScale: maxScale,
      child: const SampleImage(label: 'scroll pans · ⌥scroll zooms · ± · 0'),
    ),
  );
}
