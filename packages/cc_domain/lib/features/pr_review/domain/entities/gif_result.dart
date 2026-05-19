/// Gif result.
class GifResult {
  /// GifResult.
  const GifResult({
    required this.id,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
  });

  /// Creates a [GifResult] from a JSON map.
  factory GifResult.fromJson(Map<String, dynamic> json) {
    final file = json['file'] as Map<String, dynamic>;
    final sm = file['sm'] as Map<String, dynamic>?;
    final hd = file['hd'] as Map<String, dynamic>?;
    final gif =
        (hd?['gif'] ?? sm?['gif'] ?? sm?['webp']) as Map<String, dynamic>?;
    final preview =
        (sm?['gif'] ?? sm?['webp'] ?? sm?['jpg'] ?? gif)
            as Map<String, dynamic>?;
    return GifResult(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      url: (gif?['url'] as String?) ?? '',
      previewUrl:
          (preview?['url'] as String?) ?? (gif?['url'] as String?) ?? '',
      width: (gif?['width'] as num?)?.toInt() ?? 0,
      height: (gif?['height'] as num?)?.toInt() ?? 0,
    );
  }

  /// Rebuilds a [GifResult] from its flat [toWire] map (the thin client's parse
  /// of the `gif.search` / `gif.trending` RPC result).
  factory GifResult.fromWire(Map<String, dynamic> json) => GifResult(
    id: (json['id'] as num?)?.toInt() ?? 0,
    url: json['url'] as String? ?? '',
    previewUrl: json['preview_url'] as String? ?? '',
    width: (json['width'] as num?)?.toInt() ?? 0,
    height: (json['height'] as num?)?.toInt() ?? 0,
  );

  /// Flat wire map for the `gif.*` RPC ops (the server parses Klipy's nested
  /// response via [GifResult.fromJson], then ships this to the client).
  Map<String, dynamic> toWire() => <String, dynamic>{
    'id': id,
    'url': url,
    'preview_url': previewUrl,
    'width': width,
    'height': height,
  };

  /// Identifier.
  final int id;

  /// URL.
  final String url;

  /// Preview URL.
  final String previewUrl;

  /// Width.
  final int width;

  /// Height.
  final int height;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GifResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          previewUrl == other.previewUrl &&
          width == other.width &&
          height == other.height;

  /// Hash code.
  @override
  int get hashCode => Object.hash(id, url, previewUrl, width, height);
}
