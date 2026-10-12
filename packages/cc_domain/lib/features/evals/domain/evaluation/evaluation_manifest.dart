import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';

/// The pinned reproducibility manifest for one evaluation campaign
/// (HARNESS_RESEARCH §6: "Pin repository state, model, effort, tool catalog,
/// instructions, and CLI version").
///
/// One manifest is shared by every arm of a paired comparison; an
/// `EvaluationArm` may *deliberately* deviate on exactly one axis, and the
/// report records which axis deviated. Because the manifest hash covers the
/// pinned fields, a run whose manifest drifts cannot be silently paired with
/// one whose did: pairing requires an identical [pairingKey].
///
/// The hash is computed with the same canonical-JSON + SHA-256 convention the
/// agent config hash uses ([canonicalHash]), so it is stable across platforms
/// and map ordering.
class EvaluationManifest {
  /// Creates an [EvaluationManifest].
  const EvaluationManifest({
    required this.corpusId,
    required this.corpusHash,
    required this.adapter,
    required this.providerId,
    required this.modelId,
    this.effortLevel,
    this.repoRef,
    this.baseCommit,
    this.repoWorktreeSha,
    this.cliVersion,
    this.cliPath,
    this.toolCatalog = const [],
    this.toolCatalogHash = '',
    this.instructionsHash = '',
    this.systemPromptHash = '',
    this.configHash = '',
    this.harnessVersion = '',
    this.runnerVersion = currentRunnerVersion,
    this.skillKey,
    this.skillHash,
    this.baselineSkillHash,
    this.ambientSkillHashes = const {},
    this.skillComparison,
    this.skillSnapshotMetadata = const {},
    this.temperature,
    this.cacheEnabled = true,
    this.toolDeferralEnabled = true,
    this.version = currentVersion,
    this.notes = '',
  });

  /// Parses from JSON.
  factory EvaluationManifest.fromJson(
    Map<String, dynamic> json,
  ) => EvaluationManifest(
    corpusId: json['corpusId'] as String? ?? '',
    corpusHash: json['corpusHash'] as String? ?? '',
    adapter: json['adapter'] as String? ?? 'builtin',
    providerId: json['providerId'] as String? ?? 'anthropic',
    modelId: json['modelId'] as String? ?? '',
    effortLevel: json['effortLevel'] as String?,
    repoRef: json['repoRef'] as String?,
    baseCommit: json['baseCommit'] as String?,
    repoWorktreeSha: json['repoWorktreeSha'] as String?,
    cliVersion: json['cliVersion'] as String?,
    cliPath: json['cliPath'] as String?,
    toolCatalog:
        (json['toolCatalog'] as List?)
            ?.map((e) => (e as List?)?.map((x) => '$x').toList() ?? const [])
            .toList() ??
        const [],
    toolCatalogHash: json['toolCatalogHash'] as String? ?? '',
    instructionsHash: json['instructionsHash'] as String? ?? '',
    systemPromptHash: json['systemPromptHash'] as String? ?? '',
    configHash: json['configHash'] as String? ?? '',
    harnessVersion: json['harnessVersion'] as String? ?? '',
    skillKey: json['skillKey'] as String?,
    skillHash: json['skillHash'] as String?,
    baselineSkillHash: json['baselineSkillHash'] as String?,
    ambientSkillHashes: {
      for (final entry
          in (json['ambientSkillHashes'] as Map? ?? const <String, String>{})
              .entries)
        '${entry.key}': '${entry.value}',
    },
    skillComparison: json['skillComparison'] as String?,
    skillSnapshotMetadata: {
      for (final entry
          in (json['skillSnapshotMetadata'] as Map? ?? const <String, String>{})
              .entries)
        '${entry.key}': '${entry.value}',
    },
    runnerVersion: json['runnerVersion'] as String? ?? currentRunnerVersion,
    temperature: (json['temperature'] as num?)?.toDouble(),
    cacheEnabled: json['cacheEnabled'] as bool? ?? true,
    toolDeferralEnabled: json['toolDeferralEnabled'] as bool? ?? true,
    version: (json['version'] as num?)?.toInt() ?? currentVersion,
    notes: json['notes'] as String? ?? '',
  );

