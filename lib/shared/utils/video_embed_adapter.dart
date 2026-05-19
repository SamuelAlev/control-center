/// Adapters that recognise third-party video-sharing URLs and translate them
/// into the form that can be embedded inside an in-app webview.
///
/// Each provider (Loom, …) gets one [VideoEmbedAdapter]. To support a new
/// provider, add an adapter and register it in [VideoEmbedRegistry.instance] —
/// nothing else in the markdown pipeline needs to change.
library;

/// Recognises a single video provider and rewrites its share/watch URLs to
/// the provider's embeddable form.
abstract interface class VideoEmbedAdapter {
  /// Human-readable provider name (proper noun, not translated) — used for
  /// the fallback card label, e.g. "Loom".
  String get providerName;

  /// Aspect ratio (width / height) to reserve for the embed.
  double get aspectRatio;

  /// Returns the embeddable URL for [url] when this adapter recognises it, or
  /// `null` when the URL belongs to another provider.
  Uri? embedUrlFor(Uri url);
}

/// The result of resolving a URL against the [VideoEmbedRegistry]: the adapter
/// that claimed it plus the embeddable URL it produced.
class VideoEmbedMatch {
  /// Creates a [VideoEmbedMatch].
  const VideoEmbedMatch({required this.adapter, required this.embedUrl});

  /// The adapter that recognised the source URL.
  final VideoEmbedAdapter adapter;

  /// The provider's embeddable URL (e.g. Loom's `/embed/<id>` form).
  final Uri embedUrl;
}

/// Resolves a URL against an ordered list of [VideoEmbedAdapter]s.
class VideoEmbedRegistry {
  /// Creates a registry over [adapters], tried in order.
  const VideoEmbedRegistry(this.adapters);

  /// The adapters to try, first match wins.
  final List<VideoEmbedAdapter> adapters;

  /// The app-wide registry. Add adapters here to support new providers.
  static const VideoEmbedRegistry instance = VideoEmbedRegistry(
    <VideoEmbedAdapter>[LoomEmbedAdapter()],
  );

  /// Returns the first adapter that recognises [url] together with the
  /// embeddable URL it produced, or `null` when no adapter handles it.
  VideoEmbedMatch? resolve(Uri url) {
    for (final adapter in adapters) {
      final embed = adapter.embedUrlFor(url);
      if (embed != null) {
        return VideoEmbedMatch(adapter: adapter, embedUrl: embed);
      }
    }
    return null;
  }
}

/// Recognises Loom share/embed links and normalises them to Loom's embed
/// form: `https://www.loom.com/embed/<id>`.
///
/// Both `loom.com/share/<id>` and `loom.com/embed/<id>` (with or without the
/// `www.` prefix and any query string / fragment) resolve to the same embed
/// URL — the `share` → `embed` swap is the whole adaptation.
class LoomEmbedAdapter implements VideoEmbedAdapter {
  /// Creates a [LoomEmbedAdapter].
  const LoomEmbedAdapter();

  static const Set<String> _hosts = {'loom.com', 'www.loom.com'};
  static const Set<String> _kinds = {'share', 'embed'};

  @override
  String get providerName => 'Loom';

  @override
  double get aspectRatio => 16 / 9;

  @override
  Uri? embedUrlFor(Uri url) {
    if (!_hosts.contains(url.host.toLowerCase())) {
      return null;
    }
    // Drop empty segments so a trailing slash (`/share/<id>/`) still resolves.
    final segments =
        url.pathSegments.where((s) => s.isNotEmpty).toList(growable: false);
    if (segments.length < 2) {
      return null;
    }
    if (!_kinds.contains(segments[0].toLowerCase())) {
      return null;
    }
    // Loom ids are alphanumeric; strip any trailing punctuation that may have
    // been pasted along with the URL (e.g. a sentence-ending period).
    final id = RegExp(r'[A-Za-z0-9]+').firstMatch(segments[1])?.group(0);
    if (id == null || id.isEmpty) {
      return null;
    }
    return Uri(
      scheme: 'https',
      host: 'www.loom.com',
      pathSegments: ['embed', id],
    );
  }
}
