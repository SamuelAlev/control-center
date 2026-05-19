import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web-safe access to the host's SKILL SOURCES subsystem: GitHub repositories
/// the operator registers as skill catalogs (the skills.sh registry
/// replacement).
///
/// The source store, the GitHub catalog adapter, the scanner and the install
/// pipeline all live in the HOST (the spawned `cc_server` that BOTH the
/// desktop and the web client connect to). This control drives the
/// `skills.sources*` / `skills.source*` RPC ops, so the browse-and-install UI
/// is identical on desktop and web and never touches GitHub directly. The
/// file carries no `dart:io`, so it is safe in the shared web compilation
/// graph.
///
/// SECURITY NOTE: a source repository is UNTRUSTED. A listing's name,
/// description and star count are display-only provenance evidence — they are
/// NEVER a safety guarantee. The real safety signal is the scan `verdict`
/// returned by `detail`/`install`; the UI surfaces it prominently.

/// One registered GitHub skill-source repository.
class SkillSourceDto {
  /// Creates a [SkillSourceDto].
  const SkillSourceDto({
    required this.id,
    required this.owner,
    required this.repo,
    required this.url,
    this.description = '',
    this.defaultBranch = '',
    this.starCount = 0,
    this.skillCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  /// Parses from the `skills.sourcesList` wire shape.
  factory SkillSourceDto.fromJson(Map<String, dynamic> json) => SkillSourceDto(
    id: json['id'] as String? ?? '',
    owner: json['owner'] as String? ?? '',
    repo: json['repo'] as String? ?? '',
    url: json['url'] as String? ?? '',
    description: json['description'] as String? ?? '',
    defaultBranch: json['default_branch'] as String? ?? '',
    starCount: (json['star_count'] as num?)?.toInt() ?? 0,
    skillCount: (json['skill_count'] as num?)?.toInt() ?? 0,
    lastSyncedAt:
        json['last_synced_at'] == null
        ? null
        : DateTime.tryParse(json['last_synced_at'] as String),
    lastError: json['last_error'] as String?,
  );

  /// Row id (the RPC key for listings/detail/install).
  final String id;

  /// GitHub owner login.
  final String owner;

  /// Repository name.
  final String repo;

  /// Normalized repository URL.
  final String url;

  /// Repository description (untrusted).
  final String description;

  /// Default branch.
  final String defaultBranch;

  /// Star count (untrusted popularity signal).
  final int starCount;

  /// Skills discovered at the last sync.
  final int skillCount;

  /// Last successful catalog sync.
  final DateTime? lastSyncedAt;

  /// The last sync's error, if any.
  final String? lastError;

  /// `owner/repo`.
  String get fullName => '$owner/$repo';

  /// True when a full name is present.
  bool get isValid => id.isNotEmpty && owner.isNotEmpty && repo.isNotEmpty;
}

/// One skill in a source's catalog grid.
class SourceSkillDto {
  /// Creates a [SourceSkillDto].
  const SourceSkillDto({
    required this.slug,
    required this.name,
    required this.description,
    required this.path,
    required this.installed,
    required this.slugTaken,
    required this.updateAvailable,
  });

  /// Parses from the `skills.sourceListings` wire shape.
  factory SourceSkillDto.fromJson(Map<String, dynamic> json) => SourceSkillDto(
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    path: json['path'] as String? ?? '',
    installed: json['installed'] as bool? ?? false,
    slugTaken: json['slug_taken'] as bool? ?? false,
    updateAvailable: json['update_available'] as bool? ?? false,
  );

  /// Local install slug (the skill directory's basename).
  final String slug;

  /// Human-readable name (untrusted frontmatter metadata).
  final String name;

  /// Short description (untrusted).
  final String description;

  /// Repo-relative path to the skill's `SKILL.md` (the install key).
  final String path;

  /// Installed in this workspace from this exact source+path.
  final bool installed;

  /// The slug is taken by a skill installed from elsewhere.
  final bool slugTaken;

  /// A newer upstream version is available.
  final bool updateAvailable;
}

/// The scan preview of a source skill — the real safety signal.
class SourceSkillScan {
  /// Creates a [SourceSkillScan].
  const SourceSkillScan({
    required this.verdict,
    required this.llmReviewed,
    required this.capabilities,
    required this.requiredActionClasses,
    required this.findings,
  });

  /// Parses from the `skills.sourceSkillDetail` wire shape.
  factory SourceSkillScan.fromJson(Map<String, dynamic> json) =>
      SourceSkillScan(
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

/// The detail payload of one source skill: README + pinned ref + scan preview.
class SourceSkillDetailDto {
  /// Creates a [SourceSkillDetailDto].
  const SourceSkillDetailDto({
    required this.ref,
    required this.fileCount,
    required this.readme,
    required this.scan,
  });

  /// Parses from the `skills.sourceSkillDetail` wire shape.
  factory SourceSkillDetailDto.fromJson(Map<String, dynamic> json) =>
      SourceSkillDetailDto(
        ref: json['ref'] as String? ?? '',
        fileCount: (json['file_count'] as num?)?.toInt() ?? 0,
        readme: json['readme'] as String? ?? '',
        scan: SourceSkillScan.fromJson(
          (json['scan'] as Map).cast<String, dynamic>(),
        ),
      );

  /// The commit SHA the preview resolved to (the install pin).
  final String ref;

  /// How many files the skill bundle carries.
  final int fileCount;

  /// README markdown (the skill's `README.md`, else its `SKILL.md` body).
  final String readme;

  /// The scan preview over the exact bytes an install would write.
  final SourceSkillScan scan;
}

/// The outcome of an install/update call: `installed`/`updated` on success, or
/// `blocked` with the scan findings when the gate refused (nothing written).
class SkillInstallResultDto {
  /// Creates a [SkillInstallResultDto].
  const SkillInstallResultDto({
    required this.status,
    required this.slug,
    this.ref,
    this.computedHash,
    this.verdict,
    this.llmReviewed = false,
    this.findings = const [],
    this.reason,
  });

  /// Parses from the `skills.sourceInstall` / `skills.updateSkill` wire shape.
  factory SkillInstallResultDto.fromJson(Map<String, dynamic> json) =>
      SkillInstallResultDto(
        status: json['status'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        ref: json['ref'] as String?,
        computedHash: json['computed_hash'] as String?,
        verdict:
            (json['scan_verdict'] ?? json['verdict']) is String
                ? SkillScanVerdict.fromWire(
                    (json['scan_verdict'] ?? json['verdict']) as String,
                  )
                : null,
        llmReviewed: json['llm_reviewed'] as bool? ?? false,
        findings: [
          for (final f in (json['findings'] as List?) ?? const [])
            if (f is Map) SkillScanFinding.fromJson(f.cast<String, dynamic>()),
        ],
        reason: json['reason'] as String?,
      );

  /// `installed` / `updated` / `blocked` / `up_to_date`.
  final String status;

  /// The skill slug the call targeted.
  final String slug;

  /// The pinned commit SHA (success only).
  final String? ref;

  /// The computed content hash (success only).
  final String? computedHash;

  /// The verdict (present on both success and `blocked`).
  final SkillScanVerdict? verdict;

  /// Whether the Layer 3 LLM review ran.
  final bool llmReviewed;

  /// Findings (present on `blocked`).
  final List<SkillScanFinding> findings;

  /// Machine-readable block reason (`blocked` only).
  final String? reason;

  /// Whether the gate refused the operation.
  bool get blocked => status == 'blocked';
}

/// One available skill update (`skills.checkUpdates`).
class SkillUpdateInfoDto {
  /// Creates a [SkillUpdateInfoDto].
  const SkillUpdateInfoDto({
    required this.slug,
    required this.currentRef,
    required this.latestRef,
  });

  /// Parses from the `skills.checkUpdates` wire shape.
  factory SkillUpdateInfoDto.fromJson(Map<String, dynamic> json) =>
      SkillUpdateInfoDto(
        slug: json['slug'] as String? ?? '',
        currentRef: json['current_ref'] as String? ?? '',
        latestRef: json['latest_ref'] as String? ?? '',
      );

  /// The installed skill slug.
  final String slug;

  /// The pinned ref.
  final String currentRef;

  /// The latest upstream ref.
  final String latestRef;
}

/// RPC-backed control over the host's skill-sources subsystem: manage source
/// repositories, browse a source's catalog, preview + install skills, and
/// drive the installed skills' update/uninstall lifecycle. Lib-only (no
/// cc_data repository) — mirrors `skill_security_providers.dart`.
class RpcSkillSourceControl {
  /// Creates a control over the given client.
  RpcSkillSourceControl(this._client);

  final RemoteRpcClient _client;

  /// The workspace's registered sources. Resolves to an empty list when the
  /// host predates the sources surface (`opUnknown`) — the panel reads that
  /// as "no sources on this server".
  Future<List<SkillSourceDto>> listSources() async {
    try {
      final data = await _client.call('skills.sourcesList', const {});
      final list = (data['sources'] as List?) ?? const [];
      return [
        for (final e in list)
          if (e is Map) SkillSourceDto.fromJson(e.cast<String, dynamic>()),
      ];
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  /// Registers a GitHub repository URL as a skill source. Returns the stored
  /// source and whether it was already registered.
  Future<(SkillSourceDto, bool)> addSource(String url) async {
    final data = await _client.call('skills.sourcesAdd', {'url': url});
    return (
      SkillSourceDto.fromJson(
        (data['source'] as Map).cast<String, dynamic>(),
      ),
      data['already_exists'] == true,
    );
  }

  /// Removes a source (installed skills stay installed).
  Future<void> removeSource(String sourceId) async {
    await _client.call('skills.sourcesRemove', {'source_id': sourceId});
  }

  /// Lists a source's skill catalog, annotated with installed/update state.
  Future<List<SourceSkillDto>> listings(String sourceId) async {
    final data = await _client.call('skills.sourceListings', {
      'source_id': sourceId,
    });
    final list = (data['skills'] as List?) ?? const [];
    return [
      for (final e in list)
        if (e is Map) SourceSkillDto.fromJson(e.cast<String, dynamic>()),
    ];
  }

  /// Loads one skill's README + scan preview (no bytes are written).
  Future<SourceSkillDetailDto> detail(String sourceId, String path) async {
    final data = await _client.call('skills.sourceSkillDetail', {
      'source_id': sourceId,
      'path': path,
    });
    return SourceSkillDetailDto.fromJson(data);
  }

  /// Installs (or re-installs at the latest commit) a source skill.
  /// Workspace-scoped; a `quarantine` verdict installs only with an explicit
  /// [allowQuarantineOverride] (recorded server-side).
  Future<SkillInstallResultDto> install(
    String sourceId,
    String path, {
    bool allowQuarantineOverride = false,
  }) async {
    final data = await _client.call('skills.sourceInstall', {
      'source_id': sourceId,
      'path': path,
      if (allowQuarantineOverride) 'allow_quarantine_override': true,
    });
    return SkillInstallResultDto.fromJson(data);
  }

  /// Uninstalls a skill: deletes its directory and its lock pin.
  Future<void> uninstall(String slug) async {
    await _client.call('skills.uninstall', {'skill_slug': slug});
  }

  /// Checks every GitHub-pinned skill for an upstream update.
  Future<List<SkillUpdateInfoDto>> checkUpdates() async {
    try {
      final data = await _client.call('skills.checkUpdates', const {});
      final list = (data['updates'] as List?) ?? const [];
      return [
        for (final e in list)
          if (e is Map) SkillUpdateInfoDto.fromJson(e.cast<String, dynamic>()),
      ];
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  /// Updates one installed skill to its latest upstream commit through the
  /// full scan gate.
  Future<SkillInstallResultDto> updateSkill(
    String slug, {
    bool allowQuarantineOverride = false,
  }) async {
    final data = await _client.call('skills.updateSkill', {
      'skill_slug': slug,
      if (allowQuarantineOverride) 'allow_quarantine_override': true,
    });
    return SkillInstallResultDto.fromJson(data);
  }
}

/// The control the sources panel drives — RPC-backed, talking to the connected
/// host.
final skillSourceControlProvider = Provider<RpcSkillSourceControl>(
  (ref) => RpcSkillSourceControl(ref.watch(rpcClientProvider)),
);

/// The workspace's registered skill sources.
final skillSourcesProvider =
    FutureProvider.family<List<SkillSourceDto>, String>((ref, workspaceId) {
      return ref.watch(skillSourceControlProvider).listSources();
    });

/// A source's skill catalog, annotated with installed/update state.
final skillSourceListingsProvider =
    FutureProvider.family<List<SourceSkillDto>, String>((
      ref,
      sourceId,
    ) async {
      try {
        return await ref.watch(skillSourceControlProvider).listings(sourceId);
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return const [];
        }
        rethrow;
      }
    });

/// One source skill's README + scan preview.
final skillSourceDetailProvider =
    FutureProvider.family<SourceSkillDetailDto, ({String sourceId, String path})>((
      ref,
      key,
    ) {
      return ref
          .watch(skillSourceControlProvider)
          .detail(key.sourceId, key.path);
    });
