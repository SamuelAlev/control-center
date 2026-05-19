import 'package:cc_ui/src/primitives/image_fade.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// A network/asset image that reserves its box and cross-fades in, instead of
/// popping onto the surface the moment its bytes arrive.
///
/// This wraps [ImageFade], which paints a [placeholder] while
/// the [image] resolves and then animates the loaded frame over it. The widget
/// does NOT impose a size: the caller decides the box (an [AspectRatio], a
/// fixed [SizedBox], an [Expanded] inside a bounded column, …) and this fills
/// it. That is the whole point — deciding the box up front is what stops layout
/// from jumping when an image lands.
///
/// ## Progressive loading (lightweight → full)
///
/// Pass a [preview] — a small, cheap [ImageProvider] (typically a
/// proxy-rewritten URL asked for only a few device pixels). It becomes the
/// placeholder the full-resolution [image] fades in over, so the box fills
/// with a recognisable, if soft, image almost immediately and then sharpens as
/// the real bytes arrive — instead of sitting on a flat colour and then
/// snapping. See the app's `ProxiedImage`, which wires this up against the host
/// media proxy's server-side downscale.
///
/// Keep placeholders simple: a solid surface colour or a shimmer. Avoid
/// loading spinners — they read as "stuck". Keep [errorBuilder] subtle too: a
/// muted surface, a small icon at most, never a technical message.
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
    this.duration = const Duration(milliseconds: 300),
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

  /// How to align the image within its bounds.
  final Alignment alignment;

  /// Cross-fade duration. Honours the ambient `disableAnimations` media query
  /// (collapses to [Duration.zero] under reduced motion).
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = reduceMotion ? Duration.zero : duration;

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
