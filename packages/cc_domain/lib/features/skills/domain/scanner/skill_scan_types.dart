import 'dart:convert';

/// The aggregate verdict of a skill scan (PRD 23 §2). Ordered by severity so a
/// verdict can only ever *tighten*: an LLM `pass` can never override a static
/// `quarantine`.
enum SkillScanVerdict {
  /// Installable.
  pass('pass', 0),

  /// Installable; findings shown at approval.
  warn('warn', 1),

  /// Blocked; findings stored; explicit operator override possible (recorded).
  quarantine('quarantine', 2);

  const SkillScanVerdict(this.wire, this.severity);

  /// Stable wire/storage string.
  final String wire;

  /// Higher = more severe (used for tighten-only combination).
  final int severity;

  /// Parses from wire, defaulting to [quarantine] (fail-closed on unknown).
  static SkillScanVerdict fromWire(String value) =>
      SkillScanVerdict.values.firstWhere(
        (v) => v.wire == value,
        orElse: () => SkillScanVerdict.quarantine,
      );

  /// Whether installation is permitted for this verdict (quarantine blocks).
  bool get installable => this != SkillScanVerdict.quarantine;

  /// The more severe of two verdicts (tighten-only).
  static SkillScanVerdict tighten(SkillScanVerdict a, SkillScanVerdict b) =>
      a.severity >= b.severity ? a : b;
}

/// Provenance trust tier of a skill (PRD 23 §5).
enum SkillTrustTier {
  /// Shipped with CC.
  firstParty('firstParty'),

  /// Authored in-workspace.
  workspace('workspace'),

  /// From a registry-verified publisher (provenance metadata, never a scan
  /// substitute).
  verified('verified'),

  /// Everything else.
  community('community');

  const SkillTrustTier(this.wire);

  /// Stable wire/storage string.
  final String wire;

  /// Parses from wire, defaulting to [community] (the least-trusted).
  static SkillTrustTier fromWire(String? value) =>
      SkillTrustTier.values.firstWhere(
        (t) => t.wire == value,
        orElse: () => SkillTrustTier.community,
      );
}

/// One finding from the scanner (PRD 23 §3). Carries the exact pattern, file,
/// and line so the operator sees precisely what was flagged.
class SkillScanFinding {
  /// Creates a [SkillScanFinding].
  const SkillScanFinding({
    required this.ruleId,
    required this.verdict,
    required this.message,
    required this.file,
    this.line = 0,
    this.snippet = '',
  });

  /// Parses from JSON.
  factory SkillScanFinding.fromJson(Map<String, dynamic> json) =>
      SkillScanFinding(
        ruleId: json['ruleId'] as String? ?? '',
        verdict: SkillScanVerdict.fromWire(
          json['verdict'] as String? ?? 'warn',
        ),
        message: json['message'] as String? ?? '',
        file: json['file'] as String? ?? '',
        line: (json['line'] as num?)?.toInt() ?? 0,
        snippet: json['snippet'] as String? ?? '',
      );

  /// The rule that fired (e.g. `curl_pipe_bash`).
  final String ruleId;

  /// The severity this finding contributes (warn / quarantine).
  final SkillScanVerdict verdict;

  /// Human-readable description of the risk.
  final String message;

  /// Bundle-relative file the finding is in.
  final String file;

  /// 1-based line number (0 when not line-specific).
  final int line;

  /// The offending snippet (redacted/short).
  final String snippet;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'ruleId': ruleId,
    'verdict': verdict.wire,
    'message': message,
    'file': file,
    'line': line,
    'snippet': snippet,
  };
}

/// What a skill *asks an agent to do* (PRD 23 §2 Layer 2) — rendered at approval
/// like an app store's permission list, and checked against the PRD 24 action
/// policy at install time.
class SkillCapabilityManifest {
  /// Creates a [SkillCapabilityManifest].
  const SkillCapabilityManifest({
    this.needsBash = false,
    this.writesFiles = false,
    this.deletesFiles = false,
    this.networkEgress = false,
    this.readsSecrets = false,
    this.installsPackages = false,
  });

