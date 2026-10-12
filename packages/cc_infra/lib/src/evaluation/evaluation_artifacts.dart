import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_report_renderer.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:path/path.dart' as p;

/// A named set of corpus tasks plus the hash that pins them.
class EvaluationCorpus {
  /// Creates an [EvaluationCorpus].
  const EvaluationCorpus({required this.id, required this.tasks});

  /// Parses from JSON.
  factory EvaluationCorpus.fromJson(Map<String, dynamic> json) =>
      EvaluationCorpus(
        id: json['id'] as String? ?? 'corpus',
        tasks:
            (json['tasks'] as List?)
                ?.map(
                  (e) => EvaluationTask.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList() ??
            const [],
      );

  /// Parses from a JSON string.
  factory EvaluationCorpus.fromJsonString(String source) =>
      EvaluationCorpus.fromJson(
        (jsonDecode(source) as Map).cast<String, dynamic>(),
      );

  /// Reads a corpus from [path].
  static Future<EvaluationCorpus> read(String path) async =>
      EvaluationCorpus.fromJsonString(await File(path).readAsString());

  /// Corpus id.
  final String id;

  /// The tasks, in declared order.
  final List<EvaluationTask> tasks;

  /// The task with [id], or null.
  EvaluationTask? taskById(String id) {
    for (final task in tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  /// The tasks by id.
  Map<String, EvaluationTask> get byId => {for (final t in tasks) t.id: t};

  /// Whether every task id is unique.
  bool get idsAreUnique => byId.length == tasks.length;

  /// The `sha256:…` content hash of the corpus, so a manifest can pin it.
  String get corpusHash => 'sha256:${canonicalHash(canonicalDocument())}';

  /// The canonical document the hash covers.
  Map<String, dynamic> canonicalDocument() => {
    'id': id,
    'tasks': [for (final t in tasks) t.toJson()],
  };

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => canonicalDocument();
}

/// The on-disk layout of one evaluation run.
///
/// Everything needed to audit or replay a campaign lives under one directory:
/// the pinned manifest, the plan, the attempt stream (written as it happens, so
/// a crash still leaves auditable partial data), the per-attempt diffs, the
/// replayable recordings, and the report.
class EvaluationArtifacts {
  EvaluationArtifacts._(this.runDir);

  /// Creates (or reopens) the run directory under [baseDir].
  static Future<EvaluationArtifacts> create(
    String baseDir,
    String planId, {
    DateTime? now,
    String? suffix,
  }) async {
    final stamp = (now ?? DateTime.now())
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final slug = planId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final runDir = p.join(baseDir, '$slug-$stamp${suffix ?? ''}');
    await Directory(runDir).create(recursive: true);
    return EvaluationArtifacts._(runDir);
  }

  /// Reopens an existing run directory (for `report`/re-verification).
  static EvaluationArtifacts forExisting(String runDir) =>
      EvaluationArtifacts._(runDir);

  /// Absolute path of the run directory.
  final String runDir;

  /// Path of the JSONL attempt stream.
  String get attemptsPath => p.join(runDir, 'attempts.jsonl');

  /// Path of the JSON report.
  String get reportJsonPath => p.join(runDir, 'report.json');

  /// Path of the markdown report.
  String get reportMarkdownPath => p.join(runDir, 'report.md');

  /// Directory holding replay cassettes.
  String get recordingsDir => p.join(runDir, 'recordings');

  /// Directory holding per-attempt diffs.
  String get patchesDir => p.join(runDir, 'patches');

  /// Writes the pinned manifest.
  Future<void> writeManifest(EvaluationManifest manifest) =>
      File(p.join(runDir, 'manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      );

  /// Writes the campaign plan.
  Future<void> writePlan(EvaluationPlan plan) => File(
    p.join(runDir, 'plan.json'),
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(plan.toJson()));

  /// Writes the corpus as it was read.
  Future<void> writeCorpus(EvaluationCorpus corpus) => File(
    p.join(runDir, 'corpus.json'),
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(corpus.toJson()));

  /// Appends one attempt to the JSONL stream and flushes it.
  Future<void> appendAttempt(EvaluationAttempt attempt) async {
    final file = File(attemptsPath);
    final sink = file.openWrite(mode: FileMode.append);
    sink.writeln(jsonEncode(attempt.toJson()));
    await sink.flush();
    await sink.close();
  }

  /// Reads every attempt in the stream.
  Future<List<EvaluationAttempt>> readAttempts() async {
    final file = File(attemptsPath);
    if (!file.existsSync()) {
      return const [];
    }
    final attempts = <EvaluationAttempt>[];
    for (final line in await file.readAsLines()) {
      if (line.trim().isEmpty) {
        continue;
      }
      attempts.add(
        EvaluationAttempt.fromJson(
          (jsonDecode(line) as Map).cast<String, dynamic>(),
        ),
      );
    }
    return attempts;
  }

  /// Stores the workspace change for [attemptId] and returns its path (null
  /// when the diff was empty, so an unchanged attempt carries no patch).
  Future<String?> writePatch(String attemptId, String diff) async {
    if (diff.trim().isEmpty) {
      return null;
    }
    await Directory(patchesDir).create(recursive: true);
    final file = File(p.join(patchesDir, '$attemptId.diff'));
    await file.writeAsString(diff);
    return file.path;
  }

  /// Stores a replay cassette for [attemptId], so a later `replay` run can
  /// re-verify this attempt offline without any model call.
  Future<void> writeRecording({
    required String attemptId,
    required EvaluationAttempt attempt,
    required String diff,
  }) async {
    await Directory(recordingsDir).create(recursive: true);
    await File(
      p.join(recordingsDir, '$attemptId.json'),
    ).writeAsString(jsonEncode({'attempt': attempt.toJson(), 'diff': diff}));
  }

  /// Writes the machine-readable and human-readable reports.
  Future<void> writeReport(EvaluationReport report) async {
    await File(reportJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report.toJson()),
    );
    await File(
      reportMarkdownPath,
    ).writeAsString(const EvaluationReportRenderer().render(report));
  }
}
