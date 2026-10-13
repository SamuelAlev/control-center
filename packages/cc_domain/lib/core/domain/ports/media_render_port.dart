import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Renders bounded previews from an image, video or PDF in the caller's workspace.
abstract interface class MediaRenderPort {
  /// Returns persisted image references and their bytes for the model.
  Future<MediaRenderResult> render(MediaRenderRequest request);
}

/// The authenticated scope and selectors, omitted for a still image.
class MediaRenderRequest {
  /// Creates a request. The transport and renderer each validate selectors.
  const MediaRenderRequest({
    required this.workspaceId,
    required this.agentId,
    this.spaceId,
    this.conversationId,
    required this.path,
    this.timestampsSeconds = const [],
    this.pages = const [],
    this.maxDimension = 1600,
    this.abandoned,
  });

  /// The workspace owning the source and previews.
  final String workspaceId;

  /// The agent making the request.
  final String agentId;

  /// Optional space containing the run.
  final String? spaceId;

  /// Optional conversation identifying the active run within the agent.
  final String? conversationId;

  /// Source path to resolve within the workspace.
  final String path;

  /// Video timestamps in seconds, finite and nonnegative.
  final List<double> timestampsSeconds;

  /// One-based PDF page numbers.
  final List<int> pages;

  /// Longest output edge, between 128 and 2048 pixels.
  final int maxDimension;

  /// Completes when the caller has stopped waiting for the preview.
  final Future<void>? abandoned;

  /// Checks the shared bounds before any media IO or process launch.
  void validate() {
    if (workspaceId.isEmpty || agentId.isEmpty) {
      throw const MediaRenderException(
        'Authenticated workspace and agent are required.',
      );
    }
    if (path.trim().isEmpty ||
        path.contains('\x00') ||
        path.contains('://') ||
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]+:').hasMatch(path)) {
      throw const MediaRenderException(
        'path must be a local image, video or PDF path.',
      );
    }
    if ((timestampsSeconds.isNotEmpty && pages.isNotEmpty) ||
        timestampsSeconds.length > 4 ||
        pages.length > 4) {
      throw const MediaRenderException(
        'Specify 1 to 4 timestamps_seconds or pages, but not both. Omit selectors for a still image.',
      );
    }
    if (timestampsSeconds.any((value) => !value.isFinite || value < 0)) {
      throw const MediaRenderException(
        'timestamps_seconds must contain finite nonnegative numbers.',
      );
    }
    if (pages.any((value) => value < 1)) {
      throw const MediaRenderException(
        'pages must contain one-based integers.',
      );
    }
    if (maxDimension < 128 || maxDimension > 2048) {
      throw const MediaRenderException(
        'max_dimension must be between 128 and 2048.',
      );
    }
  }
}

/// Metadata and the ordered rendered previews.
class MediaRenderResult {
  /// Creates a result.
  const MediaRenderResult({
    required this.source,
    this.durationSeconds,
    this.pageCount,
    required this.images,
  });

  /// Source media kind (`image`, `video` or `pdf`).
  final String source;

  /// Video duration when available.
  final double? durationSeconds;

  /// Number of PDF pages when available.
  final int? pageCount;

  /// Rendered previews, in requested order.
  final List<RenderedMediaImage> images;
}

/// Encoded image bytes plus a durable blob reference for the transcript.
class RenderedMediaImage {
  /// Creates one rendered image.
  const RenderedMediaImage({
    required this.bytes,
    required this.image,
    this.page,
    this.timestampSeconds,
    this.requestedTimestampSeconds,
  });

  /// Image bytes delivered to the model, never persisted in the transcript.
  final Uint8List bytes;

  /// Durable blob metadata delivered to the transcript.
  final ToolImageRef image;

  /// One-based PDF page, when rendering a PDF.
  final int? page;

  /// Actual timestamp of the selected video frame.
  final double? timestampSeconds;

  /// Timestamp requested by the model.
  final double? requestedTimestampSeconds;
}

/// An invalid source or a failed media render.
class MediaRenderException implements Exception {
  /// Creates a domain-level error.
  const MediaRenderException(this.message);

  /// Human-readable failure reason.
  final String message;

  @override
  String toString() => 'MediaRenderException: $message';
}
