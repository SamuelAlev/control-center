import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The brand logo of a browser rig's engine (Chromium / Firefox / WebKit), tinted to
/// [color] — or in the brand's own colours when [color] is null.
/// A missing/unparseable asset falls back to the generic globe, never to a hole.
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
