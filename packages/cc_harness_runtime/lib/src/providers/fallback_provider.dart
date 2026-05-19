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
  });

  /// Provider id this entry targets (for cost attribution).
  final String providerId;

  /// Model id this entry uses.
  final String model;

  /// Builds the provider on first use (cached by [FallbackProvider]).
  final LlmProviderPort Function() build;
}

/// An [LlmProviderPort] that streams from the first working target in a chain
/// and transparently advances to the next on a NON-retryable error (auth,
/// quota, model-not-found). Retryable errors (rate-limit / overloaded) are
/// surfaced to the loop, which retries the same target with backoff. A terminal
/// error is only emitted when every target has failed.
///
/// The chain is credential rotation (same provider, different keys/accounts)
/// and/or cross-provider fallback. It is session-sticky: once a target works,
/// later turns start there.
class FallbackProvider implements LlmProviderPort {
  /// Creates a [FallbackProvider] over `entries` (primary first).
  FallbackProvider(this._entries, {this.onFallback})
    : assert(_entries.isNotEmpty, 'need at least one entry');

  final List<FallbackEntry> _entries;

  /// Called when the chain advances from one entry to the next.
  final void Function(String fromProvider, String toProvider, String reason)?
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
      LlmError? nonRetryable;
      var producedTerminal = false;
      // Once any observable output has streamed, switching targets would
      // duplicate/corrupt the assistant turn — so we must not fail over anymore.
      var producedOutput = false;

      await for (final event in provider.complete(
        messages: messages,
        tools: tools,
        config: config,
      )) {
        if (event is LlmError && !event.retryable) {
          nonRetryable = event;
          break; // cancels the stream; maybe try the next target
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
        if (event is LlmError) {
          // Retryable: surface to the loop (it retries this target). Emit a
          // terminal Done so the loop's stream completes.
          yield const LlmDone(stopReason: LlmStopReason.unknown);
          producedTerminal = true;
          break;
        }
      }

      if (producedTerminal) {
        return;
      }
      if (nonRetryable != null) {
        final hasNext = i + 1 < _entries.length;
        // Only fail over when it is safe AND useful: no output has streamed yet
        // (else we'd replay a partial turn) and the failure is target-specific
        // (auth/quota/model) rather than a request-level 400 that every target
        // would reject identically.
        if (hasNext && !producedOutput && _isTargetError(nonRetryable)) {
          onFallback?.call(
            _entries[i].providerId,
            _entries[i + 1].providerId,
            nonRetryable.code ?? nonRetryable.message,
          );
          i++;
          continue;
        }
        yield nonRetryable;
        yield const LlmDone(stopReason: LlmStopReason.unknown);
        return;
      }
      // Stream ended without a terminal event.
      return;
    }
  }

  /// Whether [error] is a target-specific failure (bad credential / quota /
  /// missing model) that a different target might succeed at — as opposed to a
  /// request-level rejection (400 / invalid request / context-length) that every
  /// target would reject identically, so failing over just wastes calls.
  static bool _isTargetError(LlmError error) {
    final code = (error.code ?? '').toLowerCase();
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
        code.contains('quota') ||
        code.contains('billing') ||
        code.contains('credit') ||
        code.contains('permission') ||
        code.contains('429');
  }
}
