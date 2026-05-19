import 'dart:convert';

import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/repositories/skill_scan_repository.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scanner.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_static_rules.dart';
import 'package:crypto/crypto.dart';

/// The optional Layer-3 hook (PRD 23 §2). Given the fetched [bundle] and the
/// passing Layers 1–2 [staticResult], runs the budgeted LLM reviewer (an inert
/// posture: empty tool registry, deny-all policy, provider-endpoint-only
/// egress) and returns a possibly-tightened result. Null ⇒ Layer 3 is skipped.
///
/// A failure of this hook must NOT quarantine content that already passed
/// Layers 1–2: [SkillScannerAdapter.scan] catches it and keeps the static
/// verdict with `llmReviewed:false` (§Clarifications).
typedef SkillReviewRunner =
    Future<SkillScanResult> Function(
      SkillBundle bundle,
      SkillScanResult staticResult,
    );

/// Infrastructure implementation of [SkillScanPort] — the mandatory install-gate
/// scanner (PRD 23 §2). It is inert by construction: it runs the pure Layers 1–2
/// static scanner and (optionally) the budgeted Layer-3 review, but NEVER
/// executes anything the bundle contains.
///
/// Verdicts are cached by `(workspaceId, contentHash, kSkillRulesVersion)`:
/// identical bytes scanned under the same rules are never re-scanned.
class SkillScannerAdapter implements SkillScanPort {
  /// Creates a [SkillScannerAdapter].
  SkillScannerAdapter({
    required SkillScanner scanner,
    required SkillScanRepository cache,
    SkillReviewRunner? llmReview,
  }) : _scanner = scanner,
       _cache = cache,
       _llmReview = llmReview;

  final SkillScanner _scanner;
  final SkillScanRepository _cache;
  SkillReviewRunner? _llmReview;

  /// Wires (or replaces) the Layer-3 reviewer after construction. The
  /// composition root builds this adapter early (so the bundle service + skill
  /// tools can reference it) but the LLM provider deps are constructed later;
  /// this lets the runtime attach the reviewer once those exist, before any
  /// scan actually runs. Null disables Layer 3.
  set llmReview(SkillReviewRunner? runner) => _llmReview = runner;

  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async {
    final hash = _bundleHash(bundle);

    // Cache-by-hash fast path: identical bytes under the same rules are reused
    // (never re-scanned), scoped to this workspace.
    final cached = await _cache.byHash(workspaceId, hash, kSkillRulesVersion);
    if (cached != null) {
      return cached;
    }

    // Layers 1–2: pure, deterministic, execution-free.
    var result = _scanner.scanStatic(bundle);

    // Layer 3 (budgeted LLM review): only when requested, only when a hook is
    // wired and only when Layers 1–2 already pass. It can only *tighten* the
    // verdict, never loosen it. A failure keeps the static verdict (fail-OPEN
    // for Layer 3 only — Layers 1–2 already cleared it), recording that the
    // review did not complete.
    if (runLlmReview && result.verdict.installable) {
      final reviewer = _llmReview;
      if (reviewer != null) {
        try {
          result = await reviewer(bundle, result);
        } on Object {
          result = SkillScanResult(
            verdict: result.verdict,
            findings: result.findings,
            manifest: result.manifest,
            rulesVersion: result.rulesVersion,
            llmReviewed: false,
          );
        }
      }
    }

    // Persist to the workspace-scoped cache + audit trail, then return.
    await _cache.upsert(workspaceId, hash, result, skillRef: bundle.slug);
    return result;
  }

  /// Content-addresses [bundle] with the same rolled-up SHA256 shape as
  /// `SkillBundleService.computeSkillHash`: hash each file's bytes, combine the
  /// per-file `path:sha256` lines in sorted-path order, then hash the rollup.
  static String _bundleHash(SkillBundle bundle) {
    final entries =
        bundle.files.entries
            .map(
              (e) => (e.key, sha256.convert(utf8.encode(e.value)).toString()),
            )
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));
    final rollup = entries.map((e) => '${e.$1}:${e.$2}').join('\n');
    return sha256.convert(utf8.encode(rollup)).toString();
  }
}
