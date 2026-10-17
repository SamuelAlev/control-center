import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';

/// Stops every physical model request at the provider boundary, including
/// compaction/auxiliary calls that do not enter the agent loop's turn guard.
/// [canBegin] reads completed, priced call records. A concurrent request is
/// refused until the one in-flight request has finished and been accounted.
class ProviderCallBudgetGuard
    implements LlmProviderPort, LlmDeferredToolSupport {
  /// Wraps [delegate] and checks [canBegin] before each physical model call.
  ProviderCallBudgetGuard(this.delegate, {required this.canBegin});

  /// Provider receiving calls after the budget and concurrency checks pass.
  final LlmProviderPort delegate;

  /// Whether accounted spend permits another physical provider request.
  final bool Function() canBegin;
  bool _inFlight = false;

  @override
  String get displayName => delegate.displayName;

  @override
  String get defaultModel => delegate.defaultModel;

  @override
  Future<List<ProviderModel>> listModels() => delegate.listModels();

  @override
  bool supportsDeferredTools({String? model}) =>
      providerSupportsDeferredTools(delegate, model: model);

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    // async* runs this check on subscription, immediately before the wire
    // request, not when a caller merely constructs an unused stream.
    if (_inFlight || !canBegin()) {
      yield const LlmError(
        'Evaluation usage threshold reached or provider spend unknown',
        code: 'evaluation_budget_exhausted',
      );
      yield const LlmDone();
      return;
    }
    _inFlight = true;
    try {
      yield* delegate.complete(
        messages: messages,
        tools: tools,
        config: config,
      );
    } finally {
      _inFlight = false;
    }
  }
}
