import 'package:cc_domain/features/skills/domain/scanner/skill_capability_extractor.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_static_rules.dart';

/// The pure Layers 1–2 scanner (PRD 23 §3). Deterministic and execution-free:
/// runs the static rules + capability extractor over the in-memory bundle and
/// aggregates a verdict. Layer 3 (the LLM review) is applied by the infra port
/// implementation and can only *tighten* this verdict, never loosen it.
class SkillScanner {
  /// Creates a [SkillScanner].
  const SkillScanner();

  /// Runs Layers 1–2 and returns the aggregate result. No process spawn, no
  /// network, no disk — the whole pipeline's only active step is Layer 3, which
  /// this method does not perform.
  SkillScanResult scanStatic(SkillBundle bundle) {
    final findings = SkillStaticRules.scan(bundle);
    final manifest = SkillCapabilityExtractor.extract(bundle);
    var verdict = SkillScanVerdict.pass;
    for (final f in findings) {
      verdict = SkillScanVerdict.tighten(verdict, f.verdict);
    }
    return SkillScanResult(
      verdict: verdict,
      findings: findings,
      manifest: manifest,
      rulesVersion: kSkillRulesVersion,
    );
  }
}
