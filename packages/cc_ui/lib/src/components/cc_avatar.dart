import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/primitives/image_fade.dart';
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
    this.semanticLabel,
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

  /// Accessible name announced for this avatar (the person/agent/feed it
  /// stands for).
  ///
  /// Without it an image-backed avatar announces NOTHING — the initials text
  /// only exists in the fallback path, so a screen reader gets an empty disc.
  /// Attribution is load-bearing in this product (who said it, who ran it), so
  /// the roster is exactly where that silence costs most. `CcIconButton`
  /// derives its name from its tooltip for the same reason.
  ///
  /// Null falls back to [initials] when present, so existing call sites gain a
  /// name for free; pass the full name to do better than "SA".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

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
      // flashes through to a blank avatar and [ImageFade] holds the last
      // frame across rebuilds — without it, web re-fetches the image on every
      // rebuild (hover, stream, timer) and the avatar visibly blinks. The disc
      // is ImageFade's placeholder, so the avatar cross-fades in over it
      // instead of snapping onto the surface.
      //
      // Only the empty disc goes behind — never the initials/icon fallback.
      // Logos and favicons are frequently transparent PNGs, so anything painted
      // behind them bleeds through `BoxFit.cover`'s transparent pixels. The
      // initials belong solely to the image-absent path and the `errorBuilder`.
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      content = ImageFade(
        image: sized,
        placeholder: _disc(t),
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 250),
        // Already-cached avatars (the common case after first load) appear
        // instantly rather than re-fading on every build.
        syncDuration: Duration.zero,
        errorBuilder: (context, error) => _fallback(t),
      );
    } else {
      content = _fallback(t);
    }

    final label = semanticLabel ?? initials;
    final avatar = SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: content),
    );
    if (label == null || label.isEmpty) {
      // A purely decorative avatar (icon/empty disc with no identity) is
      // EXCLUDED rather than announced as an unlabelled image.
      return ExcludeSemantics(child: avatar);
    }
    // `container: true` so this is a node of its own, and the inner initials
    // Text is excluded so the name is announced once, not twice.
    return Semantics(
      container: true,
      image: image != null,
      label: label,
      child: ExcludeSemantics(child: avatar),
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
            fontWeight: CcTypography.regularWeight,
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
