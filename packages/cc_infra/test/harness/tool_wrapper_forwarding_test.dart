import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_file_tools.dart';
import 'package:cc_infra/src/harness/diagnostics_on_write.dart';
import 'package:cc_infra/src/harness/harness_tool_search_tool.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A write tool with every property a wrapper must forward set away from its
/// default, answering with a structured value.
class _Inner extends HarnessTool {
  @override
  String get name => 'write';
  @override
  String get description => 'Writes a file.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;
  @override
  bool get scriptCallable => false;
  @override
  String? scriptArgumentRefusal(Map<String, dynamic> args) =>
      args.containsKey('owner') ? 'no owner from a script' : null;
  @override
  bool get waitsOnPerson => true;
  @override
  String get resultNote => '{path: string}.';
  @override
  Map<String, dynamic> get outputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
    },
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    await File('${args['path']}').writeAsString('notes\n');
    return HarnessToolResult.success(
      'wrote',
      structured: {'path': args['path']},
    );
  }
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('cc_wrappers_'));
  tearDown(() => root.deleteSync(recursive: true));

  group('DiagnosticsOnWriteTool', () {
    DiagnosticsOnWriteTool wrap() => DiagnosticsOnWriteTool(
      inner: _Inner(),
      supervisor: LspSupervisor(),
      ledger: DiagnosticsLedger(),
      workingDirectory: root.path,
      launcher: const RefusingToolProcessLauncher(),
    );

    test('reports the wrapped tool\'s script properties', () {
      final tool = wrap();
      expect(tool.scriptCallable, isFalse);
      expect(tool.waitsOnPerson, isTrue);
      expect(tool.outputSchema, _Inner().outputSchema);
      expect(tool.resultNote, _Inner().resultNote);
      // The wrapped tool's argument rule reaches the gate unchanged.
      expect(
        tool.scriptArgumentRefusal({'owner': 'x'}),
        'no owner from a script',
      );
      expect(tool.scriptArgumentRefusal({'path': 'x'}), isNull);
    });

    test('keeps the wrapped tool\'s structured result', () async {
      // A markdown file has no language server, so the result is the inner
      // tool's own.
      final path = p.join(root.path, 'notes.md');
      final result = await wrap().execute({
        'path': path,
      }, HarnessToolContext(workingDirectory: root.path));

      expect(result.isError, isFalse);
      expect(result.structured, {'path': path});
    });
  });

  group('controlled evaluation tools', () {
    ControlledEvaluationProcess process() => ControlledEvaluationProcess(
      root: root.path,
      home: root.path,
      readOnlyRoots: const [],
    );

    test('bash reports the wrapped tool\'s script properties', () {
      final tool = ControlledEvaluationBashTool(process());
      final bash = BashTool(process());
      expect(tool.scriptCallable, bash.scriptCallable);
      expect(tool.waitsOnPerson, bash.waitsOnPerson);
      expect(tool.outputSchema, bash.outputSchema);
      expect(tool.outputSchema, isNotNull);
      expect(tool.resultNote, bash.resultNote);
      expect(tool.resultNote, isNotNull);
    });

    test('file tools promise no structured result they never return', () {
      for (final tool in controlledFileTools(process())) {
        expect(tool.scriptCallable, isTrue, reason: tool.name);
        expect(tool.waitsOnPerson, isFalse, reason: tool.name);
        expect(tool.outputSchema, isNull, reason: tool.name);
        expect(tool.resultNote, isNull, reason: tool.name);
      }
    });
  });

  test('search_tools cannot be called from a script', () {
    final tool = HarnessToolSearchTool(
      catalog: const [],
      residency: const ToolResidencySpec(),
    );
    expect(tool.scriptCallable, isFalse);
  });
}
