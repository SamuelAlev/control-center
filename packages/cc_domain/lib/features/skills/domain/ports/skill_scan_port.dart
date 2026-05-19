import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// The mandatory scan gate invoked between fetch and write in the install path
/// (PRD 23 §2). The server-side implementation runs Layers 1–2 (pure) and,
/// unless the LLM review is disabled, the budgeted Layer 3 reviewer (inert
/// posture (empty tool registry, deny-all policy, provider-endpoint-only
/// egress). A port failure/exception is fail-closed by the caller (quarantine).
abstract interface class SkillScanPort {
  /// Scans [bundle] and returns the verdict + findings + capability manifest.
  ///
  /// [runLlmReview] is false for the `create_skill` lighter gate (Layers 1–2
  /// only). [workspaceId] scopes the scan-result cache; [trustTier] is carried
  /// through for the policy hook. Implementations must never execute anything
  /// the skill contains.
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  });
}
