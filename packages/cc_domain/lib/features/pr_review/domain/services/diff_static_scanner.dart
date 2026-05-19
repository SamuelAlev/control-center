// Deterministic security rules run over a PR's ADDED lines.
//
// A reviewer agent reads a diff and forms a judgement; these rules read the
// same diff and either match or do not. That difference is the point — a regex
// hit is reproducible, costs no tokens, and never varies between two runs of
// the same PR. It is also much narrower than a model, which is why the two run
// together rather than one replacing the other.
//
// Reuses `SkillStaticRules` verbatim rather than forking its pattern table.
// Those rules are a fail-closed supply-chain gate whose regexes are the
// regression-tested product of real attack shapes (Trojan Source, curl|bash,
// secret-plus-egress); re-deriving a second, drifting copy for PR diffs would
// be strictly worse than feeding the same rules a different body.
//
// The trick that makes it work: each changed file is rebuilt as a synthetic
// body where only ADDED lines carry text, at their real head-side line
// numbers. So a rule fires only on what this PR introduces (pre-existing
// `eval` in the file is not this PR's problem), and the line number it reports
// is a line a reviewer can actually open.

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_static_rules.dart';

/// One deterministic finding over a PR's added lines.
class StaticFinding {
  /// Creates a [StaticFinding].
  const StaticFinding({
    required this.ruleId,
    required this.message,
    required this.filePath,
    required this.priority,
    required this.confidence,
    this.line,
    this.snippet = '',
  });

  /// The rule that fired (e.g. `curl_pipe_shell`).
  final String ruleId;

  /// Human-readable description of the risk.
  final String message;

  /// Repository-relative file the finding anchors to.
  final String filePath;

  /// Head-side line number, when the rule reported one.
  final int? line;

  /// The matched source text, truncated.
  final String snippet;

  /// Action-ordering priority.
  final ReviewNodePriority priority;

  /// Confidence in the match.
  final double confidence;

  /// Stable dedup identity within one scan.
  String get dedupKey => '$ruleId|$filePath|${line ?? 0}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticFinding &&
          runtimeType == other.runtimeType &&
          ruleId == other.ruleId &&
          filePath == other.filePath &&
          line == other.line;

  @override
  int get hashCode => Object.hash(ruleId, filePath, line);
}

/// Runs the shared static rules over a PR's added lines.
class DiffStaticScanner {
  /// Creates a [DiffStaticScanner].
  const DiffStaticScanner();

  /// Scans each entry of [patchByFile] (a unified diff per changed file).
  ///
  /// Returns findings sorted by priority then file then line, deduplicated by
  /// rule + file + line.
  List<StaticFinding> scan(Map<String, String> patchByFile) {
    if (patchByFile.isEmpty) {
      return const [];
    }
    final bodies = <String, String>{};
    for (final entry in patchByFile.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      final body = addedLinesBody(entry.value);
      if (body.trim().isEmpty) {
        continue;
      }
      bodies[entry.key] = body;
    }
    if (bodies.isEmpty) {
      return const [];
    }

    // The bundle is a carrier for the path→content map; nothing here reads or
    // writes a skill.
    final raw = SkillStaticRules.scan(
      SkillBundle(slug: '__pr_diff__', files: bodies),
    );

    final seen = <String>{};
    final findings = <StaticFinding>[];
    for (final f in raw) {
      final finding = _toFinding(f);
      if (finding == null) {
        continue;
      }
      if (seen.add(finding.dedupKey)) {
        findings.add(finding);
      }
    }
    findings.sort((a, b) {
      final byPriority = a.priority.index.compareTo(b.priority.index);
      if (byPriority != 0) {
        return byPriority;
      }
      final byFile = a.filePath.compareTo(b.filePath);
      if (byFile != 0) {
        return byFile;
      }
      return (a.line ?? 0).compareTo(b.line ?? 0);
    });
    return findings;
  }

  /// Rebuilds a patch as a body where only added lines carry text, positioned
  /// at their head-side line numbers.
  ///
  /// Blank-filling rather than concatenating is what keeps the reported line
  /// numbers real. It also gives the file-level co-occurrence rule
  /// (`secret_exfiltration`) exactly the right semantics for a diff: it fires
  /// only when BOTH halves of the shape were added by this PR.
  String addedLinesBody(String patch) {
    final lines = parseUnifiedDiff(patch);
    final byLine = <int, String>{};
    var max = 0;
    for (final line in lines) {
      if (line.kind != DiffLineKind.addition) {
        continue;
      }
      final n = line.newLine;
      if (n == null || n <= 0) {
        continue;
      }
      byLine[n] = line.content;
      if (n > max) {
        max = n;
      }
    }
    if (max == 0) {
      return '';
    }
    final buffer = StringBuffer();
    for (var i = 1; i <= max; i++) {
      buffer.writeln(byLine[i] ?? '');
    }
    return buffer.toString();
  }

  /// Maps a rule finding onto review priority.
  ///
  /// Deliberately capped at P1: a regex is evidence, not proof, and P0 blocks
  /// a merge outright. A pattern match that stops a release without a human
  /// ever agreeing would train people to disable the scanner, which costs more
  /// than the bug it caught.
  StaticFinding? _toFinding(SkillScanFinding f) {
    if (f.file.isEmpty) {
      return null;
    }
    final quarantine = f.verdict == SkillScanVerdict.quarantine;
    return StaticFinding(
      ruleId: f.ruleId,
      message: f.message,
      filePath: f.file,
      line: f.line > 0 ? f.line : null,
      snippet: f.snippet,
      priority: quarantine ? ReviewNodePriority.p1 : ReviewNodePriority.p2,
      confidence: quarantine ? 0.9 : 0.8,
    );
  }
}
