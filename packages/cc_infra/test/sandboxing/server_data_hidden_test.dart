// Run sandboxes are Seatbelt and bubblewrap; Windows has none.
@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/process/agent_run_client_launcher.dart';
import 'package:cc_infra/src/sandboxing/hidden_roots.dart';
import 'package:cc_infra/src/sandboxing/linux_sandbox.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The server's data directory and `.env` are out of reach of every sandboxed
/// process, but for exactly what the run is handed.
///
/// The data dir holds every credential the server keeps (`secrets.json`, the
/// sealed sign-ins, the Connect install key), every workspace database and
/// every other run's worktree. The layout below is the real one, and the
/// spec is the one a dispatch builds for its CLI.
void main() {
  late _Tree tree;

  setUp(() => tree = _Tree.create());
  tearDown(() => tree.root.deleteSync(recursive: true));

  group('dispatch sandbox (real Seatbelt)', () {
    late SandboxManager manager;
    late SandboxSpec spec;
    late String runDir;

    setUp(() async {
      manager = SandboxManager(hiddenPaths: [tree.data, tree.env]);
      spec = await tree.session().sandboxSpecForTesting(signShim: true);
      runDir = processSandboxRunDir(spec)!;
      Directory(runDir).createSync(recursive: true);
    });

    tearDown(() => manager.disposeSession(spec.sessionId));

    /// Runs [script] under the dispatch's profile, with the tree's root as
    /// `$HOME`: the data dir sits under the writable home, the case the hide
    /// has to hold for.
    Future<ProcessResult> sandboxed(String script) async {
      final config = await buildSandboxConfigFromPolicy(
        const SandboxPolicyResolver().resolve(
          spec: spec,
          homeDir: tree.root.path,
          runDir: runDir,
        ),
      );
      final wrap = await manager.wrap(
        config: config,
        argv: ['/bin/bash', '-c', script],
        workingDirectory: tree.overlay,
      );
      return Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: tree.overlay,
        environment: {
          ...wrap.environment,
          'HOME': tree.root.path,
          'GIT_CONFIG_NOSYSTEM': '1',
          'GIT_CONFIG_GLOBAL': '/dev/null',
        },
        includeParentEnvironment: false,
      );
    }

    Future<void> expectDenied(String script) async {
      final r = await sandboxed(script);
      expect(r.exitCode, isNot(0), reason: '`$script` was allowed');
      expect(
        '${r.stderr}',
        contains('Operation not permitted'),
        reason: '`$script` failed for another reason: ${r.stderr}',
      );
    }

    Future<String> expectAllowed(String script) async {
      final r = await sandboxed(script);
      expect(r.exitCode, 0, reason: '`$script`: ${r.stderr}');
      return '${r.stdout}'.trim();
    }

    test('credential stores, databases and sibling runs are hidden', () async {
      for (final file in [
        tree.secrets,
        tree.globalDb,
        tree.workspaceDb,
        tree.siblingMcp,
        tree.siblingRepoFile,
        tree.otherAccount,
        tree.env,
      ]) {
        await expectDenied('cat "$file"');
        await expectDenied('echo planted >> "$file"');
      }
      await expectDenied('ls "${tree.data}"');
      await expectDenied('ls "${p.dirname(tree.siblingMcp)}"');
      await expectDenied('echo planted > "${tree.data}/new-file"');
      await expectDenied('cp "${tree.secrets}" "$runDir/copy"');
      await expectDenied('ln "${tree.secrets}" "$runDir/link"');
      // Renaming a directory above the data dir would move it out from under
      // every rule that names it.
      await expectDenied('mv "${p.dirname(tree.data)}" "${tree.root.path}/x"');
      expect(File(tree.secrets).readAsStringSync(), 'server secrets\n');
      expect(File(tree.siblingMcp).readAsStringSync(), contains('tok-other'));
    });

    test('what the run is handed still reads and writes', () async {
      final repo = p.join(tree.overlay, 'repos', 'app');
      expect(
        await expectAllowed(
          'echo own > own.txt && cat own.txt && '
          'echo wt > "$repo/new.txt" && cat "$repo/new.txt" && '
          'mkdir "$repo/sub" && mv "$repo/new.txt" "$repo/sub/moved" && '
          // `find -delete`, not `rm`: rm is exec-denied on every host where
          // it is not a multi-call binary.
          'find "$repo/sub" -delete && echo moved',
        ),
        'own\nwt\nmoved',
      );
      expect(
        await expectAllowed('cd "$repo" && git status --porcelain && pwd -P'),
        endsWith(Directory(tree.repo).resolveSymbolicLinksSync()),
      );
      expect(
        await expectAllowed('echo r > "$runDir/f" && cat "$runDir/f"'),
        'r',
      );
      expect(
        await expectAllowed(
          'cat "${tree.credentials}" && '
          'echo refreshed > "${tree.credentials}"',
        ),
        'token',
      );
      // The agent profile and the skills its links point to, read-only.
      expect(
        await expectAllowed('cat AGENTS.md .agents/skills/lint/SKILL.md'),
        'instructions\nskill',
      );
      await expectDenied('echo x >> "${tree.configDir}/AGENTS.md"');
      // A granted tree still executes.
      expect(await expectAllowed('"$repo/tool.sh"'), 'tool ran');
    });

    test('the run cannot change its tool dirs, and they still run', () async {
      final shimDir = spec.toolDirs.single;
      final shim = p.join(shimDir, AgentRunSigning.shimName);
      expect(spec.execGrantRoots, isNot(contains(shimDir)));
      await expectDenied('echo "echo owned" > "$shim"');
      await expectDenied('echo "echo owned" > "$shimDir/git"');
      await expectDenied('mv "$shim" "$runDir/gone"');
      await expectDenied('mv "$shimDir" "$shimDir.old"');
      await expectDenied('mv "${p.dirname(shimDir)}" "$runDir/moved"');
      await expectDenied(
        'mv "${p.dirname(p.dirname(shimDir))}" "${tree.overlay}/cc-runs-old"',
      );
      expect(
        File(shim).readAsStringSync(),
        AgentRunSigning.shim(AgentRunClientLauncher.current),
      );
      final r = await sandboxed('"$shim"');
      expect(r.exitCode, 1);
      expect('${r.stderr}', contains('this signer only signs commits'));
    });
  }, skip: Platform.isMacOS ? false : 'real Seatbelt proof runs on macOS');

  group('space terminal (real Seatbelt)', () {
    test('a terminal in a space sees that space, never the rest', () async {
      final manager = SandboxManager(hiddenPaths: [tree.data, tree.env]);
      const session = 'terminal-hidden-test';
      addTearDown(() => manager.disposeSession(session));
      final space = p.dirname(p.dirname(tree.overlay));
      final script =
          'cat "${p.join(tree.repo, 'README')}"; '
          'cat "${tree.secrets}" || echo denied; '
          'cat "${tree.siblingMcp}" || echo denied';
      final wrap = await manager.wrap(
        config: terminalSandboxConfig(sessionId: session, cwd: space),
        argv: ['/bin/bash', '-c', script],
        workingDirectory: space,
      );
      final r = await Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: space,
        environment: wrap.environment,
      );
      expect('${r.stdout}'.trim().split('\n'), ['readme', 'denied', 'denied']);
    });
  }, skip: Platform.isMacOS ? false : 'real Seatbelt proof runs on macOS');

  group('Linux launcher', () {
    late SandboxSpec spec;
    late List<String> args;

    setUp(() async {
      spec = await tree.session().sandboxSpecForTesting(signShim: true);
      final config = await buildSandboxConfigFromPolicy(
        const SandboxPolicyResolver().resolve(
          spec: spec,
          homeDir: tree.root.path,
          runDir: processSandboxRunDir(spec),
        ),
      );
      // bwrap cannot enforce the secret-file globs and refuses them
      // ([LinuxSandbox.validateConfig]); they are not what this pins.
      final fs = config.filesystem;
      final withoutGlobs = config.copyWith(
        filesystem: FilesystemConfig(
          denyRead: fs.denyRead,
          allowRead: fs.allowRead,
          allowWrite: fs.allowWrite,
          denyWrite: [
            for (final d in fs.denyWrite)
              if (!d.contains('*')) d,
          ],
        ),
      );
      args = LinuxSandbox.buildBwrapArgs(
        config: withHiddenRoots(withoutGlobs, [tree.data, tree.env]),
        innerCommand: 'true',
      );
    });

    /// Index of the last `<flag> <path…>` mount of [path] (bwrap's last mount
    /// wins), or -1.
    int mount(String flag, String path) {
      for (var i = args.length - 2; i >= 0; i--) {
        if (args[i] == flag && args.sublist(i + 1).take(2).contains(path)) {
          return i;
        }
      }
      return -1;
    }

    test('the data dir is masked after the home that contains it', () {
      final home = mount('--bind', tree.root.path);
      final mask = mount('--tmpfs', tree.data);
      expect(home, isNonNegative);
      expect(mask, greaterThan(home));
      expect(mount('--ro-bind-try', tree.env), greaterThan(home));
      expect(args[mount('--ro-bind-try', tree.env) + 1], '/dev/null');
    });

    test('exactly what the run is handed is bound back after the mask', () {
      final mask = mount('--tmpfs', tree.data);
      for (final writable in [
        tree.overlay,
        p.join(p.dirname(p.dirname(tree.overlay)), 'repos'),
        p.dirname(tree.credentials),
        processSandboxRunDir(spec)!,
      ]) {
        final at = mount('--bind-try', writable) >= 0
            ? mount('--bind-try', writable)
            : mount('--bind', writable);
        expect(at, greaterThan(mask), reason: writable);
      }
      for (final readOnly in [tree.configDir, tree.skills]) {
        expect(
          mount('--ro-bind-try', readOnly),
          greaterThan(mask),
          reason: readOnly,
        );
      }
      for (final hidden in [
        tree.secrets,
        tree.globalDb,
        p.dirname(tree.siblingMcp),
        p.dirname(tree.otherAccount),
      ]) {
        expect(args, isNot(contains(hidden)), reason: hidden);
      }
    });

    test('tool dirs are re-bound read-only after every writable bind', () {
      final shimDir = spec.toolDirs.single;
      final readOnly = mount('--ro-bind-try', shimDir);
      final lastWritable = [
        for (var i = 0; i < args.length; i++)
          if (args[i] == '--bind' || args[i] == '--bind-try') i,
      ].last;
      expect(readOnly, greaterThan(lastWritable));
    });
  });

  test('a config without hidden roots is unchanged', () async {
    final config = await processSandboxConfig(
      await tree.session().sandboxSpecForTesting(),
    );
    expect(HiddenRoots.of(config).roots, isEmpty);
    expect(
      MacosSandbox.generateSeatbeltProfile(config),
      isNot(contains('(deny file-read* (subpath "${tree.data}"))')),
    );
  });
}

