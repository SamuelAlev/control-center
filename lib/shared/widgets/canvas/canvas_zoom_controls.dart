import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The inset every canvas places its zoom controls at, so the three node
/// canvases put the same control in the same corner.
const double kCanvasControlInset = AppSpacing.lg;

/// The floating zoom control shared by the app's node canvases — the plan
/// studio DAG, the memory knowledge graph and the agent org chart.
///
/// ## Why this exists
///
/// Every canvas was navigable by gesture ALONE: drag to pan, pinch or
/// ⌘-scroll to zoom. That is a discoverability floor, not a design — a
/// trackpad pinch is invisible until someone tries it, a mouse has no pinch at
/// all, and a canvas that has drifted to 4× with its content off-screen offers
/// no way back except more of the same gesture. So each canvas now carries a
/// visible stack: in, out, and a reset that puts the content back on screen.
///
/// It is deliberately three buttons and no zoom percentage. The number is a
/// readout nobody acts on; what a reader wants is "closer", "further" and
/// "put it back", and a percentage between the buttons would push the reset
/// out of thumb reach on the phone remote.
class CanvasZoomControls extends StatelessWidget {
  /// Creates a [CanvasZoomControls].
  const CanvasZoomControls({
    super.key,
    required this.controller,
    required this.viewport,
    required this.onReset,
    this.minScale = 0.25,
    this.maxScale = 4.0,
    this.step = 1.25,
    this.resetTooltip,
  });

  /// The canvas transform this drives. The controls write it directly rather
  /// than going through the viewer, the same way each canvas's own wheel
  /// handling already does.
  final TransformationController controller;

  /// The canvas viewport, needed to zoom about its centre rather than about
  /// the scene origin — zooming about the origin walks the content off screen,
  /// which is the failure the reset button then has to undo.
  ///
  /// Read when a button is PRESSED, not when this widget is built, and that is
  /// the whole point of the callback. A canvas measures its viewport inside a
  /// `LayoutBuilder`, which runs during layout — *after* the frame in which
  /// this control was built. Passing the `Size` itself therefore froze
  /// `Size.zero` in on the first build, and since fitting the content only
  /// mutates the transform (never the host's widget state) nothing forced a
  /// later rebuild: every press hit the empty-viewport guard and both zoom
  /// buttons silently did nothing for the whole session. Whether a canvas got
  /// away with it came down to whether some unrelated provider happened to
  /// rebuild it after layout.
  final ValueGetter<Size> viewport;

  /// Puts the content back: each canvas defines its own "back" (fit the graph,
  /// recentre, identity), so the host owns it.
  final VoidCallback onReset;

  /// Zoom floor. Match the host viewer's `minScale`, or the buttons will offer
  /// a zoom the viewer snaps back on the next drag.
  final double minScale;

  /// Zoom ceiling. Match the host viewer's `maxScale`.
  final double maxScale;

  /// Multiplier per press.
  final double step;

  /// Overrides the reset button's tooltip (defaults to "Fit to view").
  final String? resetTooltip;

  /// Scales about the centre of [viewport], leaving the scene point under the
  /// centre exactly where it is.
  void _zoomBy(double factor) {
    final current = controller.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(minScale, maxScale);
    final box = viewport();
    if ((target - current).abs() < 1e-6 || box.isEmpty) {
      return;
    }
    final centre = Offset(box.width / 2, box.height / 2);
    final anchor = controller.toScene(centre);
    controller.value = Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..scaleByDouble(target, target, target, 1)
      ..translateByDouble(-anchor.dx, -anchor.dy, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scale = controller.value.getMaxScaleOnAxis();
        return DecoratedBox(
          decoration: ShapeDecoration(
            color: tokens.bgPrimary,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: tokens.borderSecondary),
              borderRadius: AppRadii.brMd,
            ),
            // It floats over the canvas, so it takes the design system's
            // floating elevation rather than a hand-rolled drop shadow.
            shadows: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CcIconButton(
                icon: AppIcons.plus,
                tooltip: l10n.zoomIn,
                semanticLabel: l10n.zoomIn,
                // Disabled at the ceiling rather than silently doing nothing:
                // a button that responds to nothing is indistinguishable from
                // one that is broken.
                onPressed: scale >= maxScale - 1e-6
                    ? null
                    : () => _zoomBy(step),
              ),
              const CcDivider(),
              CcIconButton(
                icon: AppIcons.minus,
                tooltip: l10n.zoomOut,
                semanticLabel: l10n.zoomOut,
                onPressed: scale <= minScale + 1e-6
                    ? null
                    : () => _zoomBy(1 / step),
              ),
              const CcDivider(),
              CcIconButton(
                icon: AppIcons.maximize2,
                tooltip: resetTooltip ?? l10n.fitToView,
                semanticLabel: resetTooltip ?? l10n.fitToView,
                onPressed: onReset,
              ),
            ],
          ),
        );
      },
    );
  }
}
