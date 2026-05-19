import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Signature used by [ImageFade.errorBuilder] to build the widget shown when an
/// image fails to load.
typedef ImageFadeErrorBuilder =
    Widget Function(BuildContext context, Object error);

/// Displays [placeholder] while [image] loads, then cross-fades the decoded
/// image in over it. Changing [image] cross-fades the new one over the last
/// frame of the old one; setting it to null fades back to [placeholder].
///
/// This does NOT size itself unless [width]/[height] are given — the caller
/// reserves the box. See `CcImageFade`, the themed wrapper most app code should
/// use instead of this primitive.
///
/// ## Animated images
///
/// An animated image (GIF, APNG, animated WebP) delivers a new frame to its
/// image stream every few tens of milliseconds. Only the FIRST frame starts the
/// cross-fade; every frame after it merely repaints. Restarting the fade per
/// frame is what renders animated images washed out — a 30ms frame interval
/// against a 300ms fade never lets opacity climb past ~10%, so the animation
/// plays but the colours sit at a fraction of their real intensity.
class ImageFade extends StatefulWidget {
  /// Creates an [ImageFade].
  const ImageFade({
    super.key,
    this.image,
    this.placeholder,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 300),
    this.syncDuration,
    this.width,
    this.height,
    this.scale = 1,
    this.fit = BoxFit.scaleDown,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.excludeFromSemantics = false,
    this.semanticLabel,
    this.errorBuilder,
  });

  /// The image to display. Changing it fades the new image over the previous one.
  final ImageProvider<Object>? image;

  /// Painted behind the image layers and shown while [image] first loads.
  final Widget? placeholder;

  /// Curve of the fade-in.
  final Curve curve;

  /// Duration of the fade-in.
  final Duration duration;

  /// Duration used when the image resolved synchronously (already decoded, from
  /// the image cache), when [errorBuilder] content fades in and when fading
  /// back to [placeholder]. Pass [Duration.zero] to show cached images
  /// instantly. Falls back to [duration] when null.
  final Duration? syncDuration;

  /// Width of the reserved box. See [Image.width].
  final double? width;

  /// Height of the reserved box. See [Image.height].
  final double? height;

  /// Scale factor for drawing the image at its intended size. See [RawImage.scale].
  final double scale;

  /// How the image paints inside its box. See [Image.fit].
  final BoxFit fit;

  /// How the image aligns within its bounds. See [Image.alignment].
  final Alignment alignment;

  /// How to paint any area not covered by the image. See [Image.repeat].
  final ImageRepeat repeat;

  /// Whether to flip the image in RTL. See [Image.matchTextDirection].
  final bool matchTextDirection;

  /// Whether to exclude this image from semantics. See [Image.excludeFromSemantics].
  final bool excludeFromSemantics;

  /// Semantic description of the image. See [Image.semanticLabel].
  final String? semanticLabel;

  /// Builds the content shown when [image] fails. It fades in over whatever was
  /// already on screen, so give it an opaque background.
  final ImageFadeErrorBuilder? errorBuilder;

  @override
  State<ImageFade> createState() => _ImageFadeState();
}

class _ImageFadeState extends State<ImageFade> with TickerProviderStateMixin {
  late final AnimationController _controller;

  _ImageResolver? _resolver;

  /// The outgoing layer — the last frame of the previous image, held behind the
  /// incoming one — and its faded form.
  Widget? _back;
  Widget? _fadeBack;

  Animation<double>? _frontOpacity;
  Animation<double>? _backOpacity;

  /// Null until the first build; true when the image resolved before it, which
  /// means it came from the cache and should use [ImageFade.syncDuration].
  bool? _sync;

