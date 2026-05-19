import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_button.dart';
import 'package:cc_ui/src/components/cc_dialog.dart';
import 'package:cc_ui/src/components/cc_icon_button.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The user-facing strings the image viewer needs.
///
/// cc_ui holds no localizations, so every label is supplied by the host — the
/// same contract [CcIconButton.tooltip] already uses. Bundled into one object
/// because [CcExpandableImage] forwards all of them to the viewer it opens and
/// five loose `String?` parameters at each call site is how a surface ends up
/// with three of them wired and two silently null.
@immutable
class CcImageViewerLabels {
  /// Creates a [CcImageViewerLabels].
  const CcImageViewerLabels({
    required this.expand,
    required this.zoomIn,
    required this.zoomOut,
    required this.resetZoom,
    required this.close,
  });

  /// Names the affordance that opens the viewer (also its accessible name).
  final String expand;

  /// Names the zoom-in control.
  final String zoomIn;

  /// Names the zoom-out control.
  final String zoomOut;

  /// Names the "back to fit" control.
  final String resetZoom;

  /// Names the viewer's close control.
  final String close;

  @override
  bool operator ==(Object other) =>
      other is CcImageViewerLabels &&
      other.expand == expand &&
      other.zoomIn == zoomIn &&
      other.zoomOut == zoomOut &&
      other.resetZoom == resetZoom &&
      other.close == close;

  @override
  int get hashCode => Object.hash(expand, zoomIn, zoomOut, resetZoom, close);
}

/// A pannable, zoomable frame around one visual — the body of the fullscreen
/// image lightbox [showCcImageViewer] presents.
///
/// The child is laid out at the viewer's own size (so hand it something that
/// paints with `BoxFit.contain`) and then transformed, so scale 1 means *the
/// whole image is on screen*, whatever its aspect ratio. That is the resting
/// point, not the floor: [minScale] goes below it, because "show me less of the
/// screen than the frame gives" is a real request — a tall screenshot at fit is
/// still taller than the panel.
///
/// **Scrolling scrolls; it does not zoom.** `InteractiveViewer` hardwires a
/// mouse wheel to zoom with no flag to change it, which makes a lightbox lurch
/// under a two-finger flick. Here a plain wheel or trackpad scroll PANS, and
/// zoom is on ⌥ / ⌘ / Ctrl + scroll. All three modifiers, deliberately: ⌥ is
/// the image-editor convention, ⌘/Ctrl is what the app's other canvases already
/// use (`CanvasWheelPan`), and a trackpad pinch reaches the framework AS
/// ctrl+scroll — so dropping Ctrl would break pinch-to-zoom on the web build.
///
/// Zoom is reachable four ways because each covers a device the others don't:
/// the toolbar buttons (the only discoverable one), modifier+scroll and pinch
/// (mouse + trackpad + touch), double-tap (touch) and `+` / `-` / `0`
/// (keyboard).
class CcImageViewer extends StatefulWidget {
  /// Creates a [CcImageViewer].
  const CcImageViewer({
    super.key,
    required this.child,
    required this.labels,
    this.minScale = 0.2,
    this.maxScale = 8,
    this.actions = const <Widget>[],
    this.background,
    this.bordered = true,
  });

  /// The visual to display. Painted at the viewer's size, then transformed.
  final Widget child;

  /// Strings for the zoom controls.
  final CcImageViewerLabels labels;

  /// Furthest the controls and gestures will zoom OUT. Below 1 the whole image
  /// sits inside the frame with room around it, centered — there is nothing
  /// left to pan to, so panning switches off.
  final double minScale;

  /// Deepest zoom the controls and gestures will reach.
  final double maxScale;

  /// Extra controls appended to the toolbar (e.g. "open original", "download").
  final List<Widget> actions;

  /// Painted behind the image. Defaults to the quiet secondary surface — an
  /// explicit fill, because a transparent backdrop lets a transparent PNG read
  /// against whatever happens to sit under the dialog.
  final Color? background;

  /// Draws a hairline around the frame. On by default: presented in a dialog
  /// the viewer needs its own edge. Turn it off when it fills a pane that
  /// already has one — a second hairline just inside the first reads as a bug.
  final bool bordered;

