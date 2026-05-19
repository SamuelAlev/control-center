import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:collection/collection.dart';

/// A single host→guest bind mount entry for [SandboxSpec].
class SandboxBindMount {
  /// Creates a bind mount.
  const SandboxBindMount({
    required this.hostPath,
    required this.guestPath,
    this.readOnly = false,
  });

  /// Absolute path on the host that gets mapped into the sandbox.
  final String hostPath;

  /// Path inside the sandbox the [hostPath] appears at. With the native
  /// sandbox the in-sandbox path is the same as [hostPath] — this field is
  /// retained for adapter symmetry.
  final String guestPath;

  /// Mount read-only when true.
  final bool readOnly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SandboxBindMount &&
          runtimeType == other.runtimeType &&
          hostPath == other.hostPath &&
          guestPath == other.guestPath &&
          readOnly == other.readOnly;

  @override
  int get hashCode => Object.hash(hostPath, guestPath, readOnly);
}

/// Specification used by `SandboxPort.launch` to provision a sandbox session.
///
/// Each session has one or more bind mounts (typically the channel's agent
/// folder and conversation folder) plus a default [guestWorkdir]. Individual
/// `exec` calls can override the working directory.
class SandboxSpec {
  /// Creates a new [SandboxSpec].
  const SandboxSpec({
    required this.sessionId,
    required this.workspaceId,
    required this.bindMounts,
    this.agentId,
    this.networkEnabled = true,
    this.egressAllowlist = const [],
    this.guestWorkdir,
    this.mode = ConversationMode.chat,
    this.capabilities = AgentCapabilities.safeDefault,
  });

  /// Stable id for the sandbox session (typically the channel id).
  final String sessionId;

  /// Workspace id this sandbox belongs to.
  final String workspaceId;

  /// Agent id this sandbox is currently bound to, if any.
  final String? agentId;

  /// One or more host→guest mounts. The sandbox only sees the host paths
  /// listed here; everything else is invisible (or read-only on macOS).
  final List<SandboxBindMount> bindMounts;

  /// When false, the sandbox is launched with no network access at all
  /// (the in-process HTTP/SOCKS proxies are not exposed). When true, the
  /// proxies enforce [egressAllowlist].
  final bool networkEnabled;

  /// Optional egress allowlist (domain names). When [networkEnabled] is true
  /// and this list is empty, the sandbox can reach a curated baseline plus
  /// whatever the agent's capabilities add (GitHub, ticketing provider).
  /// Wildcards supported (`*.example.com`).
  final List<String> egressAllowlist;

  /// Default working directory inside the sandbox. Individual `exec` calls
  /// can override this for one invocation. With the native sandbox this is
  /// just the host path the agent runs in.
  final String? guestWorkdir;

  /// Conversation mode (chat / review / plan / orchestrate). Carves the
  /// sandbox's filesystem `allowWrite` rules: chat keeps the existing
  /// behaviour, review/plan/orchestrate are read-only on the bind mounts.
  final ConversationMode mode;

  /// Capabilities the agent has in this sandbox. Used by the policy resolver
  /// to derive the egress domain allowlist (GitHub / ticketing) and the
  /// network on/off decision. Defaults to the conservative [AgentCapabilities.safeDefault].
  final AgentCapabilities capabilities;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SandboxSpec &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          const ListEquality<SandboxBindMount>().equals(bindMounts, other.bindMounts) &&
          networkEnabled == other.networkEnabled &&
          const ListEquality<String>().equals(egressAllowlist, other.egressAllowlist) &&
          guestWorkdir == other.guestWorkdir &&
          mode == other.mode &&
          capabilities == other.capabilities;

  @override
  int get hashCode => Object.hash(
    sessionId,
    workspaceId,
    agentId,
    Object.hashAll(bindMounts),
    networkEnabled,
    Object.hashAll(egressAllowlist),
    guestWorkdir,
    mode,
    capabilities,
  );
}
