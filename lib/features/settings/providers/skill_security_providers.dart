import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_analysis_port.dart'
    show SkillAnalysisSkillResult;
import 'package:cc_domain/features/skills/domain/scanner/installed_skill_status.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to the host's SKILLS ANTIVIRUS over already-installed
/// skills (PRD 23 §2/§6): the installed list with lock provenance + verdicts,
/// on-demand re-scans and the gated local-save path the settings editor uses.
///
/// All heavy lifting (scanning, lock writes, quarantine detach) lives in the
/// HOST; this control only drives the `skills.*` RPC ops, so desktop and web
/// behave identically. No `dart:io` — safe in the web compilation graph.
///
/// SECURITY NOTE: the verdict is the only safety signal. Lock provenance
/// (origin/trust tier) is display evidence, never a scan substitute.

/// One installed skill with its security posture, parsed from the
/// `skills.installedList` wire shape.
class InstalledSkillDto {
  /// Creates an [InstalledSkillDto].
  const InstalledSkillDto({
    required this.slug,
    required this.lockState,
    required this.computedHash,
    this.content,
    this.origin,
    this.source,
    this.trustTier,
    this.scanVerdict,
    this.scanFindings = const [],
    this.scanLlmReviewed = false,
    this.scanRulesStale = false,
  });

  /// Parses from the `skills.installedList` element wire shape.
  factory InstalledSkillDto.fromJson(Map<String, dynamic> json) {
    final scan = json['scan'];
    final scanMap = scan is Map ? scan.cast<String, dynamic>() : null;
    return InstalledSkillDto(
      slug: json['slug'] as String? ?? '',
      lockState: InstalledSkillLockState.fromWire(
        json['lock_state'] as String? ?? '',
      ),
      computedHash: json['computed_hash'] as String? ?? '',
      content: json['content'] as String?,
      origin: json['origin'] == null
          ? null
          : SkillOrigin.fromWire(json['origin'] as String),
      source: json['source'] as String?,
      trustTier: json['trust_tier'] == null
          ? null
          : SkillTrustTier.fromWire(json['trust_tier'] as String?),
      scanVerdict: scanMap == null
          ? null
          : SkillScanVerdict.fromWire(scanMap['verdict'] as String? ?? ''),
      scanFindings: [
        if (scanMap != null)
          for (final f in (scanMap['findings'] as List?) ?? const [])
            if (f is Map) SkillScanFinding.fromJson(f.cast<String, dynamic>()),
      ],
      scanLlmReviewed: scanMap?['llm_reviewed'] as bool? ?? false,
      scanRulesStale: scanMap?['rules_stale'] as bool? ?? false,
    );
  }

  /// The skill slug (directory basename).
  final String slug;

  /// How the skill relates to the lock (managed / unmanaged / drifted).
  final InstalledSkillLockState lockState;

  /// The content hash of the current on-disk bytes.
  final String computedHash;

  /// Raw `SKILL.md` content (null when the host sent none).
  final String? content;

  /// Lock-recorded origin (null when unmanaged).
  final SkillOrigin? origin;

  /// Lock-recorded source descriptor (null when unmanaged).
  final String? source;

  /// Lock-recorded provenance trust tier (null when unmanaged).
  final SkillTrustTier? trustTier;

  /// The freshest cached scan verdict for the CURRENT bytes (null when these
  /// exact bytes were never scanned).
  final SkillScanVerdict? scanVerdict;

  /// The findings of that cached scan.
  final List<SkillScanFinding> scanFindings;

  /// Whether the Layer 3 LLM review ran for that scan.
  final bool scanLlmReviewed;

  /// Whether the cached scan predates the current scanner rules version.
  final bool scanRulesStale;
}

/// A full scan report (PRD 23 §3 payload), parsed from the
/// `skills.scanInstalled` / `skills.registryPreview` wire shape.
class SkillScanReport {
  /// Creates a [SkillScanReport].
  const SkillScanReport({
    required this.verdict,
    required this.llmReviewed,
    required this.capabilities,
    required this.requiredActionClasses,
    required this.findings,
    this.detachedAgents = const [],
    this.runId,
  });

