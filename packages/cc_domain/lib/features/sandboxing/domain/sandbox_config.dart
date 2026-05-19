import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';

/// Configuration for a sandboxed execution environment.
class SandboxConfig {
  /// Creates a [SandboxConfig] with the given configuration parameters.
  const SandboxConfig({
    required this.sessionId,
    required this.network,
    required this.filesystem,
    this.denyExecutables = const [],
    this.allowedExecutables = const [],
    this.allowAllUnixSockets = false,
    this.parentProxy,
    this.skipMandatoryHomeRcDenies = false,
    this.policy,
  });

  /// The session identifier associated with this sandbox.
  final String sessionId;
  /// Network access configuration for the sandbox.
  final NetworkConfig network;
  /// Filesystem access configuration for the sandbox.
  final FilesystemConfig filesystem;
  /// Absolute paths denied for exec (always-dangerous binaries resolved by
  /// the infra materializer from [SandboxPolicySpec.denyExecutables]).
  final List<String> denyExecutables;
  /// Absolute paths explicitly allowed for exec even inside writable-dir
  /// exec blocks (resolved runtime tools: node, python, dart, … under
  /// `$HOME/.fnm` / `~/.nvm` etc.). Lets legitimate CLIs spawn their
  /// runtimes without disabling the writable-dir exec block.
  final List<String> allowedExecutables;
  /// Whether to allow all Unix socket connections.
  final bool allowAllUnixSockets;
  /// Optional parent proxy address.
  final String? parentProxy;
  /// Whether to skip mandatory home RC deny rules.
  final bool skipMandatoryHomeRcDenies;
  /// The resolved policy spec that produced this config. Carried so the
  /// platform materializers (Seatbelt profile, bwrap argv) can read the
  /// home/runDir anchors and dangerous-path data they need for recursive
  /// mandatory-deny and move-blocking emission.
  final SandboxPolicySpec? policy;
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
