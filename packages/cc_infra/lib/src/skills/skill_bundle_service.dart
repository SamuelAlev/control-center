import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/exceptions/skill_scan_blocked_exception.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_registry_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/repositories/skill_scan_repository.dart';
import 'package:cc_domain/features/skills/domain/scanner/installed_skill_status.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_capability_extractor.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_static_rules.dart';
import 'package:cc_harness/tools.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Fetches a file's raw contents from GitHub at a pinned [ref]. Injected so the
/// service is testable without a live `dio`/GitHub client.
typedef GitHubFileFetcher =
    Future<String> Function({
      required String owner,
      required String repo,
      required String path,
      required String ref,
    });

/// Resolves the latest commit SHA touching a path on a branch (null branch =
/// default branch). Injected for the update-check; null disables it.
typedef GitHubLatestCommitResolver =
    Future<String?> Function({
      required String owner,
      required String repo,
      required String path,
      String? branch,
    });

/// Resolves a repo's default branch. Injected for the update-check.
typedef GitHubDefaultBranchResolver =
    Future<String?> Function({required String owner, required String repo});

/// Content-addresses, pins and installs workspace skill bundles, persisting a
/// `skills-lock.json` next to the workspace's skills.
///
/// Hashing is a rolled-up SHA256: every file in the skill directory is hashed,
/// the per-file hashes are combined in sorted path order and that digest is
/// the skill's content address. A GitHub install is pinned to a commit SHA so
/// the recorded hash is reproducible.
class SkillBundleService implements SkillBundlePort {
  /// Creates a [SkillBundleService].
  ///
  /// [scanner] is the mandatory install-gate (PRD 23 §2). It is OPTIONAL only so
  /// pre-scanner callers/tests still compile — when null the gate is a no-op and
  /// behavior is unchanged. The server ALWAYS wires it; a wired scanner is
  /// fail-closed (a quarantine verdict or a scanner error aborts before write).
  SkillBundleService({
    required WorkspaceFilesystemPort filesystem,
    required GitHubFileFetcher fetchGitHubFile,
    SkillScanPort? scanner,
    SkillScanRepository? scanCache,
    ActionGuardService? actionGuard,
    GitHubLatestCommitResolver? latestCommit,
    GitHubDefaultBranchResolver? defaultBranch,
    SkillRegistryPort? registry,
    DomainEventBus? eventBus,
  }) : _fs = filesystem,
       _fetch = fetchGitHubFile,
       _scanner = scanner,
       _scanCache = scanCache,
       _actionGuard = actionGuard,
       _latestCommit = latestCommit,
       _defaultBranch = defaultBranch,
       _registry = registry,
       _eventBus = eventBus;

  final WorkspaceFilesystemPort _fs;
  final GitHubFileFetcher _fetch;
  final SkillScanPort? _scanner;
  final GitHubLatestCommitResolver? _latestCommit;
  final GitHubDefaultBranchResolver? _defaultBranch;
  final SkillRegistryPort? _registry;

  /// Publishes [SkillUpdated] after every gated write (install / update /
  /// editor save). Null (tests) skips publishing. Consumers: the seeded
  /// `skill_analysis` pipeline trigger and any user-authored trigger.
  final DomainEventBus? _eventBus;

  /// The persisted scan cache/audit (PRD 23 §2/§3), read for status lookups:
  /// `listInstalledStatus` resolves each skill's freshest verdict by its current
  /// content hash. Null (tests) simply reports no cached verdicts.
  final SkillScanRepository? _scanCache;

  /// The shared PRD 24 action guard. When set, a skill's declared capabilities
  /// are resolved against the workspace policy at install time (before any disk
  /// write) — a capability the policy denies blocks the install. Null (pre-
  /// scanner callers / tests) skips the check.
  final ActionGuardService? _actionGuard;

  /// Publishes [SkillUpdated] for a just-written pin. Best-effort: a bus
  /// failure must never fail the write that already succeeded.
  void _publishUpdated(
    String workspaceId,
    SkillLockEntry entry,
    String origin,
  ) {
    final bus = _eventBus;
    if (bus == null) {
      return;
    }
    try {
      bus.publish(
        SkillUpdated(
          workspaceId: workspaceId,
          slug: entry.slug,
          origin: origin,
          computedHash: entry.computedHash,
          scanVerdict: entry.scanVerdict,
          occurredAt: DateTime.now(),
        ),
      );
    } on Object {
      // The write is durable; the notification is advisory.
    }
  }