  /// Parses from the scan-payload wire shape.
  factory SkillScanReport.fromJson(Map<String, dynamic> json) =>
      SkillScanReport(
        verdict: SkillScanVerdict.fromWire(json['verdict'] as String? ?? ''),
        llmReviewed: json['llm_reviewed'] as bool? ?? false,
        capabilities: [
          for (final c in (json['capabilities'] as List?) ?? const [])
            if (c is String) c,
        ],
        requiredActionClasses: [
          for (final c
              in (json['required_action_classes'] as List?) ?? const [])
            if (c is String) c,
        ],
        findings: [
          for (final f in (json['findings'] as List?) ?? const [])
            if (f is Map) SkillScanFinding.fromJson(f.cast<String, dynamic>()),
        ],
        detachedAgents: [
          for (final a in (json['detached_agents'] as List?) ?? const [])
            if (a is String) a,
        ],
        runId: json['run_id'] as String?,
      );

  /// The aggregate scan verdict (pass / warn / quarantine).
  final SkillScanVerdict verdict;

  /// Whether the Layer 3 LLM review ran as part of this scan.
  final bool llmReviewed;

  /// What the skill asks an agent to do (human-readable capability labels).
  final List<String> capabilities;

  /// The PRD 24 ActionClass wire names the capabilities map to.
  final List<String> requiredActionClasses;

  /// Every finding the scanner recorded, in report order.
  final List<SkillScanFinding> findings;

  /// Agents the skill was just detached from (present only when the scan
  /// returned `quarantine` and enforcement ran).
  final List<String> detachedAgents;

  /// The pipeline run that recorded this scan, when the `skill_analysis`
  /// template is enabled on the server (null otherwise).
  final String? runId;
}

/// The summary of a `skills.analyze` batch scan (scan-all), parsed from the
/// `SkillAnalysisOutcome` wire shape plus the optional recording run id.
class SkillAnalyzeSummary {
  /// Creates a [SkillAnalyzeSummary].
  const SkillAnalyzeSummary({
    required this.passCount,
    required this.warnCount,
    required this.quarantineCount,
    required this.results,
    this.detachedAgents = const [],
    this.runId,
  });

  /// Parses from the `skills.analyze` wire shape.
  factory SkillAnalyzeSummary.fromJson(Map<String, dynamic> json) =>
      SkillAnalyzeSummary(
        passCount: (json['pass'] as num?)?.toInt() ?? 0,
        warnCount: (json['warn'] as num?)?.toInt() ?? 0,
        quarantineCount: (json['quarantine'] as num?)?.toInt() ?? 0,
        results: [
          for (final r in (json['scanned'] as List?) ?? const [])
            if (r is Map)
              SkillAnalysisSkillResult.fromJson(r.cast<String, dynamic>()),
        ],
        detachedAgents: [
          for (final a in (json['detached_agents'] as List?) ?? const [])
            if (a is String) a,
        ],
        runId: json['run_id'] as String?,
      );

  /// How many skills scanned clean.
  final int passCount;

  /// How many scanned with warnings.
  final int warnCount;

  /// How many were quarantined (and therefore detached from their agents).
  final int quarantineCount;

  /// One entry per skill the pass attempted (errors carry `error`).
  final List<SkillAnalysisSkillResult> results;

  /// Agents detached during the pass.
  final List<String> detachedAgents;

  /// The pipeline run that recorded the pass, when one was written.
  final String? runId;
}

/// The outcome of a `skills.saveLocal` call: either saved (through the scan
/// gate) or blocked with the findings that caused it.
class SkillSaveResult {
  /// Creates a [SkillSaveResult].
  const SkillSaveResult({
    required this.status,
    required this.slug,
    this.verdict,
    this.findings = const [],
    this.reason,
  });

