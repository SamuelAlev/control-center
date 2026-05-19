import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// Thrown by the mandatory install gate (PRD 23 §2) when a skill bundle is
/// BLOCKED before any of its bytes touch disk — either the scan returned a
/// `quarantine` verdict (without an explicit operator override), or the scanner
/// itself failed/produced no verdict. Both are fail-closed: the install aborts.
///
/// Carries the blocking [result] (verdict + findings + capability manifest) when
/// a verdict was produced, so the operator/agent sees exactly what was flagged.
/// When [result] is null the scanner errored (see [reason]) — still a block, by
/// design. Surfaced verbatim to the agent via the MCP tool error path, so
/// [toString] returns a clean, self-contained explanation.
class SkillScanBlockedException implements Exception {
  /// Creates a [SkillScanBlockedException].
  const SkillScanBlockedException(this.slug, {this.result, this.reason});

  /// The slug that was blocked.
  final String slug;

  /// The scan result that blocked the install, when a verdict was produced.
  /// Null when the scanner threw before returning a verdict.
  final SkillScanResult? result;

  /// A human-readable reason the gate blocked (e.g. the scanner threw). Used
  /// when no [result] verdict is available.
  final String? reason;

  /// The findings that triggered the block (empty when the scanner errored).
  List<SkillScanFinding> get findings => result?.findings ?? const [];

  @override
  String toString() {
    if (result == null) {
      return 'Skill "$slug" was blocked by the scan gate '
          '(fail-closed): ${reason ?? 'the scanner failed to produce a verdict'}.';
    }
    final summary = findings.isEmpty
        ? 'no findings recorded'
        : findings
              .map(
                (f) =>
                    '${f.ruleId} (${f.verdict.wire}) in ${f.file}'
                    '${f.line > 0 ? ':${f.line}' : ''}',
              )
              .join('; ');
    return 'Skill "$slug" was blocked by the scan gate '
        '(verdict: ${result!.verdict.wire}): $summary';
  }
}
