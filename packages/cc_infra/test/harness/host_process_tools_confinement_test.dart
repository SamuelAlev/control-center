import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/debug_tool.dart';
import 'package:cc_infra/src/harness/diagnostics_on_write.dart';
import 'package:cc_infra/src/harness/eval_tool.dart';
import 'package:cc_infra/src/harness/harness_tool_registry_builder.dart';
import 'package:cc_infra/src/harness/lsp_rename_tool.dart';
import 'package:cc_infra/src/harness/lsp_tool.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The `eval` kernel, the debug adapter, language servers and the project
/// checker start only through the run's [ToolProcessLauncher], declare host
/// execution exactly when it is unconfined, and `debug attach` reaches only
/// the run's own loopback ports.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc-host-tools-');
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x\n');
    Directory(p.join(root.path, 'lib')).createSync();
  });
  tearDown(() => root.deleteSync(recursive: true));

  group('action classes follow the launcher', () {
    final supervisor = LspSupervisor();
    tearDownAll(supervisor.dispose);

    Map<String, Set<ActionClass>> classes(ToolProcessLauncher launcher) {
      final ledger = DiagnosticsLedger();
      return {
        'eval': EvalTool(
          kernelFor: (_) => fail('no kernel'),
          hostConfined: launcher.confined,
        ).actionClasses,
        'debug': DebugTool(
          supervisor: DebugSessionSupervisor(),
          workingDirectory: root.path,
          sessionKey: 'conv-1',
          launcher: launcher,
          attachablePorts: const [],
        ).actionClasses,
        'lsp': LspTool(
          supervisor: supervisor,
          ledger: ledger,
          workingDirectory: root.path,
          launcher: launcher,
        ).actionClasses,
        'lsp_rename': LspRenameTool(
          supervisor: supervisor,
          ledger: ledger,
          workingDirectory: root.path,
          launcher: launcher,
        ).actionClasses,
      };
    }

    test('confined: a process spawn, never host execution', () {
      final declared = classes(_Recording(confined: true));
      expect(declared['eval'], {ActionClass.processSpawn});
      expect(declared['debug'], {ActionClass.processSpawn});
      expect(declared['lsp'], isEmpty);
      expect(declared['lsp_rename'], {ActionClass.fileWriteOutsideWorktree});
    });

    test('unconfined: host execution on every one of them', () {
      final declared = classes(_Recording(confined: false));
      for (final entry in declared.entries) {
        expect(
          entry.value,
          contains(ActionClass.hostExecution),
          reason: entry.key,
        );
      }
    });
  });

  test('debug attach refuses a port outside the run before starting', () async {
    final launcher = _Recording(confined: true);
    final tool = DebugTool(
      supervisor: DebugSessionSupervisor(),
      workingDirectory: root.path,
      sessionKey: 'conv-1',
      launcher: launcher,
      attachablePorts: const [4100],
    );
    final ctx = HarnessToolContext(workingDirectory: root.path);
    final refused = await tool.execute({'op': 'attach', 'port': 5432}, ctx);
    expect(refused.isError, isTrue);
    expect(refused.content, contains('4100'));
    expect(launcher.started, isEmpty);

    final none = DebugTool(
      supervisor: DebugSessionSupervisor(),
      workingDirectory: root.path,
      sessionKey: 'conv-1',
      launcher: launcher,
      attachablePorts: const [],
    );
    final closed = await none.execute({'op': 'attach', 'port': 4100}, ctx);
    expect(closed.isError, isTrue);
    expect(launcher.started, isEmpty);
  });

  test('the project checker runs through the launcher', () async {
    final launcher = _Recording(confined: true);
    final tool = LspTool(
      supervisor: LspSupervisor(),
      ledger: DiagnosticsLedger(),
      workingDirectory: root.path,
      launcher: launcher,
    );
    await tool.execute({
      'action': 'diagnostics',
      'file': '*',
    }, HarnessToolContext(workingDirectory: root.path));
    expect(launcher.started.single, ['dart', 'analyze', '--fatal-infos=false']);
  });

  test('the host kernel starts through the launcher, with the repo venv only '
      'when confined', () async {
    final venv = Directory(p.join(root.path, '.venv', 'bin'))
      ..createSync(recursive: true);
    File(p.join(venv.path, 'python3')).writeAsStringSync('#!/bin/sh\n');
    for (final confined in [true, false]) {
      final launcher = _Recording(confined: confined);
      await expectLater(
        HostKernelLauncher(
          workingDirectory: root.path,
          processes: launcher,
        ).start(KernelLanguage.python, 'runner.py'),
        throwsA(isA<_Refused>()),
      );
      expect(
        launcher.started.single.first,
        confined ? p.join(venv.path, 'python3') : 'python3',
      );
    }
  });

  test('an unconfined write never starts a language server', () async {
    final launcher = _Recording(confined: false);
    final tool = DiagnosticsOnWriteTool(
      inner: _Write(),
      supervisor: LspSupervisor(),
      ledger: DiagnosticsLedger(),
      workingDirectory: root.path,
      launcher: launcher,
    );
    final file = p.join(root.path, 'lib', 'a.dart');
    File(file).writeAsStringSync('int a = 1;\n');
    final result = await tool.execute({
      'path': file,
    }, HarnessToolContext(workingDirectory: root.path));
    expect(result.isError, isFalse);
    expect(launcher.started, isEmpty);
  });

  group('the registry offers the tools only with a launcher', () {
    HarnessToolRegistry build({ToolProcessLauncher? processes}) =>
        buildHarnessToolRegistry(
          mode: Mode.chat,
          networkEnabled: false,
          env: const {},
          conversationId: 'conv-1',
          fileSearch: _NoSearch(),
          lspSupervisor: LspSupervisor(),
          lspWorkingDirectory: root.path,
          debugSupervisor: DebugSessionSupervisor(),
          evalKernelFor: (_) => fail('no kernel'),
          toolProcesses: processes,
          debugProcesses: processes,
          lspProcesses: processes,
        );

    const names = ['eval', 'debug', 'lsp', 'lsp_rename'];

    test('without one, none of them', () {
      final registry = build();
      for (final name in names) {
        expect(registry.findByName(name), isNull, reason: name);
      }
    });

    test('with one, all of them', () {
      final registry = build(processes: _Recording(confined: true));
      for (final name in names) {
        expect(registry.findByName(name), isNotNull, reason: name);
      }
    });
  });

  group('host execution gate', () {
    Future<Object?> admit(
      HostExecutionPosture posture, {
      required String? requestedBy,
    }) async {
      try {
        await HostExecutionGate(
          posture: posture,
          // The owner fact as the server answers it: the acting person, else
          // (automation) the workspace owner, who is `olga` here.
          ownerAccountable:
              ({required workspaceId, required requestedByUserId}) async =>
                  (requestedByUserId ?? 'olga') == 'olga',
        ).admit(workspaceId: 'ws-1', requestedByUserId: requestedBy);
        return null;
      } on Object catch (e) {
        return e;
      }
    }

    for (final posture in HostExecutionPosture.values) {
      final refusesOthers = posture == HostExecutionPosture.unavailable;
      test('${posture.name}: the owner, interactive and automation', () async {
        expect(await admit(posture, requestedBy: 'olga'), isNull);
        expect(await admit(posture, requestedBy: null), isNull);
      });
      test(
        '${posture.name}: ${refusesOthers ? 'refuses' : 'admits'} anyone else',
        () async {
          final outcome = await admit(posture, requestedBy: 'eve');
          if (refusesOthers) {
            expect(outcome, isA<HostSandboxUnavailableException>());
            expect(
              (outcome! as HostSandboxUnavailableException).message,
              HostSandboxUnavailableException.refusal,
            );
          } else {
            expect(outcome, isNull);
          }
        },
      );
    }

    test('unavailable with no owner fact admits nobody', () async {
      await expectLater(
        const HostExecutionGate(
          posture: HostExecutionPosture.unavailable,
        ).admit(workspaceId: 'ws-1', requestedByUserId: 'olga'),
        throwsA(isA<HostSandboxUnavailableException>()),
      );
    });
  });
}

class _Refused implements Exception {}

/// Records every start and starts nothing.
class _Recording implements ToolProcessLauncher {
  _Recording({required this.confined});

  @override
  final bool confined;

  final started = <List<String>>[];

  @override
  Future<void> release() async {}

  @override
  Future<Process> start(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    started.add([executable, ...args]);
    throw _Refused();
  }
}

class _Write extends HarnessTool {
  @override
  String get name => 'write';
  @override
  String get description => 'write';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('wrote');
}

class _NoSearch implements FileSearchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
