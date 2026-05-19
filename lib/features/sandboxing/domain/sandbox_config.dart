import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';

/// Configuration for a sandboxed execution environment.
class SandboxConfig {
  /// Creates a [SandboxConfig] with the given configuration parameters.
  const SandboxConfig({
    required this.sessionId,
    required this.network,
    required this.filesystem,
    this.allowAllUnixSockets = false,
    this.parentProxy,
    this.skipMandatoryHomeRcDenies = false,
  });

  /// The session identifier associated with this sandbox.
  final String sessionId;
  /// Network access configuration for the sandbox.
  final NetworkConfig network;
  /// Filesystem access configuration for the sandbox.
  final FilesystemConfig filesystem;
  /// Whether to allow all Unix socket connections.
  final bool allowAllUnixSockets;
  /// Optional parent proxy address.
  final String? parentProxy;
  /// Whether to skip mandatory home RC deny rules.
  final bool skipMandatoryHomeRcDenies;
}

/// Network access configuration for sandboxed execution.
class NetworkConfig {
  /// Creates a [NetworkConfig] with the given network rules.
  const NetworkConfig({
    this.allowAll = true,
    this.allowedDomains = const [],
    this.deniedDomains = const [],
  });

  /// Whether all network access is allowed by default.
  final bool allowAll;
  /// Domains explicitly allowed for network access.
  final List<String> allowedDomains;
  /// Domains explicitly denied for network access.
  final List<String> deniedDomains;

  /// Whether network access is restricted (not fully open).
  bool get isRestricted =>
      !allowAll || allowedDomains.isNotEmpty || deniedDomains.isNotEmpty;

  /// Whether network access is completely blocked.
  bool get isBlocked => !allowAll && allowedDomains.isEmpty;
}

/// Filesystem access configuration for sandboxed execution.
class FilesystemConfig {
  /// Creates a [FilesystemConfig] with the given filesystem rules.
  const FilesystemConfig({
    this.denyRead = const [],
    this.allowRead = const [],
    this.allowWrite = const [],
    this.denyWrite = const [],
  });

  /// Paths denied for read access.
  final List<String> denyRead;
  /// Paths explicitly allowed for read access.
  final List<String> allowRead;
  /// Paths explicitly allowed for write access.
  final List<String> allowWrite;
  /// Paths denied for write access.
  final List<String> denyWrite;
}

/// Builds a [SandboxConfig] from the given session details, capabilities, and mode.
SandboxConfig buildSandboxConfig({
  required String sessionId,
  required AgentCapabilities capabilities,
  required String agentDir,
  required ConversationMode mode,
  String? homeDir,
  List<String> ticketingDomains = const [],
}) {
  final domains = <String>[];
  if (capabilities.canAccessNetwork) {
    domains.addAll(_baselineDomains);
  }
  if (capabilities.canCallGitHubApi || capabilities.canPushToRepo) {
    domains.addAll(_githubDomains);
  }
  if (capabilities.canCallTicketing) {
    domains.addAll(ticketingDomains);
  }

  final denyRead = <String>[];
  if (homeDir != null && homeDir.isNotEmpty) {
    denyRead.addAll([
      '$homeDir/.ssh',
      '$homeDir/.aws',
      '$homeDir/.gnupg',
      '$homeDir/.config/gh',
      '$homeDir/Library/Keychains',
    ]);
  }

  final allowWrite = switch (mode) {
    ConversationMode.chat => <String>[agentDir, '/tmp'],
    ConversationMode.review => const <String>[],
    // plan + orchestrate are read-mostly: only the plans dir + scratch.
    ConversationMode.plan ||
    ConversationMode.orchestrate =>
      <String>['$agentDir/plans', '/tmp'],
  };

  return SandboxConfig(
    sessionId: sessionId,
    network: NetworkConfig(allowedDomains: domains.toSet().toList()),
    filesystem: FilesystemConfig(
      denyRead: denyRead,
      allowWrite: allowWrite,
    ),
  );
}

const List<String> _baselineDomains = [
  'anthropic.com',
  '*.anthropic.com',
  'claude.ai',
  '*.claude.ai',
  'pypi.org',
  '*.pypi.org',
  'pythonhosted.org',
  '*.pythonhosted.org',
  'registry.npmjs.org',
  '*.npmjs.org',
];

const List<String> _githubDomains = [
  'github.com',
  '*.github.com',
  'api.github.com',
  'lfs.github.com',
  'objects.githubusercontent.com',
  'raw.githubusercontent.com',
];
