import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';

/// Decorator around [CredentialBrokerPort] that mints task-scoped credentials
/// bound to (agentId, taskId, workspaceId) with short TTL.
///
/// Currently delegates to the base broker. Task-scoped token minting with
/// narrow capability scope will be added when the backend supports it.
class TaskScopedCredentialBroker implements CredentialBrokerPort {
  /// Creates a [TaskScopedCredentialBroker] wrapping the given [inner] broker.
  TaskScopedCredentialBroker({required CredentialBrokerPort inner})
      : _inner = inner;

  final CredentialBrokerPort _inner;

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) =>
      _inner.mint(
        conversationId: conversationId,
        capabilities: capabilities,
        repoOwner: repoOwner,
        repoName: repoName,
      );

  @override
  Future<void> revoke(String handle) => _inner.revoke(handle);
}
