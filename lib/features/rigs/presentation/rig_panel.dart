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

class _RigPanelState extends ConsumerState<RigPanel> {
  /// The canvas size the stream is currently negotiated for.
  Size? _negotiated;
  Timer? _resizeDebounce;
  Timer? _modeDebounce;
  DateTime _lastModeChange = DateTime.fromMillisecondsSinceEpoch(0);

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
    _scheduleGuestResize(logical);
  }

  /// Asks the guest to change its display mode to the tab's LOGICAL size.
  ///
  /// Logical, not physical: a Retina tab in guest-native pixels would render
  /// half-size text nobody can read. At logical size the guest screen maps
  /// 1:1 onto layout points and the stream upscales for the panel — the same
  /// trade a 1x external display makes.
  void _scheduleGuestResize(Size logical) {
    final rig = widget.rig;
    if (rig.surfaceKind == RigSurface.mobile || !rig.isLive) {
      return;
    }
    final w = logical.width.round().clamp(640, 2560);
    final h = logical.height.round().clamp(480, 1600);
    final dw = rig.displayWidth;
    final dh = rig.displayHeight;
    // The letterbox absorbs small mismatches; a mode change only pays off
    // when the shape is meaningfully different.
    if (dw != null &&
        dh != null &&
        (dw - w).abs() < 48 &&
        (dh - h).abs() < 48) {
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
          () => _scheduleGuestResize(logical),
        );
        return;
      }
      _lastModeChange = DateTime.now();
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
                        // Re-opens the stream when the GUEST re-modes: the
                        // in-guest capture keeps its opening geometry, so a
                        // stream older than the mode shows the previous
                        // screen size (cropped, letterboxed wrong) until
                        // something reconnects it.
                        guestKey: '${rig.displayWidth}x${rig.displayHeight}',
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
