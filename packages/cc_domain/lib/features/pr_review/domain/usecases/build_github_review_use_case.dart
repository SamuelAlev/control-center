import 'package:cc_domain/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';

/// A review finding ready to be turned into GitHub output: its structured
/// [payload] (kind / priority / confidence / anchor) plus the human-readable
/// [content] the reviewer wrote.
class ReviewFindingDraft {
  /// Creates a [ReviewFindingDraft].
  const ReviewFindingDraft({required this.payload, required this.content});

  /// Structured metadata for the finding.
  final ReviewNodePayload payload;

  /// Markdown body the reviewer authored.
  final String content;
}

/// Maps the workspace's structured review findings + the per-PR [ReviewVerdict]
/// into a [GitHubReviewPlan]: an event, a summary body and line-anchored
/// inline comments.
///
/// Pure (no I/O) so the mapping — anchoring, event selection, body rendering —
/// is unit-testable in isolation. The data-layer publisher takes the resulting
/// plan and submits it to GitHub.
class BuildGitHubReviewUseCase {
  /// Creates a [BuildGitHubReviewUseCase].
  const BuildGitHubReviewUseCase();

  /// Footer appended to every inline comment so the source is unambiguous.
  static const String inlineFooter = '— Control Center AI review';

  /// Builds the plan. [approveOnShip] lets the caller opt into an `APPROVE`
  /// event on a clean verdict; the safe default leaves a `COMMENT` review so
  /// the bot never approves on the author's behalf unexpectedly.
  /// [walkthrough], when the finalized review carried one, renders the
  /// CodeRabbit-style summary + per-area sections at the top of the body.
  GitHubReviewPlan execute({
    required List<ReviewFindingDraft> findings,
    required ReviewVerdict verdict,
    ReviewWalkthroughSummary? walkthrough,
    bool approveOnShip = false,
  }) {
    final inline = <GitHubInlineComment>[];
    final unanchored = <ReviewFindingDraft>[];

    for (final finding in findings) {
      final anchor = finding.payload.anchor;
      if (anchor.filePath != null && anchor.lineNumber != null) {
        inline.add(
          _toInlineComment(finding, anchor.filePath!, anchor.lineNumber!),
        );
      } else {
        unanchored.add(finding);
      }
    }

    return GitHubReviewPlan(
      event: _eventFor(verdict.overall, approveOnShip: approveOnShip),
      body: _renderBody(
        verdict: verdict,
        unanchored: unanchored,
        findings: findings,
        walkthrough: walkthrough,
      ),
      inlineComments: inline,
    );
  }

  GitHubInlineComment _toInlineComment(
    ReviewFindingDraft finding,
    String path,
    int lineNumber,
  ) {
    final anchor = finding.payload.anchor;
    final isRange = anchor.lineEnd != null && anchor.lineEnd! > lineNumber;
    return GitHubInlineComment(
      path: path,
      // GitHub anchors a multi-line comment with `line` = end, `start_line` =
      // start.
      line: isRange ? anchor.lineEnd! : lineNumber,
      startLine: isRange ? lineNumber : null,
      body: _renderFindingBody(finding),
    );
  }

  String _renderFindingBody(ReviewFindingDraft finding) {
    final p = finding.payload;
    final conf = (p.confidence * 100).round();
    final header =
        '**[${p.priority.name.toUpperCase()}] ${p.kind.name}** '
        '· $conf% confidence';
    return '$header\n\n${finding.content.trim()}\n\n$inlineFooter';
  }

  String _renderBody({
    required ReviewVerdict verdict,
    required List<ReviewFindingDraft> unanchored,
    required List<ReviewFindingDraft> findings,
    ReviewWalkthroughSummary? walkthrough,
  }) {
    final buf = StringBuffer()..writeln(_renderVerdictBanner(verdict));
    if (walkthrough != null && !walkthrough.isAbsent) {
      buf
        ..writeln()
        ..writeln(_renderWalkthrough(walkthrough));
    }
    final byFile = _findingsByFile(findings);
    if (byFile.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('## Findings by file (${findings.length})');
      final paths = byFile.keys.toList()..sort();
      for (final path in paths) {
        buf
          ..writeln()
          ..writeln('### `$path`')
          ..writeln();
        for (final finding in byFile[path]!) {
          buf.writeln(_renderFindingLine(finding));
        }
      }
    }
    if (unanchored.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('## Findings not tied to a line (${unanchored.length})')
        ..writeln();
      for (final finding in unanchored) {
        buf.writeln(_renderFindingLine(finding));
      }
    }
    buf
      ..writeln()
      ..writeln('_${inlineFooter}_');
    return buf.toString().trimRight();
  }

  /// Groups the findings by anchored file (findings without a file are the
  /// caller's `unanchored` bucket and never appear here).
  Map<String, List<ReviewFindingDraft>> _findingsByFile(
    List<ReviewFindingDraft> findings,
  ) {
    final byFile = <String, List<ReviewFindingDraft>>{};
    for (final finding in findings) {
      final path = finding.payload.anchor.filePath;
      if (path == null) {
        continue;
      }
      byFile.putIfAbsent(path, () => []).add(finding);
    }
    // Most severe first inside each file (p0 has the lowest enum index).
    for (final list in byFile.values) {
      list.sort(
        (a, b) => a.payload.priority.index.compareTo(b.payload.priority.index),
      );
    }
    return byFile;
  }

  String _renderFindingLine(ReviewFindingDraft finding) {
    final p = finding.payload;
    final conf = (p.confidence * 100).round();
    final fileNote = p.anchor.filePath != null
        ? ' (`${p.anchor.filePath}`)'
        : '';
    final summary = finding.content.trim().split('\n').first;
    return '- **${p.priority.name.toUpperCase()} · ${p.kind.name}** '
        '($conf%)$fileNote — $summary';
  }

  String _renderWalkthrough(ReviewWalkthroughSummary w) {
    final buf = StringBuffer()..writeln('## Summary');
    if (w.headline.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(w.headline);
    }
    for (final area in w.areas) {
      buf
        ..writeln()
        ..writeln('**${area.title}**')
        ..writeln();
      for (final bullet in area.bullets) {
        buf.writeln('- $bullet');
      }
    }
    if (w.riskNotes.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('**Risks**')
        ..writeln();
      for (final risk in w.riskNotes) {
        buf.writeln('- $risk');
      }
    }
    return buf.toString().trimRight();
  }

  String _renderVerdictBanner(ReviewVerdict v) {
    final pct = (v.confidence * 100).round();
    final tag = switch (v.overall) {
      ReviewVerdictOverall.ship => '✅ Ship',
      ReviewVerdictOverall.hold => '⏸️ Hold',
      ReviewVerdictOverall.block => '⛔ Block',
    };
    final explanation = v.explanation.trim().isEmpty
        ? ''
        : '\n\n${v.explanation.trim()}';
    return '## Verdict: $tag ($pct% confidence)$explanation\n\n'
        '**Counts** — P0: ${v.p0Count} · P1: ${v.p1Count} · '
        'P2: ${v.p2Count} · P3: ${v.p3Count}';
  }

  String _eventFor(
    ReviewVerdictOverall overall, {
    required bool approveOnShip,
  }) {
    switch (overall) {
      case ReviewVerdictOverall.block:
        return 'REQUEST_CHANGES';
      case ReviewVerdictOverall.hold:
        return 'COMMENT';
      case ReviewVerdictOverall.ship:
        return approveOnShip ? 'APPROVE' : 'COMMENT';
    }
  }
}
