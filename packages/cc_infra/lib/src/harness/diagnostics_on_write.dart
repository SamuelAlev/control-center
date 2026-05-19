import 'dart:async';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:path/path.dart' as p;

/// Argument keys the built-in write tools use for their target path.
const List<String> _pathKeys = ['path', 'file_path', 'filename', 'file'];

/// Wraps a file-mutating tool so its result carries the compiler's opinion.
///
/// **This is the feature, not the `lsp` tool.** An agent that has to remember
/// to ask "did that compile?" mostly does not, and finds out several edits
/// later when the error is entangled with three other changes. Folding
/// diagnostics into the write result closes the loop at the moment it is
/// cheapest to close: the model just wrote the line, and the feedback arrives
/// attached to that write.
///
/// Two properties make it usable rather than noisy:
///
///  * **Only NEW diagnostics.** A file with a dozen pre-existing warnings
///    would otherwise re-report all of them after every edit, burying the one
///    error the edit introduced. The [DiagnosticsLedger] holds what has
///    already been said.
///  * **A budget, not a blocker.** The wait is bounded; a server still
///    indexing simply contributes nothing this time. A successful edit must
///    never fail because a language server was slow.
class DiagnosticsOnWriteTool extends HarnessTool {
  /// Wraps [inner], reporting diagnostics for whatever file it wrote.
  DiagnosticsOnWriteTool({
    required HarnessTool inner,
    required LspSupervisor supervisor,
    required DiagnosticsLedger ledger,
    required String workingDirectory,
    this.budget = const Duration(seconds: 5),
  }) : _inner = inner,
       _supervisor = supervisor,
       _ledger = ledger,
       _workingDirectory = workingDirectory;

  final HarnessTool _inner;
  final LspSupervisor _supervisor;
  final DiagnosticsLedger _ledger;
  final String _workingDirectory;

  /// How long to wait for the server to publish after the write.
  final Duration budget;

  @override
  String get name => _inner.name;
  @override
  String get description => _inner.description;
  @override
  Map<String, dynamic> get inputSchema => _inner.inputSchema;
  @override
  ToolApprovalTier get approvalTier => _inner.approvalTier;
  @override
  Set<ActionClass> get actionClasses => _inner.actionClasses;
  @override
  bool get selfGuards => _inner.selfGuards;
  @override
  bool get parallelSafe => _inner.parallelSafe;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final result = await _inner.execute(args, context);
    // A failed edit changed nothing, so there is nothing new to say about it —
    // and the model's next move is to fix the edit, not to read diagnostics.
    if (result.isError) {
      return result;
    }
    final report = await _report(args).timeout(
      budget + const Duration(seconds: 2),
      onTimeout: () => '',
    );
    if (report.isEmpty) {
      return result;
    }
    return HarnessToolResult(
      content: '${result.content}\n\n$report',
      isError: false,
      images: result.images,
    );
  }

  Future<String> _report(Map<String, dynamic> args) async {
    try {
      final paths = _targetPaths(args);
      if (paths.isEmpty) {
        return '';
      }
      final sections = <String>[];
      for (final path in paths) {
        final section = await _reportOne(path);
        if (section.isNotEmpty) {
          sections.add(section);
        }
      }
      return sections.join('\n\n');
    } on Object catch (e) {
      // Diagnostics are an enhancement to a write that already succeeded.
      // Nothing here may turn that success into a failure.
      CcInfraLog.warning('diagnostics-on-write failed: $e');
      return '';
    }
  }

  Future<String> _reportOne(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return '';
    }
    final root = findProjectRoot(p.dirname(path));
    // No server for this language is the common case (markdown, JSON, YAML)
    // and must cost nothing — notably NOT a server start.
    if (_supervisor.serversForFile(root, path).isEmpty) {
      return '';
    }
    final clients = await _supervisor.clientsForFile(root, path);
    if (clients.isEmpty) {
      return '';
    }
    final content = await file.readAsString();
    final all = <LspDiagnostic>[];
    for (final client in clients) {
      await client.syncFile(path, content);
      all.addAll(await client.waitForDiagnostics(path, timeout: budget));
    }
    final fresh = freshDiagnosticsReport(
      ledger: _ledger,
      path: path,
      current: all,
    );
    if (fresh.isEmpty) {
      return '';
    }
    final relative = p.relative(path, from: _workingDirectory);
    return 'Diagnostics for $relative:\n$fresh';
  }

  /// Every file path this call wrote — one for a single edit, several for a
  /// batch. A batch that reported only its first file would let an error in
  /// the second pass silently.
  List<String> _targetPaths(Map<String, dynamic> args) {
    final out = <String>{};
    void add(Object? value) {
      if (value is! String || value.trim().isEmpty) {
        return;
      }
      out.add(
        p.isAbsolute(value)
            ? p.normalize(value)
            : p.normalize(p.join(_workingDirectory, value)),
      );
    }

    for (final key in _pathKeys) {
      add(args[key]);
    }
    final edits = args['edits'];
    if (edits is List) {
      for (final edit in edits) {
        if (edit is Map) {
          for (final key in _pathKeys) {
            add(edit[key]);
          }
        }
      }
    }
    return out.toList();
  }
}
