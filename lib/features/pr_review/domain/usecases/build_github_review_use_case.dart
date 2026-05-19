import 'package:control_center/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_verdict.dart';

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
/// into a [GitHubReviewPlan]: an event, a summary body, and line-anchored
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
  GitHubReviewPlan execute({
    required List<ReviewFindingDraft> findings,
    required ReviewVerdict verdict,
    bool approveOnShip = false,
  }) {
    final inline = <GitHubInlineComment>[];
    final unanchored = <ReviewFindingDraft>[];

    for (final finding in findings) {
      final anchor = finding.payload.anchor;
      if (anchor.filePath != null && anchor.lineNumber != null) {
        inline.add(_toInlineComment(finding, anchor.filePath!, anchor.lineNumber!));
      } else {
        unanchored.add(finding);
      }
    }

    return GitHubReviewPlan(
      event: _eventFor(verdict.overall, approveOnShip: approveOnShip),
      body: _renderBody(verdict: verdict, unanchored: unanchored),
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
    final header = '**[${p.priority.name.toUpperCase()}] ${p.kind.name}** '
        '· $conf% confidence';
    return '$header\n\n${finding.content.trim()}\n\n$inlineFooter';
  }

  String _renderBody({
    required ReviewVerdict verdict,
    required List<ReviewFindingDraft> unanchored,
  }) {
    final buf = StringBuffer()
      ..writeln(_renderVerdictBanner(verdict));
    if (unanchored.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('## Findings not tied to a line (${unanchored.length})')
        ..writeln();
      for (final finding in unanchored) {
        final p = finding.payload;
        final conf = (p.confidence * 100).round();
        final fileNote = p.anchor.filePath != null
            ? ' (`${p.anchor.filePath}`)'
            : '';
        final summary = finding.content.trim().split('\n').first;
        buf.writeln(
          '- **${p.priority.name.toUpperCase()} · ${p.kind.name}** '
          '($conf%)$fileNote — $summary',
        );
      }
    }
    buf
      ..writeln()
      ..writeln('_${inlineFooter}_');
    return buf.toString().trimRight();
  }

  String _renderVerdictBanner(ReviewVerdict v) {
    final pct = (v.confidence * 100).round();
    final tag = switch (v.overall) {
      ReviewVerdictOverall.ship => '✅ Ship',
      ReviewVerdictOverall.hold => '⏸️ Hold',
      ReviewVerdictOverall.block => '⛔ Block',
    };
    final explanation =
        v.explanation.trim().isEmpty ? '' : '\n\n${v.explanation.trim()}';
    return '## Verdict: $tag ($pct% confidence)$explanation\n\n'
        '**Counts** — P0: ${v.p0Count} · P1: ${v.p1Count} · '
        'P2: ${v.p2Count} · P3: ${v.p3Count}';
  }

  String _eventFor(ReviewVerdictOverall overall, {required bool approveOnShip}) {
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
