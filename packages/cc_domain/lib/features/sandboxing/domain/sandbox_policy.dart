import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/network_baseline.dart';

/// Resolved, pure-data sandbox policy. Produced by [SandboxPolicyResolver]
/// (pure Dart, no `dart:io`) and materialized into a platform `SandboxConfig`
/// by the infra layer's `SandboxConfigBuilder`.
///
/// Everything the infra materializer needs to build a Seatbelt profile or
/// bwrap argv is here: the per-session filesystem/network/exec rules plus
/// the `homeDir`/`runDir` anchors the platform-specific mandatory-deny and
/// recursive emitters expand against.
class SandboxPolicySpec {
  /// Creates a [SandboxPolicySpec].
  const SandboxPolicySpec({
    required this.sessionId,
    required this.denyRead,
    required this.allowWrite,
    required this.denyWrite,
    required this.denyExecutables,
    required this.allowedDomains,
    required this.deniedDomains,
    required this.networkOn,
    required this.isPty,
    this.readOnlyMounts = const [],
    this.homeDir,
    this.runDir,
  });

  /// Sandbox session id.
  final String sessionId;

  /// Absolute paths denied for read (secrets: `~/.ssh`, `~/.aws`, …).
  final List<String> denyRead;

  /// Writable roots (bind mounts in chat; HOME + /tmp + run-dir in all
  /// modes). Read-only modes add no bind-mount writes.
  final List<String> allowWrite;

  /// Glob patterns denied for write (secrets: `**/.env`, `**/*.key`, …).
  final List<String> denyWrite;

  /// Single-token binary names that are always dangerous at any invocation
  /// (`rm`, `dd`, `chroot`, …). Resolved to absolute paths + denied at the
  /// exec level by the infra materializer.
  final List<String> denyExecutables;

  /// Domains allowed when [networkOn] is true.
  final List<String> allowedDomains;

  /// Domains always denied (metadata APIs, telemetry).
  final List<String> deniedDomains;

  /// Whether network access is on at all.
  final bool networkOn;

  /// Whether the wrapped process needs a PTY (relay transport).
  final bool isPty;

  /// Paths mounted read-only (visible but not writable) — the worktree
  /// bind mounts in review/plan/orchestrate modes. Linux bwrap needs an
  /// explicit `--ro-bind` for these; macOS reads are open by default.
  final List<String> readOnlyMounts;

  /// Real user home (for platform mandatory-deny expansion). Null on
  /// platforms without a home concept.
  final String? homeDir;

  /// CC-managed run directory (writable scratch for plan artifacts, logs).
  /// Outside the worktree bind mounts in read-only modes.
  final String? runDir;
}

/// Pure-Dart resolver that turns a [SandboxSpec] + [AgentCapabilities] +
/// mode into a [SandboxPolicySpec]. Holds the baseline domain lists, secrets
/// globs, and dangerous-file/dir names as data — the single source of truth
/// the infra materializer consults.
///
/// Default-deny network: when the agent cannot access the network, all
/// egress is blocked. When it can, only the curated baseline plus
/// capability-granted domains are reachable.
class SandboxPolicyResolver {
  const SandboxPolicyResolver();

  // ---- Filesystem: secrets deny-write globs ----

  /// Secret-bearing files denied for write anywhere they appear under a
  /// writable root.
  static const List<String> secretsDenyWrite = [
    '**/.env',
    '**/.env.*',
    '**/*.key',
    '**/*.pem',
    '**/*.p12',
    '**/*.pfx',
  ];

  // ---- Filesystem: secrets deny-read ----

  /// Relative paths under `$HOME` denied for read. Expanded by the resolver
  /// with the supplied `homeDir`.
  static const List<String> secretsDenyReadRels = [
    '.ssh',
    '.aws',
    '.gnupg',
    '.config/gh',
    '.kube',
    '.docker',
    '.netrc',
    '.git-credentials',
    '.pypirc',
    '.cargo/credentials',
    '.cargo/credentials.toml',
    '.config/gcloud',
    'Library/Keychains',
  ];

  // ---- Filesystem: dangerous file/dir names (recursive emitter data) ----

  /// Files that must never be writable inside a bind mount (code-execution /
  /// exfil vectors).
  static const List<String> dangerousFiles = [
    '.gitconfig',
    '.gitmodules',
    '.bashrc',
    '.bash_profile',
    '.zshrc',
    '.zprofile',
    '.profile',
    '.ripgreprc',
    '.mcp.json',
  ];

  /// Directories that must never be writable inside a bind mount.
  static const List<String> dangerousDirectories = [
    '.vscode',
    '.idea',
    '.claude/commands',
    '.claude/agents',
  ];

  /// Always-blocked git internals under each writable root.
  static const List<String> dangerousGitPaths = [
    '.git/hooks',
    '.git/config',
  ];

  /// Additional single files to block inside writable roots (npm auth).
  static const List<String> dangerousExtraFiles = ['.npmrc'];

  // ---- macOS/Linux home mandatory-deny (persistence + policy-flip) ----

