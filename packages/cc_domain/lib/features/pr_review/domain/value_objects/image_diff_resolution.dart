/// Blob references for a PR image/SVG before/after comparison.
///
/// Bytes never travel on the RPC socket (the WebSocket payload cap is 256 KB).
/// The client paints from signed `GET /blob` URLs built from these refs.
class ImageDiffResolution {
  /// Creates an [ImageDiffResolution].
  const ImageDiffResolution({
    this.baseRef,
    this.headRef,
    this.overlayRef,
    required this.mediaType,
    required this.changedPercent,
    required this.isIdentical,
  });

  /// Reads one back off the wire / disk cache.
  factory ImageDiffResolution.fromJson(Map<String, dynamic> json) {
    return ImageDiffResolution(
      baseRef: json['base_ref'] as String?,
      headRef: json['head_ref'] as String?,
      overlayRef: json['overlay_ref'] as String?,
      mediaType: json['media_type'] as String? ?? 'application/octet-stream',
      changedPercent: (json['changed_percent'] as num?)?.toDouble() ?? 0,
      isIdentical: json['identical'] as bool? ?? false,
    );
  }

  /// Empty result: no sides could be stored (missing blob store, empty fetch,
  /// or a demo/empty repository).
  static const empty = ImageDiffResolution(
    mediaType: 'application/octet-stream',
    changedPercent: 0,
    isIdentical: true,
  );

  /// `blob:sha256:<hex>` for the base (before) side, or null when the file
  /// was added / the fetch failed.
  final String? baseRef;

  /// `blob:sha256:<hex>` for the head (after) side, or null when the file
  /// was removed / the fetch failed.
  final String? headRef;

  /// PNG overlay of changed pixels, or null when sides differ in size, either
  /// side is missing, the file is SVG, or the pixels are identical.
  final String? overlayRef;

  /// MIME type of the source bytes (`image/png`, `image/svg+xml`, …).
  final String mediaType;

  /// Percentage of pixels that differ (0..100). Meaningful only when
  /// [overlayRef] is present; otherwise a size-mismatch or decode failure
  /// reports 100 without advertising a difference mode.
  final double changedPercent;

  /// Whether the two sides are byte-identical (or a single side exists).
  final bool isIdentical;

  /// Wire / cache payload. Refs only — never bytes.
  Map<String, dynamic> toJson() => {
    'base_ref': ?baseRef,
    'head_ref': ?headRef,
    'overlay_ref': ?overlayRef,
    'media_type': mediaType,
    'changed_percent': changedPercent,
    'identical': isIdentical,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDiffResolution &&
          baseRef == other.baseRef &&
          headRef == other.headRef &&
          overlayRef == other.overlayRef &&
          mediaType == other.mediaType &&
          changedPercent == other.changedPercent &&
          isIdentical == other.isIdentical;

  @override
  int get hashCode => Object.hash(
    baseRef,
    headRef,
    overlayRef,
    mediaType,
    changedPercent,
    isIdentical,
  );
}
