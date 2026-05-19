import 'package:flutter/widgets.dart';

/// Mutes every ticker in the primary window while the app is not foregrounded.
///
/// On macOS the engine keeps rasterizing frames that were scheduled while the
/// window cannot present them (app hidden, window covered or minimized): the
/// surfaces accumulate natively — the Dart heap stays flat while the process
/// balloons. Repeating animations (activity bars, status pulses, spinners, the
/// shader background) schedule such frames at 30–60fps even when nobody can
/// see them, which is what grew the idle process to tens of GB in minutes.
/// Muting all tickers through [TickerMode] the moment the app leaves
/// [AppLifecycleState.resumed] stops every animation-driven frame until the
/// user returns; on resume the animations simply continue.
///
/// Scope this gate to the PRIMARY window only: the always-on-top HUD windows
/// (focus pill, meeting toolbar, mini player) are designed to stay visible
/// while the operator works inside another app — their frames present normally
/// and their tickers must keep running while the app is `inactive`.
///
/// This generalises the policy `ShaderBackground`, `EditorBodyHost` and
/// `MeetingToolbarController` already apply individually: motion nobody can
/// see must not burn frames.
///
/// **`inactive` is the state this actually buys you.** Below it (`hidden`,
/// `paused`, `detached`) the scheduler disables frames outright, so no ticker
/// can produce one whatever this gate says — and the `setState` below stays
/// pending until frames return, because a rebuild needs a frame. `inactive` is
/// different: another app merely took focus, frames stay ENABLED, and every
/// repeating animation keeps rendering into a window the user may not be able to
/// see. That is the gap this closes. The deeper states are still handled here so
/// the gate's state is correct when frames resume.
class ForegroundTickerGate extends StatefulWidget {
  /// Creates a [ForegroundTickerGate].
  const ForegroundTickerGate({super.key, required this.child});

  /// The subtree whose tickers are muted while the app is backgrounded.
  final Widget child;

  @override
  State<ForegroundTickerGate> createState() => _ForegroundTickerGateState();
}

class _ForegroundTickerGateState extends State<ForegroundTickerGate>
    with WidgetsBindingObserver {
  late bool _foreground;

  @override
  void initState() {
    super.initState();
    // `lifecycleState` is null until the platform reports the first state;
    // at launch the window is foreground by definition. Reading it (instead
    // of assuming) keeps a hot restart performed while backgrounded from
    // resurrecting the tickers.
    _foreground = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.resumed => true,
      _ => false,
    };
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only `resumed` presents frames the user can see. On macOS `inactive`
    // fires when another app takes focus (the window may still be covered),
    // `hidden` on Cmd+H, `paused`/`detached` when the engine is going away —
    // all of them must stop ticker-driven frame production.
    final foreground = state == AppLifecycleState.resumed;
    if (foreground != _foreground) {
      setState(() => _foreground = foreground);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: _foreground, child: widget.child);
}
