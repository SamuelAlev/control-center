import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';

class SandboxConfig {
  const SandboxConfig({
    required this.sessionId,
    required this.network,
    required this.filesystem,
    this.allowAllUnixSockets = false,
    this.parentProxy,
    this.skipMandatoryHomeRcDenies = false,
  });

  final String sessionId;
  final NetworkConfig network;
  final FilesystemConfig filesystem;
  final bool allowAllUnixSockets;
  final String? parentProxy;
  final bool skipMandatoryHomeRcDenies;
}

class NetworkConfig {
  const NetworkConfig({
    this.allowAll = true,
    this.allowedDomains = const [],
    this.deniedDomains = const [],
  });

  final bool allowAll;
  final List<String> allowedDomains;
  final List<String> deniedDomains;

  bool get isRestricted =>
      !allowAll || allowedDomains.isNotEmpty || deniedDomains.isNotEmpty;

  bool get isBlocked => !allowAll && allowedDomains.isEmpty;
}

class FilesystemConfig {
  const FilesystemConfig({
    this.denyRead = const [],
    this.allowRead = const [],
    this.allowWrite = const [],
    this.denyWrite = const [],
  });

  final List<String> denyRead;
  final List<String> allowRead;
  final List<String> allowWrite;
  final List<String> denyWrite;
}

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
    ConversationMode.plan => <String>['$agentDir/plans', '/tmp'],
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
