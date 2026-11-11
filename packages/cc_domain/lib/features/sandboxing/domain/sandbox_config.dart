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
    this.allowedExecRoots = const [],
    this.toolchainExecRoots = const [],
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

  /// Absolute, symlink-resolved directory TREES the operator approved for exec
  /// (see `SandboxSpec.execGrantRoots`). Emitted as `subpath` allows after the
  /// writable-dir denies, so anything beneath one becomes runnable — including
  /// binaries the agent writes there itself, which is the widening the operator
  /// was asked about. Distinct from [allowedExecutables], which are individual
  /// binaries pinned by exact path.
  final List<String> allowedExecRoots;

  /// Absolute, symlink-resolved toolchain install trees under `$HOME` (see
  /// `SandboxPolicyResolver.homeToolchainExecRels`) that may exec. Unlike
  /// [allowedExecRoots] they are emitted BEFORE the always-dangerous denies,
  /// so a toolchain tree can never re-open `rm` or `sudo`.
  final List<String> toolchainExecRoots;

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

  /// A copy with the given fields replaced.
  SandboxConfig copyWith({
    FilesystemConfig? filesystem,
    List<String>? allowedExecutables,
  }) => SandboxConfig(
    sessionId: sessionId,
    network: network,
    filesystem: filesystem ?? this.filesystem,
    denyExecutables: denyExecutables,
    allowedExecutables: allowedExecutables ?? this.allowedExecutables,
    allowedExecRoots: allowedExecRoots,
    toolchainExecRoots: toolchainExecRoots,
    allowAllUnixSockets: allowAllUnixSockets,
    parentProxy: parentProxy,
    skipMandatoryHomeRcDenies: skipMandatoryHomeRcDenies,
    policy: policy,
  );
}

/// Network access configuration for sandboxed execution.
class NetworkConfig {
  /// Creates a [NetworkConfig] with the given network rules.
  const NetworkConfig({
    this.allowAll = true,
    this.allowedDomains = const [],
    this.deniedDomains = const [],
    this.loopbackPorts = const [],
    this.environmentScope,
  });

  /// Whether all network access is allowed by default.
  final bool allowAll;

  /// Domains explicitly allowed for network access.
  final List<String> allowedDomains;

  /// Domains explicitly denied for network access.
  final List<String> deniedDomains;

  /// Host loopback ports reachable even when the network is restricted or off
  /// (bridged into the namespace on Linux). See `SandboxSpec.loopbackPorts`.
  final List<int> loopbackPorts;

  /// `<workspaceId>/<spaceId>` of a run whose space has an environment. The
  /// run's proxy admits exactly that environment's hostnames.
  final String? environmentScope;

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
    this.hiddenRoots = const [],
    this.hostExecutables = HostExecutableDirs.none,
  });

  /// Paths denied for read access.
  final List<String> denyRead;

  /// Paths explicitly allowed for read access. On Linux, where a sandbox
  /// sees only what is bound into it, each is bound read-only so it exists
  /// there; it is never made writable by being listed here.
  final List<String> allowRead;

  /// Paths explicitly allowed for write access.
  final List<String> allowWrite;

  /// Paths denied for write access.
  final List<String> denyWrite;

  /// Server-private trees (the server's data directory, its `.env`) that are
  /// neither readable nor writable, except for the paths inside them this
  /// config grants by name: its [allowRead] and [allowWrite] entries and the
  /// policy's read-only mounts, run dir, runner state dirs and tool dirs.
  ///
  /// The sandbox manager adds these to every config it wraps, so no launcher
  /// can leave them out.
  final List<String> hiddenRoots;

  /// Where the host resolves the executables it runs outside any sandbox.
  /// Nothing in them may change from inside one; the sandbox manager adds
  /// them to every config it wraps, like [hiddenRoots].
  final HostExecutableDirs hostExecutables;

  /// A copy with the given fields replaced.
  FilesystemConfig copyWith({
    List<String>? allowRead,
    List<String>? hiddenRoots,
    HostExecutableDirs? hostExecutables,
  }) => FilesystemConfig(
    denyRead: denyRead,
    allowRead: allowRead ?? this.allowRead,
    allowWrite: allowWrite,
    denyWrite: denyWrite,
    hiddenRoots: hiddenRoots ?? this.hiddenRoots,
    hostExecutables: hostExecutables ?? this.hostExecutables,
  );
}

/// The directories the host resolves executables from, and the paths that
/// decide what runs from them, as found once at server start.
///
/// The host runs bare names (`claude`, `node`, `git`, `docker`, a hook's
/// `#!/usr/bin/env node`) outside every sandbox, through its `PATH` and the
/// install prefixes it probes. When one of those lies under a tree a sandbox
/// may write (`$HOME`, `/tmp`), a sandboxed run could put a program there that
/// the host later runs as the server user. Every sandbox profile therefore
/// keeps [dirs]' direct children, [links] and [installRoots] unchangeable and
/// the directories above them unrenameable, while leaving the trees below the
/// direct children writable (an SDK's `bin/cache`, a node version's
/// `lib/node_modules`).
final class HostExecutableDirs {
  /// Creates a [HostExecutableDirs].
  const HostExecutableDirs({
    this.dirs = const [],
    this.links = const [],
    this.installRoots = const [],
  });

  /// Nothing to protect.
  static const HostExecutableDirs none = HostExecutableDirs();

  /// The directories, each in every spelling: as written and after each
  /// symlink on the way (`~/fvm/default/bin`, `~/fvm/versions/<v>/bin`).
  final List<String> dirs;

  /// The symlinks on the way to a directory or to a direct child's target
  /// (`~/fvm/default`). Replacing one would point the host somewhere else.
  final List<String> links;

  /// The trees a symlinked direct child resolves into, protected whole: the
  /// package an npm global's link names (`lib/node_modules/<pkg>`), the
  /// version directory a native installer's link names.
  final List<String> installRoots;

  /// Whether there is nothing to protect.
  bool get isEmpty => dirs.isEmpty && links.isEmpty && installRoots.isEmpty;
}
