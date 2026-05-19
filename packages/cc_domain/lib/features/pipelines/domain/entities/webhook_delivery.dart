/// Lifecycle status of an inbound webhook delivery.
enum WebhookDeliveryStatus {
  /// Accepted, awaiting dispatch.
  queued,

  /// Started its pipeline run.
  dispatched,

  /// Refused before dispatch (bad signature, unknown token, duplicate).
  rejected,

  /// Accepted but intentionally not acted on (filtered out by event filters).
  ignored,

  /// Dispatch was attempted but errored.
  failed;

  /// Storage string.
  String toStorageString() => name;

  /// Parses from storage string, defaulting to [rejected].
  static WebhookDeliveryStatus fromString(String value) => switch (value) {
    'queued' => WebhookDeliveryStatus.queued,
    'dispatched' => WebhookDeliveryStatus.dispatched,
    'ignored' => WebhookDeliveryStatus.ignored,
    'failed' => WebhookDeliveryStatus.failed,
    _ => WebhookDeliveryStatus.rejected,
  };
}

/// Outcome of verifying an inbound delivery's HMAC signature.
enum WebhookSignatureStatus {
  /// Signature present and matched.
  valid,

  /// Signature present but did not match.
  invalid,

  /// No signature header was sent.
  missing,

  /// Verification was not performed (the trigger has no secret configured).
  skipped;

  /// Storage string.
  String toStorageString() => name;

  /// Parses from storage string, defaulting to [missing].
  static WebhookSignatureStatus fromString(String value) => switch (value) {
    'valid' => WebhookSignatureStatus.valid,
    'invalid' => WebhookSignatureStatus.invalid,
    'skipped' => WebhookSignatureStatus.skipped,
    _ => WebhookSignatureStatus.missing,
  };
}

/// A logged inbound webhook delivery: the raw request, its verification
/// outcome and what the server did with it.
class WebhookDelivery {
  /// Creates a [WebhookDelivery].
  WebhookDelivery({
    required this.id,
    required this.workspaceId,
    required this.triggerId,
    required this.status,
    required this.signatureStatus,
    this.dedupeKey,
    this.dedupeSource,
    this.eventAction,
    this.rawBody,
    this.headers = const {},
    this.responseStatus,
    this.responseBody,
    this.runId,
    required this.createdAt,
  });

  /// Unique delivery id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The trigger this delivery was routed to.
  final String triggerId;

  /// What the server did with the delivery.
  final WebhookDeliveryStatus status;

  /// The signature verification outcome.
  final WebhookSignatureStatus signatureStatus;

  /// Idempotency key extracted from the request (e.g. GitHub `X-GitHub-Delivery`),
  /// used to drop duplicate deliveries.
  final String? dedupeKey;

  /// Where [dedupeKey] came from (e.g. the header name).
  final String? dedupeSource;

  /// The event action declared by the request (e.g. `push`, `opened`), matched
  /// against the trigger's event filters.
  final String? eventAction;

  /// The raw request body.
  final String? rawBody;

  /// The request headers.
  final Map<String, String> headers;

  /// HTTP status the server replied with.
  final int? responseStatus;

  /// Response body the server replied with.
  final String? responseBody;

  /// The pipeline run this delivery started, if any.
  final String? runId;

  /// When the delivery was received.
  final DateTime createdAt;

  /// Whether this delivery can be replayed.
  ///
  /// A delivery that failed signature verification (invalid or missing) is
  /// **never** replayable — replaying it would still fail the security gate.
  /// Deliveries that passed (or skipped) verification but were ignored/failed
  /// for a downstream reason can be replayed.
  bool get replayable =>
      signatureStatus != WebhookSignatureStatus.invalid &&
      signatureStatus != WebhookSignatureStatus.missing;

  /// Returns a copy with an updated [status], [runId] and response fields.
  WebhookDelivery copyWith({
    WebhookDeliveryStatus? status,
    String? runId,
    int? responseStatus,
    String? responseBody,
  }) => WebhookDelivery(
    id: id,
    workspaceId: workspaceId,
    triggerId: triggerId,
    status: status ?? this.status,
    signatureStatus: signatureStatus,
    dedupeKey: dedupeKey,
    dedupeSource: dedupeSource,
    eventAction: eventAction,
    rawBody: rawBody,
    headers: headers,
    responseStatus: responseStatus ?? this.responseStatus,
    responseBody: responseBody ?? this.responseBody,
    runId: runId ?? this.runId,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebhookDelivery &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
