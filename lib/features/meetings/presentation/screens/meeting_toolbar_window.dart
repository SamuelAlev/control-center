// Uses Flutter's experimental windowing API (unlocked via the `windowing`
// feature flag). Confined to the window wrapper; the UI below is ordinary.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';

import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_toolbar_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/live_dot.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart'
    show RegularWindow, RegularWindowController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the user must hold before the recording stops. Long enough that a
/// stray click can't end a meeting, short enough not to feel like a chore.
const _holdToStopDuration = Duration(milliseconds: 1100);

/// How quickly the charge recedes once released — fast, so an accidental press
/// snaps back rather than lingering.
const _holdReleaseDuration = Duration(milliseconds: 220);

/// Pointer travel (logical px) past which the press is read as a slip rather
/// than a deliberate hold, so the charge backs off instead of completing. The
/// body is no longer a drag region (the grip handle owns dragging), so this is
/// purely a steadiness check on the hold itself.
const _dragSlop = 8.0;

/// Design-system dark tokens, read directly: the toolbar renders in a bare,
/// frameless window with no [Theme]. Like the focus pill, it floats over
/// arbitrary desktop content and commits to the dark surface.
final _t = DesignSystemTokens.dark();

/// The floating meeting-recording toolbar window. A sibling window in the main
/// isolate, so it reads [meetingRecorderControllerProvider] directly and drives
/// stop through [meetingToolbarControllerProvider] — no cross-engine IPC. Shown
/// / hidden by `AppWindows` as the toolbar controller's bool flips.
class MeetingToolbarWindow extends ConsumerStatefulWidget {
  /// Creates the [MeetingToolbarWindow].
  const MeetingToolbarWindow({super.key});

  @override
  ConsumerState<MeetingToolbarWindow> createState() =>
      _MeetingToolbarWindowState();
}

class _MeetingToolbarWindowState extends ConsumerState<MeetingToolbarWindow> {
  final RegularWindowController _controller = RegularWindowController(
    preferredSize: meetingToolbarSize,
    preferredConstraints: BoxConstraints.tight(meetingToolbarSize),
    title: meetingToolbarWindowTitle,
  );

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeProvider)?.languageCode;
    return RegularWindow(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: localeCode != null ? Locale(localeCode) : null,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // This sibling window must ignore the engine's current route (the main
        // window's `/workspaces/<id>/…` deep link is shared across windows in
        // this isolate). WidgetsApp ignores `initialRoute` when the platform
        // route isn't "/", so override route generation to always show the
        // toolbar rather than try (and fail) to match the deep link.
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => const _ToolbarView()),
        ],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _ToolbarView(),
        ),
      ),
    );
  }
}

class _ToolbarView extends ConsumerStatefulWidget {
  const _ToolbarView();

  @override
  ConsumerState<_ToolbarView> createState() => _ToolbarViewState();
}

class _ToolbarViewState extends ConsumerState<_ToolbarView>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;

  /// Drives the charging fill, 0 → 1 over [_holdToStopDuration] while pressed,
  /// reversing over [_holdReleaseDuration] on release.
  late final AnimationController _hold;

  /// Where the active press began, used to tell a hold from a drag. Null once
  /// the press ends or is reclassified as a drag.
  Offset? _holdAnchor;

  /// Latched once the hold completes (or an a11y activation fires) so we issue
  /// exactly one stop and ignore further presses while tearing down.
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _hold =
        AnimationController(
          vsync: this,
          duration: _holdToStopDuration,
          reverseDuration: _holdReleaseDuration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _confirmStop();
          }
        });
    // The elapsed clock ticks locally so the bar updates each second without
    // rebuilding the whole recorder graph.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hold.dispose();
    super.dispose();
  }

  // --- Hold-to-stop gesture ------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (_stopping) {
      return;
    }
    _holdAnchor = event.position;
    _hold.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    final anchor = _holdAnchor;
    if (anchor == null) {
      return;
    }
    if ((event.position - anchor).distance > _dragSlop) {
      _holdAnchor = null;
      _hold.reverse();
    }
  }

  void _onPointerUp() {
    if (_holdAnchor == null) {
      return;
    }
    _holdAnchor = null;
    if (_hold.status != AnimationStatus.completed) {
      _hold.reverse();
    }
  }

  void _confirmStop() {
    if (_stopping) {
      return;
    }
    _stopping = true;
    _holdAnchor = null;
    ref.read(meetingToolbarControllerProvider.notifier).requestStop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recorder = ref.watch(meetingRecorderControllerProvider);
    final paused = recorder.paused;
    final elapsed = recorder.elapsedAt(DateTime.now());
    final label = l10n.meetingToolbarHoldToStop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _hold,
        builder: (context, _) {
          final charge = _hold.value;
          return DecoratedBox(
            decoration: BoxDecoration(color: _t.panel),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (charge > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: charge,
                    child: ColoredBox(
                      color: _t.danger.withValues(alpha: 0.20 + 0.18 * charge),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hold-to-stop body. NOT a drag area — a press here only
                    // ever charges the stop gesture, so relocating the window
                    // can't accidentally arm a stop (and arming a stop can't
                    // accidentally move the window). Dragging lives solely on
                    // the grip handle to the right.
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: label,
                        hint: l10n.meetingToolbarSemanticLabel,
                        // Assistive activation stops immediately — no sighted
                        // hold required.
                        onTap: _confirmStop,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: _onPointerDown,
                            onPointerMove: _onPointerMove,
                            onPointerUp: (_) => _onPointerUp(),
                            onPointerCancel: (_) => _onPointerUp(),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Row(
                                children: [
                                  paused
                                      ? Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: _t.muted,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : LiveDot(color: _t.danger, size: 9),
                                  const SizedBox(width: 11),
                                  Text(
                                    _formatClock(elapsed),
                                    style: TextStyle(
                                      color: paused ? _t.muted : _t.fg,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: Color.lerp(
                                          _t.textSecondary,
                                          _t.fg,
                                          charge,
                                        ),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Grip handle — the ONLY draggable region of the toolbar.
                    WindowDragArea(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Icon(
                              AppIcons.gripVertical,
                              size: 14,
                              color: _t.idle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// `MM:SS`, or `H:MM:SS` past an hour.
String _formatClock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
