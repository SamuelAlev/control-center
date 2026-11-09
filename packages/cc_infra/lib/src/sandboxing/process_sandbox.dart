import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';

/// The ONE way a local process sandbox spec is built: a dispatch's CLI
/// transports, the harness shell tools and pipeline shell steps all go
/// through here, so a new security input is added once and every launcher has
/// to state it.
///
/// Every security-relevant input is required — a caller that wants the
/// permissive value (network on, no protected paths) says so at its call site
/// instead of inheriting a constructor default. [bindMounts] defaults to
/// [workdir] alone, read-write.
SandboxSpec processSandboxSpec({
  required String sessionId,
  required String workspaceId,
  required String workdir,
  required bool networkEnabled,
  required Mode mode,
  required List<String> protectedPaths,
  required List<String> execGrantRoots,
  required List<int> loopbackPorts,
  required String? environmentScope,
  String? agentId,
  List<SandboxBindMount>? bindMounts,
  List<String> runnerStateDirs = const [],
  bool superviseProcessGroup = false,
}) => SandboxSpec(
  sessionId: sessionId,
  workspaceId: workspaceId,
  agentId: agentId,
  bindMounts:
      bindMounts ?? [SandboxBindMount(hostPath: workdir, guestPath: workdir)],
  guestWorkdir: workdir,
  networkEnabled: networkEnabled,
  mode: mode,
  protectedPaths: protectedPaths,
  runnerStateDirs: runnerStateDirs,
  execGrantRoots: execGrantRoots,
  loopbackPorts: loopbackPorts,
  environmentScope: environmentScope,
  superviseProcessGroup: superviseProcessGroup,
);

/// The run directory a spec's session gets when the launcher names none:
/// `<guestWorkdir>/.cc-runs/<sessionId>`, or none without a workdir.
String? processSandboxRunDir(SandboxSpec spec) => spec.guestWorkdir == null
    ? null
    : '${spec.guestWorkdir}/.cc-runs/${spec.sessionId}';

/// Resolves [spec] into the platform-neutral policy, with this process's
/// `$HOME` and [runDir] (default [processSandboxRunDir]).
SandboxPolicySpec processSandboxPolicy(SandboxSpec spec, {String? runDir}) {
  final home = Platform.environment['HOME'];
  return const SandboxPolicyResolver().resolve(
    spec: spec,
    homeDir: (home != null && home.isNotEmpty) ? home : null,
    runDir: runDir ?? processSandboxRunDir(spec),
  );
}

/// [processSandboxPolicy] materialized into the platform config.
Future<SandboxConfig> processSandboxConfig(
  SandboxSpec spec, {
  String? runDir,
}) => buildSandboxConfigFromPolicy(processSandboxPolicy(spec, runDir: runDir));
