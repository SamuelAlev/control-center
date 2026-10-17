import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifact_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Runs deterministic acceptance checks. Controlled campaigns accept only
/// typed oracles: expected values remain in the controller, and submitted code
/// runs in a separate contained process without a checker mount. The legacy
/// noncontrolled CLI still supports its explicit local trusted-script checks;
/// it is not a security boundary for untrusted skill campaigns.
class EvaluationVerifierRunner {
  /// Creates an [EvaluationVerifierRunner].
  const EvaluationVerifierRunner({
    this.defaultTimeout = const Duration(minutes: 10),
    this.maxScanBytes = 2 * 1024 * 1024,
    this.maxScannedFiles = 20000,
  });

  /// Timeout for a verifier command.
  final Duration defaultTimeout;

  /// Largest file [EvaluationVerifierKind.declarationExists] will read.
  final int maxScanBytes;

  /// Largest number of files [EvaluationVerifierKind.declarationExists] walks.
  final int maxScannedFiles;

  /// True only for declarative checks the contained runner can grade without
  /// evaluating checker code or sharing expected answers with candidate code.
  static bool supportsContainedOracle(EvaluationVerifier verifier) {
    if (verifier.kind != EvaluationVerifierKind.tests &&
        verifier.kind != EvaluationVerifierKind.commandExit) {
      return false;
    }
    final params = verifier.params;
    if (params.keys.any((key) => key != 'oracle' && key != 'timeoutSeconds')) {
      return false;
    }
    final timeout = params['timeoutSeconds'];
    if (timeout != null && (timeout is! num || timeout <= 0)) {
      return false;
    }
    final oracle = params['oracle'];
    if (oracle is! Map) {
      return false;
    }
    final kind = oracle['kind'];
    final keys = switch (kind) {
      'python-module-cases' => {'kind', 'path', 'function', 'cases'},
      'python-review' => {
        'kind',
        'path',
        'function',
        'cases',
        'report',
        'reference',
      },
      'json-artifact' => {'kind', 'path', 'expected'},
      'safety-artifact' => {'kind', 'path', 'expected', 'absent'},
      _ => <String>{},
    };
    if (keys.isEmpty ||
        oracle.length != keys.length ||
        !oracle.keys.toSet().containsAll(keys)) {
      return false;
    }
    bool safePath(Object? path) =>
        path is String &&
        path.isNotEmpty &&
        !p.isAbsolute(path) &&
        !p.split(p.normalize(path)).contains('..') &&
        !p.split(p.normalize(path)).contains('.git') &&
        !p.split(p.normalize(path)).contains('.agents');
    if (!safePath(oracle['path'])) {
      return false;
    }
    if (kind == 'python-module-cases' || kind == 'python-review') {
      final function = oracle['function'];
      final cases = oracle['cases'];
      if (function is! String ||
          !RegExp(r'^[a-zA-Z_][a-zA-Z_0-9]*$').hasMatch(function) ||
          cases is! List ||
          cases.isEmpty ||
          cases.any((pair) => pair is! List || pair.length != 2)) {
        return false;
      }
      if (kind == 'python-review' &&
          (!safePath(oracle['report']) ||
              !_reviewReferences.contains(oracle['reference']))) {
        return false;
      }
    }
    if (kind == 'safety-artifact') {
      final absent = oracle['absent'];
      if (absent is! List || absent.any((path) => !safePath(path))) {
        return false;
      }
    }
    return true;
  }

  /// Runs [verifiers] and returns one result per verifier, in order.
  ///
  /// [workspaceRoot] is the candidate's working directory (file checks resolve
  /// against it). [gitRoot] is the repository root used for git-backed checks,
  /// which may be a PARENT of [workspaceRoot] when the task works in a
  /// sub-directory — passing only the sub-directory would silently skip the
  /// read-only checks.
  Future<List<EvaluationVerificationResult>> run({
    required List<EvaluationVerifier> verifiers,
    required String workspaceRoot,
    String? gitRoot,
    String? trustedScriptDir,
    EvaluationExecutionMode mode = EvaluationExecutionMode.live,
    bool controlled = false,
    CancellationToken? cancellation,
  }) async {
    final provenance = mode == EvaluationExecutionMode.offlineReplay
        ? VerificationProvenance.replayDeterministic
        : VerificationProvenance.behavioral;
    if (controlled || verifiers.any((v) => v.params.containsKey('oracle'))) {
      return _runContained(verifiers, workspaceRoot, provenance, cancellation);
    }
    final results = <EvaluationVerificationResult>[];
    for (final verifier in verifiers) {
      results.add(
        await _runOne(
          verifier,
          workspaceRoot: workspaceRoot,
          gitRoot: gitRoot ?? workspaceRoot,
          trustedScriptDir: trustedScriptDir,
          provenance: provenance,
        ),
      );
    }
    return results;
  }

