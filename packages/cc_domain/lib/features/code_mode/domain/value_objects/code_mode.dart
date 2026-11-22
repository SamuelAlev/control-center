// Code mode: whether this server can run `repl` scripts. There is no setting:
// a run has `repl` exactly when the runner passed its boot self-test here.

/// Whether the script runner can be used on this host, as the boot self-test
/// found it.
///
/// A runner that could not lock itself down fully is unavailable, never
/// degraded: there is no mode in which a script runs with less isolation.
sealed class CodeRunnerAvailability {
  const CodeRunnerAvailability();

  /// The runner passed its self-test.
  const factory CodeRunnerAvailability.available() = CodeRunnerAvailable;

  /// The runner failed its self-test, or could not be started, for [reason].
  const factory CodeRunnerAvailability.unavailable(String reason) =
      CodeRunnerUnavailable;

  /// Rebuilds from [toJson]'s output. Anything that is not an explicit
  /// `available: true` reads as unavailable, so a malformed status can never
  /// offer scripts.
  factory CodeRunnerAvailability.fromJson(Map<String, dynamic> json) {
    if (json['available'] == true) {
      return const CodeRunnerAvailable();
    }
    final reason = json['reason'];
    return CodeRunnerUnavailable(
      reason is String && reason.isNotEmpty ? reason : 'unknown',
    );
  }

  /// Whether scripts can run.
  bool get isAvailable;

  /// The wire form for `codeMode.status` and the startup line.
  Map<String, dynamic> toJson();
}

/// The runner passed its self-test.
final class CodeRunnerAvailable extends CodeRunnerAvailability {
  /// Creates the available state.
  const CodeRunnerAvailable();

  @override
  bool get isAvailable => true;

  @override
  Map<String, dynamic> toJson() => {'available': true};

  @override
  bool operator ==(Object other) => other is CodeRunnerAvailable;

  @override
  int get hashCode => (CodeRunnerAvailable).hashCode;

  @override
  String toString() => 'available';
}

/// The runner cannot be used on this host.
final class CodeRunnerUnavailable extends CodeRunnerAvailability {
  /// Creates the unavailable state with a human-readable [reason].
  const CodeRunnerUnavailable(this.reason);

  /// Why, in a sentence an operator can act on (which control failed, or that
  /// the binary could not be started).
  final String reason;

  @override
  bool get isAvailable => false;

  @override
  Map<String, dynamic> toJson() => {'available': false, 'reason': reason};

  @override
  bool operator ==(Object other) =>
      other is CodeRunnerUnavailable && other.reason == reason;

  @override
  int get hashCode => Object.hash(CodeRunnerUnavailable, reason);

  @override
  String toString() => 'unavailable($reason)';
}
