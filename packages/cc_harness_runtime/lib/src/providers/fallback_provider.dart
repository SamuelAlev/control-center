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
///
/// Implements [LlmServedIdentity] so a usage ledger wrapping the CHAIN can
/// attribute a call to the target that actually consumed it, and
/// [LlmDeferredToolSupport] conservatively over the WHOLE chain — see
/// [supportsDeferredTools].
class FallbackProvider
    implements LlmProviderPort, LlmServedIdentity, LlmDeferredToolSupport {
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
  @override
  String get lastServedProviderId => _entries[_active].providerId;

  /// The model that served the most recent completion.
  @override
  String get lastServedModel => _entries[_active].model;

  /// Whether EVERY target in the chain can defer tool loading natively.
  ///
  /// Deliberately conservative over the whole chain rather than answered by the
  /// currently active target. The caller decides ONCE per turn whether to keep
  /// deferred schemas out of the request and carry activations as references;
  /// if the turn then fails over to a target that cannot expand a reference
  /// (or was never told the schema), the model is left unable to call a tool
  /// the history claims is available. `false` here means the request keeps the
  /// full resident catalog — the pre-deferral cost — which is correct on every
  /// target instead of fast on one and broken on the next.
  ///
  /// A target that cannot be built answers `false`: an unpriceable unknown is
  /// not a capability.
  ///
  /// Each entry is checked with ITS OWN model, never the caller's: a rotation
  /// entry shares the run's model, but a cross-provider entry targets a
  /// different one, and an older model on the second target would reject
  /// `defer_loading` even though the primary supports it.
  @override
  bool supportsDeferredTools({String? model}) {
    if (_entries.isEmpty) {
      return false;
    }
    for (var i = 0; i < _entries.length; i++) {
      try {
        if (!providerSupportsDeferredTools(
          _providerAt(i),
          model: _entryModel(i) ?? model,
        )) {
          return false;
        }
      } on Object {
        return false;
      }
    }
    return true;
  }

  LlmProviderPort _providerAt(int i) => _built[i] ??= _entries[i].build();

  /// Binds each physical target to a new run without wrapping the chain as a
  /// single request. Credential resolvers and transports remain shared, but
  /// fallback position and per-target accounting belong to the new run.
  FallbackProvider mapProviders(
    LlmProviderPort Function(LlmProviderPort provider, String providerId) bind,
  ) {
    final entries = <FallbackEntry>[];
    for (var i = 0; i < _entries.length; i++) {
      final index = i;
      final entry = _entries[i];
      entries.add(
        FallbackEntry(
          providerId: entry.providerId,
          model: entry.model,
          credentialId: entry.credentialId,
          build: () => bind(_providerAt(index), entry.providerId),
        ),
      );
    }
    return FallbackProvider(entries, onFallback: onFallback).._active = _active;
  }

  /// The model to ask entry [i]'s provider for, or null when neither the entry
  /// nor its provider names one.
  ///
  /// The entry's declared model wins; a rotation entry declares the run's model,
  /// a cross-provider entry its own. Only when an entry declares none does the
  /// built provider's default apply.
  String? _entryModel(int i) {
    final declared = _entries[i].model;
    if (declared.isNotEmpty) {
      return declared;
    }
    final fallback = _providerAt(i).defaultModel;
    return fallback.isEmpty ? null : fallback;
  }

  @override
  String get displayName => _providerAt(_active).displayName;

  @override
  String get defaultModel {
    // The model the ACTIVE target will actually be asked for, not the entry's
    // declared field alone: a cross-provider entry may declare none and rely on
    // its provider's default, and reporting '' there would misattribute the
    // call (the request itself uses the provider's default).
    final declared = _entries[_active].model;
    if (declared.isNotEmpty) {
      return declared;
    }
    try {
      return _providerAt(_active).defaultModel;
    } on Object {
      return '';
    }
  }

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
      // Ask the TARGET for its own model. A cross-provider fallback entry
      // targets a different model than the primary, and forwarding the caller's
      // config verbatim would spend the whole turn asking the fallback provider
      // for the primary's model (a 404 on every provider that validates it).
      // An entry that declares no model keeps the provider's default — passing
      // an empty id would be worse than passing none.
      final entryModel = _entryModel(i);
      final entryConfig = entryModel == null
          ? config
          : config.copyWith(model: entryModel);
      LlmError? failure;
      var producedTerminal = false;
      // Once any observable output has streamed, switching targets would
      // duplicate/corrupt the assistant turn — so we must not fail over anymore.
      var producedOutput = false;

      await for (final event in provider.complete(
        messages: messages,
        tools: tools,
        config: entryConfig,
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
