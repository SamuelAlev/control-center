import 'package:cc_domain/src/errors/app_exceptions.dart';

/// Whether agent processes on this server host run inside the OS sandbox,
/// decided once at boot.
///
/// The rule it encodes: nothing runs on the server host outside a sandbox
/// unless the server owner started it or explicitly chose unconfined host
/// execution for everyone.
enum HostExecutionPosture {
  /// The sandbox is enabled and its backend is available: every run and its
  /// tool processes are wrapped.
  sandboxed('native'),

  /// The server owner turned the sandbox off (`--sandbox off`): every run is
  /// unconfined, whoever started it.
  offByOwner('off'),

  /// The sandbox is enabled but this host has no backend: only work the
  /// server owner is accountable for may run, and it runs unconfined.
  unavailable('unavailable');

  const HostExecutionPosture(this.wire);

  /// Decides the posture from the configuration and the backend probe.
  factory HostExecutionPosture.resolve({
    required bool sandboxEnabled,
    required bool backendAvailable,
  }) => !sandboxEnabled
      ? HostExecutionPosture.offByOwner
      : backendAvailable
      ? HostExecutionPosture.sandboxed
      : HostExecutionPosture.unavailable;

  /// The value printed on the startup exposure line.
  final String wire;

  /// Whether processes are wrapped by the OS sandbox.
  bool get confined => this == HostExecutionPosture.sandboxed;

  /// Whether a run whose accountable person is the server owner
  /// ([ownerAccountable]) may start under this posture.
  bool admits({required bool ownerAccountable}) =>
      this != HostExecutionPosture.unavailable || ownerAccountable;
}

/// A run refused because this server has no sandbox and its accountable
/// person is not the server owner.
class HostSandboxUnavailableException extends AuthException {
  /// Creates a [HostSandboxUnavailableException].
  const HostSandboxUnavailableException()
    : super(refusal, code: 'sandbox_unavailable');

  /// The text shown to the person whose run was refused.
  static const String refusal =
      'This server has no sandbox, so only its owner can run agents here. '
      'The owner can install the sandbox or turn sandboxing off for everyone.';
}
