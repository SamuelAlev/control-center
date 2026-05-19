import 'dart:async';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

/// Channel the pill uses to send actions back to the main window.
const _pillToMainChannel = WindowMethodChannel(
  'focus_pill_to_main',
  mode: ChannelMode.unidirectional,
);

/// design system dark tokens, read directly: the pill renders in a bare
/// sub-window with no [Theme] (and therefore no `context.designSystem`), so we
/// resolve the token set ourselves rather than through the widget tree. The
/// HUD floats over arbitrary desktop content, so it commits to the dark surface
/// of the design system regardless of the main window's theme.
final _t = DesignSystemTokens.dark();

/// Standalone Flutter app rendered in the pill sub-window.
///
/// Receives focus session details via [args] from [WindowController.arguments].
class FocusPillApp extends StatelessWidget {
  /// Creates a [FocusPillApp].
  const FocusPillApp({
    super.key,
    required this.windowController,
    required this.args,
  });

  /// The controller for this sub-window.
  final WindowController windowController;

  /// Focus session arguments parsed from the window's JSON args.
  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _PillScreen(windowController: windowController, args: args),
    );
  }
}

class _PillScreen extends StatefulWidget {
  const _PillScreen({required this.windowController, required this.args});

  final WindowController windowController;
  final Map<String, dynamic> args;

  @override
  State<_PillScreen> createState() => _PillScreenState();
}

class _PillScreenState extends State<_PillScreen> {
  late DateTime _sessionStartedAt;
  late int _durationMinutes;
  late String? _goal;

