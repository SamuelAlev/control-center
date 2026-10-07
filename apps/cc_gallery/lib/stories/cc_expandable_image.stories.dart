import 'package:cc_gallery/showcase.dart';
import 'package:cc_gallery/stories/support/sample_image.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_expandable_image.stories.g.dart';

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

const component = ComponentMeta(name: 'CcExpandableImage', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcExpandableImagePlayground.new,
);

final $Expandable = _PlaygroundStory(
  args: _PlaygroundArgs(
    width: DoubleArg(
      320,
      name: 'Inline width',
      style: const SliderDoubleArgStyle(min: 120, max: 640, divisions: 65),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccExpandableImageStory(context, args)),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcExpandableImagePlayground {
  CcExpandableImagePlayground({required this.width});

  final double width;
}

/// The affordance in situ: hover the thumbnail to reveal the corner chip, click
/// anywhere on it to open the lightbox.
Widget ccExpandableImageStory(
  BuildContext context,
  CcExpandableImagePlaygroundArgs args,
) {
  final t = context.ds;
  final width = args.width;
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: width * 9 / 16,
          child: const CcExpandableImage(
            labels: sampleImageViewerLabels,
            title: 'sample.png',
            viewerBuilder: _buildViewerSample,
            child: SampleImage(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Hover for the chip · click to expand',
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ],
    ),
  );
}

Widget _buildViewerSample(BuildContext context) =>
    const SampleImage(label: 'sample.png · 2560×1440');
