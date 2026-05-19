import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';

/// Outcome of a [CredentialBrokerPort.mint] call.
class ScopedCredentials {
  /// Creates a new [ScopedCredentials].
  const ScopedCredentials({
    required this.handle,
    required this.environment,
    this.expiresAt,
    this.notes = const [],
  });

  /// Opaque token used to [CredentialBrokerPort.revoke] this grant later.
  final String handle;

  /// Env vars to inject into the sandbox guest process. Keys never present
  /// outside the sandbox (`GITHUB_TOKEN`, `TICKETING_API_KEY`, etc.).
  final Map<String, String> environment;

  /// Wall-clock time after which the credentials should be considered dead.
  /// Used by the UI to show "expires in N min" and by the broker to auto-
  /// revoke if the sandbox outlives the credential.
  final DateTime? expiresAt;

  /// Human-readable notes shown in the UI (e.g. "Using raw PAT — swap in
  /// fine-grained tokens for production").
  final List<String> notes;
}

/// Port that mints scoped, capability-gated credentials for a sandbox launch
/// and revokes them on teardown.
///
/// Implementations live in `lib/features/sandboxing/data/brokers/`.
abstract interface class CredentialBrokerPort {
  /// Mints credentials for one launch of [conversationId]'s sandbox given
  /// the user's chosen [capabilities]. Returns an env map to merge into the
  /// guest environment plus a revoke handle.
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  });

  /// Revokes a previously-minted grant. Idempotent.
  Future<void> revoke(String handle);
}
