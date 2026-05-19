import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

/// A remote image that loads through the host media proxy and cross-fades in:
/// a server-downscaled lightweight preview fills the box almost instantly, then
/// the full-resolution image fades in over it as its bytes arrive.
///
/// This does NOT size itself — the caller reserves the box (an [AspectRatio], a
/// fixed [SizedBox], an [Expanded] in a bounded column, …). Reserving the box
/// up front is what keeps layout from jumping when the image lands; this just
/// fills that box. See the component doc on [CcImageFade] for the sizing rules.
///
/// Two proxy requests are issued per image:
///   * [maxWidth] device px — the full-resolution variant, the one that ends up
///     on screen.
///   * [previewMaxWidth] device px (defaults to a small fraction of [maxWidth],
///     capped) — a cheap lightweight variant the proxy serves almost
///     instantly. It becomes [CcImageFade]'s placeholder, so the box fills with
///     a recognisable (if soft) image within a frame and then sharpens, instead
///     of sitting on a flat colour and snapping.
///
/// Each `(url, w)` is a distinct proxy cache key, so the lightweight fetch does
/// not evict or thrash the full one — see `MediaProxyConfig.resolve`. When no
/// [MediaProxyScope] is present (not-yet-connected) the URLs pass through
/// unchanged.
class ProxiedImage extends StatelessWidget {
  /// Creates a [ProxiedImage].
  const ProxiedImage({
    super.key,
    required this.url,
    required this.maxWidth,
    this.previewMaxWidth,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorBuilder,
    this.duration = const Duration(milliseconds: 300),
  });

  /// The raw upstream image URL (rewritten through the host media proxy).
  final String url;

  /// Target width in DEVICE pixels for the full-resolution variant. The proxy
  /// downscale and the decode cap both key off this. Always supply it: it is
  /// what stops a multi-thousand-pixel photo from decoding full-res into a
  /// small tile.
  final int maxWidth;

  /// Target width in DEVICE pixels for the lightweight preview. Defaults to a
  /// small fraction of [maxWidth] (capped at 48px) — enough to fill the box
  /// recognisably, cheap enough to serve in a frame.
  final int? previewMaxWidth;

  /// How the image paints inside its (caller-sized) box.
  final BoxFit fit;

  /// How to align the image within its bounds.
  final Alignment alignment;

  /// Painted behind everything while no bytes are present. Defaults to a quiet
  /// design-system surface.
  final Widget? placeholder;

  /// Faded in over prior content if the full image fails. Keep it subtle.
  final ImageFadeErrorBuilder? errorBuilder;

  /// Cross-fade duration.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final full = MediaProxyScope.urlOf(context, url, maxWidth: maxWidth);
    final previewWidth = previewMaxWidth ?? (maxWidth < 96 ? maxWidth : 48);
    final preview = MediaProxyScope.urlOf(context, url, maxWidth: previewWidth);

    return CcImageFade(
      // Wrap in ResizeImage so the decode (not just the proxy fetch) is capped
      // to the displayed size — a belt-and-suspenders to the server downscale.
      image: ResizeImage(DiskCachedNetworkImage(full), width: maxWidth),
      preview: ResizeImage(
        DiskCachedNetworkImage(preview),
        width: previewWidth,
      ),
      placeholder: placeholder,
      errorBuilder: errorBuilder,
      fit: fit,
      alignment: alignment,
      duration: duration,
    );
  }
}
