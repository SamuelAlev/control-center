// The mark a rig tab shows while its machine is coming up.
//
// A browser engine already breathes its own colour logo on that screen.
// Android and iOS have the same job — say which machine is starting — so they
// reuse the same pulse on their platform glyphs instead of a generic spinner.
library;

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/browser_engine_logo.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:flutter/widgets.dart';

/// Opacity + scale pulse while a machine boots.
///
/// The curve matches [BrowserEngineBootMark] so a Firefox tab and an iOS tab
/// feel like one product. The breathing is presence, not decoration: it runs
/// only while a boot is in flight, and under reduced motion the child holds
/// still (the "starting" label already carries the state).
class RigBootBreath extends StatefulWidget {
  /// Creates a [RigBootBreath].
  const RigBootBreath({super.key, required this.child});

  /// The identity mark that pulses.
  final Widget child;

  @override
  State<RigBootBreath> createState() => _RigBootBreathState();
}

class _RigBootBreathState extends State<RigBootBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _breath,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _curve.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = CcMotion.reduced(context);
    if (reduceMotion) {
      _breath.stop();
      return widget.child;
    }
    if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// The full-color brand mark of [engine], breathing while its machine boots.
///
/// It draws the colour asset, which is pinned byte-identical to the mark the
/// rig's own new-tab page inlines — so the pulse on the boot screen settles
/// into an identical logo on the page the browser opens to. The breathing is
/// presence, not decoration: it runs only while a boot is in flight, and
/// under reduced motion the mark holds still (the "starting" label already
/// carries the state).
class BrowserEngineBootMark extends StatelessWidget {
  /// Creates a [BrowserEngineBootMark].
  const BrowserEngineBootMark({
    super.key,
    required this.engine,
    this.size = 40,
  });

  /// The engine whose machine is coming up.
  final RigBrowserEngine engine;

  /// Rendered edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return RigBootBreath(
      child: BrowserEngineLogo(engine: engine, size: size),
    );
  }
}

/// The boot-screen mark for [surface]: an engine's colour logo, a platform
/// glyph, or the spinner for surfaces that have no identity of their own.
class RigBootMark extends StatelessWidget {
  /// Creates a [RigBootMark].
  const RigBootMark({
    super.key,
    required this.surface,
    this.engine,
    this.size = 40,
  });

  /// Which machine is coming up.
  final String surface;

  /// Which browser, when the surface is one.
  final RigBrowserEngine? engine;

  /// Rendered edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (engine case final engine?) {
      return BrowserEngineBootMark(engine: engine, size: size);
    }
    if (surface == RigTabSurfaces.mobile || surface == RigTabSurfaces.ios) {
      final t = context.designSystem ?? DesignSystemTokens.light();
      return RigBootBreath(
        child: Icon(
          RigTabSurfaces.iconFor(surface),
          size: size,
          color: t.textPrimary,
        ),
      );
    }
    return const CcSpinner();
  }
}