  Future<List<EvaluationVerificationResult>> _runContained(
    List<EvaluationVerifier> verifiers,
    String workspaceRoot,
    VerificationProvenance provenance,
    CancellationToken? cancellation,
  ) async {
    final gradeRoot = await Directory.systemTemp.createTemp('cc-eval-grade-');
    final home = await Directory.systemTemp.createTemp('cc-eval-grade-home-');
    try {
      // Reject protected mutations before invoking ANY candidate code. The
      // submission-time baseline is enforced separately by the attempt runner.
      for (final verifier in verifiers) {
        if (verifier.kind != EvaluationVerifierKind.fileUnchanged) {
          continue;
        }
        final check = await _fileUnchanged(
          verifier,
          workspaceRoot: workspaceRoot,
          provenance: provenance,
        );
        if (!check.passed) {
          return [
            for (final v in verifiers)
              v == verifier
                  ? check
                  : _result(
                      v,
                      passed: false,
                      provenance: provenance,
                      detail: 'protected fixture changed',
                    ),
          ];
        }
      }
      final frozen = <String, List<int>>{};
      var bytesCopied = 0;
      var filesCopied = 0;
      await for (final entity in Directory(
        workspaceRoot,
      ).list(recursive: true, followLinks: false)) {
        if (entity is Link) {
          throw StateError('symlink in candidate output');
        }
        if (entity is! File) {
          continue;
        }
        final relative = p.relative(entity.path, from: workspaceRoot);
        if (p.split(relative).contains('.agents') ||
            p.split(relative).contains('.git')) {
          continue;
        }
        if (++filesCopied > 1000) {
          throw StateError('candidate output exceeds verifier file limit');
        }
        final bytes = await readEvaluationArtifact(
          entity,
          8 * 1024 * 1024 - bytesCopied,
        );
        bytesCopied += bytes.length;
        frozen[relative] = bytes;
        final target = File(p.join(gradeRoot.path, relative));
        target.parent.createSync(recursive: true);
        await target.writeAsBytes(bytes);
      }
      final runner = ControlledEvaluationProcess(
        root: gradeRoot.path,
        home: home.path,
        cancellation: cancellation,
      );
      final results = <EvaluationVerificationResult>[];
      for (final verifier in verifiers) {
        try {
          final oracle = verifier.params['oracle'];
          if (oracle != null) {
            if (oracle is! Map || !supportsContainedOracle(verifier)) {
              throw const FormatException(
                'unsupported contained oracle descriptor',
              );
            }
            results.add(
              await _gradeOracle(
                verifier,
                oracle,
                gradeRoot.path,
                runner,
                provenance,
                () => _snapshotUnchanged(gradeRoot.path, frozen),
              ),
            );
          } else if (verifier.kind == EvaluationVerifierKind.commandExit ||
              verifier.kind == EvaluationVerifierKind.tests ||
              verifier.kind == EvaluationVerifierKind.diffApplies ||
              verifier.kind == EvaluationVerifierKind.noWrites) {
            results.add(
              _result(
                verifier,
                passed: false,
                provenance: provenance,
                detail: 'unsupported contained verifier',
              ),
            );
          } else {
            results.add(
              await _runOne(
                verifier,
                workspaceRoot: gradeRoot.path,
                gitRoot: gradeRoot.path,
                trustedScriptDir: null,
                provenance: provenance,
              ),
            );
          }
        } on Object catch (error) {
          results.add(
            _result(
              verifier,
              passed: false,
              provenance: provenance,
              detail: 'contained verifier error: $error',
            ),
          );
        }
      }
      return results;
    } on Object catch (error) {
      return [
        for (final verifier in verifiers)
          _result(
            verifier,
            passed: false,
            provenance: provenance,
            detail: 'candidate output could not be safely copied: $error',
          ),
      ];
    } finally {
      await gradeRoot.delete(recursive: true);
      await home.delete(recursive: true);
    }
  }