/// A server data dir laid out the way the provisioner lays it out, with one
/// dispatch's overlay and a sibling space's run beside it.
final class _Tree {
  _Tree._(this.root);

  factory _Tree.create() {
    final root = Directory(
      Directory.systemTemp
          .createTempSync('cc-hidden-')
          .resolveSymbolicLinksSync(),
    );
    final t = _Tree._(root);
    void write(String path, String content) {
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('$content\n');
    }

    write(t.secrets, 'server secrets');
    write(t.globalDb, 'db');
    write(t.workspaceDb, 'db');
    write(t.env, 'GITHUB_CLIENT_SECRET=x');
    write(t.credentials, 'token');
    write(t.otherAccount, 'other token');
    write(p.join(t.configDir, 'AGENTS.md'), 'instructions');
    write(p.join(t.skills, 'lint', 'SKILL.md'), 'skill');
    write(t.siblingMcp, '{"headers":{"X-CC-Agent-Run":"tok-other"}}');
    write(t.siblingRepoFile, 'other');
    write(p.join(t.repo, 'README'), 'readme');
    write(p.join(t.repo, 'tool.sh'), '#!/bin/sh\necho tool ran\n');
    Process.runSync('/bin/chmod', ['755', p.join(t.repo, 'tool.sh')]);
    Process.runSync(
      'git',
      ['init', '-q', t.repo],
      environment: {
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_GLOBAL': '/dev/null',
      },
    );
    Directory(t.overlay).createSync(recursive: true);
    Link(p.join(t.overlay, 'repos')).createSync('../../repos');
    Link(
      p.join(t.overlay, 'AGENTS.md'),
    ).createSync(p.join(t.configDir, 'AGENTS.md'));
    Link(
      p.join(t.overlay, '.agents', 'skills', 'lint'),
    ).createSync(p.join(t.skills, 'lint'), recursive: true);
    return t;
  }

