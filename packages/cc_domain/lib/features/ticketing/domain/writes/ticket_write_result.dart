/// Closed, machine-readable error vocabulary for agent ticket writes.
///
/// Agents (and the CLI) get a stable `code` they can branch on instead of
/// parsing free-text exception messages. New cases are added here, never
/// invented at a call site.
enum TicketWriteErrorCode {
  /// The referenced ticket / worktree does not exist.
  notFound,

  /// The target belongs to a different workspace.
  workspaceMismatch,

  /// A required argument was missing or malformed.
  invalidArgument,

  /// The operation is not supported (e.g. an unknown subcommand / flag).
  unsupported,

  /// The write lost an optimistic-concurrency race; retry with fresh state.
  conflict,

  /// A vendor sync target was unreachable.
  vendorUnavailable,

  /// A vendor rejected the write for rate-limiting.
  rateLimited,

  /// An unexpected internal failure.
  internal;

  /// Serializes for storage / wire.
  String toWire() => name;
}

/// The result of an agent ticket write. Carries the success payload, a
/// closed-vocabulary error and the `meta.deduplicated` flag set when a
/// duplicate `writeId` short-circuited to a cached result.
class TicketWriteResult {
  /// Creates a success result.
  const TicketWriteResult.ok(this.data, {this.deduplicated = false})
    : ok = true,
      errorCode = null,
      errorMessage = null;

  /// Creates a failure result.
  const TicketWriteResult.failure(
    this.errorCode,
    this.errorMessage, {
    this.deduplicated = false,
    this.data = const {},
  }) : ok = false;

  /// Parses a result back from its JSON shape (used by the ledger replay).
  factory TicketWriteResult.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    final meta = json['meta'];
    final deduplicated = meta is Map && meta['deduplicated'] == true;
    if (ok) {
      final data = json['data'];
      return TicketWriteResult.ok(
        data is Map<String, dynamic> ? data : const {},
        deduplicated: deduplicated,
      );
    }
    final error = json['error'];
    final codeName = error is Map ? '${error['code']}' : 'internal';
    return TicketWriteResult.failure(
      TicketWriteErrorCode.values.firstWhere(
        (c) => c.name == codeName,
        orElse: () => TicketWriteErrorCode.internal,
      ),
      error is Map ? '${error['message']}' : '',
      deduplicated: deduplicated,
    );
  }

  /// Whether the write succeeded.
  final bool ok;

  /// Success payload (e.g. `{ticket_id, status}`). Empty on failure.
  final Map<String, dynamic> data;

  /// Whether this result was served from the idempotency ledger (a retry).
  final bool deduplicated;

  /// Closed-vocabulary error code, null on success.
  final TicketWriteErrorCode? errorCode;

  /// Human-readable error detail, null on success.
  final String? errorMessage;

  /// Returns a copy with [deduplicated] forced to true (used when replaying a
  /// ledgered result).
  TicketWriteResult asDeduplicated() {
    return ok
        ? TicketWriteResult.ok(data, deduplicated: true)
        : TicketWriteResult.failure(
            errorCode,
            errorMessage,
            deduplicated: true,
            data: data,
          );
  }

  /// The MCP/CLI-friendly JSON shape:
  /// `{ok, data?, error?: {code, message}, meta: {deduplicated}}`.
  Map<String, dynamic> toJson() => {
    'ok': ok,
    if (ok) 'data': data,
    if (!ok)
      'error': {'code': errorCode!.toWire(), 'message': errorMessage ?? ''},
    'meta': {'deduplicated': deduplicated},
  };
}
