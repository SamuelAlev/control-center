import 'dart:async';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:path/path.dart' as p;

/// Argument keys the built-in write tools use for their target path.
const List<String> _pathKeys = ['path', 'file_path', 'filename', 'file'];

/// Wraps a file-mutating tool so its result includes compiler diagnostics.
///
/// Closes the feedback loop at write time (agents rarely call `lsp` later).
/// Reports only NEW diagnostics via [DiagnosticsLedger]. Wait is budgeted —
/// a slow language server must not fail a successful edit.
///
/// Starts a language server only through a confined [ToolProcessLauncher]:
/// with an unconfined one it reads the servers already running (started by
/// an `lsp` call, which declares host execution), so a write never starts an
/// unconfined process by itself.
class DiagnosticsOnWriteTool extends HarnessTool {
  /// Wraps [_inner], reporting diagnostics for whatever file it wrote.
  DiagnosticsOnWriteTool({
    required this._inner,
    required this._supervisor,
    required this._ledger,
    required this._workingDirectory,
    required this._launcher,
    this.budget = const Duration(seconds: 5),
  });

  final HarnessTool _inner;
  final LspSupervisor _supervisor;
  final DiagnosticsLedger _ledger;
  final String _workingDirectory;
  final ToolProcessLauncher _launcher;

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
  bool get scriptCallable => _inner.scriptCallable;
  @override
  String? scriptArgumentRefusal(Map<String, dynamic> args) =>
      _inner.scriptArgumentRefusal(args);
  @override
  String? executedContent(Map<String, dynamic> args) =>
      _inner.executedContent(args);
  @override
  Map<String, dynamic>? get outputSchema => _inner.outputSchema;

  @override
  String? get resultNote => _inner.resultNote;
  @override
  bool get waitsOnPerson => _inner.waitsOnPerson;

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
    final report = await _report(
      args,
    ).timeout(budget + const Duration(seconds: 2), onTimeout: () => '');
    if (report.isEmpty) {
      return result;
    }
    // Only the text grows: everything else the edit returned (its images, the
    // tools it activates, the structured result a script reads, its outcome
    // and its guard's decision)
    // is the wrapped tool's and passes through untouched.
    return HarnessToolResult(
      content: '${result.content}\n\n$report',
      isError: false,
      images: result.images,
      activateTools: result.activateTools,
      refusal: result.refusal,
      structured: result.structured,
      outcome: result.outcome,
      guardVerdict: result.guardVerdict,
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
    final root = findProjectRoot(p.dirname(path), ceiling: _workingDirectory);
    // No server for this language is the common case (markdown, JSON, YAML)
    // and must cost nothing — notably NOT a server start.
    if (_supervisor.serversForFile(root, path, _launcher).isEmpty) {
      return '';
    }
    final clients = _launcher.confined
        ? await _supervisor.clientsForFile(root, path, _launcher)
        : _supervisor.runningClientsForFile(root, path, _launcher);
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