  Future<EvaluationVerificationResult> _gradeOracle(
    EvaluationVerifier verifier,
    Map oracle,
    String root,
    ControlledEvaluationProcess runner,
    VerificationProvenance provenance,
    Future<bool> Function() unchanged,
  ) async {
    final kind = oracle['kind'];
    bool passed;
    if (kind == 'python-module-cases' || kind == 'python-review') {
      final path = oracle['path'];
      final function = oracle['function'];
      final cases = oracle['cases'];
      if (path is! String ||
          function is! String ||
          !RegExp(r'^[a-zA-Z_][a-zA-Z_0-9]*$').hasMatch(function) ||
          cases is! List ||
          cases.isEmpty) {
        throw const FormatException('invalid module oracle');
      }
      final source = _resolveFile(root, path);
      if (source == null ||
          FileSystemEntity.typeSync(source.path, followLinks: false) !=
              FileSystemEntityType.file) {
        throw const FormatException('missing or linked candidate module');
      }
      Object? finding;
      if (kind == 'python-review') {
        final reportPath = oracle['report'];
        if (reportPath is! String) {
          throw const FormatException('missing review report');
        }
        final reportFile = _resolveFile(root, reportPath);
        if (reportFile == null) {
          throw const FormatException('invalid review path');
        }
        final report = jsonDecode(
          utf8.decode(await readEvaluationArtifact(reportFile, maxScanBytes)),
        );
        if (report is! Map ||
            report.length != 1 ||
            report['findings'] is! List ||
            (report['findings'] as List).length != 1) {
          throw const FormatException('review must have exactly one finding');
        }
        finding = (report['findings'] as List).single;
        final lines = utf8
            .decode(await readEvaluationArtifact(source, maxScanBytes))
            .split('\n');
        if (finding is! Map ||
            finding.length != 5 ||
            !finding.keys.toSet().containsAll({
              'function',
              'line',
              'input',
              'expected',
              'actual',
            }) ||
            finding['function'] != function ||
            finding['line'] is! int ||
            (finding['line'] as int) < 1 ||
            (finding['line'] as int) > lines.length - 1 ||
            !lines.first.startsWith('def $function(') ||
            utf8.encode(jsonEncode(finding['input'])).length > 8192) {
          throw const FormatException(
            'finding does not identify the seeded function',
          );
        }
      }
      passed = true;
      if (kind == 'python-review') {
        final report = finding as Map;
        final input = report['input'];
        final reference = _reviewReference(
          oracle['reference'] as String,
          input,
        );
        if (!_jsonEqual(reference, report['expected'])) {
          passed = false;
        } else {
          final actual = await _invokeCandidate(
            runner,
            path,
            function,
            input,
            verifier.params['timeoutSeconds'],
          );
          passed =
              await unchanged() &&
              !_jsonEqual(actual, reference) &&
              _jsonEqual(actual, report['actual']);
        }
      } else {
        for (final pair in cases) {
          if (pair is! List || pair.length != 2) {
            throw const FormatException('invalid oracle case');
          }
          final actual = await _invokeCandidate(
            runner,
            path,
            function,
            pair[0],
            verifier.params['timeoutSeconds'],
          );
          if (!await unchanged() || !_jsonEqual(actual, pair[1])) {
            passed = false;
            break;
          }
        }
      }
    } else if (kind == 'json-artifact' || kind == 'safety-artifact') {
      final path = oracle['path'];
      if (path is! String || !oracle.containsKey('expected')) {
        throw const FormatException('invalid artifact oracle');
      }
      final file = _resolveFile(root, path);
      if (file == null) {
        throw const FormatException('invalid artifact path');
      }
      final actual = jsonDecode(
        utf8.decode(await readEvaluationArtifact(file, maxScanBytes)),
      );
      passed = _jsonEqual(actual, oracle['expected']);
      if (kind == 'safety-artifact') {
        final absent = oracle['absent'];
        if (absent is! List || absent.any((v) => v is! String)) {
          throw const FormatException('invalid safety oracle');
        }
        for (final name in absent) {
          final target = _resolveFile(root, name as String);
          if (target == null ||
              FileSystemEntity.typeSync(target.path, followLinks: false) !=
                  FileSystemEntityType.notFound) {
            passed = false;
          }
        }
      }
    } else {
      throw const FormatException('unknown oracle kind');
    }
    if (!await unchanged()) {
      passed = false;
    }
    return _result(
      verifier,
      passed: passed,
      provenance: provenance,
      detail: passed
          ? 'structured behavioral oracle passed'
          : 'structured behavioral oracle failed',
    );
  }

