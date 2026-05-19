import 'package:control_center/core/domain/entities/agent_run_log.dart';

/// Stage at which the failure occurred.
enum FailureStage {
  /// Failure before the process was spawned.
  launch,
  /// Failure while the process was running.
  execution,
  /// Failure after the process exited.
  postRun,
}

/// Structured classification of a failed run.
class RunFailureClassification {
  /// Creates a [RunFailureClassification] with the given fields.
  const RunFailureClassification({
    required this.family,
    required this.stage,
    required this.detail,
    required this.retryable,
    this.userAction,
  });

  /// High-level error family.
  final RunErrorFamily family;

  /// Stage at which the failure occurred.
  final FailureStage stage;

  /// Human-readable detail describing the failure.
  final String detail;

  /// Whether this failure is retryable without user intervention.
  final bool retryable;

  /// Suggested user action to resolve the failure, if any.
  final String? userAction;
}

/// Classifies failed runs based on exit code, stderr output, and the last
/// events from the run. Produces a structured [RunFailureClassification]
/// that feeds into the retry policy and user-facing error messages.
class RunFailureClassifier {
  /// Classifies a failed run.
  ///
  /// [exitCode] is the process exit code (null if the process was killed
  /// before exiting normally).
  /// [stderr] is the captured stderr output.
  /// [lastError] is the last error event content, if any.
  RunFailureClassification classify({
    required int? exitCode,
    required String stderr,
    String? lastError,
    String? structuredCode,
  }) {
    // Structured codes from the adapter (Anthropic relay error types, the Pi
    // JSON error stream, the relay-crash sentinel) are authoritative — consult
    // them before the brittle substring matching.
    final byCode = _classifyByCode(structuredCode);
    if (byCode != null) {
      return byCode;
    }

    final combined = '${lastError ?? ''}\n$stderr'.toLowerCase();

    // Auth errors — not retryable, user must fix credentials.
    if (_matches(combined, _authPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.launch,
        detail: 'Authentication failed',
        retryable: false,
        userAction: 'Check your API credentials and try again.',
      );
    }

    // Rate limiting — retryable.
    if (_matches(combined, _rateLimitPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Rate limited by upstream provider',
        retryable: true,
        userAction: null,
      );
    }

    // Prompt too large — not retryable.
    if (_matches(combined, _promptTooLargePatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.launch,
        detail: 'Prompt exceeds maximum allowed size',
        retryable: false,
        userAction: 'Reduce the conversation context or start a new chat.',
      );
    }

    // Permission / access denied — not retryable.
    if (_matches(combined, _permissionPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Permission denied by upstream provider',
        retryable: false,
        userAction: 'Check your plan and API access.',
      );
    }

    // Upstream timeout / connection errors — retryable.
    if (_matches(combined, _timeoutPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Upstream timeout or connection error',
        retryable: true,
        userAction: null,
      );
    }

    // Model not available — retryable.
    if (_matches(combined, _modelUnavailablePatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Requested model is not available',
        retryable: true,
        userAction: 'Try a different model or retry later.',
      );
    }

    // Sandbox / process infrastructure — not retryable.
    if (_matches(combined, _sandboxPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.sandboxInfrastructure,
        stage: FailureStage.launch,
        detail: 'Sandbox infrastructure failure',
        retryable: false,
        userAction: 'Check sandboxing settings or disable sandboxing.',
      );
    }

    // Binary not found — exit code 127.
    if (exitCode == 127) {
      return const RunFailureClassification(
        family: RunErrorFamily.sandboxInfrastructure,
        stage: FailureStage.launch,
        detail: 'CLI binary not found on PATH',
        retryable: false,
        userAction: 'Install the CLI or check Settings → Adapters.',
      );
    }

    // Process killed / lost.
    if (exitCode == null || exitCode == 143) {
      return const RunFailureClassification(
        family: RunErrorFamily.processLost,
        stage: FailureStage.execution,
        detail: 'Process was killed or lost',
        retryable: false,
        userAction: null,
      );
    }

    // Empty output / silent run.
    if (_matches(combined, _emptyOutputPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.silentRun,
        stage: FailureStage.postRun,
        detail: 'Agent produced no output',
        retryable: true,
        userAction: null,
      );
    }

    // Budget exceeded.
    if (_matches(combined, _budgetPatterns)) {
      return const RunFailureClassification(
        family: RunErrorFamily.budgetExceeded,
        stage: FailureStage.execution,
        detail: 'Budget or token limit exceeded',
        retryable: false,
        userAction: 'Increase your budget limit or start a new conversation.',
      );
    }

    // Default — unknown.
    return RunFailureClassification(
      family: RunErrorFamily.unknown,
      stage: FailureStage.execution,
      detail: lastError ?? 'Run failed with exit code $exitCode',
      retryable: false,
      userAction: null,
    );
  }

