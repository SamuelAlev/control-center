// Uses Flutter's experimental windowing API (unlocked via the `windowing`
// feature flag). Confined to the window wrapper; the UI below is ordinary.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';

import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart'
    show RegularWindow, RegularWindowController;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-system dark tokens, read directly: the pill renders in a bare,
/// frameless window with no [Theme] (and therefore no `context.designSystem`).
/// It floats over arbitrary desktop content, so it commits to the dark surface
/// regardless of the main window's theme.
final _t = DesignSystemTokens.dark();

/// The floating focus-pill window. Lives in the main isolate as a sibling
/// window of the app, so it reads [focusModeProvider] directly — no IPC. Added
/// to / removed from the window tree by `AppWindows` as `compactMode` flips.
class FocusPillWindow extends StatefulWidget {
  /// Creates the [FocusPillWindow].
  const FocusPillWindow({super.key});

  @override
  State<FocusPillWindow> createState() => _FocusPillWindowState();
}

class _FocusPillWindowState extends State<FocusPillWindow> {
  final RegularWindowController _controller = RegularWindowController(
    preferredSize: focusPillSize,
    preferredConstraints: BoxConstraints.tight(focusPillSize),
    title: focusPillWindowTitle,
  );

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RegularWindow(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // This sibling window must ignore the engine's current route (the main
        // window's `/workspaces/<id>/…` deep link is shared across windows in
        // this isolate). WidgetsApp ignores `initialRoute` when the platform
        // route isn't "/", so override route generation to always show the
        // pill rather than try (and fail) to match the deep link.
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => const _PillView()),
        ],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _PillView(),
        ),
      ),
    );
  }
}

class _PillView extends ConsumerStatefulWidget {
  const _PillView();

  @override
  ConsumerState<_PillView> createState() => _PillViewState();
}

class _PillViewState extends ConsumerState<_PillView> {
  /// Local copy of the session start, so a pause can shift it without mutating
  /// the shared session state. Seeded from [focusModeProvider] on first build.
  DateTime? _sessionStartedAt;
  Timer? _ticker;
  bool _paused = false;
  DateTime? _pausedAt;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
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

  Duration _elapsed(DateTime start) {
    final now = _paused ? _pausedAt! : DateTime.now();
    return now.difference(start);
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        final pauseDuration = DateTime.now().difference(_pausedAt!);
        _sessionStartedAt = _sessionStartedAt!.add(pauseDuration);
        _pausedAt = null;
        _paused = false;
      } else {
        _pausedAt = DateTime.now();
        _paused = true;
      }
    });
  }

  void _complete() {
    ref.read(focusModeProvider.notifier).deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusModeProvider);
    final goal = session.goal;
    final durationMinutes = session.sessionDurationMinutes;
    // Seed/refresh the local start from the session; once seeded, pauses adjust
    // the local copy only.
    _sessionStartedAt ??= session.sessionStartedAt ?? DateTime.now();
    final start = _sessionStartedAt!;

    final total = durationMinutes * 60;
    final elapsedSecs = _elapsed(start).inSeconds;
    final secs = (total - elapsedSecs).clamp(0, total);
    final progress = total == 0 ? 0.0 : (elapsedSecs / total).clamp(0.0, 1.0);

    // Auto-complete once the planned duration elapses.
    if (secs <= 0 && session.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _complete();
        }
      });
    }

    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    final timeLabel = '$mm:$ss';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: WindowDragArea(
          // Fill the window edge-to-edge. macOS already rounds and shadows the
          // window, so an inset panel with its own corners reads as a
          // box-in-a-box — let the OS window shape be the bar's shape.
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: _t.panel),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                    child: Row(
                      children: [
                        _PresenceDot(active: !_paused),
                        const SizedBox(width: 9),
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
                        Expanded(
                          child: Text(
                            goal?.isNotEmpty == true ? goal! : 'Focus session',
                            style: TextStyle(
                              color: _t.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                                      ? AppIcons.play
                                      : AppIcons.pause,
                                  onTap: _togglePause,
                                ),
                                const SizedBox(width: 6),
                                _ActionButton(
                                  label: 'Complete',
                                  icon: AppIcons.circleCheckBig,
                                  primary: true,
                                  onTap: _complete,
                                ),
                                const SizedBox(width: 6),
                                IgnorePointer(
                                  child: Icon(
                                    AppIcons.gripVertical,
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

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
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
      ),
    );
  }
}
