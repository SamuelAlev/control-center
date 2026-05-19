import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A circular avatar.
///
/// Renders, in priority order: an [image] (clipped to a circle), then
/// [initials] (uppercased, centered), then an [icon], falling back to an empty
/// tinted disc. The fallback disc fills with [background] (default
/// `bgTertiary`) and draws text/icon in `textSecondary`.
class CcAvatar extends StatelessWidget {
  /// Creates a [CcAvatar].
  const CcAvatar({
    super.key,
    this.size = 32,
    this.image,
    this.initials,
    this.icon,
    this.background,
  });

  /// Diameter in logical pixels.
  final double size;

  /// Optional image; takes precedence over [initials] and [icon].
  final ImageProvider<Object>? image;

  /// Fallback initials shown when [image] is null.
  final String? initials;

  /// Fallback icon shown when both [image] and [initials] are null.
  final IconData? icon;

  /// Disc fill for the fallback states; defaults to `bgTertiary`.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    final Widget content;
    if (image != null) {
      // Decode at the displayed size, not the source's. A 460px GitHub avatar or
      // a 256px favicon otherwise decodes full-res into the image cache for a
      // ~24px disc — the dominant cost behind image jank on the web client.
      // ResizeImage's value-based `==` keeps the cache/stream identity stable
      // across rebuilds, so `gaplessPlayback` below still holds the last frame.
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      final decodePx = (size * dpr).ceil();
      final sized = ResizeImage.resizeIfNeeded(decodePx, decodePx, image!);

      // A plain background disc sits BEHIND the image so a re-resolve never
      // flashes through to a blank avatar, and `gaplessPlayback` keeps the last
      // frame across rebuilds — without it, web re-fetches the image on every
      // rebuild (hover, stream, timer) and the avatar visibly blinks.
      //
      // Only the empty disc goes behind — never the initials/icon fallback.
      // Logos and favicons are frequently transparent PNGs, so anything painted
      // behind them bleeds through `BoxFit.cover`'s transparent pixels. The
      // initials belong solely to the image-absent path and the `errorBuilder`.
      content = Stack(
        fit: StackFit.expand,
        children: [
          _disc(t),
          Image(
            image: sized,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _fallback(t),
          ),
        ],
      );
    } else {
      content = _fallback(t);
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: content),
    );
  }

  /// The non-image content: [initials], then [icon], then an empty disc.
  /// Also used as the error fallback when [image] fails to load.
  Widget _fallback(DesignSystemTokens t) {
    if (initials != null && initials!.isNotEmpty) {
      return _disc(
        t,
        child: Text(
          initials!.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: size * 0.4,
            height: 1,
            fontWeight: FontWeight.w400,
            color: t.textSecondary,
          ),
        ),
      );
    } else if (icon != null) {
      return _disc(
        t,
        child: Icon(icon, size: size * 0.5, color: t.textSecondary),
      );
    }
    return _disc(t);
  }

  Widget _disc(DesignSystemTokens t, {Widget? child}) {
    return ColoredBox(
      color: background ?? t.bgTertiary,
      child: Center(child: child),
    );
  }
}
