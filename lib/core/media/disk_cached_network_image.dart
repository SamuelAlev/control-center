import 'dart:async';
import 'dart:ui' as ui;

import 'package:control_center/core/media/media_disk_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The process-wide media disk cache, or null before [installMediaDiskCache].
///
/// A global rather than an injected dependency for the same reason
/// `imageCache` is one: the consumers are `ImageProvider`s, which Flutter
/// constructs inside `build` with no access to a `Ref` or a `BuildContext` at
/// resolve time. Null until boot installs one, and every call site degrades to
/// a plain network fetch — so a test that pumps a widget without booting the
/// app gets today's behaviour rather than a null check.
MediaDiskCache? _installed;

/// Installs [cache] as the process-wide media disk cache.
void installMediaDiskCache(MediaDiskCache cache) => _installed = cache;

/// Clears the installed cache (tests).
@visibleForTesting
void resetMediaDiskCache() => _installed = null;

/// The installed cache, if boot got that far.
MediaDiskCache? get mediaDiskCache => _installed;

/// A [NetworkImage] that reads through [MediaDiskCache] when one is installed.
///
/// Behaviourally identical to `NetworkImage` otherwise: same equality (so
/// Flutter's `ImageCache` still dedupes), same scale, same error semantics. The
/// only difference is where the bytes come from, which is what makes it safe to
/// swap in at every proxied-image call site.
///
/// On web the installed cache is inert and this falls through to the browser,
/// which is already caching these responses — see [MediaDiskCache].
@immutable
class DiskCachedNetworkImage extends ImageProvider<DiskCachedNetworkImage> {
  /// Creates a [DiskCachedNetworkImage] for [url].
  const DiskCachedNetworkImage(this.url, {this.scale = 1.0});

  /// The (already proxy-resolved) URL to load.
  final String url;

  /// Decode scale, matching [NetworkImage.scale].
  final double scale;

  @override
  Future<DiskCachedNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<DiskCachedNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final cache = _installed;
    if (cache == null) {
      return NetworkImage(key.url, scale: key.scale).loadImage(
        NetworkImage(key.url, scale: key.scale),
        decode,
      );
    }
    return MultiFrameImageStreamCompleter(
      codec: _load(cache, key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<String>('URL', key.url),
      ],
    );
  }

  Future<ui.Codec> _load(
    MediaDiskCache cache,
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) async {
    Uint8List? bytes;
    try {
      bytes = await cache.get(key.url);
    } on Object {
      bytes = null;
    }
    if (bytes == null || bytes.isEmpty) {
      // Fall back to the platform loader rather than failing: a cache that
      // cannot answer must never be the reason an image does not render.
      return _decodeViaNetwork(key, decode);
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  Future<ui.Codec> _decodeViaNetwork(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final completer = Completer<ui.Codec>();
    final provider = NetworkImage(key.url, scale: key.scale);
    final stream = provider.loadImage(provider, (
      buffer, {
      getTargetSize,
    }) async {
      final codec = await decode(buffer, getTargetSize: getTargetSize);
      if (!completer.isCompleted) {
        completer.complete(codec);
      }
      return codec;
    });
    // `loadImage` returns a completer, not the codec — surface its error so a
    // failed network load rejects instead of hanging forever.
    stream.addListener(
      ImageStreamListener(
        (_, _) {},
        onError: (error, stack) {
          if (!completer.isCompleted) {
            completer.completeError(error, stack);
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiskCachedNetworkImage &&
          other.url == url &&
          other.scale == scale;

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'DiskCachedNetworkImage')}'
      '("$url", scale: ${scale.toStringAsFixed(1)})';
}
