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

  @override
  int get hashCode => Object.hash(id, url, previewUrl, width, height);
}

