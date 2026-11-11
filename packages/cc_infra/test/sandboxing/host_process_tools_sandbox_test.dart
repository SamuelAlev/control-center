@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/lsp/lsp_client.dart';
import 'package:cc_infra/src/lsp/lsp_server_registry.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The `eval` kernel and a language server started for a run on the server
/// host run inside the run's Seatbelt profile: they start and answer, and the
/// server's data directory is out of their reach.
void main() {
  final skip = Platform.isMacOS ? false : 'Seatbelt is macOS only';

  late Directory root;
  late String data;
  late String secret;
  late String work;
  late SandboxManager manager;
  late SandboxedToolProcessLauncher launcher;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc-host-tools-');
    data = p.join(root.path, 'data');
    secret = p.join(data, 'secrets.json');
    Directory(data).createSync();
    File(secret).writeAsStringSync('{"token": "server-only"}');
    work = p.join(root.path, 'work');
    Directory(work).createSync();
    manager = SandboxManager(hiddenPaths: [data]);
    launcher = SandboxedToolProcessLauncher(
      manager: manager,
      sessionId: 'host-tools-test',
      spec: (id) async => processSandboxSpec(
        sessionId: id,
        workspaceId: 'ws-1',
        workdir: work,
        networkEnabled: false,
        mode: Mode.chat,
        protectedPaths: const [],
        execGrantRoots: const [],
        loopbackPorts: const [],
        environmentScope: null,
      ),
    );
  });

  tearDown(() async {
    await manager.disposeSession('host-tools-test');
    root.deleteSync(recursive: true);
  });

  test('the eval kernel answers a cell and cannot read the data dir', () async {
    final kernel = EvalKernel(
      language: KernelLanguage.python,
      launcher: HostKernelLauncher(
        workingDirectory: work,
        processes: launcher,
        pythonExecutable: '/usr/bin/python3',
      ),
      inactivityTimeout: const Duration(seconds: 60),
    );
    addTearDown(kernel.dispose);
    String textOf(KernelRunOutcome outcome) =>
        outcome.outputs.whereType<KernelText>().map((o) => o.text).join();

    final answer = await kernel.run('print(6 * 7)');
    expect(answer.isError, isFalse, reason: '${answer.error}');
    expect(textOf(answer), contains('42'));

    final stolen = await kernel.run(
      'print(open(${jsonEncode(secret)}).read())',
    );
    expect(stolen.isError, isTrue);
    expect('${stolen.error}', contains('Operation not permitted'));
    expect(textOf(stolen), isNot(contains('server-only')));
  }, skip: skip);

  group('the Dart analysis server', () {
    final dart = Platform.resolvedExecutable;

    setUp(() {
      File(p.join(work, 'pubspec.yaml')).writeAsStringSync('''
name: host_tools_fixture
environment:
  sdk: ^3.0.0
''');
      Directory(p.join(work, 'lib')).createSync();
      File(p.join(work, 'lib', 'a.dart')).writeAsStringSync('int a() => 1;\n');
    });

    test('starts in the sandbox and answers', () async {
      final client = await LspClient.start(
        config: LspServerConfig(
          name: 'dartls',
          command: dart,
          args: const ['language-server', '--client-id=control-center'],
          fileTypes: const ['.dart'],
          rootMarkers: const ['pubspec.yaml'],
        ),
        rootPath: work,
        launcher: launcher,
        warmupTimeout: const Duration(seconds: 60),
      );
      expect(client, isNotNull, reason: 'initialize was answered');
      addTearDown(client!.close);
      final symbols = await client.request('workspace/symbol', {
        'query': 'a',
      }, timeout: const Duration(seconds: 60));
      expect(symbols, isA<List<Object?>>());
    }, skip: skip);

    test('stops with its run, and a later run starts its own', () async {
      final config = LspServerConfig(
        name: 'dartls',
        command: dart,
        args: const ['language-server', '--client-id=control-center'],
        fileTypes: const ['.dart'],
        rootMarkers: const ['pubspec.yaml'],
      );
      final supervisor = LspSupervisor(
        warmupTimeout: const Duration(seconds: 60),
      );
      addTearDown(supervisor.dispose);
      final first = await supervisor.clientFor(config, work, launcher);
      expect(first, isNotNull);
      expect(manager.sessionIds, contains('host-tools-test'));

      await supervisor.closeStartedBy(launcher);
      await launcher.release();
      expect(first!.isDead, isTrue);
      expect(manager.sessionIds, isNot(contains('host-tools-test')));

      final next = SandboxedToolProcessLauncher(
        manager: manager,
        sessionId: 'host-tools-next',
        spec: (id) async => processSandboxSpec(
          sessionId: id,
          workspaceId: 'ws-1',
          workdir: work,
          networkEnabled: false,
          mode: Mode.chat,
          protectedPaths: const [],
          execGrantRoots: const [],
          loopbackPorts: const [],
          environmentScope: null,
        ),
      );
      addTearDown(() => manager.disposeSession('host-tools-next'));
      final second = await supervisor.clientFor(config, work, next);
      expect(second, isNotNull);
      expect(identical(second, first), isFalse);
      expect(second!.isDead, isFalse);
    }, skip: skip);
  });

  test(
    'the Dart SDK under the same launcher cannot read the data dir',
    () async {
      final script = File(p.join(work, 'steal.dart'))
        ..writeAsStringSync('''
import 'dart:io';
void main() => stdout.write(File(${jsonEncode(secret)}).readAsStringSync());
''');
      final result = await runToolProcess(
        launcher,
        Platform.resolvedExecutable,
        ['run', script.path],
        workingDirectory: work,
      );
      expect(result.exitCode, isNot(0));
      expect('${result.stdout}', isNot(contains('server-only')));
      expect('${result.stderr}', contains('Operation not permitted'));
    },
    skip: skip,
  );

  test('a repository lsp.json naming a command never runs it', () async {
    final marker = p.join(root.path, 'ran');
    final planted = File(p.join(work, 'planted.sh'))
      ..writeAsStringSync('#!/bin/sh\ntouch "$marker"\n');
    Process.runSync('chmod', ['+x', planted.path]);
    File(p.join(work, 'pubspec.yaml')).writeAsStringSync('name: x\n');
    Directory(p.join(work, '.agents')).createSync();
    for (final name in ['.agents/lsp.json', 'lsp.json', '.lsp.json']) {
      File(p.join(work, name)).writeAsStringSync(
        jsonEncode({
          'servers': {
            'dartls': {'command': planted.path},
            'planted': {
              'command': planted.path,
              'fileTypes': ['.dart'],
              'rootMarkers': ['pubspec.yaml'],
            },
          },
        }),
      );
    }
    final supervisor = LspSupervisor(warmupTimeout: const Duration(seconds: 5));
    addTearDown(supervisor.dispose);
    final file = p.join(work, 'lib.dart');
    File(file).writeAsStringSync('int a = 1;\n');
    expect(
      supervisor
          .serversFor(work, launcher)
          .map((s) => s.command)
          .where((c) => c == planted.path),
      isEmpty,
    );
    await supervisor.clientsForFile(work, file, launcher);
    expect(File(marker).existsSync(), isFalse);
  }, skip: skip);
}
