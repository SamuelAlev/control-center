import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to the connected host's SKILLS REGISTRY subsystem
/// (PRD 23 §1 — "browse & install skills from the skills.sh registry").
///
/// The registry client, the scanner and the install pipeline all live in the
/// HOST (the spawned `cc_server` that BOTH the desktop and the web client
/// connect to). This control drives the `skills.registry*` RPC ops, so the
/// browse-and-install UI is identical on desktop and web and never touches the
/// server-side registry code. The file carries no `dart:io`, so it is safe in
/// the shared web compilation graph.
///
/// SECURITY NOTE: the registry is UNTRUSTED. A listing's author, install count,
/// and "verified publisher" flag are display-only provenance evidence — they are
/// NEVER a safety guarantee. The real safety signal is the scan `verdict`
/// returned by `preview`/`install`; the UI surfaces it prominently.

/// One registry search hit (display-only provenance — never a safety guarantee).
class RegistryListing {
  /// Creates a [RegistryListing].
  const RegistryListing({
    required this.slug,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.installCount,
    required this.verifiedPublisher,
  });

  /// Parses from the `skills.registrySearch` wire shape.
  factory RegistryListing.fromJson(Map<String, dynamic> json) =>
      RegistryListing(
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? (json['slug'] as String? ?? ''),
        description: json['description'] as String? ?? '',
        author: json['author'] as String? ?? '',
        version: json['version'] as String? ?? '',
        installCount: (json['install_count'] as num?)?.toInt() ?? 0,
        verifiedPublisher: json['verified_publisher'] as bool? ?? false,
      );

  /// Stable registry slug (the install key).
  final String slug;

  /// Human-readable display name.
  final String name;

  /// Short description.
  final String description;

  /// Publishing author/handle (display-only evidence, not a trust signal).
  final String author;

  /// Latest published version.
  final String version;

  /// Registry-reported install count (display-only evidence, not a trust
  /// signal).
  final int installCount;

  /// Whether the registry marks the publisher as "verified" (provenance
  /// metadata only — NEVER a substitute for the scan verdict).
  final bool verifiedPublisher;
}

/// The scan preview of a registry skill (PRD 23 §2/§3) — the real safety signal.
class RegistryPreview {
  /// Creates a [RegistryPreview].
  const RegistryPreview({
    required this.verdict,
    required this.llmReviewed,
    required this.capabilities,
    required this.requiredActionClasses,
    required this.findings,
  });

  /// Parses from the `skills.registryPreview` wire shape.
  factory RegistryPreview.fromJson(Map<String, dynamic> json) =>
      RegistryPreview(
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
      );

  /// The aggregate scan verdict (pass / warn / quarantine). A `quarantine`
  /// blocks install unless the operator explicitly overrides.
  final SkillScanVerdict verdict;

  /// Whether the Layer 3 LLM review ran as part of this scan.
  final bool llmReviewed;

  /// What the skill asks an agent to do (human-readable capability labels).
  final List<String> capabilities;

  /// The PRD 24 ActionClass wire names the capabilities map to (technical).
  final List<String> requiredActionClasses;

  /// Every finding the scanner recorded, in report order.
  final List<SkillScanFinding> findings;
}

/// The outcome of a `skills.registryInstall` call.
class RegistryInstallResult {
  /// Creates a [RegistryInstallResult].
  const RegistryInstallResult({
    required this.slug,
    required this.source,
    required this.computedHash,
    required this.trustTier,
    required this.scanVerdict,
    required this.status,
  });

  /// Parses from the `skills.registryInstall` wire shape.
  factory RegistryInstallResult.fromJson(Map<String, dynamic> json) =>
      RegistryInstallResult(
        slug: json['slug'] as String? ?? '',
        source: json['source'] as String? ?? '',
        computedHash: json['computed_hash'] as String? ?? '',
        trustTier: SkillTrustTier.fromWire(json['trust_tier'] as String?),
        scanVerdict: SkillScanVerdict.fromWire(
          json['scan_verdict'] as String? ?? '',
        ),
        status: json['status'] as String? ?? '',
      );

  /// The installed skill slug.
  final String slug;

  /// Where the bundle was fetched from.
  final String source;

  /// The content hash the server computed for the fetched bundle.
  final String computedHash;

  /// The provenance trust tier recorded for the install.
  final SkillTrustTier trustTier;

  /// The verdict the bundle scanned to at install time.
  final SkillScanVerdict scanVerdict;

  /// The install status the server reports.
  final String status;
}

/// RPC-backed control over the host's skills-registry subsystem: search,
/// scan-preview and install over the `skills.registry*` ops. Lib-only (no
/// cc_data repository) — mirrors `mcpClientControl`.
class RpcSkillRegistryControl {
  /// Creates a control over the given client.
  RpcSkillRegistryControl(this._client);

  final RemoteRpcClient _client;

  /// Searches the registry. Read, NOT workspace-scoped — but the client injects
  /// `workspace_id` harmlessly; the server op ignores it.
  Future<List<RegistryListing>> search(String query, {int? limit}) async {
    final data = await _client.call('skills.registrySearch', {
      'query': query,
      'limit': ?limit,
    });
    final list = (data['results'] as List?) ?? const [];
    return [
      for (final e in list)
        if (e is Map) RegistryListing.fromJson(e.cast<String, dynamic>()),
    ];
  }

  /// Scans a registry skill and returns its verdict, capabilities and findings.
  /// Workspace-scoped — `workspace_id` is auto-injected by [RemoteRpcClient].
  Future<RegistryPreview> preview(String slug, {String? version}) async {
    final data = await _client.call('skills.registryPreview', {
      'slug': slug,
      'version': ?version,
    });
    return RegistryPreview.fromJson(data);
  }

  /// Installs a registry skill. Workspace-scoped. A `quarantine` verdict is only
  /// installed when [allowQuarantineOverride] is set (recorded server-side).
  Future<RegistryInstallResult> install(
    String slug, {
    String? version,
    bool allowQuarantineOverride = false,
  }) async {
    final data = await _client.call('skills.registryInstall', {
      'slug': slug,
      'version': ?version,
      if (allowQuarantineOverride) 'allow_quarantine_override': true,
    });
    return RegistryInstallResult.fromJson(data);
  }
}

/// The control the browse panel drives — RPC-backed, talking to the connected
/// host.
final skillRegistryControlProvider = Provider<RpcSkillRegistryControl>(
  (ref) => RpcSkillRegistryControl(ref.watch(rpcClientProvider)),
);

/// Registry search results for the given query. Resolves to an empty list when the host
/// exposes no skills-registry control (`skills.registry*` absent → `opUnknown`)
/// — the panel then reads that as "the registry is not available on this
/// server". An empty result for a real query reads the same way (no matches).
final skillRegistrySearchProvider =
    FutureProvider.family<List<RegistryListing>, String>((ref, query) async {
      try {
        return await ref.watch(skillRegistryControlProvider).search(query);
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return const [];
        }
        rethrow;
      }
    });
