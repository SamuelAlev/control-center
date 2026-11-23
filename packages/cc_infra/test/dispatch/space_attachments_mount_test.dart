@Timeout(Duration(minutes: 1))
library;

import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/messaging/prompt_attachments.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// What a person attaches to a message is written under the space's
/// `attachments/` and the prompt names it there, so the run's sandbox must
/// reach it read-only — also when the space checks out no repository and the
/// run works in the agent's own directory instead of a space overlay.
void main() {
  late Directory root;
  late String workspace;
  late String configDir;

  String attachmentsOf(String spaceId) =>
      p.join(workspace, 'spaces', spaceId, SpacePromptAttachments.dirName);

  setUp(() {
    root = Directory(
      Directory.systemTemp
          .createTempSync('cc-space-attachments-')
          .resolveSymbolicLinksSync(),
    );
    workspace = p.join(root.path, 'data', 'ws-1');
    configDir = p.join(workspace, 'agents', 'engineer');
    Directory(configDir).createSync(recursive: true);
  });
  tearDown(() => root.deleteSync(recursive: true));

  DispatchSession session({required String cwd, String? spaceId}) =>
      DispatchSession(
        freshHistory: false,
        deps: SandboxDispatchDeps(
          hostExecution: const HostExecutionGate(
            posture: HostExecutionPosture.offByOwner,
          ),
          sandbox: _NoopSandbox(),
          agentRepo: _UnusedAgentRepo(),
          runLogRepo: _UnusedRunLogRepo(),
          eventBus: null,
          backendRegistry: BackendRegistry(const {}),
        ),
        onResolveHandle:
            ({
              required String sessionId,
              required SandboxSpec spec,
              required void Function(AgentProcessEvent) emit,
            }) async => SandboxHandle(
              sessionId: sessionId,
              backend: SandboxBackend.none,
              state: SandboxState.warm,
            ),
        onScheduleCooldown: (_) {},
        dispatchId: 'd1',
        cliName: 'claude',
        prompt: 'read the pasted text',
        agentDirHostPath: cwd,
        agentConfigDir: configDir,
        modelId: 'opus',
        callerEnv: const {},
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        spaceId: spaceId,
        runLogId: 'run-1',
        requestedByUserId: 'olga',
        mode: Mode.chat,
        readOnly: false,
      );

  List<SandboxBindMount> readOnlyAt(SandboxSpec spec, String path) => [
    for (final m in spec.bindMounts)
      if (m.hostPath == path) m,
  ];

  test('a space with no repository still binds its attachments read-only '
      'beside the agent directory', () async {
    final attachments = attachmentsOf('space-1');
    Directory(attachments).createSync(recursive: true);

    final spec = await session(
      cwd: configDir,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();

    final mounts = readOnlyAt(spec, attachments);
    expect(mounts, hasLength(1));
    expect(mounts.single.readOnly, isTrue);
    expect(mounts.single.guestPath, attachments);
    expect(
      spec.bindMounts.where((m) => m.hostPath == configDir && !m.readOnly),
      hasLength(1),
    );
  });

  test('a space with nothing attached yet still binds its attachments '
      'read-only, so a file attached while the run is live stays '
      'readable', () async {
    Directory(
      p.join(workspace, 'spaces', 'space-1'),
    ).createSync(recursive: true);
    final attachments = attachmentsOf('space-1');

    final spec = await session(
      cwd: configDir,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();

    expect(Directory(attachments).existsSync(), isTrue);
    final mounts = readOnlyAt(spec, attachments);
    expect(mounts, hasLength(1));
    expect(mounts.single.readOnly, isTrue);
  });

  test('a space whose directory does not exist gets no attachments '
      'directory and binds nothing extra', () async {
    final spec = await session(
      cwd: configDir,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();

    expect(spec.bindMounts.map((m) => m.hostPath), [configDir]);
    expect(
      Directory(p.join(workspace, 'spaces', 'space-1')).existsSync(),
      isFalse,
    );
  });

  test('another space\'s attachments are never bound', () async {
    Directory(attachmentsOf('space-2')).createSync(recursive: true);

    final spec = await session(
      cwd: configDir,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();

    expect(spec.bindMounts.map((m) => m.hostPath), [configDir]);
  });

  test('a space id that is not one path segment binds nothing', () async {
    Directory(
      p.join(workspace, SpacePromptAttachments.dirName),
    ).createSync(recursive: true);

    for (final spaceId in ['..', '.', '../ws-1', 'a/b']) {
      final spec = await session(
        cwd: configDir,
        spaceId: spaceId,
      ).sandboxSpecForTesting();
      expect(spec.bindMounts.map((m) => m.hostPath), [
        configDir,
      ], reason: spaceId);
    }
  });

  test('a run with no space binds only its directory', () async {
    Directory(attachmentsOf('space-1')).createSync(recursive: true);

    final spec = await session(cwd: configDir).sandboxSpecForTesting();

    expect(spec.bindMounts.map((m) => m.hostPath), [configDir]);
  });

  test(
    'an overlay run keeps binding the space attachments it sits in',
    () async {
      final attachments = attachmentsOf('space-1');
      Directory(attachments).createSync(recursive: true);
      final overlay = p.join(
        workspace,
        'spaces',
        'space-1',
        'agents',
        'engineer',
      );
      Directory(overlay).createSync(recursive: true);

      final spec = await session(
        cwd: overlay,
        spaceId: 'space-1',
      ).sandboxSpecForTesting();

      final mounts = readOnlyAt(spec, attachments);
      expect(mounts, hasLength(1));
      expect(mounts.single.readOnly, isTrue);
    },
  );

  test('an overlay run in a space with nothing attached yet binds its '
      'attachments', () async {
    final attachments = attachmentsOf('space-1');
    final overlay = p.join(
      workspace,
      'spaces',
      'space-1',
      'agents',
      'engineer',
    );
    Directory(overlay).createSync(recursive: true);

    final spec = await session(
      cwd: overlay,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();

    expect(Directory(attachments).existsSync(), isTrue);
    final mounts = readOnlyAt(spec, attachments);
    expect(mounts, hasLength(1));
    expect(mounts.single.readOnly, isTrue);
  });

  test('real Seatbelt: a file attached to the space after the run started '
      'is readable from inside it', () async {
    Directory(
      p.join(workspace, 'spaces', 'space-1'),
    ).createSync(recursive: true);
    final spec = await session(
      cwd: configDir,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();
    final manager = SandboxManager(hiddenPaths: [p.join(root.path, 'data')]);
    addTearDown(() => manager.disposeSession(spec.sessionId));
    final runDir = processSandboxRunDir(spec)!;
    Directory(runDir).createSync(recursive: true);
    final config = await buildSandboxConfigFromPolicy(
      const SandboxPolicyResolver().resolve(
        spec: spec,
        homeDir: root.path,
        runDir: runDir,
      ),
    );

    // The space's first attachment, materialized after the profile is fixed
    // (a message steered into the live run).
    final attached = p.join(
      attachmentsOf('space-1'),
      'd583ac35-Catalogs-empty-state.json',
    );
    File(attached)
      ..createSync(recursive: true)
      ..writeAsStringSync('{"v":"5.7.4"}');

    final wrap = await manager.wrap(
      config: config,
      argv: ['/bin/bash', '-c', 'cat "$attached"'],
      workingDirectory: configDir,
    );
    final read = await Process.run(
      wrap.executable,
      wrap.argv,
      workingDirectory: configDir,
      environment: {...wrap.environment, 'HOME': root.path},
      includeParentEnvironment: false,
    );
    expect(read.exitCode, 0, reason: '${read.stderr}');
    expect('${read.stdout}', '{"v":"5.7.4"}');
  }, skip: Platform.isMacOS ? false : 'real Seatbelt proof runs on macOS');

  test('real Seatbelt: the run reads the pasted file by the path its prompt '
      'names, cannot change it, and still sees no other space', () async {
    final attachments = attachmentsOf('space-1');
    final pasted = p.join(attachments, '0eba213b-pasted-text.txt');
    File(pasted)
      ..createSync(recursive: true)
      ..writeAsStringSync('long paste\n');
    final other = p.join(attachmentsOf('space-2'), 'secret.txt');
    File(other)
      ..createSync(recursive: true)
      ..writeAsStringSync('other space\n');

    final spec = await session(
      cwd: configDir,
      spaceId: 'space-1',
    ).sandboxSpecForTesting();
    // As the server does: the whole data dir is hidden but what a run is
    // handed.
    final manager = SandboxManager(hiddenPaths: [p.join(root.path, 'data')]);
    addTearDown(() => manager.disposeSession(spec.sessionId));
    final runDir = processSandboxRunDir(spec)!;
    Directory(runDir).createSync(recursive: true);
    final config = await buildSandboxConfigFromPolicy(
      const SandboxPolicyResolver().resolve(
        spec: spec,
        homeDir: root.path,
        runDir: runDir,
      ),
    );

    Future<ProcessResult> sandboxed(String script) async {
      final wrap = await manager.wrap(
        config: config,
        argv: ['/bin/bash', '-c', script],
        workingDirectory: configDir,
      );
      return Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: configDir,
        environment: {...wrap.environment, 'HOME': root.path},
        includeParentEnvironment: false,
      );
    }

    final read = await sandboxed('cat "$pasted"');
    expect(read.exitCode, 0, reason: '${read.stderr}');
    expect('${read.stdout}', 'long paste\n');
    for (final script in [
      'echo x >> "$pasted"',
      'echo x > "$attachments/new.txt"',
      'cat "$other"',
    ]) {
      final r = await sandboxed(script);
      expect(r.exitCode, isNot(0), reason: '`$script` was allowed');
    }
    expect(File(pasted).readAsStringSync(), 'long paste\n');
  }, skip: Platform.isMacOS ? false : 'real Seatbelt proof runs on macOS');
}

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRunLogRepo implements AgentRunLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
