import 'package:cc_domain/features/evals/domain/services/eval_graders.dart';

/// The task classes the representative corpus must cover (HARNESS_RESEARCH §6):
/// bug fixes, multi-file features, reviews, repository exploration, long
/// conversations, orchestration and tool-heavy runs.
enum EvaluationTaskKind {
  /// A localized defect fix with an observable before/after behaviour.
  bugfix('bugfix'),

  /// A feature that necessarily spans several files.
  multifileFeature('multifile_feature'),

  /// Reviewing a diff and reporting a seeded defect.
  review('review'),

  /// Repository exploration: find where something lives, without editing.
  exploration('exploration'),

  /// A long multi-turn conversation where earlier turns must stay usable.
  longContext('long_context'),

  /// Orchestration: turn a goal into a plan / delegate bounded subtasks.
  orchestration('orchestration'),

  /// A run dominated by tool calls (search + read + shell round trips).
  toolHeavy('tool_heavy');

  const EvaluationTaskKind(this.wire);

  /// Stable wire string used in corpus JSON and reports.
  final String wire;

  /// Parses a wire string, defaulting to [bugfix] for unknown values.
  static EvaluationTaskKind fromWire(String? raw) {
    for (final kind in values) {
      if (kind.wire == raw) {
        return kind;
      }
    }
    return EvaluationTaskKind.bugfix;
  }

  /// Sentence-case label for reports.
  String get label => switch (this) {
    EvaluationTaskKind.bugfix => 'Bug fix',
    EvaluationTaskKind.multifileFeature => 'Multi-file feature',
    EvaluationTaskKind.review => 'Review',
    EvaluationTaskKind.exploration => 'Exploration',
    EvaluationTaskKind.longContext => 'Long context',
    EvaluationTaskKind.orchestration => 'Orchestration',
    EvaluationTaskKind.toolHeavy => 'Tool-heavy',
  };
}

/// A single independent acceptance check that runs against the *workspace*,
/// never against the agent's own claim (HARNESS_RESEARCH §6: "Use behavioral
/// acceptance checks and human review where needed—not the agent's claim that
/// it finished").
///
/// Deterministic checks inspect bytes on disk or independently compare
/// structured results. Controlled campaigns accept only declarative oracles:
/// candidate code runs in an enclosure with inputs, while expected values and
/// assertions remain in the controller. Legacy local CLI command checks are
/// not an acceptable contained-campaign oracle.
enum EvaluationVerifierKind {
  /// Run `command` in the workspace; pass when its exit status is in
  /// `expectExit` (default `[0]`).
  commandExit('command_exit'),

  /// A test command must pass; kept distinct from [commandExit] only so the
  /// report can label the class of failure ("tests" vs "build").
  tests('tests'),

  /// The file at `path` must contain `needle` (optionally a `pattern` regex,
  /// optionally `count` occurrences).
  fileContains('file_contains'),

  /// The file at `path` must NOT contain `needle` (regression guard for a
  /// removed defect).
  fileExcludes('file_excludes'),

  /// `patch` must apply cleanly to the workspace (`git apply --check`). Proves
  /// the run left the tree in the expected shape without trusting its summary.
  diffApplies('diff_applies'),

  /// A declaration matching `pattern` must exist somewhere under `path`.
  declarationExists('declaration_exists'),

  /// No tracked file may have changed (read-only tasks: exploration, review
  /// with a no-edit instruction).
  noWrites('no_writes'),

  /// The file at `path` must be byte-identical to `sha256`.
  fileUnchanged('file_unchanged');

  const EvaluationVerifierKind(this.wire);

  /// Stable wire string used in corpus JSON and reports.
  final String wire;

  /// Parses a wire string, defaulting to [commandExit].
  static EvaluationVerifierKind fromWire(String? raw) {
    for (final kind in values) {
      if (kind.wire == raw) {
        return kind;
      }
    }
    return EvaluationVerifierKind.commandExit;
  }
}

/// A declarative, serializable acceptance check for one [EvaluationTask].
class EvaluationVerifier {
  /// Creates an [EvaluationVerifier].
  const EvaluationVerifier({
    required this.id,
    required this.kind,
    this.params = const {},
    this.description = '',
    this.authoritative = true,
  });

