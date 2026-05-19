// The live view of one enclosure, with take-over.
//
// Two lanes meet here. The canvas shows the HUMAN lane — full-resolution
// frames sized to this panel, negotiated on resize — while the agent driving
// the rig sees its own downscaled stills. That split is the whole point: a
// person watching should get a fluid picture, and a model should get a cheap
// one, and neither should have to compromise for the other.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/mjpeg_view.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_toolbar.dart';
import 'package:control_center/features/rigs/presentation/rig_input_surface.dart';
import 'package:control_center/features/rigs/presentation/rig_panel_chrome.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A live rig: status header, frame canvas and take-over controls.
class RigPanel extends ConsumerStatefulWidget {
  /// Creates a [RigPanel] for [rig] in [workspaceId].
  const RigPanel({
    super.key,
    required this.workspaceId,
    required this.rig,
    this.showHeader = true,
    this.paused = false,
    this.onStop,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The rig to render.
  final RigView rig;

  /// Whether to draw the status header (hidden when the host draws its own).
  final bool showHeader;

  /// When true the live stream is closed and the last frame is held. Set by a
  /// tab host while this panel sits behind another tab.
  final bool paused;

  /// Shown as a "stop" action in the header when non-null.
  final VoidCallback? onStop;

  @override
  ConsumerState<RigPanel> createState() => _RigPanelState();
}

/// The JPEG quality to ask for when the guest paints [scale] device pixels
/// per CSS pixel.
///
/// Raising the scale multiplies the frame's pixels — 2x is FOUR times as
/// many — so holding quality would roughly quadruple the bytes on a lane
/// that a phone may be watching over the relay. It does not have to: the
/// viewer downsamples the frame back to its panel, and averaging 4 source
/// pixels into 1 is a low-pass filter over exactly the 8x8 block noise JPEG
/// adds. So a 2x frame at q45 reads CLEANER than a 1x frame at q70 while
/// carrying real detail the 1x frame never had, and the net cost lands near
/// 2x rather than 4x.
int rigStreamQualityFor(double scale) => (70 / scale).round().clamp(45, 70);

class _RigPanelState extends ConsumerState<RigPanel> {
  /// The canvas size the stream is currently negotiated for.
  Size? _negotiated;
  Timer? _resizeDebounce;
  Timer? _modeDebounce;
  DateTime _lastModeChange = DateTime.fromMillisecondsSinceEpoch(0);

  /// The device pixel ratio the guest was last asked to render at.
  ///
  /// Tracked separately from the negotiated SIZE because the two change
  /// independently: dragging the window to a display of a different density
  /// leaves the panel exactly as many layout points wide, so nothing in the
  /// size comparison would notice that every frame is now the wrong
  /// resolution. It also decides the stream's JPEG quality, so the two must
  /// move together — a 2x request at 1x quality is bytes for nothing.
  double _appliedScale = 1;

  /// Whether the guest's sound plays here. Off by default — a machine that
  /// starts talking the moment its tab opens is a surprise, not a feature.
  bool _audioOn = false;

  @override
  void dispose() {
    _resizeDebounce?.cancel();
    _modeDebounce?.cancel();
    super.dispose();
  }

  /// Renegotiates the stream for the canvas, debounced, and asks the GUEST to
  /// adopt the tab's size as its display mode.
  ///
  /// A drag resizes the panel dozens of times a second; each change tears down
  /// a stream and opens another, so applying every one would spend the whole
  /// drag reconnecting and show nothing. Settling first is what makes a resize
  /// feel like a resize. The mode change gets a longer settle and a churn
  /// guard on top: reconfiguring the guest's screen is the expensive end of a
  /// resize, and the letterbox already absorbs small mismatches.
  void _onCanvasSize(Size logical, double ratio) {
    final physical = Size(logical.width * ratio, logical.height * ratio);
    final rounded = Size(
      (physical.width / 32).round() * 32.0,
      (physical.height / 32).round() * 32.0,
    );
    if (rounded.width >= 64 && rounded.height >= 64 && rounded != _negotiated) {
      _resizeDebounce?.cancel();
      _resizeDebounce = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _negotiated = rounded);
        }
      });
    }
    _scheduleGuestResize(logical, ratio);
  }

  /// Asks the guest to change its display mode to the tab's LOGICAL size, at
  /// the viewer's device pixel ratio.
  ///
  /// Logical, not physical: a Retina tab in guest-native pixels would render
  /// half-size text nobody can read. So the SIZE stays in layout points and
  /// [ratio] raises the resolution underneath it — which is what a Retina
  /// display itself does, and what a browser exposes as `devicePixelRatio`.
  ///
  /// It used to send the logical size alone, and the stream then upscaled a
  /// 1x render across 2x physical pixels: every glyph on the watch lane was
  /// soft on any display above 1x, in a way that reads as a bad codec rather
  /// than a missing parameter. Only the BROWSER surface carries the ratio —
  /// `set_display` reconfigures a real framebuffer, where "device pixels per
  /// CSS pixel" is not a thing that exists.
  void _scheduleGuestResize(Size logical, double ratio) {
    final rig = widget.rig;
    if (rig.surfaceKind == RigSurface.mobile || !rig.isLive) {
      return;
    }
    final w = logical.width.round().clamp(640, 2560);
    final h = logical.height.round().clamp(480, 1600);
    // Above 2 the extra pixels stop being visible, and the guest's raster
    // budget usually cuts it further — a browser rig is a 2-vCPU microVM with
    // no GPU, so asking a full-size viewport for 2x is four times the software
    // rasterisation and its control channel stops answering. The server
    // re-derives the same number; this is here so the STREAM's quality and
    // cache key agree with what the guest was actually asked for.
    final scale = rig.surfaceKind == RigSurface.browser
        ? RigDisplaySize(w, h).deviceScaleWithin(ratio.clamp(1.0, 2.0))
        : 1.0;
    final dw = rig.displayWidth;
    final dh = rig.displayHeight;
    // The letterbox absorbs small mismatches; a mode change only pays off
    // when the shape is meaningfully different. Dragging the window to a
    // display of a different density is the exception: the SIZE is unchanged
    // and the guest still has to re-render, so the scale is compared too.
    if (dw != null &&
        dh != null &&
        (dw - w).abs() < 48 &&
        (dh - h).abs() < 48 &&
        scale == _appliedScale) {
      return;
    }
    _modeDebounce?.cancel();
    _modeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) {
        return;
      }
      // Inside the cooldown, RE-ARM rather than drop: nothing else re-runs
      // this after the last layout pass, so a resize that landed within 2s
      // of the previous mode change would otherwise be lost forever and the
      // guest would stay the old size until some unrelated rebuild.
      final sinceLast = DateTime.now().difference(_lastModeChange);
      if (sinceLast < const Duration(seconds: 2)) {
        _modeDebounce = Timer(
          const Duration(seconds: 2) - sinceLast,
          () => _scheduleGuestResize(logical, ratio),
        );
        return;
      }
      _lastModeChange = DateTime.now();
      _appliedScale = scale;
      // Fire-and-forget: a refusal (an agent holds the lock, the rig closed)
      // leaves the letterboxed view, which is the correct fallback.
      unawaited(
        ref
            .read(rigRepositoryProvider)
            .act(
              workspaceId: widget.workspaceId,
              rigId: rig.id,
              action: {
                'action': rig.surfaceKind == RigSurface.browser
                    ? 'set_viewport'
                    : 'set_display',
                'width': w,
                'height': h,
                if (scale != 1) 'device_scale_factor': scale,
              },
            )
            .catchError((_) => (text: '', isError: true)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final rig = widget.rig;

    return Container(
      decoration: BoxDecoration(color: t.bgPrimaryAlt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The browser surface's chrome is its toolbar alone — the address
          // bar answers "where", its size label "how big", and closing the
          // tab shuts the machine down, so the header row would only repeat
          // the tab strip.
          if (widget.showHeader && rig.surfaceKind != RigSurface.browser)
            RigHeader(
              rig: rig,
              onStop: widget.onStop,
              audioOn: _audioOn,
              // Only the computer surface has an audio lane today.
              onToggleAudio: rig.surfaceKind == RigSurface.mobile
                  ? null
                  : () => setState(() => _audioOn = !_audioOn),
            ),
          // The browser surface gets the same chrome as the in-app browser
          // tab: back / forward / reload and an address bar driving the
          // enclosed Chromium over rig.act.
          if (rig.surfaceKind == RigSurface.browser && rig.isLive)
            RigBrowserToolbar(workspaceId: widget.workspaceId, rig: rig),
          if (_audioOn && rig.isLive && !widget.paused)
            RigAudioPlayer(
              url: MediaProxyScope.rigAudioUrlOf(
                context,
                workspaceId: widget.workspaceId,
                rigId: rig.id,
              ),
            ),
          Expanded(
            child: rig.isStarting
                ? RigStarting(detail: rig.detail)
                : rig.isFailed
                ? RigFailed(detail: rig.detail)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Physical pixels for the STREAM (a logical-pixel
                      // request reads soft on any display above 1x); logical
                      // for the guest MODE (see _scheduleGuestResize).
                      final ratio = MediaQuery.devicePixelRatioOf(context);
                      final logical = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final size = Size(
                        logical.width * ratio,
                        logical.height * ratio,
                      );
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _onCanvasSize(logical, ratio),
                      );
                      final negotiated = _negotiated ?? size;
                      final url = MediaProxyScope.rigStreamUrlOf(
                        context,
                        workspaceId: widget.workspaceId,
                        rigId: rig.id,
                        width: negotiated.width.round(),
                        height: negotiated.height.round(),
                        quality: rigStreamQualityFor(_appliedScale),
                        // Re-opens the stream when the GUEST re-modes: the
                        // in-guest capture keeps its opening geometry, so a
                        // stream older than the mode shows the previous
                        // screen size (cropped, letterboxed wrong) until
                        // something reconnects it. The scale belongs in the
                        // key for the same reason — it changes the frames
                        // coming out of a screencast that is already running.
                        guestKey:
                            '${rig.displayWidth}x${rig.displayHeight}'
                            '@$_appliedScale',
                      );
                      if (url == null) {
                        return Center(
                          child: Text(
                            l10n.rigStreamDisconnected,
                            style: CcTypography.caption.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                        );
                      }
                      return ColoredBox(
                        color: DesignSystemPalette.gray950,
                        // The user drives by DEFAULT: input forwards whenever
                        // no one holds an exclusive lock (the server's
                        // chokepoint already allows exactly that) or this
                        // user holds it. Only an agent's lock makes the
                        // canvas watch-only — and "Take over" breaks even
                        // that, because the machine is ultimately the
                        // human's.
                        child: RigInputSurface(
                          workspaceId: widget.workspaceId,
                          rig: rig,
                          enabled:
                              rig.isLive &&
                              rig.surfaceKind != RigSurface.mobile &&
                              (rig.controller == null || rig.isHumanControlled),
                          // The machine on the active tab owns the keyboard
                          // without needing a click first.
                          active: !widget.paused,
                          child: MjpegView(url: url, paused: widget.paused),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
