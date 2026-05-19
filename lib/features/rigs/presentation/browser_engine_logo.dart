import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The brand logo of a browser rig's engine (Chromium / Firefox / WebKit),
/// tinted to [color] — or in the brand's own colours when [color] is null.
///
/// The Phosphor set has no browser-engine glyphs, so these ship as SVG assets
/// rather than icon-font codepoints, and each engine has BOTH treatments on
/// disk: `assets/browser_logos/<engine>.svg` is the flat silhouette a tinted
/// label wants, `<engine>_color.svg` is the real mark. Two files, because a
/// brand logo cannot be derived from its own silhouette at render time —
/// WebKit's is three stacked slabs, a white ring and a compass rose, and
/// collapsing that to one tint is a drawing decision, not a colour filter.
///
/// The colour variants are byte-identical to [browserRigEngineMark], the
/// const the rig guest's own new-tab page inlines (it cannot read a Flutter
/// asset), so the mark on a tab, on the boot screen and on the page the
/// browser finally opens to is one picture. `browser_logo_assets_test.dart`
/// pins that.
///
/// The tint is a `srcIn` filter, so a monochrome logo follows the surrounding
/// text colour the way an icon would. A missing/unparseable asset falls back
/// to the generic globe, never to a hole.
class BrowserEngineLogo extends StatelessWidget {
  /// Creates a [BrowserEngineLogo].
  const BrowserEngineLogo({
    super.key,
    required this.engine,
    this.color,
    this.size = 14,
  });

  /// The engine whose logo is drawn.
  final RigBrowserEngine engine;

  /// The monochrome tint (usually the surrounding label color). Null draws the
  /// engine's own brand colours.
  final Color? color;

  /// Rendered edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    final fallback = Icon(AppIcons.globe, size: size, color: tint);
    return SvgPicture.asset(
      'assets/browser_logos/${engine.wire}${tint == null ? '_color' : ''}.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

/// The full-color brand mark of [engine], breathing while its machine boots.
///
/// It draws the colour asset, which is pinned byte-identical to
/// [browserRigEngineMark] — the mark the rig's own new-tab page inlines — so
/// the pulse on the boot screen settles into an identical logo on the page
/// the browser opens to. The breathing is presence, not decoration: it runs
/// only while a boot is in flight, and under reduced motion the mark holds
/// still (the "starting" label already carries the state).
class BrowserEngineBootMark extends StatefulWidget {
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
  State<BrowserEngineBootMark> createState() => _BrowserEngineBootMarkState();
}

class _BrowserEngineBootMarkState extends State<BrowserEngineBootMark>
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
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
    final mark = BrowserEngineLogo(engine: widget.engine, size: widget.size);
    if (reduceMotion) {
      return mark;
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(_curve),
        child: mark,
      ),
    );
  }
}