  static const String _lockFileName = 'skills-lock.json';

  @override
  Future<String?> computeSkillHash(String workspaceId, String slug) async {
    final dirPath = await _fs.skillDir(workspaceId, slug);
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      // Fall back to the single SKILL.md when there is no directory listing.
      final content = await _fs.readSkillFile(workspaceId, slug);
      if (content == null) {
        return null;
      }
      return sha256.convert(utf8.encode(content)).toString();
    }
    final entries = <(String, String)>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final rel = p.relative(entity.path, from: dirPath);
      if (rel == _lockFileName) {
        continue; // The lock never hashes itself.
      }
      final bytes = await entity.readAsBytes();
      entries.add((rel, sha256.convert(bytes).toString()));
    }
    if (entries.isEmpty) {
      return null;
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    final rollup = entries.map((e) => '${e.$1}:${e.$2}').join('\n');
    return sha256.convert(utf8.encode(rollup)).toString();
  }

  @override
  Future<SkillLock> readLock(String workspaceId) async {
    final file = File(await _lockPath(workspaceId));
    if (!file.existsSync()) {
      return SkillLock.empty;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return SkillLock.fromJson(decoded);
      }
    } on FormatException {
      // Malformed lock — treat as empty rather than crash an install.
    }
    return SkillLock.empty;
  }

  @override
  Future<void> writeLock(String workspaceId, SkillLock lock) async {
    final file = File(await _lockPath(workspaceId));
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(lock.toJson())}\n');
  }

  @override
  Future<SkillLockEntry> installFromGitHub({
    required String workspaceId,
    required String slug,
    required String owner,
    required String repo,
    required String path,
    required String ref,
    bool allowQuarantineOverride = false,
    String? channelId,
    String? agentId,
  }) async {
    final content = await _fetch(
      owner: owner,
      repo: repo,
      path: path,
      ref: ref,
    );

    // Mandatory scan gate (PRD 23 §2): scan the EXACT bytes that get written +
    // hashed (one in-memory buffer, no TOCTOU) BEFORE anything touches disk.
    // Fail-closed — a quarantine verdict or a scanner error throws here and
    // aborts the install before `writeSkillFile`.
    final scanResult = await _runGate(
      workspaceId: workspaceId,
      slug: slug,
      files: {'SKILL.md': content},
      trustTier: SkillTrustTier.community,
      runLlmReview: true,
      allowQuarantineOverride: allowQuarantineOverride,
    );

    // Capability→policy gate (PRD 23 §2 ties PRD 24): the skill's declared
    // capabilities are resolved against the workspace action policy on the SAME
    // buffer, before write. A denied capability blocks the install here.
    await _checkManifestPolicy(
      workspaceId: workspaceId,
      slug: slug,
      files: {'SKILL.md': content},
      scanResult: scanResult,
      channelId: channelId,
      agentId: agentId,
    );

    await _fs.writeSkillFile(workspaceId, slug, content);
    final hash =
        await computeSkillHash(workspaceId, slug) ??
        sha256.convert(utf8.encode(content)).toString();
    final entry = SkillLockEntry(
      slug: slug,
      source: '$owner/$repo',
      sourceType: SkillOrigin.github,
      skillPath: path,
      computedHash: hash,
      ref: ref,
      trustTier: SkillTrustTier.community,
      scanVerdict: scanResult?.verdict,
      rulesVersion: scanResult?.rulesVersion,
    );
    final lock = await readLock(workspaceId);
    await writeLock(workspaceId, lock.withEntry(entry));
    _publishUpdated(workspaceId, entry, SkillUpdateOrigin.github);
    return entry;
  }

  @override
  Future<List<SkillUpdateCandidate>> checkUpdates(String workspaceId) async {
    final resolveLatest = _latestCommit;
    if (resolveLatest == null) {
      return const [];
    }
    final lock = await readLock(workspaceId);
    final candidates = <SkillUpdateCandidate>[];
    for (final entry in lock.skills.values) {
      if (entry.sourceType != SkillOrigin.github) {
        continue;
      }
      final parts = entry.source.split('/');
      if (parts.length != 2 || parts.any((p) => p.isEmpty)) {
        continue;
      }
      try {
        final branch = await _defaultBranch?.call(
          owner: parts[0],
          repo: parts[1],
        );
        final latest = await resolveLatest(
          owner: parts[0],
          repo: parts[1],
          path: entry.skillPath,
          branch: branch,
        );
        if (latest == null || latest.isEmpty) {
          continue;
        }
        final candidate = SkillUpdateCandidate(
          slug: entry.slug,
          currentRef: entry.ref ?? '',
          latestRef: latest,
        );
        if (candidate.hasUpdate) {
          candidates.add(candidate);
        }
      } on Object {
        // Best-effort: a network error for one skill must not fail the sweep.
        continue;
      }
    }
    return candidates;
  }

  @override
  Future<SkillLockEntry> applyUpdate({
    required String workspaceId,
    required String slug,
    required String ref,
    bool allowQuarantineOverride = false,
    String? channelId,
    String? agentId,
  }) async {
    final lock = await readLock(workspaceId);
    final existing = lock.skills[slug];
    if (existing == null) {
      throw StateError('Skill "$slug" is not installed; cannot update it.');
    }
    if (existing.sourceType != SkillOrigin.github) {
      throw StateError(
        'Skill "$slug" is not a GitHub skill; cannot update it.',
      );
    }
    final parts = existing.source.split('/');
    if (parts.length != 2 || parts.any((p) => p.isEmpty)) {
      throw StateError('Skill "$slug" has an unparseable source.');
    }

    // Re-fetch at the target ref: ONE buffer through gate → manifest → write →
    // hash → re-pin (TOCTOU-safe, identical to install).
    final content = await _fetch(
      owner: parts[0],
      repo: parts[1],
      path: existing.skillPath,
      ref: ref,
    );
    final scanResult = await _runGate(
      workspaceId: workspaceId,
      slug: slug,
      files: {'SKILL.md': content},
      trustTier: existing.trustTier,
      runLlmReview: true,
      allowQuarantineOverride: allowQuarantineOverride,
    );
    await _checkManifestPolicy(
      workspaceId: workspaceId,
      slug: slug,
      files: {'SKILL.md': content},
      scanResult: scanResult,
      channelId: channelId,
      agentId: agentId,
    );

    await _fs.writeSkillFile(workspaceId, slug, content);
    final hash =
        await computeSkillHash(workspaceId, slug) ??
        sha256.convert(utf8.encode(content)).toString();
    final entry = SkillLockEntry(
      slug: slug,
      source: existing.source,
      sourceType: SkillOrigin.github,
      skillPath: existing.skillPath,
      computedHash: hash,
      ref: ref,
      trustTier: existing.trustTier,
      scanVerdict: scanResult?.verdict,
      rulesVersion: scanResult?.rulesVersion,
      // The rollback chain: keep the version we just replaced.
      previousHash: existing.computedHash,
    );
    await writeLock(
      workspaceId,
      (await readLock(workspaceId)).withEntry(entry),
    );
    _publishUpdated(workspaceId, entry, SkillUpdateOrigin.github);
    return entry;
  }

  @override
  Future<SkillLockEntry> installFromRegistry({
    required String workspaceId,
    required String slug,
    String? version,
    bool allowQuarantineOverride = false,
    String? channelId,
    String? agentId,
  }) async {
    final registry = _registry;
    if (registry == null) {
      throw StateError('No skills registry is configured.');
    }
    final resolved = await registry.resolve(slug, version: version);
    final files = resolved.files;

    final scanResult = await _runGate(
      workspaceId: workspaceId,
      slug: slug,
      files: files,
      // A verified publisher is provenance evidence only — never a scan
      // shortcut; it just records a higher trust tier on the pin.
      trustTier: resolved.verifiedPublisher
          ? SkillTrustTier.verified
          : SkillTrustTier.community,
      runLlmReview: true,
      allowQuarantineOverride: allowQuarantineOverride,
    );
    await _checkManifestPolicy(
      workspaceId: workspaceId,
      slug: slug,
      files: files,
      scanResult: scanResult,
      channelId: channelId,
      agentId: agentId,
    );

    // Registry bundles are single-file today; write the SKILL.md content.
    final content = files['SKILL.md'] ?? files.values.first;
    await _fs.writeSkillFile(workspaceId, slug, content);
    final hash =
        await computeSkillHash(workspaceId, slug) ??
        sha256.convert(utf8.encode(content)).toString();
    final entry = SkillLockEntry(
      slug: slug,
      source: resolved.publisher.isEmpty ? 'skills.sh' : resolved.publisher,
      sourceType: SkillOrigin.registry,
      skillPath: 'skills/$slug/SKILL.md',
      computedHash: hash,
      // Registry pins are content-hash pins; the version is recorded as the ref.
      ref: resolved.version.isEmpty ? null : resolved.version,
      trustTier: resolved.verifiedPublisher
          ? SkillTrustTier.verified
          : SkillTrustTier.community,
      scanVerdict: scanResult?.verdict,
      rulesVersion: scanResult?.rulesVersion,
    );
    await writeLock(
      workspaceId,
      (await readLock(workspaceId)).withEntry(entry),
    );
    _publishUpdated(workspaceId, entry, SkillUpdateOrigin.registry);
    return entry;
  }

  @override
  Future<SkillScanResult> previewInstall({
    required String workspaceId,
    required String slug,
    String? version,
  }) async {
    final registry = _registry;
    if (registry == null) {
      throw StateError('No skills registry is configured.');
    }
    final scanner = _scanner;
    if (scanner == null) {
      throw StateError('No scanner is configured; cannot preview an install.');
    }
    final resolved = await registry.resolve(slug, version: version);
    // Scan-only: returns even a quarantine verdict, writes nothing. The bytes
    // are byte-identical to what installFromRegistry would write, so the later
    // install's scan is a free cache hit.
    return scanner.scan(
      SkillBundle(slug: slug, files: resolved.files),
      workspaceId: workspaceId,
      trustTier: resolved.verifiedPublisher
          ? SkillTrustTier.verified
          : SkillTrustTier.community,
      runLlmReview: true,
    );
  }

  /// Reads every file in the skill's directory (lock excluded) into a bundle —
  /// the exact file set [computeSkillHash] addresses, so a scan over this bundle
  /// is keyed by the same content hash the lock pins. Returns null when the
  /// skill is absent on disk or has no files.
  Future<SkillBundle?> _readBundleFromDisk(
    String workspaceId,
    String slug,
  ) async {
    final dirPath = await _fs.skillDir(workspaceId, slug);
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return null;
    }
    final files = <String, String>{};
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final rel = p.relative(entity.path, from: dirPath);
      if (rel == _lockFileName) {
        continue; // The lock never scans (or hashes) itself.
      }
      files[rel] = await entity.readAsString();
    }
    if (files.isEmpty) {
      return null;
    }
    return SkillBundle(slug: slug, files: files);
  }

  @override
  Future<SkillScanResult> scanInstalled({
    required String workspaceId,
    required String slug,
    bool runLlmReview = true,
  }) async {
    final scanner = _scanner;
    if (scanner == null) {
      throw StateError('No scanner is configured; cannot scan a skill.');
    }
    final bundle = await _readBundleFromDisk(workspaceId, slug);
    if (bundle == null) {
      throw StateError('Skill "$slug" is not present on disk; cannot scan it.');
    }
    final lock = await readLock(workspaceId);
    final entry = lock.skills[slug];
    // Scan-only over the on-disk bytes; returns even a quarantine verdict so
    // the operator sees why. The adapter persists the result to the scan cache.
    final result = await scanner.scan(
      bundle,
      workspaceId: workspaceId,
      trustTier: entry?.trustTier ?? SkillTrustTier.workspace,
      runLlmReview: runLlmReview,
    );
    if (result.verdict == SkillScanVerdict.quarantine) {
      // Make the quarantine durable: enforcement (the agent-link filter and
      // detach passes) reads lock verdicts, so a quarantined skill MUST have a
      // lock entry — an unmanaged skill is adopted as manual-origin here. A
      // non-quarantine verdict leaves the lock untouched (scan is not a pin).
      final hash = await computeSkillHash(workspaceId, slug);
      final pinned = SkillLockEntry(
        slug: slug,
        source: entry?.source ?? 'workspace',
        sourceType: entry?.sourceType ?? SkillOrigin.manual,
        skillPath: entry?.skillPath ?? 'skills/$slug/SKILL.md',
        // Keep an existing pin (drift stays visible via verify()); only an
        // adopted unmanaged skill gets pinned, at its current hash.
        computedHash: entry?.computedHash ?? hash ?? '',
        ref: entry?.ref,
        trustTier: entry?.trustTier ?? SkillTrustTier.workspace,
        scanVerdict: result.verdict,
        rulesVersion: result.rulesVersion,
        previousHash: entry?.previousHash,
      );
      await writeLock(workspaceId, lock.withEntry(pinned));
    }
    return result;
  }

  @override
  Future<SkillLockEntry> saveLocal({
    required String workspaceId,
    required String slug,
    required String content,
    bool allowQuarantineOverride = false,
    String? channelId,
    String? agentId,
  }) async {
    // ONE buffer through gate → policy → write → hash → pin (TOCTOU-safe,
    // identical to install). Local saves use the create_skill profile: static
    // Layers 1–2 only (no LLM round-trip on every editor save) at workspace
    // trust — the operator is the author.
    final scanResult = await _runGate(
      workspaceId: workspaceId,
      slug: slug,
      files: {'SKILL.md': content},
      trustTier: SkillTrustTier.workspace,
      runLlmReview: false,
      allowQuarantineOverride: allowQuarantineOverride,
    );
    await _checkManifestPolicy(
      workspaceId: workspaceId,
      slug: slug,
      files: {'SKILL.md': content},
      scanResult: scanResult,
      channelId: channelId,
      agentId: agentId,
    );

    final existing = (await readLock(workspaceId)).skills[slug];
    await _fs.writeSkillFile(workspaceId, slug, content);
    final hash =
        await computeSkillHash(workspaceId, slug) ??
        sha256.convert(utf8.encode(content)).toString();
    final entry = SkillLockEntry(
      slug: slug,
      // Preserve the install provenance across a local edit (a registry skill
      // edited in the UI stays a registry skill); new skills pin as manual.
      source: existing?.source ?? 'workspace',
      sourceType: existing?.sourceType ?? SkillOrigin.manual,
      skillPath: existing?.skillPath ?? 'skills/$slug/SKILL.md',
      computedHash: hash,
      ref: existing?.ref,
      trustTier: existing?.trustTier ?? SkillTrustTier.workspace,
      scanVerdict: scanResult?.verdict,
      rulesVersion: scanResult?.rulesVersion,
      // The rollback chain: keep the version we just replaced.
      previousHash: existing?.computedHash,
    );
    await writeLock(
      workspaceId,
      (await readLock(workspaceId)).withEntry(entry),
    );
    _publishUpdated(workspaceId, entry, SkillUpdateOrigin.manual);
    return entry;
  }

  @override
  Future<List<InstalledSkillStatus>> listInstalledStatus(
    String workspaceId,
  ) async {
    final slugs = await _fs.listSkillSlugs(workspaceId);
    final lock = await readLock(workspaceId);
    final cache = _scanCache;
    final statuses = <InstalledSkillStatus>[];
    for (final slug in slugs) {
      final entry = lock.skills[slug];
      final hash = await computeSkillHash(workspaceId, slug);
      if (hash == null) {
        continue; // Raced with a delete; the next refresh won't see it.
      }
      // The verdict shown is the freshest cached scan of the CURRENT bytes —
      // never the (possibly stale-pinned) lock verdict.
      final scan = cache == null
          ? null
          : await cache.latestForHash(workspaceId, hash);
      statuses.add(
        InstalledSkillStatus(
          slug: slug,
          lockState: entry == null
              ? InstalledSkillLockState.unmanaged
              : (entry.computedHash == hash
                    ? InstalledSkillLockState.managed
                    : InstalledSkillLockState.drifted),
          computedHash: hash,
          origin: entry?.sourceType,
          source: entry?.source,
          trustTier: entry?.trustTier,
          scan: scan,
        ),
      );
    }
    statuses.sort((a, b) => a.slug.compareTo(b.slug));
    return statuses;
  }

  @override
  Future<List<String>> reVerify(String workspaceId) async {
    final scanner = _scanner;
    if (scanner == null) {
      return const [];
    }
    final lock = await readLock(workspaceId);
    final reScanned = <String>[];
    for (final entry in lock.skills.values) {
      final rv = entry.rulesVersion;
      // A skill is due for a re-scan when its recorded verdict is rules-stale
      // OR its on-disk bytes drifted from the pin: the recorded verdict
      // describes the pinned bytes, not what is on disk now, so a current-rules
      // verdict over edited content is still a lie.
      var due = rv == null || rv < kSkillRulesVersion;
      if (!due) {
        final current = await computeSkillHash(workspaceId, entry.slug);
        due = current != null && current != entry.computedHash;
      }
      if (!due) {
        continue;
      }
      try {
        final bundle = await _readBundleFromDisk(workspaceId, entry.slug);
        if (bundle == null) {
          continue; // Missing on disk — surfaced by verify(), not here.
        }
        // Re-scan the on-disk bytes under the CURRENT rules (the cache misses on
        // the bumped rules version, so this genuinely re-runs). runLlmReview is
        // off — re-verify is a fast, deterministic Layers 1-2 refresh.
        final result = await scanner.scan(
          bundle,
          workspaceId: workspaceId,
          trustTier: entry.trustTier,
          runLlmReview: false,
        );
        // The pin itself is NOT refreshed: a drifted skill stays drifted (the
        // tamper signal `verify()` reports survives the sweep). Only the
        // verdict/rulesVersion move — and the verdict describes the CURRENT
        // on-disk bytes, which is what enforcement (the agent-link filter)
        // reads.
        final updated = SkillLockEntry(
          slug: entry.slug,
          source: entry.source,
          sourceType: entry.sourceType,
          skillPath: entry.skillPath,
          computedHash: entry.computedHash,
          ref: entry.ref,
          trustTier: entry.trustTier,
          scanVerdict: result.verdict,
          rulesVersion: result.rulesVersion,
          previousHash: entry.previousHash,
        );
        await writeLock(
          workspaceId,
          (await readLock(workspaceId)).withEntry(updated),
        );
        reScanned.add(entry.slug);
      } on Object {
        // Best-effort: one skill's failure never aborts the sweep.
        continue;
      }
    }
    return reScanned;
  }

  /// Runs the mandatory scan gate over [files] BEFORE any disk write and returns
  /// the passing/warning result (or null when no scanner is wired — the
  /// backward-compatible no-op). Fail-closed: a scanner error, or a
  /// `quarantine` verdict without [allowQuarantineOverride], throws a
  /// [SkillScanBlockedException] and aborts the install.
  Future<SkillScanResult?> _runGate({
    required String workspaceId,
    required String slug,
    required Map<String, String> files,
    required SkillTrustTier trustTier,
    required bool runLlmReview,
    required bool allowQuarantineOverride,
  }) async {
    final scanner = _scanner;
    if (scanner == null) {
      return null;
    }
    final SkillScanResult result;
    try {
      result = await scanner.scan(
        SkillBundle(slug: slug, files: files),
        workspaceId: workspaceId,
        trustTier: trustTier,
        runLlmReview: runLlmReview,
      );
    } on SkillScanBlockedException {
      rethrow;
    } on Object catch (e) {
      // A scanner failure blocks the install — never write on an errored scan.
      throw SkillScanBlockedException(slug, reason: 'scan failed: $e');
    }
    if (result.verdict == SkillScanVerdict.quarantine &&
        !allowQuarantineOverride) {
      throw SkillScanBlockedException(slug, result: result);
    }
    return result;
  }

  /// Resolves the skill's declared capabilities against the PRD 24 action policy
  /// before install (PRD 23 §2). The manifest maps to [ActionClass]es; the
  /// shared [ActionGuardService] combines them most-restrictively and surfaces
  /// one confirmation for a `prompt` decision or refuses on `deny`. Fail-closed:
  /// a denied/blocked capability throws before any disk write. No-op when no
  /// guard is wired or the skill requests no classified capabilities.
  Future<void> _checkManifestPolicy({
    required String workspaceId,
    required String slug,
    required Map<String, String> files,
    required SkillScanResult? scanResult,
    String? channelId,
    String? agentId,
  }) async {
    final guard = _actionGuard;
    if (guard == null) {
      return;
    }
    // Prefer the manifest the scanner already computed; fall back to a direct
    // extraction so the policy still applies when no scanner is wired.
    final manifest =
        scanResult?.manifest ??
        SkillCapabilityExtractor.extract(SkillBundle(slug: slug, files: files));
    final classes = manifest.requiredActionClassWires
        .map(ActionClass.fromWire)
        .whereType<ActionClass>()
        .toSet();
    if (classes.isEmpty) {
      return;
    }
    final GuardVerdict verdict;
    try {
      verdict = await guard.check(
        workspaceId: workspaceId,
        classes: classes,
        channelId: channelId,
        agentId: agentId,
        // A distinct summary keeps this install-time capability prompt from
        // colliding with the tool-level guard's remembered decisions.
        actionSummary:
            'install skill "$slug" — wants: '
            '${manifest.labels.join(", ")} '
            '(scan: ${scanResult?.verdict.wire ?? 'n/a'})',
      );
    } on Object catch (e) {
      // Fail-closed: a policy-resolution error must not let an install through.
      throw SkillScanBlockedException(slug, reason: 'policy check failed: $e');
    }
    if (!verdict.allowed) {
      throw SkillScanBlockedException(
        slug,
        reason: 'blocked by action policy: ${verdict.reason}',
      );
    }
  }

  @override
  Future<SkillLockEntry> pinLocal({
    required String workspaceId,
    required String slug,
    SkillOrigin origin = SkillOrigin.manual,
    String source = 'workspace',
  }) async {
    final hash = await computeSkillHash(workspaceId, slug);
    if (hash == null) {
      throw StateError('Skill "$slug" is not present on disk; cannot pin it.');
    }
    final entry = SkillLockEntry(
      slug: slug,
      source: source,
      sourceType: origin,
      skillPath: 'skills/$slug/SKILL.md',
      computedHash: hash,
    );
    final lock = await readLock(workspaceId);
    await writeLock(workspaceId, lock.withEntry(entry));
    return entry;
  }

  @override
  Future<SkillVerifyResult> verify(String workspaceId) async {
    final lock = await readLock(workspaceId);
    final matched = <String>[];
    final drifted = <String>[];
    final missing = <String>[];
    final stale = <String>[];
    final quarantined = <String>[];
    for (final entry in lock.skills.values) {
      final current = await computeSkillHash(workspaceId, entry.slug);
      if (current == null) {
        missing.add(entry.slug);
      } else if (current == entry.computedHash) {
        matched.add(entry.slug);
      } else {
        drifted.add(entry.slug);
      }
      // Verdict staleness (PRD 23 §6): a skill scanned under an older rules
      // version is due for a re-scan. Derived from the lock's recorded version
      // vs the current `kSkillRulesVersion` — no scan-cache read needed.
      final rv = entry.rulesVersion;
      if (rv != null && rv < kSkillRulesVersion) {
        stale.add(entry.slug);
      }
      // A lock-recorded quarantine is blocked pending operator action (PRD 23
      // §6): enforcement (agent-link filtering) already detaches these.
      if (entry.scanVerdict == SkillScanVerdict.quarantine) {
        quarantined.add(entry.slug);
      }
    }
    return SkillVerifyResult(
      matched: matched,
      drifted: drifted,
      missing: missing,
      stale: stale,
      quarantined: quarantined,
    );
  }

  Future<String> _lockPath(String workspaceId) async {
    final skillsDir = await _fs.skillsDir(workspaceId);
    return p.join(skillsDir, _lockFileName);
  }
}