  /// Maps a structured adapter error code to a classification. Returns null
  /// when the code is null or unrecognized (fall through to regex matching).
  RunFailureClassification? _classifyByCode(String? code) {
    switch (code) {
      case 'rate_limit_error':
      case 'overloaded_error':
        return const RunFailureClassification(
          family: RunErrorFamily.transientUpstream,
          stage: FailureStage.execution,
          detail: 'Rate limited / overloaded by upstream provider',
          retryable: true,
        );
      case 'authentication_error':
        return const RunFailureClassification(
          family: RunErrorFamily.transientUpstream,
          stage: FailureStage.launch,
          detail: 'Authentication failed',
          retryable: false,
          userAction: 'Check your API credentials and try again.',
        );
      case 'permission_error':
        return const RunFailureClassification(
          family: RunErrorFamily.transientUpstream,
          stage: FailureStage.execution,
          detail: 'Permission denied by upstream provider',
          retryable: false,
          userAction: 'Check your plan and API access.',
        );
      case 'invalid_request_error':
        return const RunFailureClassification(
          family: RunErrorFamily.transientUpstream,
          stage: FailureStage.launch,
          detail: 'Invalid request (often prompt too large)',
          retryable: false,
          userAction: 'Reduce the conversation context or start a new chat.',
        );
      case 'relay_crash':
        return const RunFailureClassification(
          family: RunErrorFamily.processLost,
          stage: FailureStage.execution,
          detail: 'Agent relay crashed mid-turn',
          retryable: true,
        );
      default:
        return null;
    }
  }

  static bool _matches(String text, List<String> patterns) {
    for (final p in patterns) {
      if (text.contains(p)) {
        return true;
      }
    }
    return false;
  }

  static const _authPatterns = [
    'authentication failed',
    'invalid api key',
    'invalid_api_key',
    'unauthorized',
    '401',
    'auth error',
    'not authenticated',
    'credentials',
    'login required',
  ];

  static const _rateLimitPatterns = [
    'rate limit',
    'rate_limit',
    'too many requests',
    '429',
    'quota exceeded',
    'quota_exceeded',
    'capacity',
  ];

  static const _promptTooLargePatterns = [
    'prompt is too long',
    'prompt too large',
    'max_tokens',
    'context length',
    'context_length_exceeded',
    'too many tokens',
    'request too large',
  ];

  static const _permissionPatterns = [
    'permission denied',
    'access denied',
    'forbidden',
    '403',
    'insufficient permissions',
  ];

  static const _timeoutPatterns = [
    'timeout',
    'timed out',
    'connection refused',
    'connection reset',
    'econnrefused',
    'econnreset',
    'socket hang up',
    'network error',
    '502',
    '503',
    '504',
    'gateway',
  ];

  static const _modelUnavailablePatterns = [
    'model not found',
    'model not available',
    'model_unavailable',
    'does not exist',
    'not supported',
  ];

  static const _sandboxPatterns = [
    'sandbox',
    '[sandbox]',
    'sandboxing',
    'denied operation',
  ];

  static const _emptyOutputPatterns = [
    'empty response',
    'no output',
    'silent run',
  ];

  static const _budgetPatterns = [
    'budget',
    'limit exceeded',
    'spending limit',
    'cost limit',
  ];
}
