/// Gif result.
class GifResult {
  /// GifResult.
  const GifResult({
    required this.id,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
    this.title = '',
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
      title: json['title'] is String ? json['title'] as String : '',
    );
  }

  /// Rebuilds a [GifResult] from one item of the `gif.search` /
  /// `gif.trending` RPC result: `{id, title, width, height, preview_url,
  /// gif_url}`, the same shape Control Center Connect's Klipy proxy returns.
  factory GifResult.fromWire(Map<String, dynamic> json) => GifResult(
    id: int.tryParse('${json['id']}') ?? 0,
    url: json['gif_url'] as String? ?? '',
    previewUrl: json['preview_url'] as String? ?? '',
    width: (json['width'] as num?)?.toInt() ?? 0,
    height: (json['height'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
  );

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

  /// Klipy's title for the GIF, or empty.
  final String title;

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
          height == other.height &&
          title == other.title;

  /// Hash code.
  @override
  int get hashCode => Object.hash(id, url, previewUrl, width, height, title);
}