  /// Paths under `$HOME` that must NEVER be writable, in ALL modes —
  /// credential stores, persistence vectors (LaunchAgents), and Claude
  /// config / CC's own plist (which would let the agent flip its own
  /// sandbox policy or persist outside the sandbox).
  static const List<String> homeMandatoryDenyRels = [
    '.ssh',
    '.aws',
    '.kube',
    '.docker',
    '.netrc',
    '.git-credentials',
    'Library/LaunchAgents',
    'Library/Preferences',
    '.config/gh',
    'Library/Keychains',
    // Claude config — rewriting settings.json flips the agent's own
    // permissions; hooks is arbitrary code execution on next launch.
    '.claude/settings.json',
    '.claude/settings.local.json',
    '.claude.json',
    '.claude/hooks',
  ];

  /// Home RC dotfiles denied for write.
  static const List<String> homeRcDenyRels = [
    '.bashrc',
    '.bash_profile',
    '.zshrc',
    '.zprofile',
    '.profile',
    '.gitconfig',
  ];

  // ---- Exec deny: always-dangerous-at-any-invocation binaries ----

  /// Single-token binaries denied at the exec level regardless of args.
  /// These are dangerous at *any* invocation; multi-token dangerous
  /// commands (`git push`) are enforced by the command policy (Phase 2),
  /// NOT exec-deny. Tokens ending in `.*` are glob-expanded against the
  /// bin directories by the infra materializer (e.g. `mkfs.*` →
  /// `mkfs.ext4`, `mkfs.xfs`, `mkfs.btrfs`, …).
  static const List<String> alwaysDangerousExecutables = [
    'rm',
    'mkfs.*',
    'fdisk',
    'parted',
    'dd',
    'chroot',
    'unshare',
    'nsenter',
    'sudo',
  ];

  /// Resolves a sandbox policy from the session spec, capabilities, and
  /// environment anchors.
  ///
  /// [homeDir] is the real user home (for secrets/mandatory-deny expansion).
  /// [runDir] is the CC-managed writable run directory for the session.
  /// [ticketingDomains] are added when the agent can call the ticketing
  /// provider. [isPty] flags PTY/relay transports that need process-fork.
  SandboxPolicySpec resolve({
    required SandboxSpec spec,
    required AgentCapabilities capabilities,
    String? homeDir,
    String? runDir,
    List<String> ticketingDomains = const [],
    bool isPty = false,
  }) {
    // --- Network: default-deny. ---
    final networkOn =
        capabilities.canAccessNetwork && spec.networkEnabled;
    final allowed = <String>[];
    final denied = <String>[...kBaselineDeniedDomains];
    if (networkOn) {
      allowed.addAll(kBaselineAllowedDomains);
      if (capabilities.canCallGitHubApi || capabilities.canPushToRepo) {
        allowed.addAll(kGithubDomains);
      }
      if (capabilities.canCallTicketing) {
        allowed.addAll(ticketingDomains);
      }
      allowed.addAll(spec.egressAllowlist);
    }

    // --- Secrets deny-read (expanded with home). ---
    final denyRead = <String>[];
    if (homeDir != null && homeDir.isNotEmpty) {
      for (final rel in secretsDenyReadRels) {
        denyRead.add('$homeDir/$rel');
      }
    }

    // --- Writable + read-only mounts (mode-driven). ---
    // chat: full bind-mount writes. review/plan/orchestrate: fully read-only
    // bind mounts (the `plans/` carve-out is removed — plan artifacts go via
    // MCP tools / the run dir). HOME + /tmp + run-dir are always writable
    // (the CLI needs ~/.pi, ~/.claude, fnm node-versions, etc.).
    final allowWrite = <String>{};
    final readOnlyMounts = <String>{};
    switch (spec.mode) {
      case ConversationMode.chat:
        for (final m in spec.bindMounts) {
          if (!m.readOnly) {
            allowWrite.add(m.hostPath);
          } else {
            readOnlyMounts.add(m.hostPath);
          }
        }
      case ConversationMode.review:
      case ConversationMode.plan:
      case ConversationMode.orchestrate:
        // Read-only bind mounts — worktree visible but not writable.
        for (final m in spec.bindMounts) {
          readOnlyMounts.add(m.hostPath);
        }
    }
    if (homeDir != null && homeDir.isNotEmpty) {
      allowWrite.add(homeDir);
    }
    allowWrite.add('/tmp');
    if (runDir != null && runDir.isNotEmpty) {
      allowWrite.add(runDir);
    }

    return SandboxPolicySpec(
      sessionId: spec.sessionId,
      denyRead: denyRead,
      allowWrite: allowWrite.toList(),
      denyWrite: secretsDenyWrite,
      denyExecutables: alwaysDangerousExecutables,
      allowedDomains: allowed.toSet().toList(),
      deniedDomains: denied,
      networkOn: networkOn,
      isPty: isPty,
      readOnlyMounts: readOnlyMounts.toList(),
      homeDir: homeDir,
      runDir: runDir,
    );
  }
}