  /// Parses from the `skills.saveLocal` wire shape.
  factory SkillSaveResult.fromJson(Map<String, dynamic> json) =>
      SkillSaveResult(
        status: json['status'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        verdict: json['verdict'] == null
            ? null
            : SkillScanVerdict.fromWire(json['verdict'] as String),
        findings: [
          for (final f in (json['findings'] as List?) ?? const [])
            if (f is Map) SkillScanFinding.fromJson(f.cast<String, dynamic>()),
        ],
        reason: json['reason'] as String?,
      );

  /// `saved` or `blocked`.
  final String status;

  /// The skill slug.
  final String slug;

  /// The blocking verdict (null when the scanner errored before a verdict).
  final SkillScanVerdict? verdict;

  /// The findings that blocked the save (empty when saved).
  final List<SkillScanFinding> findings;

  /// Why the gate blocked when no verdict was produced (scanner failure).
  final String? reason;

  /// Whether the save was blocked by the scan gate (nothing was written).
  bool get blocked => status == 'blocked';
}

/// RPC-backed control over the host's installed-skills antivirus surface:
/// status list, on-demand scan and the gated local save. Lib-only (no
/// cc_data repository) — mirrors `RpcSkillRegistryControl`.
class RpcSkillSecurityControl {
  /// Creates a control over the given client.
  RpcSkillSecurityControl(this._client);

  final RemoteRpcClient _client;

  /// Lists every installed skill with lock provenance + the freshest cached
  /// verdict for its current bytes. Workspace-scoped — `workspace_id` is
  /// auto-injected by [RemoteRpcClient].
  Future<List<InstalledSkillDto>> listInstalled(String workspaceId) async {
    final data = await _client.call('skills.installedList', const {});
    final list = (data['skills'] as List?) ?? const [];
    return [
      for (final e in list)
        if (e is Map) InstalledSkillDto.fromJson(e.cast<String, dynamic>()),
    ];
  }

  /// Re-scans an installed skill's current on-disk bytes and returns the full
  /// report (a `quarantine` also detaches the skill from its agents
  /// server-side; the affected agents ride back as `detachedAgents`).
  Future<SkillScanReport> scanInstalled(
    String workspaceId,
    String slug, {
    bool? llmReview,
  }) async {
    final data = await _client.call('skills.scanInstalled', {
      'skill_slug': slug,
      'llm_review': ?llmReview,
    });
    return SkillScanReport.fromJson(data);
  }

  /// Scans many installed skills in one server-side pass (empty [slugs] =
  /// every installed skill), recorded as a `skill_analysis` pipeline run when
  /// the template is enabled on the server (the summary then carries `runId`).
  Future<SkillAnalyzeSummary> analyze(
    String workspaceId, {
    List<String>? slugs,
    bool? llmReview,
  }) async {
    final data = await _client.call('skills.analyze', {
      'slugs': ?slugs,
      'llm_review': ?llmReview,
    });
    return SkillAnalyzeSummary.fromJson(data);
  }

  /// Saves a locally authored/edited skill through the antivirus gate
  /// (scan → policy → write → pin). A blocked result writes NOTHING and
  /// carries the findings; retry with [allowQuarantineOverride] after the
  /// operator ticks the explicit override.
  Future<SkillSaveResult> saveLocal(
    String workspaceId,
    String slug,
    String content, {
    bool allowQuarantineOverride = false,
  }) async {
    final data = await _client.call('skills.saveLocal', {
      'skill_slug': slug,
      'content': content,
      if (allowQuarantineOverride) 'allow_quarantine_override': true,
    });
    return SkillSaveResult.fromJson(data);
  }
}

/// The control the settings UI drives — RPC-backed, talking to the connected
/// host.
final skillSecurityControlProvider = Provider<RpcSkillSecurityControl>(
  (ref) => RpcSkillSecurityControl(ref.watch(rpcClientProvider)),
);