  /// Parses from JSON.
  factory SkillCapabilityManifest.fromJson(Map<String, dynamic> json) =>
      SkillCapabilityManifest(
        needsBash: json['needsBash'] as bool? ?? false,
        writesFiles: json['writesFiles'] as bool? ?? false,
        deletesFiles: json['deletesFiles'] as bool? ?? false,
        networkEgress: json['networkEgress'] as bool? ?? false,
        readsSecrets: json['readsSecrets'] as bool? ?? false,
        installsPackages: json['installsPackages'] as bool? ?? false,
      );

  /// The union of two manifests (aggregate across bundle files).
  SkillCapabilityManifest merge(SkillCapabilityManifest other) =>
      SkillCapabilityManifest(
        needsBash: needsBash || other.needsBash,
        writesFiles: writesFiles || other.writesFiles,
        deletesFiles: deletesFiles || other.deletesFiles,
        networkEgress: networkEgress || other.networkEgress,
        readsSecrets: readsSecrets || other.readsSecrets,
        installsPackages: installsPackages || other.installsPackages,
      );

  /// Wants to run shell commands.
  final bool needsBash;

  /// Wants to write files.
  final bool writesFiles;

  /// Wants to delete files.
  final bool deletesFiles;

  /// Wants network egress.
  final bool networkEgress;

  /// Reads secrets/credentials.
  final bool readsSecrets;

  /// Installs packages.
  final bool installsPackages;

  /// The ActionClass wire names this skill's capabilities map to (feeds the
  /// PRD 24 install-time policy check). Kept as wire strings so this stays in
  /// the skills subdomain without importing guardrails.
  List<String> get requiredActionClassWires => [
    if (needsBash) 'processSpawn',
    if (writesFiles) 'fileWriteOutsideWorktree',
    if (deletesFiles) 'fileDelete',
    if (networkEgress) 'networkEgress',
    if (readsSecrets) 'secretAccess',
    if (installsPackages) 'packageInstall',
  ];

  /// A short human list for the approval dialog ("wants: Bash, network").
  List<String> get labels => [
    if (needsBash) 'Bash',
    if (installsPackages) 'package installs',
    if (writesFiles) 'file writes',
    if (deletesFiles) 'file deletes',
    if (networkEgress) 'network egress',
    if (readsSecrets) 'secret access',
  ];

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'needsBash': needsBash,
    'writesFiles': writesFiles,
    'deletesFiles': deletesFiles,
    'networkEgress': networkEgress,
    'readsSecrets': readsSecrets,
    'installsPackages': installsPackages,
  };

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}

/// A fetched skill bundle: bundle-relative path → file text. The scanner
/// operates purely over this in-memory buffer (the TOCTOU-locked bytes).
class SkillBundle {
  /// Creates a [SkillBundle].
  const SkillBundle({required this.slug, required this.files});

  /// A single-file bundle (just SKILL.md).
  factory SkillBundle.single(String slug, String content) =>
      SkillBundle(slug: slug, files: {'SKILL.md': content});

  /// The skill slug.
  final String slug;

  /// Bundle-relative path → file content.
  final Map<String, String> files;
}

/// The complete result of a scan: verdict + findings + manifest (PRD 23 §3).
class SkillScanResult {
  /// Creates a [SkillScanResult].
  const SkillScanResult({
    required this.verdict,
    required this.findings,
    required this.manifest,
    required this.rulesVersion,
    this.llmReviewed = false,
  });

  /// The aggregate verdict.
  final SkillScanVerdict verdict;

  /// All findings across the bundle.
  final List<SkillScanFinding> findings;

  /// The union capability manifest.
  final SkillCapabilityManifest manifest;

  /// The static-rules version this result was produced under.
  final int rulesVersion;

  /// Whether the Layer 3 LLM review completed.
  final bool llmReviewed;

  /// Findings serialized to a JSON array string.
  String findingsJsonString() =>
      jsonEncode(findings.map((f) => f.toJson()).toList());

  /// A copy with a (tightened) verdict + LLM-review flag set.
  SkillScanResult tightenedTo(
    SkillScanVerdict newVerdict, {
    List<SkillScanFinding> extraFindings = const [],
    bool llmReviewed = true,
  }) => SkillScanResult(
    verdict: SkillScanVerdict.tighten(verdict, newVerdict),
    findings: [...findings, ...extraFindings],
    manifest: manifest,
    rulesVersion: rulesVersion,
    llmReviewed: llmReviewed,
  );
}
