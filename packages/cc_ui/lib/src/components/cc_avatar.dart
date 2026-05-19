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
      content = Image(
        image: image!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(t),
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