  /// The manifest field-list version. Bump only when the pinned field set
  /// changes (which deliberately re-keys every manifest).
  static const int currentVersion = 3;

  /// The evaluator build identity recorded in every manifest.
  static const String currentRunnerVersion = 'cc-eval/1';

  /// Corpus identifier (e.g. `cc-representative-v1`).
  final String corpusId;

  /// SHA-256 of the corpus payload the campaign ran.
  final String corpusHash;

  /// Adapter under test (`builtin` for the in-process harness, `claude-cli`
  /// for the Claude Code CLI).
  final String adapter;

  /// Provider id (`anthropic`, `openai`, …).
  final String providerId;

  /// The pinned model id (provider-native, e.g. `claude-opus-4-8`).
  final String modelId;

  /// The pinned reasoning effort (`minimal`…`xhigh`), or null when the adapter
  /// has no effort knob (the quality default is whatever the adapter does).
  final String? effortLevel;

  /// Where the pinned repository state came from (a local checkout path or a
  /// fixture reference). Recorded for audit, not hashed: it is a location, not
  /// a state.
  final String? repoRef;

  /// The commit the fixture checkout is pinned to.
  final String? baseCommit;

  /// Content hash of the working tree beyond [baseCommit] (fixture patches,
  /// inline seeds). Two runs with different trees must not be paired.
  final String? repoWorktreeSha;

  /// The external CLI's version string, when the adapter shells out.
  final String? cliVersion;

  /// The external CLI's resolved path, when the adapter shells out.
  final String? cliPath;

  /// Pinned tool catalog as `[name, schemaHash]` pairs (sorted before hashing).
  final List<List<String>> toolCatalog;

  /// SHA-256 over the sorted [toolCatalog].
  final String toolCatalogHash;

  /// SHA-256 of the effective instructions (system prompt + AGENTS.md +
  /// memory policies) the run was given.
  final String instructionsHash;

  /// SHA-256 of the fully-assembled system prompt, when the adapter builds one.
  final String systemPromptHash;

  /// The agent config hash ([AgentConfigSnapshot.configHash]) the run
  /// corresponds to, when one exists.
  final String configHash;

  /// Harness build identity (package version or a pinned rev).
  final String harnessVersion;

  /// Exact package identity and fixed ambient inventory. Null for legacy runs.
  final String? skillKey;
  final String? skillHash;
  final String? baselineSkillHash;
  final Map<String, String> ambientSkillHashes;
  final String? skillComparison;

  /// Origin, source commit, and scan rules for every pinned revision.
  final Map<String, String> skillSnapshotMetadata;

  /// Evaluator build identity.
  final String runnerVersion;

  /// Sampling temperature, when the adapter exposes one.
  final double? temperature;

  /// Whether provider prompt caching was requested.
  final bool cacheEnabled;

  /// Whether native tool-schema deferral was on.
  final bool toolDeferralEnabled;

  /// The pinned field-list version.
  final int version;

  /// Operator notes.
  final String notes;

  /// The canonical document the [manifestHash] covers.
  Map<String, dynamic> canonicalDocument() => {
    'adapter': adapter,
    'baseCommit': baseCommit,
    'cacheEnabled': cacheEnabled,
    'cliPath': cliPath,
    'cliVersion': cliVersion,
    'configHash': configHash,
    'corpusHash': corpusHash,
    'corpusId': corpusId,
    'effortLevel': effortLevel,
    'harnessVersion': harnessVersion,
    'instructionsHash': instructionsHash,
    'modelId': modelId,
    'providerId': providerId,
    'repoWorktreeSha': repoWorktreeSha,
    'runnerVersion': runnerVersion,
    'systemPromptHash': systemPromptHash,
    if (skillKey != null) 'skillKey': skillKey,
    if (skillHash != null) 'skillHash': skillHash,
    if (baselineSkillHash != null) 'baselineSkillHash': baselineSkillHash,
    if (skillComparison != null) 'skillComparison': skillComparison,
    if (ambientSkillHashes.isNotEmpty) 'ambientSkillHashes': ambientSkillHashes,
    if (skillSnapshotMetadata.isNotEmpty)
      'skillSnapshotMetadata': skillSnapshotMetadata,
    'temperature': temperature,
    'toolCatalog': toolCatalog,
    'toolCatalogHash': toolCatalogHash,
    'toolDeferralEnabled': toolDeferralEnabled,
    'version': version,
  };