  final Directory root;

  String get data => p.join(root.path, 'dev', 'cc', 'data');
  String get env => p.join(root.path, 'dev', 'cc', '.env');
  String get secrets => p.join(data, 'secrets.json');
  String get globalDb => p.join(data, 'global.db');
  String get credentials =>
      p.join(data, 'claude-accounts', 'account', '.credentials.json');
  String get otherAccount =>
      p.join(data, 'claude-accounts', 'account-2', '.credentials.json');
  String get workspace => p.join(data, 'ws-1');
  String get workspaceDb => p.join(workspace, 'workspace.db');
  String get configDir => p.join(workspace, 'agents', 'agent-1');
  String get skills => p.join(workspace, 'skills');
  String get overlay =>
      p.join(workspace, 'spaces', 'space-1', 'agents', 'agent-1');
  String get repo => p.join(workspace, 'spaces', 'space-1', 'repos', 'app');
  String get siblingMcp =>
      p.join(workspace, 'spaces', 'space-2', 'agents', 'agent-9', '.mcp.json');
  String get siblingRepoFile =>
      p.join(workspace, 'spaces', 'space-2', 'repos', 'other', 'file');

  /// A dispatch of agent-1 in space-1, with its Claude Code account and the
  /// space's worktrees granted for exec (they are server-made copies).
  DispatchSession session() => DispatchSession(
    deps: SandboxDispatchDeps(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: _UnusedSandbox(),
      agentRepo: _UnusedAgents(),
      runLogRepo: _UnusedRunLogs(),
      eventBus: null,
      backendRegistry: BackendRegistry(const {}),
      execGrantService: SandboxExecGrantService(
        repository: _NoDecisions(),
        idFactory: () => 'grant',
      ),
    ),
    onResolveHandle:
        ({
          required String sessionId,
          required SandboxSpec spec,
          required void Function(AgentProcessEvent) emit,
        }) => throw UnimplementedError(),
    onScheduleCooldown: (_) {},
    dispatchId: 'd1',
    cliName: 'claude',
    prompt: 'hello',
    agentDirHostPath: overlay,
    agentConfigDir: configDir,
    claudeConfigDir: p.dirname(credentials),
    modelId: 'anthropic/test',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    runLogId: 'run-1',
    mode: Mode.chat,
  );
}

/// Collaborators a sandbox spec never reaches.
mixin _Unused {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _UnusedSandbox with _Unused implements SandboxPort {}

class _UnusedAgents with _Unused implements AgentRepository {}

class _UnusedRunLogs with _Unused implements AgentRunLogRepository {}

class _NoDecisions implements SandboxExecGrantRepository {
  @override
  Future<List<SandboxExecGrant>> grants(String workspaceId) async => const [];

  @override
  Future<SandboxExecGrant?> decisionFor(
    String workspaceId,
    String path,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
