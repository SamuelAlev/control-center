import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';

/// One target in a fallback chain: a provider/model plus a lazy builder that
/// constructs the concrete [LlmProviderPort] (closing over its credential).
class FallbackEntry {
  /// Creates a [FallbackEntry].
  FallbackEntry({
    required this.providerId,
    required this.model,
    required this.build,
    this.credentialId,
  });

  /// Provider id this entry targets (for cost attribution).
  final String providerId;

  /// Model id this entry uses.
  final String model;

  /// Builds the provider on first use (cached by [FallbackProvider]).
  final LlmProviderPort Function() build;

  /// Which stored credential this entry spends, when it is a credential
  /// rotation target rather than a cross-provider fallback.
  ///
  /// Carried so the host can remember WHICH key ran out, not merely that the
  /// chain moved. Without it a rotation rediscovers the same exhausted key on
  /// every dispatch and pays a 429 to learn it again.
  final String? credentialId;
}

/// An [LlmProviderPort] that streams from the first working target in a chain
/// and transparently advances to the next on a NON-retryable error (auth,
/// quota, model-not-found). Retryable errors are surfaced to the loop, which
/// retries with backoff — EXCEPT capacity errors (429 / rate-limit /
/// overloaded / quota): when a later entry exists (a second key or
/// subscription), an exhausted target fails over immediately instead of
/// burning the loop's backoff budget on a target with no headroom. A terminal
/// error is only emitted when every target has failed.
///
/// The chain is credential rotation (same provider, different keys/accounts)
/// and/or cross-provider fallback. It is session-sticky: once a target works,
/// later turns start there.
class FallbackProvider implements LlmProviderPort {
  /// Creates a [FallbackProvider] over `entries` (primary first).
  FallbackProvider(this._entries, {this.onFallback}) {
    if (_entries.isEmpty) {
      throw ArgumentError('need at least one entry');
    }
  }

  final List<FallbackEntry> _entries;

  /// Called when the chain advances from one entry to the next.
  ///
  /// `fromCredentialId` is the credential that just failed — the actionable
  /// half, since it is what a later dispatch should skip. `capacity` marks a
  /// quota/rate-limit failure, the only kind worth remembering: an auth or
  /// model error will not clear on its own.
  final void Function(
    String fromProvider,
    String toProvider,
    String reason, {
    String? fromCredentialId,
    bool capacity,
  })?
  onFallback;

  final Map<int, LlmProviderPort> _built = {};
  int _active = 0;

  /// The provider id that served the most recent completion.
  String get lastServedProviderId => _entries[_active].providerId;

  /// The model that served the most recent completion.
  String get lastServedModel => _entries[_active].model;

  LlmProviderPort _providerAt(int i) => _built[i] ??= _entries[i].build();

  @override
  String get displayName => _providerAt(_active).displayName;

  @override
  String get defaultModel => _entries[_active].model;

  @override
  Future<List<ProviderModel>> listModels() => _providerAt(_active).listModels();

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    var i = _active;
    while (i < _entries.length) {
      final provider = _providerAt(i);
      // Attribute usage/cost to the target actually being consumed, before any
      // event is yielded (usage arrives before LlmDone, so updating _active only
      // at Done would mis-price the turn against the previous target).
      _active = i;
      LlmError? failure;
      var producedTerminal = false;
      // Once any observable output has streamed, switching targets would
      // duplicate/corrupt the assistant turn — so we must not fail over anymore.
      var producedOutput = false;

      await for (final event in provider.complete(
        messages: messages,
        tools: tools,
        config: config,
      )) {
        if (event is LlmError) {
          final canAdvance = i + 1 < _entries.length && !producedOutput;
          // A capacity error (429 / rate-limit / overloaded / quota) is
          // retryable on the SAME target after backoff, but when a later
          // entry exists the next key/account likely has headroom NOW —
          // rotate instead of stalling the run on an exhausted credential.
          if (!event.retryable || (canAdvance && _isCapacityError(event))) {
            failure = event;
            break; // cancels the stream; maybe try the next target
          }
          // Retryable with nowhere better to go: surface to the loop (it
          // retries with backoff). Emit a terminal Done so the stream completes.
          yield event;
          yield const LlmDone(stopReason: LlmStopReason.unknown);
          // Re-walk the whole chain from the primary on the loop's retry —
          // the backoff may have cleared an earlier target's window.
          _active = 0;
          producedTerminal = true;
          break;
        }
        if (event is LlmTextDelta ||
            event is LlmThinkingDelta ||
            event is LlmToolUseDelta) {
          producedOutput = true;
        }
        yield event;
        if (event is LlmDone) {
          producedTerminal = true;
          break;
        }
      }

      if (producedTerminal) {
        return;
      }
      if (failure != null) {
        final hasNext = i + 1 < _entries.length;
        // Only fail over when it is safe AND useful: no output has streamed yet
        // (else we'd replay a partial turn) and the failure is target-specific
        // (auth/quota/model, or a capacity error with a later entry) rather
        // than a request-level 400 that every target would reject identically.
        if (hasNext &&
            !producedOutput &&
            (failure.retryable || _isTargetError(failure))) {
          onFallback?.call(
            _entries[i].providerId,
            _entries[i + 1].providerId,
            failure.code ?? failure.message,
            fromCredentialId: _entries[i].credentialId,
            capacity: _isCapacityError(failure),
          );
          i++;
          continue;
        }
        yield failure;
        yield const LlmDone(stopReason: LlmStopReason.unknown);
        return;
      }
      // Stream ended without a terminal event.
      return;
    }
  }

  /// Whether [error] is a retryable capacity signal (rate limit / overloaded /
  /// quota) — eligible for rotation when a later entry exists even though the
  /// SAME target would also recover after a backoff.
  static bool _isCapacityError(LlmError error) {
    if (!error.retryable) {
      return false;
    }
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();
    return code.contains('429') ||
        code.contains('rate_limit') ||
        code.contains('overloaded') ||
        code.contains('quota') ||
        message.contains('rate limit') ||
        message.contains('quota');
  }

  /// Whether [error] is a target-specific failure (bad credential / quota /
  /// missing model) that a different target might succeed at — as opposed to a
  /// request-level rejection (400 / invalid request / context-length) that every
  /// target would reject identically, so failing over just wastes calls.
  static bool _isTargetError(LlmError error) {
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();
    // A spent balance is target-specific even when the API frames it as a
    // request error — Anthropic reports exhausted prepaid credit as a 400
    // `invalid_request_error` ("credit balance is too low"), OpenAI as a 429
    // `insufficient_quota`. Check this BEFORE the 400/invalid_request
    // exclusion or the one error rotation exists for is classified
    // un-failoverable.
    if (code.contains('quota') ||
        code.contains('billing') ||
        code.contains('credit') ||
        message.contains('insufficient_quota') ||
        message.contains('credit balance') ||
        message.contains('billing')) {
      return true;
    }
    if (code.contains('400') ||
        code.contains('invalid_request') ||
        code.contains('context')) {
      return false;
    }
    return code.contains('auth') ||
        code.contains('401') ||
        code.contains('403') ||
        code.contains('404') ||
        code.contains('model') ||
        code.contains('permission') ||
        code.contains('429');
  }
}