  bool _pendingTransition = false;
  bool _transitionStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cannot resolve in initState: createLocalImageConfiguration needs a
    // context with its inherited widgets in place.
    _resolve(providerChanged: false);
  }

  @override
  void didUpdateWidget(ImageFade old) {
    super.didUpdateWidget(old);
    if (widget.image != old.image) _resolve(providerChanged: true);
  }

  void _resolve({required bool providerChanged}) {
    final ImageProvider<Object>? provider = widget.image;

    ImageStream? stream;
    if (provider != null) {
      stream = provider.resolve(
        createLocalImageConfiguration(
          context,
          size: widget.width != null && widget.height != null
              ? Size(widget.width!, widget.height!)
              : null,
        ),
      );
      // The image configuration is context-derived, so a dependency change can
      // legitimately select a different variant — but most of them (a theme
      // swap, an unrelated MediaQuery nudge) resolve to the very same stream.
      // Re-seating the resolver for those would restart the cross-fade and for
      // an animated image it would restart it mid-animation.
      if (!providerChanged && _resolver?.isFor(stream) == true) return;
    }

    final _ImageResolver? previous = _resolver;
    if (previous != null) {
      // Freeze the outgoing image's latest frame behind the incoming one so the
      // surface never flashes through to the placeholder mid-swap. Snapshot it
      // from the resolver rather than from the last build: a frame that arrived
      // after that build has already scheduled its predecessor for release.
      if (previous.error) {
        _back = widget.errorBuilder?.call(context, previous.exception!);
      } else {
        _back = previous.hasContent ? _rawImage(previous.image) : null;
      }
      previous.dispose();
    }

    _fadeBack = null;
    _sync = null;
    _pendingTransition = false;
    _transitionStarted = false;

    _resolver = stream == null
        ? null
        : _ImageResolver(stream, onFrame: _handleFrame);

    // Nothing incoming: fade the outgoing layer out to the placeholder.
    if (_resolver == null && _back != null) _pendingTransition = true;

    // Attached only once _resolver is seated, because an already-decoded image
    // calls back synchronously and _handleFrame has to recognise the sender.
    _resolver?.start();
  }

  void _handleFrame(_ImageResolver resolver) {
    if (!mounted || resolver != _resolver) return;
    _sync ??= true;
    // Only the first frame (or an error) starts the cross-fade. Later frames
    // are the subsequent frames of an animated image: they repaint without
    // touching the controller.
    setState(() {
      if (!_transitionStarted) _pendingTransition = true;
    });
  }

  void _startTransition({required bool out}) {
    _pendingTransition = false;
    _transitionStarted = true;

    final bool fast = _sync != false || _resolver?.error == true || out;
    final Duration duration =
        (fast ? widget.syncDuration : null) ?? widget.duration;

    // Fade the incoming layer in over `duration`, then the outgoing one out
    // over half as long again.
    _controller.duration = duration * (out ? 1 : 3 / 2);

    _frontOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(0, 2 / 3, curve: widget.curve),
    );
    _backOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(out ? 0 : 2 / 3, 1)),
    );

    _fadeBack = _back == null ? null : _withOpacity(_back!, _backOpacity!);

    if (!out || _back != null) _controller.forward(from: 0);
  }

  Widget _withOpacity(Widget content, Animation<double> opacity) {
    // A decoded frame takes the opacity on the RawImage itself, which folds it
    // into the image's paint instead of allocating a saveLayer.
    return content is RawImage
        ? _rawImage(content.image, opacity: opacity)
        : FadeTransition(opacity: opacity, child: content);
  }

  RawImage _rawImage(ui.Image? image, {Animation<double>? opacity}) {
    return RawImage(
      image: image,
      width: widget.width,
      height: widget.height,
      scale: widget.scale,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
      opacity: opacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    _sync ??= false;

    final _ImageResolver? resolver = _resolver;

    // The top layer is rebuilt on every build rather than cached, so a new
    // frame of an animated image repaints against the existing animation.
    Widget? frontContent;
    if (resolver != null && resolver.hasContent) {
      frontContent = resolver.error
          ? widget.errorBuilder?.call(context, resolver.exception!)
          : _rawImage(resolver.image);
    }

    if (_pendingTransition) _startTransition(out: frontContent == null);

    // A missing animation means content appeared without a transition, which
    // should not happen — paint it opaque rather than throw.
    final Widget? front = frontContent == null
        ? null
        : _withOpacity(frontContent, _frontOpacity ?? kAlwaysCompleteAnimation);

    final Widget content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.passthrough,
        children: [?widget.placeholder, ?_fadeBack, ?front],
      ),
    );

    if (widget.excludeFromSemantics) return content;
    return Semantics(
      container: widget.semanticLabel != null,
      image: true,
      label: widget.semanticLabel ?? '',
      child: content,
    );
  }

  @override
  void dispose() {
    _resolver?.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// Listens to one [ImageStream] and exposes its latest frame.
class _ImageResolver {
  _ImageResolver(this._stream, {required this.onFrame});

  final void Function(_ImageResolver resolver) onFrame;

  final ImageStream _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    _handleFrame,
    onError: _handleError,
  );

  ImageInfo? _imageInfo;

  /// Non-null once the image failed to load.
  Object? exception;

  /// Whether a frame has arrived or the load has failed — i.e. whether this
  /// resolver has anything to paint.
  bool get hasContent => _imageInfo != null || exception != null;

  bool get error => exception != null;

  ui.Image? get image => _imageInfo?.image;

  bool isFor(ImageStream stream) => stream.key == _stream.key;

  /// Begins listening. Calls back synchronously if the image is already decoded.
  void start() => _stream.addListener(_listener);

  void _handleFrame(ImageInfo info, bool synchronousCall) {
    final ImageInfo? superseded = _imageInfo;
    _imageInfo = info;
    // Every listener receives its own clone of the frame and owns it. Releasing
    // the superseded clone after the frame it was last painted in keeps an
    // animated image from piling up one live handle per frame.
    if (superseded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => superseded.dispose());
    }
    onFrame(this);
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    exception = error;
    onFrame(this);
  }

  void dispose() => _stream.removeListener(_listener);
}