  /// Parses from JSON.
  factory EvaluationVerifier.fromJson(Map<String, dynamic> json) =>
      EvaluationVerifier(
        id: json['id'] as String? ?? (json['kind'] as String? ?? 'verifier'),
        kind: EvaluationVerifierKind.fromWire(json['kind'] as String?),
        params: (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
        description: json['description'] as String? ?? '',
        authoritative: json['authoritative'] as bool? ?? true,
      );

  /// Unique id within the task.
  final String id;

  /// Which check to run.
  final EvaluationVerifierKind kind;

  /// Type-specific parameters (see [EvaluationVerifierKind]).
  final Map<String, dynamic> params;

  /// Human-readable description for the report.
  final String description;

  /// Whether a pass here counts as *verified* success.
  ///
  /// Only behavioral checks (bytes on disk, process exit status) are
  /// authoritative. A verifier that is declaratively marked non-authoritative
  /// is recorded but can never, by itself, mark a trial successful.
  final bool authoritative;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.wire,
    if (params.isNotEmpty) 'params': params,
    if (description.isNotEmpty) 'description': description,
    if (!authoritative) 'authoritative': false,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationVerifier &&
          id == other.id &&
          kind == other.kind &&
          description == other.description &&
          authoritative == other.authoritative &&
          _mapEq(params, other.params);

  @override
  int get hashCode =>
      Object.hash(id, kind, description, authoritative, params.length);
}

/// One corpus entry: a real Control Center-shaped task with independently
/// checkable acceptance evidence and a pinned fixture (HARNESS_RESEARCH §6).
class EvaluationTask {
  /// Creates an [EvaluationTask].
  const EvaluationTask({
    required this.id,
    required this.kind,
    required this.prompt,
    this.title = '',
    this.followUps = const [],
    this.fixtureRef,
    this.fixtureSha,
    this.baseCommit,
    this.workspaceSubpath = '.',
    this.inlineFiles = const {},
    this.verifiers = const [],
    this.graders = const [],
    this.protectedFiles = const {},
    this.setupCommand,
    this.maxTurns,
    this.costCapCents,
    this.defaultRepetitions = 3,
    this.tags = const [],
    this.notes = '',
  });