  /// The `sha256:…`-prefixed content hash of [canonicalDocument].
  ///
  /// Two runs may only be compared as a pair when this value is identical.
  String get manifestHash => 'sha256:${canonicalHash(canonicalDocument())}';

  /// Alias for [manifestHash] — the pairing invariant, named at the call site
  /// where it matters.
  String get pairingKey => manifestHash;

  /// Returns a copy with the given fields replaced.
  EvaluationManifest copyWith({
    String? corpusId,
    String? corpusHash,
    String? adapter,
    String? providerId,
    String? modelId,
    String? effortLevel,
    String? repoRef,
    String? baseCommit,
    String? repoWorktreeSha,
    String? cliVersion,
    String? cliPath,
    List<List<String>>? toolCatalog,
    String? toolCatalogHash,
    String? instructionsHash,
    String? systemPromptHash,
    String? configHash,
    String? harnessVersion,
    String? runnerVersion,
    String? skillKey,
    String? skillHash,
    String? baselineSkillHash,
    Map<String, String>? ambientSkillHashes,
    String? skillComparison,
    Map<String, String>? skillSnapshotMetadata,
    double? temperature,
    bool? cacheEnabled,
    bool? toolDeferralEnabled,
    String? notes,
  }) => EvaluationManifest(
    corpusId: corpusId ?? this.corpusId,
    corpusHash: corpusHash ?? this.corpusHash,
    adapter: adapter ?? this.adapter,
    providerId: providerId ?? this.providerId,
    modelId: modelId ?? this.modelId,
    effortLevel: effortLevel ?? this.effortLevel,
    repoRef: repoRef ?? this.repoRef,
    baseCommit: baseCommit ?? this.baseCommit,
    repoWorktreeSha: repoWorktreeSha ?? this.repoWorktreeSha,
    cliVersion: cliVersion ?? this.cliVersion,
    cliPath: cliPath ?? this.cliPath,
    toolCatalog: toolCatalog ?? this.toolCatalog,
    toolCatalogHash: toolCatalogHash ?? this.toolCatalogHash,
    instructionsHash: instructionsHash ?? this.instructionsHash,
    systemPromptHash: systemPromptHash ?? this.systemPromptHash,
    skillKey: skillKey ?? this.skillKey,
    skillHash: skillHash ?? this.skillHash,
    baselineSkillHash: baselineSkillHash ?? this.baselineSkillHash,
    ambientSkillHashes: ambientSkillHashes ?? this.ambientSkillHashes,
    skillComparison: skillComparison ?? this.skillComparison,
    skillSnapshotMetadata: skillSnapshotMetadata ?? this.skillSnapshotMetadata,
    configHash: configHash ?? this.configHash,
    harnessVersion: harnessVersion ?? this.harnessVersion,
    runnerVersion: runnerVersion ?? this.runnerVersion,
    temperature: temperature ?? this.temperature,
    cacheEnabled: cacheEnabled ?? this.cacheEnabled,
    toolDeferralEnabled: toolDeferralEnabled ?? this.toolDeferralEnabled,
    notes: notes ?? this.notes,
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    ...canonicalDocument(),
    if (repoRef != null) 'repoRef': repoRef,
    if (notes.isNotEmpty) 'notes': notes,
    'manifestHash': manifestHash,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationManifest &&
          manifestHash == other.manifestHash &&
          repoRef == other.repoRef &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(manifestHash, repoRef, notes);
}
