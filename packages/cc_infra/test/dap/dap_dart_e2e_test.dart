import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dap/dap_adapter_registry.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/harness/debug_tool.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Drives the `debug` tool against a REAL `dart debug_adapter`.
///
/// The unit tests pin the protocol plumbing; this pins the only claim that
/// matters — that an agent can set a breakpoint, launch, and read a live stack
/// frame. A debugger that speaks perfect DAP and never stops anywhere is not a
/// feature.
void main() {
  final dart = _resolveDart();

  late Directory root;
  late DebugSessionSupervisor supervisor;
  late DebugTool tool;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_dap');
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: dap_fixture
environment:
  sdk: ^3.0.0
''');
    Directory(p.join(root.path, 'bin')).createSync();
    File(p.join(root.path, 'bin', 'main.dart')).writeAsStringSync('''
void main() {
  final answer = compute(6, 7);
  print(answer);
}

int compute(int a, int b) {
  final product = a * b;
  return product;
}
''');
    supervisor = DebugSessionSupervisor(ttl: const Duration(minutes: 2));
    tool = DebugTool(
      supervisor: supervisor,
      workingDirectory: root.path,
      sessionKey: 'conv-1',
    );
  });

  tearDown(() async {
    await supervisor.dispose();
    await deleteDirBestEffort(root);
  });

  HarnessToolContext ctx() => HarnessToolContext(workingDirectory: root.path);

  group('registry', () {
    test('detects the dart adapter in a pub package', () {
      final found = detectDapAdapters(root.path);
      expect(
        found.map((a) => a.spec.id),
        contains('dart'),
        skip: dart == null ? 'no dart on PATH' : null,
      );
    });

    test('a root marker alone is not enough', () {
      // Intersection, not union: a marker says "this project is Python" and
      // nothing about whether the adapter is installed. Offering a `debug`
      // tool that always fails is worse than not offering it.
      final found = detectDapAdapters(
        root.path,
        resolveBinary: (_, _, _) => null,
      );
      expect(found, isEmpty);
    });

    test('a binary alone is not enough either', () {
      final empty = Directory.systemTemp.createTempSync('cc_dap_bare');
      addTearDown(() => empty.deleteSync(recursive: true));
      expect(
        detectDapAdapters(empty.path, resolveBinary: (c, _, _) => '/bin/$c'),
        isEmpty,
      );
    });

    test('routes a file to the adapter that claims its extension', () {
      const dartAdapter = ResolvedDapAdapter(
        spec: DapAdapterSpec(
          id: 'dart',
          command: 'dart',
          args: [],
          rootMarkers: [],
          extensions: ['dart'],
        ),
        executable: 'dart',
      );
      const goAdapter = ResolvedDapAdapter(
        spec: DapAdapterSpec(
          id: 'delve',
          command: 'dlv',
          args: [],
          rootMarkers: [],
          extensions: ['go'],
        ),
        executable: 'dlv',
      );
      expect(
        adapterForPath('lib/a.dart', [goAdapter, dartAdapter])?.spec.id,
        'dart',
      );
      expect(adapterForPath('lib/a.txt', [goAdapter, dartAdapter]), isNull);
    });
  });

  group('tool guards', () {
    test('is exec tier and declares a process spawn', () {
      expect(tool.approvalTier, ToolApprovalTier.exec);
      expect(tool.actionClasses, contains(ActionClass.processSpawn));
    });

    test('is not parallel-safe — a session is state across calls', () {
      // `continue` overtaking `stack` reads a frame that has already moved.
      expect(tool.parallelSafe, isFalse);
    });

    test('reads refuse without a session rather than starting one', () async {
      final result = await tool.execute({'op': 'stack'}, ctx());
      expect(result.isError, isTrue);
      expect(result.content, contains('No debug session'));
    });

    test('breakpoints may be set before a session exists', () async {
      // That IS the DAP order: set breakpoints, launch, configurationDone.
      final result = await tool.execute({
        'op': 'breakpoints',
        'file': 'bin/main.dart',
        'lines': [7],
      }, ctx());
      expect(result.isError, isFalse);
      expect(result.content, contains('next launch'));
    });

    test('status says nothing is running', () async {
      final result = await tool.execute({'op': 'status'}, ctx());
      expect(result.content, contains('No debug session'));
    });

    test('rejects a launch with no program', () async {
      final result = await tool.execute({'op': 'launch'}, ctx());
      expect(result.isError, isTrue);
    });
  });

  group(
    'live adapter',
    () {
      // A loaded CI machine can drop the VM service between `stopped` and the
      // first `stackTrace` (seen on macos-14). Retrying is a new adapter +
      // isolate; looping `stack` on a dead service is not.
      test('stops at a breakpoint and reads the frame', () async {
        await tool.execute({
          'op': 'breakpoints',
          'file': 'bin/main.dart',
          'lines': [8],
        }, ctx());

        final launched = await tool.execute({
          'op': 'launch',
          'program': 'bin/main.dart',
        }, ctx());
        expect(launched.isError, isFalse, reason: launched.content);
        expect(
          launched.content,
          contains('Stopped'),
          reason: 'the breakpoint on the product line should be hit',
        );

        final stack = await tool.execute({'op': 'stack'}, ctx());
        expect(stack.isError, isFalse, reason: stack.content);
        expect(
          stack.content,
          contains('compute'),
          reason: 'the frame is inside compute(), not main()',
        );
        // The adapter reports frame paths with platform separators.
        expect(stack.content.replaceAll(r'\', '/'), contains('bin/main.dart'));

        // The payoff over a print statement: every local at once, plus an
        // expression evaluated in the frame's own scope.
        final frameId = RegExp(r'#(\d+)').firstMatch(stack.content)?.group(1);
        expect(frameId, isNotNull);
        final scopes = await tool.execute({
          'op': 'scopes',
          'frame_id': int.parse(frameId!),
        }, ctx());
        expect(scopes.isError, isFalse, reason: scopes.content);

        final reference = RegExp(
          r'reference (\d+)',
        ).firstMatch(scopes.content)?.group(1);
        expect(reference, isNotNull, reason: scopes.content);
        final variables = await tool.execute({
          'op': 'variables',
          'reference': int.parse(reference!),
        }, ctx());
        expect(variables.isError, isFalse, reason: variables.content);
        expect(
          variables.content,
          anyOf(contains('a'), contains('b')),
          reason: 'the arguments are in scope at that line',
        );

        final terminated = await tool.execute({'op': 'terminate'}, ctx());
        expect(terminated.isError, isFalse);
        expect(supervisor.sessionFor('conv-1'), isNull);
      }, retry: 2);

      test('a second launch is refused, not silently swapped', () async {
        await tool.execute({
          'op': 'breakpoints',
          'file': 'bin/main.dart',
          'lines': [8],
        }, ctx());
        await tool.execute({'op': 'launch', 'program': 'bin/main.dart'}, ctx());

        final second = await tool.execute({
          'op': 'launch',
          'program': 'bin/main.dart',
        }, ctx());
        expect(second.isError, isTrue);
        expect(second.content, contains('already running'));
      });
    },
    // The adapter ships with the SDK, so its absence means no Dart on PATH.
    skip: dart == null
        ? 'dart is not on PATH — the debug adapter ships with the SDK'
        : null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

String? _resolveDart() {
  try {
    final result = Process.runSync(Platform.isWindows ? 'where' : 'which', [
      'dart',
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final first = '${result.stdout}'.split('\n').first.trim();
    return first.isEmpty ? null : first;
  } on Object {
    return null;
  }
}
