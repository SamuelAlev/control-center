import 'package:cc_domain/cc_domain.dart';

/// One recorded request→response exchange in a cassette.
class HttpInteraction {
  /// Creates an [HttpInteraction].
  const HttpInteraction({required this.request, required this.response});

  /// The (redacted) request that was sent.
  final RequestSnapshot request;

  /// The response that came back.
  final ResponseSnapshot response;

  /// Serializes to a cassette JSON map.
  Map<String, dynamic> toJson() => {
    'transport': 'http',
    'request': request.toJson(),
    'response': response.toJson(),
  };

  /// Reads an interaction from a cassette JSON map.
  static HttpInteraction fromJson(Map<String, dynamic> json) => HttpInteraction(
    request: RequestSnapshot.fromJson(
      (json['request'] as Map).cast<String, dynamic>(),
    ),
    response: ResponseSnapshot.fromJson(
      (json['response'] as Map).cast<String, dynamic>(),
    ),
  );
}

/// A reviewable, version-controlled recording of HTTP traffic — the JSON file
/// at `test/fixtures/recordings/<name>.json`.
class Cassette {
  /// Creates a [Cassette].
  Cassette({
    this.version = 1,
    this.metadata,
    List<HttpInteraction>? interactions,
  }) : interactions = interactions ?? <HttpInteraction>[];

  /// Cassette format version.
  final int version;

  /// Free-form metadata (name, recordedAt, …).
  final Map<String, dynamic>? metadata;

  /// The recorded exchanges, in record order.
  final List<HttpInteraction> interactions;

  /// Serializes to a cassette JSON map.
  Map<String, dynamic> toJson() => {
    'version': version,
    if (metadata != null) 'metadata': metadata,
    'interactions': [for (final i in interactions) i.toJson()],
  };

  /// Reads a cassette from a parsed JSON map.
  static Cassette fromJson(Map<String, dynamic> json) => Cassette(
    version: (json['version'] as num?)?.toInt() ?? 1,
    metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
    interactions: [
      for (final raw in (json['interactions'] as List? ?? const []))
        if (raw is Map && raw['transport'] == 'http')
          HttpInteraction.fromJson(raw.cast<String, dynamic>()),
    ],
  );
}