  /// Parses from JSON.
  factory EvaluationTask.fromJson(Map<String, dynamic> json) => EvaluationTask(
    id: json['id'] as String? ?? '',
    kind: EvaluationTaskKind.fromWire(json['kind'] as String?),
    title: json['title'] as String? ?? '',
    prompt: json['prompt'] as String? ?? '',
    followUps:
        (json['followUps'] as List?)?.map((e) => '$e').toList() ?? const [],
    fixtureRef: json['fixtureRef'] as String?,
    fixtureSha: json['fixtureSha'] as String?,
    baseCommit: json['baseCommit'] as String?,
    workspaceSubpath: json['workspaceSubpath'] as String? ?? '.',
    inlineFiles:
        (json['inlineFiles'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{},
    verifiers:
        (json['verifiers'] as List?)
            ?.map(
              (e) => EvaluationVerifier.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList() ??
        const [],
    graders:
        (json['graders'] as List?)
            ?.map(
              (e) => GraderSpec.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    protectedFiles:
        (json['protectedFiles'] as Map?)?.cast<String, dynamic>().map(
          (key, value) => MapEntry(key, '$value'),
        ) ??
        const {},
    setupCommand: json['setupCommand'] as String?,
    maxTurns: (json['maxTurns'] as num?)?.toInt(),
    costCapCents: (json['costCapCents'] as num?)?.toInt(),
    defaultRepetitions: (json['defaultRepetitions'] as num?)?.toInt() ?? 3,
    tags: (json['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
    notes: json['notes'] as String? ?? '',
  );

  /// Stable task id (unique within a corpus).
  final String id;

  /// Which §6 task class this task represents.
  final EvaluationTaskKind kind;

  /// Short title for reports.
  final String title;

  /// The first user turn.
  final String prompt;

  /// Additional user turns, delivered as genuine follow-ups in the SAME
  /// conversation (long-context tasks). Empty for single-turn tasks.
  final List<String> followUps;

  /// Content-addressed fixture reference (e.g. a blob store key or a path
  /// relative to the corpus file) holding the pinned repository state.
  final String? fixtureRef;

  /// SHA-256 of the fixture payload, so corpus drift is detectable.
  final String? fixtureSha;

  /// The commit the fixture checkout must be at.
  final String? baseCommit;

  /// Sub-directory inside the fixture the agent works in (`.` for the root).
  final String workspaceSubpath;

  /// Small files seeded into the isolated workspace before the run, keyed by
  /// workspace-relative path. Lets a task define its own defect without a
  /// whole fixture repo.
  final Map<String, dynamic> inlineFiles;

  /// The independent acceptance checks (see [EvaluationVerifier]).
  final List<EvaluationVerifier> verifiers;

  /// Reuses the existing grader layer (`GraderSpec`) for scalar checks a
  /// runner can compute directly from the attempt (e.g. `max_turns`,
  /// `cost_budget`).
  final List<GraderSpec> graders;

  /// Fixture files the candidate MUST leave byte-identical, keyed by
  /// workspace-relative path and valued by their SHA-256.
  ///
  /// This is what keeps a behavioral fixture honest: without it a candidate can
  /// rewrite the very input a check reads. The runner appends one authoritative
  /// `file_unchanged` check per entry, so a mutation fails the trial.
  final Map<String, String> protectedFiles;

  /// A TRUSTED preparation command run by the runner in the workspace BEFORE
  /// the agent starts (fixture generation). Its output is discarded and it is
  /// never part of the candidate's surface; a non-zero exit faults the attempt.
  final String? setupCommand;

  /// Turn ceiling for this task, or null to use the loop default.
  final int? maxTurns;

  /// Cost ceiling in cents, or null for none.
  final int? costCapCents;

  /// How many paired repetitions the corpus recommends for this task.
  final int defaultRepetitions;

  /// Free-form tags (task-class facets, strata hints).
  final List<String> tags;

  /// Operator notes (why this task exists, what it guards).
  final String notes;

  /// Whether every acceptance check is behavioral (no judge, no model).
  ///
  /// Routing a task to a weaker/cheaper configuration is only defensible when
  /// its output is independently checkable (HARNESS_RESEARCH §6), so this is
  /// the predicate the routing policy consults.
  bool get independentlyCheckable =>
      verifiers.isNotEmpty && verifiers.every((v) => v.authoritative);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.wire,
    if (title.isNotEmpty) 'title': title,
    'prompt': prompt,
    if (followUps.isNotEmpty) 'followUps': followUps,
    if (fixtureRef != null) 'fixtureRef': fixtureRef,
    if (fixtureSha != null) 'fixtureSha': fixtureSha,
    if (baseCommit != null) 'baseCommit': baseCommit,
    if (workspaceSubpath != '.') 'workspaceSubpath': workspaceSubpath,
    if (inlineFiles.isNotEmpty) 'inlineFiles': inlineFiles,
    'verifiers': [for (final v in verifiers) v.toJson()],
    if (graders.isNotEmpty) 'graders': [for (final g in graders) g.toJson()],
    if (protectedFiles.isNotEmpty) 'protectedFiles': protectedFiles,
    if (setupCommand != null) 'setupCommand': setupCommand,
    if (maxTurns != null) 'maxTurns': maxTurns,
    if (costCapCents != null) 'costCapCents': costCapCents,
    'defaultRepetitions': defaultRepetitions,
    if (tags.isNotEmpty) 'tags': tags,
    if (notes.isNotEmpty) 'notes': notes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationTask &&
          id == other.id &&
          kind == other.kind &&
          title == other.title &&
          prompt == other.prompt &&
          fixtureRef == other.fixtureRef &&
          fixtureSha == other.fixtureSha &&
          baseCommit == other.baseCommit &&
          workspaceSubpath == other.workspaceSubpath &&
          maxTurns == other.maxTurns &&
          costCapCents == other.costCapCents &&
          defaultRepetitions == other.defaultRepetitions &&
          setupCommand == other.setupCommand &&
          notes == other.notes &&
          _listEq(followUps, other.followUps) &&
          _listEq(tags, other.tags) &&
          _listEq(verifiers, other.verifiers) &&
          _listEq(graders, other.graders) &&
          _mapEq(protectedFiles, other.protectedFiles) &&
          _mapEq(inlineFiles, other.inlineFiles);

  @override
  int get hashCode => Object.hashAll([
    id,
    kind,
    title,
    prompt,
    fixtureRef,
    fixtureSha,
    baseCommit,
    workspaceSubpath,
    maxTurns,
    costCapCents,
    defaultRepetitions,
    setupCommand,
    notes,
    Object.hashAll(followUps),
    Object.hashAll(tags),
    Object.hashAll(verifiers),
    Object.hashAll(graders),
    Object.hashAll(protectedFiles.entries.map((e) => '${e.key}=${e.value}')),
    Object.hashAll(inlineFiles.entries.map((e) => '${e.key}=${e.value}')),
  ]);

  /// Every acceptance check required for verified success: task checks plus
  /// one protected-file digest check per entry. Controlled attempts reject
  /// protected mutations before executing candidate code during grading.
  /// Their pre-execution snapshot must also be validated by the attempt runner.
  List<EvaluationVerifier> effectiveVerifiers() => [
    ...verifiers,
    for (final entry in protectedFiles.entries)
      EvaluationVerifier(
        id: 'protected_${entry.key}',
        kind: EvaluationVerifierKind.fileUnchanged,
        params: {'path': entry.key, 'sha256': entry.value},
        description:
            '${entry.key} is fixture evidence and must not be modified.',
      ),
  ];
}

bool _listEq(List<Object?> a, List<Object?> b) {
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

bool _mapEq(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final e in a.entries) {
    if (b[e.key] != e.value) {
      return false;
    }
  }
  return true;
}
