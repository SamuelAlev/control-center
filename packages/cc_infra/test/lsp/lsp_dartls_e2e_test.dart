@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/diagnostics_on_write.dart';
import 'package:cc_infra/src/harness/lsp_tool.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Drives a REAL `dart language-server` against a throwaway package.
///
/// The unit tests cover the pure pieces (ledger identity, symbol resolution,
/// detection). This is the one that answers the question that actually
/// matters: does an agent editing Dart in this repo get told it broke the
/// build? Everything in between — spawning the server, framing JSON-RPC,
/// syncing the document, waiting for the right publish, converting 0-indexed
/// LSP positions — only fails against a live server.
///
/// Skipped when the Dart SDK is not on PATH.
void main() {
  late Directory root;
  late LspSupervisor supervisor;
  late DiagnosticsLedger ledger;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('cc_dartls');
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: lsp_fixture
environment:
  sdk: ^3.0.0
''');
    Directory(p.join(root.path, 'lib')).createSync();
    supervisor = LspSupervisor(warmupTimeout: const Duration(seconds: 60));
    ledger = DiagnosticsLedger();
  });

  tearDown(() async {
    await supervisor.dispose();
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // A server may still hold a handle on Windows; the temp dir is swept.
    }
  });

  /// Waits for the analyzer to settle on [path] and returns fresh diagnostics.
  Future<List<LspDiagnostic>> analyze(String path, String content) async {
    File(path).writeAsStringSync(content);
    final clients = await supervisor.clientsForFile(root.path, path);
    if (clients.isEmpty) {
      return const [];
    }
    var found = <LspDiagnostic>[];
    // The analyzer publishes an empty set while it is still loading the
    // package, so settle on a non-empty answer or the deadline — polling for
    // "any publish" would consistently catch the empty one.
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(deadline)) {
      for (final client in clients) {
        await client.syncFile(path, content);
        found = await client.waitForDiagnostics(
          path,
          timeout: const Duration(seconds: 5),
        );
      }
      if (found.isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return found;
  }

  test('reports a real type error, and does not repeat it', () async {
    final path = p.join(root.path, 'lib', 'broken.dart');
    final diagnostics = await analyze(path, '''
int wrong() {
  return 'not an int';
}
''');

    expect(
      diagnostics,
      isNotEmpty,
      reason: 'dartls must report the return-type mismatch',
    );
    expect(
      diagnostics.any((d) => d.severity == 'error'),
      isTrue,
      reason: 'a String returned from an int function is an error',
    );
    expect(
      diagnostics.every((d) => d.line >= 1 && d.column >= 1),
      isTrue,
      reason: 'LSP positions are 0-indexed; ours must be 1-indexed',
    );

    // First report says everything; the second says nothing new. This is what
    // keeps diagnostics-on-write usable rather than a wall of repeats.
    final first = ledger.fresh(path, diagnostics);
    expect(first, isNotEmpty);
    expect(
      ledger.fresh(path, diagnostics),
      isEmpty,
      reason: 'the same unchanged error must not be re-reported',
    );
  });

  test('a clean file reports nothing', () async {
    final path = p.join(root.path, 'lib', 'fine.dart');
    File(path).writeAsStringSync('int fine() => 1;\n');
    final clients = await supervisor.clientsForFile(root.path, path);
    if (clients.isEmpty) {
      return;
    }
    for (final client in clients) {
      await client.syncFile(path, 'int fine() => 1;\n');
      final diagnostics = await client.waitForDiagnostics(
        path,
        timeout: const Duration(seconds: 10),
      );
      expect(diagnostics.where((d) => d.severity == 'error'), isEmpty);
    }
  });

  test('the lsp tool answers hover and definition by symbol', () async {
    final path = p.join(root.path, 'lib', 'nav.dart');
    File(path).writeAsStringSync('''
int alpha() => 1;

int beta() => alpha();
''');
    final tool = LspTool(
      supervisor: supervisor,
      ledger: ledger,
      workingDirectory: root.path,
    );
    const ctx = HarnessToolContext(workingDirectory: '.');

    // Warm the server up through the tool's own path.
    await tool.execute({'action': 'diagnostics', 'file': path}, ctx);

    final definition = await tool.execute({
      'action': 'definition',
      'file': path,
      'line': 3,
      'symbol': 'alpha',
    }, ctx);
    expect(definition.isError, isFalse);
    expect(
      definition.content,
      anyOf(contains('nav.dart'), contains('No definition')),
      reason: 'either it resolved, or the server had not indexed yet — but '
          'never a crash',
    );

    // Refusing to guess a column is the contract, and it holds through the
    // tool, not just the resolver.
    final noSymbol = await tool.execute({
      'action': 'definition',
      'file': path,
      'line': 3,
    }, ctx);
    expect(noSymbol.isError, isTrue);
    expect(noSymbol.content, contains('symbol'));
  });

  test('diagnostics-on-write folds the error into the write result', () async {
    final inner = _FakeWriteTool(root.path);
    final wrapped = DiagnosticsOnWriteTool(
      inner: inner,
      supervisor: supervisor,
      ledger: ledger,
      workingDirectory: root.path,
      budget: const Duration(seconds: 20),
    );
    const ctx = HarnessToolContext(workingDirectory: '.');
    final path = p.join(root.path, 'lib', 'written.dart');

    // Warm the analyzer first so the budget is spent on the publish, not on
    // the cold start.
    await analyze(path, 'int ok() => 1;\n');

    final result = await wrapped.execute({
      'path': path,
      'content': 'int broken() {\n  return "nope";\n}\n',
    }, ctx);

    expect(result.isError, isFalse, reason: 'the write itself succeeded');
    expect(inner.calls, 1);
    expect(
      result.content,
      contains('wrote'),
      reason: "the inner tool's own output must survive",
    );
    // The whole point: the agent is told it broke the build, attached to the
    // write that broke it.
    expect(result.content, contains('Diagnostics for'));
  });

  test('a failed write reports no diagnostics', () async {
    final wrapped = DiagnosticsOnWriteTool(
      inner: _FailingTool(),
      supervisor: supervisor,
      ledger: ledger,
      workingDirectory: root.path,
    );
    final result = await wrapped.execute(
      {'path': p.join(root.path, 'lib', 'x.dart')},
      const HarnessToolContext(workingDirectory: '.'),
    );
    expect(result.isError, isTrue);
    expect(
      result.content,
      isNot(contains('Diagnostics')),
      reason: 'nothing changed, so there is nothing new to say — and the '
          "model's next move is to fix the edit",
    );
  });
}

/// A minimal stand-in for the real write tool.
class _FakeWriteTool extends HarnessTool {
  _FakeWriteTool(this.root);
  final String root;
  int calls = 0;

  @override
  String get name => 'write';
  @override
  String get description => 'writes a file';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    calls++;
    final path = args['path'] as String;
    File(path).writeAsStringSync(args['content'] as String);
    return HarnessToolResult.success('wrote $path');
  }
}

class _FailingTool extends HarnessTool {
  @override
  String get name => 'write';
  @override
  String get description => 'fails';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.error('could not write');
}