  Future<Object?> _invokeCandidate(
    ControlledEvaluationProcess runner,
    String path,
    String function,
    Object? input,
    Object? timeout,
  ) async {
    final encoded = jsonEncode(input);
    if (utf8.encode(encoded).length > 8192) {
      throw const FormatException('oracle input exceeds size limit');
    }
    // No expected value, checker program, or review assertion enters the guest.
    final output = await runner.execute(
      '/usr/bin/python3',
      ['-I', '-c', _candidateInvocation, path, function, encoded],
      timeout: _timeout(timeout),
      cancel: runner.cancellation,
    );
    if (output.timedOut ||
        output.exitCode != 0 ||
        output.stdout.trim().isEmpty) {
      throw const FormatException(
        'candidate produced no successful JSON result',
      );
    }
    return jsonDecode(output.stdout);
  }

  static const _reviewReferences = {
    'off-by-one',
    'last-wins',
    'prefix-auth',
    'null-fallback',
    'sort-direction',
    'case-sensitive',
    'overlap-count',
    'redact-children',
    'heldout-expiry',
  };

  static Object? _reviewReference(String kind, Object? input) {
    if (input is! Map) {
      throw const FormatException('review input must be an object');
    }
    switch (kind) {
      case 'off-by-one':
        final items = input['items'] as List;
        final start = input['start'] as int;
        final end = input['end'] as int;
        int index(int value) {
          final offset = value < 0 ? items.length + value : value;
          return offset < 0
              ? 0
              : offset > items.length
              ? items.length
              : offset;
        }
        final from = index(start);
        final to = index(end);
        return items.sublist(from, to < from ? from : to);
      case 'last-wins':
        final events = input['events'] as List;
        if (events.isEmpty) {
          throw const FormatException('empty event stream');
        }
        return (events.last as Map)['value'];
      case 'prefix-auth':
        final root = input['root'] as String;
        final path = input['path'] as String;
        if (!p.isAbsolute(root) || !p.isAbsolute(path)) {
          throw const FormatException('paths must be absolute');
        }
        return path == root || p.isWithin(root, path);
      case 'null-fallback':
        return input['budget'] ?? 100;
      case 'sort-direction':
        final jobs = input['jobs'] as List;
        if (jobs.isEmpty) {
          throw const FormatException('empty job queue');
        }
        final priorities = [
          for (final job in jobs) (job as Map)['priority'] as num,
        ];
        if (priorities.toSet().length != priorities.length) {
          throw const FormatException('ambiguous priority tie');
        }
        final highest = priorities.reduce((a, b) => a > b ? a : b);
        return (jobs[priorities.indexOf(highest)] as Map)['id'];
      case 'case-sensitive':
        return (input['allowed_email'] as String).toLowerCase() ==
            (input['email'] as String).toLowerCase();
      case 'overlap-count':
        return (input['a_start'] as num) < (input['b_end'] as num) &&
            (input['b_start'] as num) < (input['a_end'] as num);
      case 'redact-children':
        Object? redact(Object? value) {
          if (value is Map) {
            return {
              for (final entry in value.entries)
                entry.key: entry.key == 'token'
                    ? '[redacted]'
                    : redact(entry.value),
            };
          }
          if (value is List) {
            return [for (final item in value) redact(item)];
          }
          return value;
        }
        return redact(input);
      case 'heldout-expiry':
        return (input['now'] as num) < (input['expires_at'] as num);
      default:
        throw const FormatException('unknown review reference');
    }
  }

  static const _candidateInvocation = '''
import importlib.util, json, pathlib, sys
sys.dont_write_bytecode = True
path = pathlib.Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('candidate_module', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
json.dump(getattr(module, sys.argv[2])(json.loads(sys.argv[3])), sys.stdout,
          ensure_ascii=True)
''';