  @override
  State<CcImageViewer> createState() => _CcImageViewerState();
}

class _CcImageViewerState extends State<CcImageViewer> {
  final TransformationController _transform = TransformationController();
  final GlobalKey _viewportKey = GlobalKey();

  /// The zoom the toolbar reports. Mirrored into state (rather than read from
  /// the matrix during build) so a pinch/scroll gesture updates the readout —
  /// `InteractiveViewer` writes the controller, it does not rebuild us.
  double _scale = 1;

  /// Where a double-tap landed, captured on down: `onDoubleTap` itself carries
  /// no position, and zooming about the viewport center instead would walk the
  /// point the user aimed at off screen.
  Offset? _doubleTapAt;

  /// The transform as it was BEFORE the interaction the viewer is applying
  /// right now, captured in `onInteractionStart` (which fires before the viewer
  /// mutates the matrix).
  ///
  /// A `PointerSignalEvent` is delivered to every `Listener` on the hit-test
  /// path rather than resolved through the gesture arena, so an ancestor cannot
  /// pre-empt the viewer's built-in wheel zoom — it can only run afterwards and
  /// rewrite the result from this snapshot. Both writes land in one event
  /// dispatch, so a single frame is painted and nothing flickers.
  Matrix4? _beforeInteraction;

  /// Guards the re-entrant write in [_normalize] — it sets the controller from
  /// inside the controller's own listener.
  bool _normalizing = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    super.dispose();
  }

  /// Every mutation — button, key, gesture, wheel — lands on the controller, so
  /// clamping here is the one place that has to be right.
  void _onTransformChanged() {
    if (!_normalizing) {
      _normalize();
    }
    final next = _transform.value.getMaxScaleOnAxis();
    if ((next - _scale).abs() > 0.001) {
      setState(() => _scale = next);
    }
  }

  Size? get _viewport {
    final box = _viewportKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }

  /// Pulls the translation back into range for the current scale.
  ///
  /// Owned here rather than left to `boundaryMargin` because the viewer's own
  /// boundary is what makes zooming below fit impossible: with a
  /// viewport-sized child it refuses any scale that would let the viewport
  /// escape the child. The viewer runs unbounded (see `boundaryMargin` in
  /// [build]) and this is the leash instead.
  ///
  /// Above fit the image must cover the frame — no strip of background down one
  /// side. At or below fit it is centered, because the whole thing is visible
  /// and there is nowhere to pan to.
  void _normalize() {
    final viewport = _viewport;
    if (viewport == null || viewport.isEmpty) {
      return;
    }
    final matrix = _transform.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0) {
      return;
    }
    final translation = matrix.getTranslation();
    final tx = _clampAxis(translation.x, viewport.width, scale);
    final ty = _clampAxis(translation.y, viewport.height, scale);
    if ((tx - translation.x).abs() < 0.01 &&
        (ty - translation.y).abs() < 0.01) {
      return;
    }
    _normalizing = true;
    _transform.value = _matrix(tx, ty, scale);
    _normalizing = false;
  }

  static double _clampAxis(double value, double extent, double scale) {
    if (scale >= 1) {
      return value.clamp(-extent * (scale - 1), 0.0);
    }
    return extent * (1 - scale) / 2;
  }

  /// All THREE axes scale: everything that reads the zoom back (this toolbar,
  /// the gestures, `InteractiveViewer` itself) asks `getMaxScaleOnAxis`, the
  /// largest column norm — leaving z at 1 makes a 0.5x matrix report 1.0.
  static Matrix4 _matrix(double tx, double ty, double scale) =>
      Matrix4.identity()
        ..translateByDouble(tx, ty, 0, 1)
        ..scaleByDouble(scale, scale, scale, 1);

  /// Zooms to [target], keeping the scene point under [focal] (viewport
  /// coordinates; the center when omitted) pinned in place.
  void _zoomTo(double target, {Offset? focal}) {
    final viewport = _viewport;
    if (viewport == null || viewport.isEmpty) {
      return;
    }
    final matrix = _transform.value;
    final current = matrix.getMaxScaleOnAxis();
    final next = target.clamp(widget.minScale, widget.maxScale).toDouble();
    if (current <= 0 || (next - current).abs() < 0.001) {
      return;
    }
    final translation = matrix.getTranslation();
    final anchor = focal ?? viewport.center(Offset.zero);
    // The scene point currently painted under `anchor`.
    final scene = Offset(
      (anchor.dx - translation.x) / current,
      (anchor.dy - translation.y) / current,
    );
    // _normalize (via the controller listener) does the clamping.
    _transform.value = _matrix(
      anchor.dx - scene.dx * next,
      anchor.dy - scene.dy * next,
      next,
    );
  }

  /// Moves the content by [delta] logical px, as a scroll would.
  void _panBy(Offset delta) {
    final matrix = _transform.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0) {
      return;
    }
    final translation = matrix.getTranslation();
    _transform.value = _matrix(
      translation.x - delta.dx,
      translation.y - delta.dy,
      scale,
    );
  }

  void _reset() => _transform.value = Matrix4.identity();

  void _toggleZoom() {
    if (_scale > 1.01) {
      _reset();
    } else {
      _zoomTo(2.5, focal: _doubleTapAt);
    }
  }

  /// Rewrites what the viewer just did to a scroll, so a plain scroll pans and
  /// a modified one zooms — on both a wheel and a trackpad, which the viewer
  /// treats as opposites (wheel always zooms, trackpad always pans).
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    final keys = HardwareKeyboard.instance;
    final zoom =
        keys.isAltPressed || keys.isMetaPressed || keys.isControlPressed;
    final trackpad = event.kind == PointerDeviceKind.trackpad;
    // The one combination the viewer already got right: a plain trackpad
    // scroll, which it pans. Leave its (boundary-aware) result alone.
    if (!zoom && trackpad) {
      return;
    }
    final base = _beforeInteraction ?? _transform.value;
    final delta = event.scrollDelta;
    if (delta == Offset.zero) {
      _transform.value = base;
      return;
    }
    _transform.value = base;
    if (zoom) {
      // Exponential so each notch is the same proportional step whichever
      // scale you start from, and so the ramp is symmetric in and out.
      final factor = math.exp(-delta.dy / 220);
      _zoomTo(base.getMaxScaleOnAxis() * factor, focal: event.localPosition);
      return;
    }
    // Shift turns the wheel horizontal (the platform convention), which is also
    // how a mouse with no horizontal wheel crosses a wide image.
    _panBy(keys.isShiftPressed && delta.dx == 0 ? Offset(delta.dy, 0) : delta);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final labels = widget.labels;
    final atMin = _scale <= widget.minScale + 0.001;
    final atMax = _scale >= widget.maxScale - 0.001;
    final atFit = (_scale - 1).abs() < 0.001;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.equal): () =>
            _zoomTo(_scale * 1.5),
        const SingleActivator(LogicalKeyboardKey.add): () =>
            _zoomTo(_scale * 1.5),
        const SingleActivator(LogicalKeyboardKey.minus): () =>
            _zoomTo(_scale / 1.5),
        const SingleActivator(LogicalKeyboardKey.digit0): _reset,
      },
      child: Focus(
        autofocus: true,
        // A Container, NOT a DecoratedBox: only Container insets its child by
        // the border's own width. Under a DecoratedBox the image paints over
        // the hairline it is supposed to sit inside, and the frame looks
        // broken along whichever edge the picture reaches.
        child: Container(
          decoration: BoxDecoration(
            color: widget.background ?? tokens.bgSecondary,
            border: widget.bordered
                ? Border.all(color: tokens.borderSecondary)
                : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                // Ancestor of the viewer on purpose: a pointer signal reaches
                // every Listener on the path, so this runs AFTER the viewer's
                // own wheel handling and rewrites it. See [_onPointerSignal].
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: ClipRect(
                    child: InteractiveViewer(
                      key: _viewportKey,
                      transformationController: _transform,
                      minScale: widget.minScale,
                      maxScale: widget.maxScale,
                      // Unbounded, with [_normalize] as the leash instead. The
                      // default boundary refuses any scale that would let the
                      // viewport escape a viewport-sized child — which is
                      // exactly every scale below 1, the ones we want.
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      // Panning is only meaningful once zoomed past fit; below
                      // that the whole image is already on screen.
                      panEnabled: _scale > 1.001,
                      // Leaves a two-finger trackpad scroll as a PAN, which is
                      // the one scroll behaviour the viewer already gets right.
                      trackpadScrollCausesScale: false,
                      onInteractionStart: (_) =>
                          _beforeInteraction = _transform.value.clone(),
                      // The double-tap detector sits INSIDE the viewer, not
                      // around it: gesture ties go to the deepest competitor,
                      // so an outer detector loses every tap to the viewer's
                      // own scale recognizer and the double-tap never fires.
                      // Being inside also means `localPosition` is in the
                      // CHILD's coordinates — identical to the viewport's at
                      // scale 1, which is the only scale we zoom IN from (the
                      // other direction resets, and needs no focal point).
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTapDown: (details) =>
                            _doubleTapAt = details.localPosition,
                        onDoubleTap: _toggleZoom,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.md,
                child: Center(
                  child: _ZoomBar(
                    scale: _scale,
                    labels: labels,
                    onZoomIn: atMax ? null : () => _zoomTo(_scale * 1.5),
                    onZoomOut: atMin ? null : () => _zoomTo(_scale / 1.5),
                    // Reset is "back to fit", so it is live in BOTH directions
                    // — zoomed out is just as far from fit as zoomed in.
                    onReset: atFit ? null : _reset,
                    actions: widget.actions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The floating zoom control cluster: out / readout / in / reset, plus whatever
/// the host appended.
class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.scale,
    required this.labels,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.actions,
  });

  final double scale;
  final CcImageViewerLabels labels;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onReset;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brLg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcIconButton(
              icon: CcIcons.minus,
              size: CcButtonSize.sm,
              color: tokens.textTertiary,
              tooltip: labels.zoomOut,
              onPressed: onZoomOut,
            ),
            // Tabular-ish fixed box: the readout swings between "100%" and
            // "800%" as you zoom and a shrink-wrapped label would shuffle the
            // buttons on either side of it.
            SizedBox(
              width: 46,
              child: Text(
                '${(scale * 100).round()}%',
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
            CcIconButton(
              icon: CcIcons.plus,
              size: CcButtonSize.sm,
              color: tokens.textTertiary,
              tooltip: labels.zoomIn,
              onPressed: onZoomIn,
            ),
            CcIconButton(
              icon: CcIcons.refreshCw,
              size: CcButtonSize.sm,
              color: tokens.textTertiary,
              tooltip: labels.resetZoom,
              onPressed: onReset,
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Presents [builder]'s visual in a near-fullscreen lightbox.
///
/// The panel deliberately takes almost the whole window rather than the modest
/// [CcDialog] default: the point of expanding an image is that the inline
/// rendition was too small, so a viewer that reads as "a slightly bigger
/// thumbnail in a box" has not done the one job it exists for.
Future<void> showCcImageViewer({
  required BuildContext context,
  required WidgetBuilder builder,
  required CcImageViewerLabels labels,
  String? title,
  double maxScale = 8,
  List<Widget> actions = const <Widget>[],
}) {
  return showCcDialog<void>(
    context: context,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      // The panel is the window less a margin; the CONTENT is the panel less
      // the dialog's own padding, border and header. Sizing the content to the
      // panel instead overflows by exactly that chrome — and a dialog is
      // centered, not scrollable, so the overflow has nowhere to go.
      final panelWidth = size.width * 0.94;
      final contentWidth = (panelWidth - AppSpacing.lg * 2 - 2).clamp(
        160.0,
        double.infinity,
      );
      final contentHeight = (size.height * 0.9 - 88).clamp(
        160.0,
        double.infinity,
      );
      return CcDialog(
        title: title,
        maxWidth: panelWidth,
        onClose: () => Navigator.of(dialogContext).pop(),
        content: SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: CcImageViewer(
            labels: labels,
            maxScale: maxScale,
            actions: actions,
            child: builder(dialogContext),
          ),
        ),
      );
    },
  );
}

/// Wraps an inline image with the product-wide "expand" affordance: a hover
/// button in the corner and a click anywhere on the image, both opening the
/// same [showCcImageViewer] lightbox.
///
/// [child] is the inline rendition (already sized by the caller — this adds no
/// layout of its own) and [viewerBuilder] the full-size one. They are separate
/// because they are genuinely different pictures: inline is a decode capped to
/// a column width, expanded is the largest the bytes support.
///
/// Reach for it on CONTENT images — screenshots, diagrams, photos, attachments.
/// Not on badges, avatars or favicons: a lightbox over a 16px status shield is
/// a click target where none was wanted. Gate on the LAID-OUT SIZE, not on
/// which layout branch produced the image (see `isExpandableMarkdownImage`) —
/// "narrower than the column" is not the same question as "is a badge", and
/// most screenshots are narrower than the column.
class CcExpandableImage extends StatefulWidget {
  /// Creates a [CcExpandableImage].
  const CcExpandableImage({
    super.key,
    required this.child,
    required this.viewerBuilder,
    required this.labels,
    this.title,
    this.actions = const <Widget>[],
    this.borderRadius = BorderRadius.zero,
    this.enabled = true,
  });

  /// The inline rendition.
  final Widget child;

  /// Builds the full-size rendition shown in the lightbox.
  final WidgetBuilder viewerBuilder;

  /// Strings for the affordance and the viewer it opens.
  final CcImageViewerLabels labels;

  /// Heading for the lightbox (typically the image's alt text).
  final String? title;

  /// Extra viewer toolbar controls (e.g. "open original").
  final List<Widget> actions;

  /// Matches the inline rendition's own clipping so the hover wash does not
  /// paint outside it.
  final BorderRadius borderRadius;

  /// When false the child renders bare — no affordance, no tap target.
  final bool enabled;

  @override
  State<CcExpandableImage> createState() => _CcExpandableImageState();
}

class _CcExpandableImageState extends State<CcExpandableImage> {
  bool _hovering = false;

  Future<void> _open() => showCcImageViewer(
    context: context,
    builder: widget.viewerBuilder,
    labels: widget.labels,
    title: widget.title,
    actions: widget.actions,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    final tokens = context.ds;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: CcTappable(
        onPressed: _open,
        // The magnifier is the whole hint on a pointer device — it says the
        // image is a target before anything is drawn over it.
        mouseCursor: SystemMouseCursors.zoomIn,
        borderRadius: widget.borderRadius,
        semanticLabel: widget.labels.expand,
        builder: (context, states) => Stack(
          children: [
            if (widget.borderRadius == BorderRadius.zero)
              widget.child
            else
              ClipRRect(borderRadius: widget.borderRadius, child: widget.child),
            // Hover-only chrome, and only a chip in the corner: the image is
            // the content, so the affordance must not sit on top of it at rest.
            // Touch has no hover — there the whole image is already the target.
            //
            // `Positioned.fill` rather than a corner offset, so the chip can
            // MEASURE the box it is decorating without joining the Stack's
            // sizing (a positioned child never does). A labelled chip is ~90px
            // wide; on a small thumbnail the Stack would simply clip it, which
            // reads as a rendering bug rather than an affordance.
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tight =
                        constraints.maxWidth < 150 ||
                        constraints.maxHeight < 56;
                    return Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(
                          tight ? AppSpacing.xs : AppSpacing.sm,
                        ),
                        child: AnimatedOpacity(
                          opacity: _hovering ? 1 : 0,
                          duration: CcMotion.resolve(context, CcMotion.fast),
                          curve: CcMotion.standard,
                          child: _ExpandChip(
                            tokens: tokens,
                            label: widget.labels.expand,
                            iconOnly: tight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The corner badge revealed on hover. Not a [CcIconButton]: it must never take
/// the press itself — the whole image is the target and a nested button would
/// swallow the tap that reaches it.
class _ExpandChip extends StatelessWidget {
  const _ExpandChip({
    required this.tokens,
    required this.label,
    required this.iconOnly,
  });

  final DesignSystemTokens tokens;
  final String label;

  /// Drops the label on a box too small to hold it. The glyph alone still
  /// reads — it sits on an image the pointer is already hovering, with a
  /// magnifier cursor on it.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brLg,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: iconOnly ? AppSpacing.xs : AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CcIcons.maximize2, size: 13, color: tokens.textTertiary),
            if (!iconOnly) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
