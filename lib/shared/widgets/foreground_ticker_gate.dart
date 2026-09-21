import 'package:flutter/widgets.dart';

/// [TickerMode] off in the primary window when not [AppLifecycleState.resumed].
///
/// macOS keeps rasterizing scheduled frames while covered — native surfaces
/// balloon. Primary only: HUD windows stay visible under `inactive` and must
/// keep ticking. The real gap is `inactive` (frames still enabled); deeper
/// states already disable frames — still tracked so resume state is correct.
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
