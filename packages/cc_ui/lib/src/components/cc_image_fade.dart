import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/primitives/image_fade.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// Network/asset image that reserves its box and cross-fades in (wraps
/// [ImageFade]). Caller sizes the box; this fills it. Optional [preview] is a
/// cheap placeholder the full [image] fades over. Keep placeholders/errors
/// subtle (surface/shimmer/icon) — no spinners or technical messages.
class CcImageFade extends StatelessWidget {
  /// Creates a [CcImageFade].
  const CcImageFade({
    super.key,
    required this.image,
    this.preview,
    this.placeholder,
    this.errorBuilder,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.duration = CcMotion.slow,
  });

  /// The full-resolution image to display; cross-fades in over [placeholder]
  /// (and [preview]) once resolved.
  final ImageProvider<Object> image;

  /// Optional lightweight image shown behind [image] while it loads. Sourced
  /// from a cheap, server-downscaled variant so it fills the box almost
  /// instantly (see `ProxiedImage`). When null, only [placeholder] shows.
  final ImageProvider<Object>? preview;

  /// Widget painted behind everything while no image bytes are present yet.
  /// Defaults to a quiet `bgSecondary` surface. Layered UNDER [preview].
  final Widget? placeholder;

  /// Shown if [image] fails to load, faded in over whatever was already on
  /// screen. Keep it an opaque, muted surface (the fade is over prior content).
  final ImageFadeErrorBuilder? errorBuilder;

  /// How the image paints inside its box. Defaults to [BoxFit.cover]. Note:
  /// `fit` only decides how the bytes paint inside an ALREADY-sized box — it
  /// does not reserve space. The parent's box does.
  final BoxFit fit;

  /// How to align the image within its bounds. [AlignmentGeometry], so
  /// directional alignments mirror under RTL.
  final AlignmentGeometry alignment;

  /// Cross-fade duration. Under reduced motion this becomes [CcMotion.fade]
  /// so the image still appears, just without a long wash.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final effectiveDuration = CcMotion.resolveFade(context, duration);

    final Widget basePlaceholder =
        placeholder ??
        ColoredBox(color: tokens?.bgSecondary ?? _kFallbackBackdrop);

    // The preview becomes the placeholder the full image fades over. Nesting a
    // second ImageFade here is intentional: ImageFade layers its `placeholder`
    // behind the loaded frame, so the preview (which itself cross-fades in over
    // [basePlaceholder]) fills the box quickly and the full image then fades in
    // on top of it — no hand-rolled timing.
    final Widget layeredPlaceholder = preview != null
        ? ImageFade(
            image: preview,
            placeholder: basePlaceholder,
            fit: fit,
            alignment: alignment,
            duration: effectiveDuration,
            // Already cached / tiny images should appear instantly, not animate.
            syncDuration: Duration.zero,
          )
        : basePlaceholder;

    return ImageFade(
      image: image,
      placeholder: layeredPlaceholder,
      fit: fit,
      alignment: alignment,
      duration: effectiveDuration,
      syncDuration: Duration.zero,
      errorBuilder: errorBuilder,
    );
  }
}

const Color _kFallbackBackdrop = Color(0xFFE5E7EB);