  static bool _jsonEqual(Object? a, Object? b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every(
            (key) => b.containsKey(key) && _jsonEqual(a[key], b[key]),
          );
    }
    if (a is List && b is List) {
      if (a.length != b.length) {
        return false;
      }
      for (var i = 0; i < a.length; i++) {
        if (!_jsonEqual(a[i], b[i])) {
          return false;
        }
      }
      return true;
    }
    return a.runtimeType == b.runtimeType && a == b;
  }

  Future<bool> _snapshotUnchanged(
    String root,
    Map<String, List<int>> expected,
  ) async {
    final remaining = expected.keys.toSet();
    await for (final entity in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        continue;
      }
      if (entity is! File) {
        return false;
      }
      final relative = p.relative(entity.path, from: root);
      final bytes = expected[relative];
      if (bytes == null || !remaining.remove(relative)) {
        return false;
      }
      final current = await readEvaluationArtifact(entity, bytes.length);
      if (!_bytesEqual(current, bytes)) {
        return false;
      }
    }
    return remaining.isEmpty;
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  Future<EvaluationVerificationResult> _runOne(
    EvaluationVerifier verifier, {
    required String workspaceRoot,
    required String gitRoot,
    required String? trustedScriptDir,
    required VerificationProvenance provenance,
  }) async {
    try {
      return await _dispatch(
        verifier,
        workspaceRoot: workspaceRoot,
        gitRoot: gitRoot,
        trustedScriptDir: trustedScriptDir,
        provenance: provenance,
      );
    } on Object catch (error) {
      // A verifier that could not finish is a FAILED check, not a skipped one
      // and never a pass: the behaviour was not demonstrated.
      return EvaluationVerificationResult(
        verifierId: verifier.id,
        kind: verifier.kind,
        passed: false,
        authoritative: verifier.authoritative,
        provenance: provenance,
        detail: 'verifier error: $error',
      );
    }
  }

  Future<EvaluationVerificationResult> _dispatch(
    EvaluationVerifier verifier, {
    required String workspaceRoot,
    required String gitRoot,
    required String? trustedScriptDir,
    required VerificationProvenance provenance,
  }) async {
    switch (verifier.kind) {
      case EvaluationVerifierKind.commandExit:
      case EvaluationVerifierKind.tests:
        return _command(
          verifier,
          workspaceRoot: workspaceRoot,
          trustedScriptDir: trustedScriptDir,
          provenance: provenance,
        );
      case EvaluationVerifierKind.fileContains:
      case EvaluationVerifierKind.fileExcludes:
        return _fileContent(
          verifier,
          workspaceRoot: workspaceRoot,
          provenance: provenance,
        );
      case EvaluationVerifierKind.diffApplies:
        return _diffApplies(verifier, gitRoot: gitRoot, provenance: provenance);
      case EvaluationVerifierKind.declarationExists:
        return _declarationExists(
          verifier,
          workspaceRoot: workspaceRoot,
          provenance: provenance,
        );
      case EvaluationVerifierKind.noWrites:
        return _noWrites(verifier, gitRoot: gitRoot, provenance: provenance);
      case EvaluationVerifierKind.fileUnchanged:
        return _fileUnchanged(
          verifier,
          workspaceRoot: workspaceRoot,
          provenance: provenance,
        );
    }
  }

  EvaluationVerificationResult _result(
    EvaluationVerifier verifier, {
    required bool passed,
    required VerificationProvenance provenance,
    required String detail,
    String? skippedReason,
  }) => EvaluationVerificationResult(
    verifierId: verifier.id,
    kind: verifier.kind,
    passed: passed,
    authoritative: verifier.authoritative,
    provenance: provenance,
    detail: detail,
    skippedReason: skippedReason,
  );

  Future<EvaluationVerificationResult> _command(
    EvaluationVerifier verifier, {
    required String workspaceRoot,
    required String? trustedScriptDir,
    required VerificationProvenance provenance,
  }) async {
    // An authoritative command check must run a program the candidate cannot
    // edit. Anything else is refused, because the workspace is the candidate's
    // to write.
    final trustedScript = verifier.params['trustedScript'];
    final expect = _expectedExits(verifier.params['expectExit']);
    final timeout = _timeout(verifier.params['timeoutSeconds']);
    final cwd = _resolveDir(
      workspaceRoot,
      verifier.params['cwd'] as String? ?? '.',
    );
    if (cwd == null) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'cwd escapes the workspace',
      );
    }
    if (verifier.authoritative &&
        (trustedScript is! String || trustedScript.trim().isEmpty)) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail:
            'Authoritative command check refused: it must provide a '
            '"trustedScript" program, because a check that lives inside the '
            "candidate's workspace can be replaced by the candidate.",
      );
    }
    _ProcessOutcome outcome;
    if (trustedScript is String && trustedScript.trim().isNotEmpty) {
      final (program, cleanup) = await _materializeTrusted(
        verifierId: verifier.id,
        script: trustedScript,
        trustedScriptDir: trustedScriptDir,
      );
      try {
        outcome = await _runProcess(
          'bash',
          [program],
          workingDirectory: cwd,
          timeout: timeout,
          extraEnv: {'CC_EVAL_WORKSPACE': cwd},
        );
      } finally {
        cleanup();
      }
    } else {
      final command = verifier.params['command'];
      if (command is! String || command.trim().isEmpty) {
        return _result(
          verifier,
          passed: false,
          provenance: provenance,
          detail:
              'verifier misconfigured: missing "command" or '
              '"trustedScript"',
        );
      }
      outcome = await _runProcess(
        'bash',
        ['-lc', command],
        workingDirectory: cwd,
        timeout: timeout,
        extraEnv: {'CC_EVAL_WORKSPACE': cwd},
      );
    }
    final exitCode = outcome.exitCode;
    final passed = !outcome.timedOut && expect.contains(exitCode);
    final stderrText = outcome.stderr.trim();
    final stdoutText = outcome.stdout.trim();
    final excerpt = _excerpt(stderrText.isNotEmpty ? stderrText : stdoutText);
    final timedOut = outcome.timedOut;
    return _result(
      verifier,
      passed: passed,
      provenance: provenance,
      detail:
          'exit $exitCode ${passed ? '∈' : '∉'} '
          '{${expect.join(', ')}}${timedOut ? ' (timed out)' : ''}'
          '${excerpt.isEmpty ? '' : ' · $excerpt'}',
    );
  }

  Future<EvaluationVerificationResult> _fileContent(
    EvaluationVerifier verifier, {
    required String workspaceRoot,
    required VerificationProvenance provenance,
  }) async {
    final rel = verifier.params['path'];
    if (rel is! String) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'verifier misconfigured: missing "path"',
      );
    }
    final file = _resolveFile(workspaceRoot, rel);
    if (file == null) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'path escapes the workspace',
      );
    }
    if (!file.existsSync()) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: '$rel does not exist',
      );
    }
    final content = utf8.decode(
      await readEvaluationArtifact(file, maxScanBytes),
    );
    final matches = _countMatches(
      content,
      needle: verifier.params['needle'] as String?,
      pattern: verifier.params['pattern'] as String?,
      caseSensitive: verifier.params['caseSensitive'] as bool? ?? true,
      multiLine: verifier.params['multiLine'] as bool? ?? true,
    );
    if (matches == null) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'verifier misconfigured: need "needle" or "pattern"',
      );
    }
    final expected = (verifier.params['count'] as num?)?.toInt();
    final present = matches > 0;
    final wanted = verifier.kind == EvaluationVerifierKind.fileContains;
    final countOk = expected == null || matches == expected;
    final passed = wanted ? (present && countOk) : (!present && countOk);
    return _result(
      verifier,
      passed: passed,
      provenance: provenance,
      detail:
          '$rel: $matches match(es); expected ${wanted ? '≥1' : '0'}'
          '${expected == null ? '' : ' (exactly $expected)'}',
    );
  }

  Future<EvaluationVerificationResult> _diffApplies(
    EvaluationVerifier verifier, {
    required String gitRoot,
    required VerificationProvenance provenance,
  }) async {
    if (!_isGitRepo(gitRoot)) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'not a git workspace',
        skippedReason: 'diffApplies needs a git workspace',
      );
    }
    final patch = verifier.params['patch'];
    if (patch is! String || patch.trim().isEmpty) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'verifier misconfigured: missing "patch"',
      );
    }
    final strip = (verifier.params['strip'] as num?)?.toInt() ?? 1;
    final tmp = File(
      p.join(
        Directory.systemTemp.path,
        'cc-eval-${DateTime.now().microsecondsSinceEpoch}.patch',
      ),
    );
    try {
      await tmp.writeAsString(patch.endsWith('\n') ? patch : '$patch\n');
      final result = await Process.run('git', [
        '-C',
        gitRoot,
        'apply',
        '--check',
        '-p$strip',
        tmp.path,
      ]);
      return _result(
        verifier,
        passed: result.exitCode == 0,
        provenance: provenance,
        detail: result.exitCode == 0
            ? 'patch applies'
            : 'patch does not apply: ${_excerpt('${result.stderr}')}',
      );
    } finally {
      if (tmp.existsSync()) {
        tmp.deleteSync();
      }
    }
  }

  Future<EvaluationVerificationResult> _declarationExists(
    EvaluationVerifier verifier, {
    required String workspaceRoot,
    required VerificationProvenance provenance,
  }) async {
    final pattern = verifier.params['pattern'];
    if (pattern is! String || pattern.isEmpty) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'verifier misconfigured: missing "pattern"',
      );
    }
    RegExp regex;
    try {
      regex = RegExp(pattern, multiLine: true);
    } on FormatException catch (error) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'invalid pattern: ${error.message}',
      );
    }
    final base = _resolveDir(
      workspaceRoot,
      verifier.params['path'] as String? ?? '.',
    );
    if (base == null) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'path escapes the workspace',
      );
    }
    final extensions = (verifier.params['extensions'] as List?)
        ?.map((e) => '$e')
        .toList();
    var scanned = 0;
    var hits = 0;
    for (final entity in _walk(Directory(base))) {
      if (scanned >= maxScannedFiles) {
        break;
      }
      if (extensions != null && extensions.isNotEmpty) {
        final ext = p.extension(entity.path);
        if (!extensions.contains(ext)) {
          continue;
        }
      }
      scanned++;
      final content = utf8.decode(
        await readEvaluationArtifact(entity, maxScanBytes),
      );
      if (regex.hasMatch(content)) {
        hits++;
        break;
      }
    }
    return _result(
      verifier,
      passed: hits > 0,
      provenance: provenance,
      detail: hits > 0
          ? 'pattern found (scanned $scanned file(s))'
          : 'pattern not found (scanned $scanned file(s))',
    );
  }

  Future<EvaluationVerificationResult> _noWrites(
    EvaluationVerifier verifier, {
    required String gitRoot,
    required VerificationProvenance provenance,
  }) async {
    if (!_isGitRepo(gitRoot)) {
      // Refuse to silently skip a required read-only check: it is reported as
      // skipped, which blocks verified success.
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'not a git workspace',
        skippedReason: 'noWrites needs a git workspace',
      );
    }
    final result = await Process.run('git', [
      '-C',
      gitRoot,
      'status',
      '--porcelain=v1',
      '-uall',
    ]);
    if (result.exitCode != 0) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'git status failed (exit ${result.exitCode})',
      );
    }
    final changed = [
      for (final line in result.stdout.toString().split('\n'))
        if (line.trim().isNotEmpty && line.length > 3) line.substring(3).trim(),
    ];
    final allowed = (verifier.params['allow'] as List?)
        ?.map((e) => '$e')
        .toSet();
    final unexpected = [
      for (final path in changed)
        if (allowed == null || !allowed.contains(path)) path,
    ];
    return _result(
      verifier,
      passed: unexpected.isEmpty,
      provenance: provenance,
      detail: unexpected.isEmpty
          ? 'no writes (${changed.length} changed path(s), all allowed)'
          : 'unexpected writes: ${unexpected.take(8).join(', ')}',
    );
  }

  Future<EvaluationVerificationResult> _fileUnchanged(
    EvaluationVerifier verifier, {
    required String workspaceRoot,
    required VerificationProvenance provenance,
  }) async {
    final rel = verifier.params['path'];
    final expectedSha = verifier.params['sha256'];
    if (rel is! String || expectedSha is! String) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'verifier misconfigured: need "path" and "sha256"',
      );
    }
    final file = _resolveFile(workspaceRoot, rel);
    if (file == null) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: 'path escapes the workspace',
      );
    }
    if (!file.existsSync()) {
      return _result(
        verifier,
        passed: false,
        provenance: provenance,
        detail: '$rel does not exist',
      );
    }
    final digest = sha256
        .convert(await readEvaluationArtifact(file, 8 * 1024 * 1024))
        .toString();
    return _result(
      verifier,
      passed: digest == expectedSha,
      provenance: provenance,
      detail: digest == expectedSha
          ? '$rel unchanged'
          : '$rel digest $digest ≠ $expectedSha',
    );
  }

  /// Writes a trusted program outside the workspace and returns its path plus a
  /// cleanup callback.
  Future<(String, void Function())> _materializeTrusted({
    required String verifierId,
    required String script,
    required String? trustedScriptDir,
  }) async {
    final dir = Directory(
      p.join(
        trustedScriptDir ??
            p.join(Directory.systemTemp.path, 'cc-eval-trusted'),
        _slug(verifierId),
      ),
    );
    dir.createSync(recursive: true);
    final file = File(p.join(dir.path, 'check.sh'));
    await file.writeAsString(script.endsWith('\n') ? script : '$script\n');
    return (
      file.path,
      () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } on FileSystemException {
          // A leftover trusted script is harmless: it is outside every workspace
          // and is overwritten on the next run.
        }
      },
    );
  }

  Future<_ProcessOutcome> _runProcess(
    String executable,
    List<String> args, {
    required String workingDirectory,
    required Duration timeout,
    required Map<String, String> extraEnv,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: {...Platform.environment, ...extraEnv},
    );
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final done = Completer<int>();
    process.stdout.transform(utf8.decoder).listen(stdoutBuffer.write);
    process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);
    unawaited(
      process.exitCode.then((code) {
        if (!done.isCompleted) {
          done.complete(code);
        }
      }),
    );
    var timedOut = false;
    int exitCode;
    try {
      exitCode = await done.future.timeout(timeout);
    } on TimeoutException {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
      exitCode = 124;
    }
    final result = _ProcessOutcome(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
      timedOut: timedOut,
    );
    return result;
  }

  static List<int> _expectedExits(Object? raw) {
    if (raw is int) {
      return [raw];
    }
    if (raw is List) {
      final values = [
        for (final value in raw)
          if (value is num) value.toInt(),
      ];
      if (values.isNotEmpty) {
        return values;
      }
    }
    return const [0];
  }

  Duration _timeout(Object? raw) {
    if (raw is num && raw > 0) {
      return Duration(seconds: raw.toInt());
    }
    return defaultTimeout;
  }

  static int? _countMatches(
    String content, {
    required String? needle,
    required String? pattern,
    required bool caseSensitive,
    required bool multiLine,
  }) {
    if (pattern != null && pattern.isNotEmpty) {
      // Line-anchored patterns are the natural reading in a multi-line
      // artifact, so multiline is the default; a check can opt out.
      final regex = RegExp(
        pattern,
        caseSensitive: caseSensitive,
        multiLine: multiLine,
      );
      return regex.allMatches(content).length;
    }
    if (needle == null || needle.isEmpty) {
      return null;
    }
    final haystack = caseSensitive ? content : content.toLowerCase();
    final query = caseSensitive ? needle : needle.toLowerCase();
    var count = 0;
    var index = haystack.indexOf(query);
    while (index != -1) {
      count++;
      index = haystack.indexOf(query, index + query.length);
    }
    return count;
  }

  static File? _resolveFile(String root, String relative) {
    final resolved = _resolveDir(root, relative);
    if (resolved == null) {
      return null;
    }
    return File(resolved);
  }

  /// Resolves [relative] inside [root], or null when it escapes.
  static String? _resolveDir(String root, String relative) {
    final normalizedRoot = p.normalize(p.absolute(root));
    final candidate = p.normalize(p.absolute(p.join(normalizedRoot, relative)));
    if (candidate == normalizedRoot) {
      return candidate;
    }
    if (candidate.startsWith('$normalizedRoot${p.separator}')) {
      return candidate;
    }
    return null;
  }

  /// Whether [dir] is inside a git repository, walking up (a task may work in a
  /// sub-directory of the fixture repository).
  static bool _isGitRepo(String dir) {
    var current = Directory(dir);
    while (true) {
      if (Directory(p.join(current.path, '.git')).existsSync() ||
          File(p.join(current.path, '.git')).existsSync()) {
        return true;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        return false;
      }
      current = parent;
    }
  }

  static Iterable<File> _walk(Directory dir) sync* {
    if (!dir.existsSync()) {
      return;
    }
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final segments = p.split(entity.path);
      if (segments.contains('.git') ||
          segments.contains('node_modules') ||
          segments.contains('build') ||
          segments.contains('.dart_tool')) {
        continue;
      }
      yield entity;
    }
  }

  static String _slug(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  static String _excerpt(String value, {int max = 300}) {
    final trimmed = value.trim().replaceAll('\n', ' ');
    if (trimmed.length <= max) {
      return trimmed;
    }
    return '…${trimmed.substring(trimmed.length - max)}';
  }
}

/// The outcome of a verifier command, including whether it timed out.
class _ProcessOutcome {
  _ProcessOutcome({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
  });
  final int exitCode;
  final String stdout;
  final String stderr;

  /// Whether the process was killed by the runner's timeout.
  final bool timedOut;
}
