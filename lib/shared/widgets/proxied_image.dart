import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A remote image that loads through the host media proxy and cross-fades in.
/// The tiny preview loads when built, including in a scroll viewport's bounded
/// cache region. The full image starts only after the tile is first painted.
/// Each `(url, w)` is a distinct proxy cache key, so the preview does not evict
/// or thrash the full one — see `MediaProxyConfig.resolve`.
class ProxiedImage extends StatefulWidget {
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
  State<ProxiedImage> createState() => _ProxiedImageState();
}

class _ProxiedImageState extends State<ProxiedImage> {
  bool _loadFullImage = false;

  @override
  void didUpdateWidget(ProxiedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.previewMaxWidth != widget.previewMaxWidth) {
      _loadFullImage = false;
    }
  }

  void _onFirstPaint() {
    // Slivers lay out their cache region but paint only visible children.
    // Wait until paint completes before rebuilding to resolve the full image.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_loadFullImage) {
        setState(() => _loadFullImage = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewWidth =
        widget.previewMaxWidth ?? (widget.maxWidth < 96 ? widget.maxWidth : 48);
    final preview = ResizeImage(
      DiskCachedNetworkImage(
        MediaProxyScope.urlOf(context, widget.url, maxWidth: previewWidth),
      ),
      width: previewWidth,
    );
    final image = _loadFullImage
        ? ResizeImage(
            DiskCachedNetworkImage(
              MediaProxyScope.urlOf(
                context,
                widget.url,
                maxWidth: widget.maxWidth,
              ),
            ),
            width: widget.maxWidth,
          )
        : preview;

    return _FirstPaint(
      onPaint: _loadFullImage ? null : _onFirstPaint,
      child: CcImageFade(
        // Proxy requests and decoded frames are both capped to the tile size.
        image: image,
        preview: _loadFullImage ? preview : null,
        placeholder: widget.placeholder,
        errorBuilder: widget.errorBuilder,
        fit: widget.fit,
        alignment: widget.alignment,
        duration: widget.duration,
      ),
    );
  }
}

/// Uses the sliver's existing paint culling instead of per-image scroll listeners.
class _FirstPaint extends SingleChildRenderObjectWidget {
  const _FirstPaint({required this.onPaint, required super.child});

  final VoidCallback? onPaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFirstPaint(onPaint);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderFirstPaint renderObject,
  ) {
    if (renderObject.onPaint != onPaint) {
      renderObject
        ..onPaint = onPaint
        ..markNeedsPaint();
    }
  }
}

class _RenderFirstPaint extends RenderProxyBox {
  _RenderFirstPaint(this.onPaint);

  VoidCallback? onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    final callback = onPaint;
    onPaint = null;
    callback?.call();
    super.paint(context, offset);
  }
}