  Timer? _ticker;
  bool _paused = false;
  DateTime? _pausedAt;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    final a = widget.args;
    _durationMinutes = (a['durationMinutes'] as num?)?.toInt() ?? 50;
    _goal = a['goal'] as String?;
    final startedAtMs = (a['startedAtMs'] as num?)?.toInt();
    _sessionStartedAt = startedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startedAtMs)
        : DateTime.now();

    // Wire close handler so main window can ask this window to close.
    widget.windowController.setWindowMethodHandler((call) async {
      if (call.method == 'window_close') {
        // FIXME(focus-pill): closing leaks this Flutter engine. The bundled
        // desktop_multi_window closes pill windows with
        // `isReleasedWhenClosed = false`, so `windowManager.close()` only hides
        // the window (orderOut) — the engine and its isolate stay alive (a
        // "zombie") for the app's lifetime, and every completed or expanded
        // focus session adds one more. window_manager's only hard teardown,
        // `destroy()`, maps to `NSApp.terminate(nil)` (it would quit the whole
        // app), so we cannot truly dispose this window from Dart. The zombies
        // are inert and self-dismiss on hot restart via the one-shot launch
        // token (see `consumeFreshPillLaunch` in focus_mode_providers.dart);
        // they are only reclaimed on app quit. Proper fix: fork/patch
        // desktop_multi_window to release the window on close (or add a native
        // per-window destroy method) and call that here instead.
        await windowManager.close();
      }
      return null;
    });
    // Auto-complete if the session has already expired (e.g. after a reload).
    final initialRemaining =
        _durationMinutes * 60 -
        DateTime.now().difference(_sessionStartedAt).inSeconds;
    if (initialRemaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _elapsed {
    final now = _paused ? _pausedAt! : DateTime.now();
    return now.difference(_sessionStartedAt);
  }

  int get _secondsRemaining {
    final total = _durationMinutes * 60;
    return (total - _elapsed.inSeconds).clamp(0, total);
  }

  double get _progress {
    final total = _durationMinutes * 60;
    if (total == 0) {
      return 0;
    }
    return (_elapsed.inSeconds / total).clamp(0.0, 1.0);
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        // Resume: shift session start forward by pause duration
        final pauseDuration = DateTime.now().difference(_pausedAt!);
        _sessionStartedAt = _sessionStartedAt.add(pauseDuration);
        _pausedAt = null;
        _paused = false;
      } else {
        _pausedAt = DateTime.now();
        _paused = true;
      }
    });
  }

  Future<void> _complete() async {
    await _savePillPosition();
    await _pillToMainChannel.invokeMethod<void>('completeFocusSession');
  }

  Future<void> _savePillPosition() async {
    try {
      final pos = await windowManager.getPosition();
      await _pillToMainChannel.invokeMethod<void>('savePillPosition', {
        'x': pos.dx,
        'y': pos.dy,
      });
    } on Object catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final secs = _secondsRemaining;
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    final timeLabel = '$mm:$ss';
    final progress = _progress;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: DragToMoveArea(
          // Fill the window edge-to-edge. macOS already rounds and shadows the
          // window, so an inset panel with its own corners reads as a
          // box-in-a-box — let the OS window shape be the bar's shape.
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: _t.panel),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                    child: Row(
                      children: [
                        _PresenceDot(active: !_paused),
                        const SizedBox(width: 9),
                        // Countdown — the hero datum: calm near-white mono,
                        // tabular figures so it doesn't jitter per tick.
                        Text(
                          _paused ? 'Paused' : timeLabel,
                          style: TextStyle(
                            color: _paused ? _t.muted : _t.fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Goal
                        Expanded(
                          child: Text(
                            _goal?.isNotEmpty == true
                                ? _goal!
                                : 'Focus session',
                            style: TextStyle(
                              color: _t.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Hover actions — invisible controls must not be
                        // clickable, so pointer events are gated on hover.
                        IgnorePointer(
                          ignoring: !_hovering,
                          child: AnimatedOpacity(
                            opacity: _hovering ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8),
                                _ActionButton(
                                  label: _paused ? 'Resume' : 'Pause',
                                  icon: _paused
                                      ? LucideIcons.play
                                      : LucideIcons.pause,
                                  onTap: _togglePause,
                                ),
                                const SizedBox(width: 6),
                                _ActionButton(
                                  label: 'Complete',
                                  icon: LucideIcons.circleCheckBig,
                                  primary: true,
                                  onTap: _complete,
                                ),
                                const SizedBox(width: 6),
                                // Drag handle visual cue (not interactive)
                                IgnorePointer(
                                  child: Icon(
                                    LucideIcons.gripVertical,
                                    size: 14,
                                    color: _t.idle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Honest progress toward session end: a 2px determinate
                  // rule flush to the bottom edge — a faint track with an
                  // accent fill that grows left→right. No decorative wash.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: 2,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: _t.hoverStrong),
                          ),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: ColoredBox(
                              color: _paused ? _t.muted : _t.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A live "running" presence dot: a solid core with an expanding, fading ping
/// ring. The ring is the only motion; under reduced motion (or when paused) it
/// settles to a static dot so the surface is never blank.
class _PresenceDot extends StatefulWidget {
  const _PresenceDot({required this.active});

  final bool active;

  @override
  State<_PresenceDot> createState() => _PresenceDotState();
}

class _PresenceDotState extends State<_PresenceDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_PresenceDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final core = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: widget.active ? _t.accent : _t.muted,
        shape: BoxShape.circle,
      ),
    );

    if (!widget.active || reduceMotion) {
      return SizedBox(width: 16, height: 16, child: Center(child: core));
    }

    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final size = 7 + t * 9;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _t.accent.withValues(alpha: (1 - t) * 0.45),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            core,
          ],
        ),
      ),
    );
  }
}

/// A quiet utility button (`button-line` vocabulary): hairline border + muted
/// content at rest, warming on hover — the primary action (`Complete`) warms to
/// accent, secondary actions to ink. 2px corners, no shadow.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.primary ? _t.accent : _t.fg;
    final content = _hover ? accent : _t.muted;
    final border = _hover ? accent : _t.lineStrong;
    final fill = _hover ? _t.hoverStrong : _t.hover;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: content),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color: content,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
