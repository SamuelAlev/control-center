import 'package:cc_domain/features/pr_review/domain/services/diff_anchor_index.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';

/// A review finding ready to be turned into GitHub output: its structured
/// [payload] (kind / priority / confidence / anchor) plus the human-readable
/// [content] the reviewer wrote.
class ReviewFindingDraft {
  /// Creates a [ReviewFindingDraft].
  const ReviewFindingDraft({
    required this.payload,
    required this.content,
    this.messageId,
  });

  /// Structured metadata for the finding.
  final ReviewNodePayload payload;

  /// Markdown body the reviewer authored.
  final String content;

  /// The `review_node` message this finding came from, when known.
  ///
  /// Carried so the publisher can match the finalizer's demotion set: the two
  /// surfaces must collapse the same findings, and matching on rendered text
  /// is how they would drift apart.
  final String? messageId;
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
  /// narrative summary + per-area sections at the top of the body.
  ///
  /// [nitpickMessageIds] names the findings the review level demoted. They are
  /// kept out of the inline comments — an inline comment is the most intrusive
  /// thing a review can do to a diff — and rendered in a collapsed group in the
  /// body instead. Nothing is dropped: a demoted finding is still published,
  /// still counted and still one click from being read.
  ///
  /// [anchors] is the set of lines the pull request's current diff actually
  /// touches. Findings that fall outside it are moved out of the inline
  /// comments and into the body — they may still be true, but a comment on
  /// code this PR did not change is a comment on the wrong pull request.
  /// Defaults to [DiffAnchorIndex.permissive] so a caller that could not fetch
  /// the diff publishes everything rather than nothing.
  GitHubReviewPlan execute({
    required List<ReviewFindingDraft> findings,
    required ReviewVerdict verdict,
    ReviewWalkthroughSummary? walkthrough,
    bool approveOnShip = false,
    Set<String> nitpickMessageIds = const {},
    DiffAnchorIndex anchors = DiffAnchorIndex.permissive,
  }) {
    final inline = <GitHubInlineComment>[];
    final unanchored = <ReviewFindingDraft>[];
    final nitpicks = <ReviewFindingDraft>[];
    final promoted = <ReviewFindingDraft>[];

    for (final finding in findings) {
      final id = finding.messageId;
      if (id != null && nitpickMessageIds.contains(id)) {
        nitpicks.add(finding);
        continue;
      }
      promoted.add(finding);
      final anchor = finding.payload.anchor;
      // Anchored AND still on changed code. The second half is checked against
      // the diff as it stands right now, which is both the admission test
      // ("tied to the changed code") and the re-verification against head: a
      // finding about a line the author has since rewritten is the most
      // trust-destroying comment a reviewer can leave, and GitHub would reject
      // it at submit time anyway.
      final placeable =
          anchor.filePath != null &&
          anchor.lineNumber != null &&
          anchors.admits(
            anchor.filePath!,
            anchor.lineNumber,
            lineEnd: anchor.lineEnd,
          );
      if (placeable) {
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
        findings: promoted,
        nitpicks: nitpicks,
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

  /// One finding, rendered for GitHub.
  ///
  /// The shape is deliberate. A triage line first (what it is about, how much
  /// it matters, what it costs) so a reader can decide in one glance whether to
  /// read on; then the reviewer's own prose, whose first line is the imperative
  /// title; then the optional fix and agent prompt, both collapsed, because a
  /// diff and a paragraph of instructions inline would bury the sentence that
  /// explains why any of it is needed.
  String _renderFindingBody(ReviewFindingDraft finding) {
    final p = finding.payload;
    final conf = (p.confidence * 100).round();
    final buf = StringBuffer()
      ..writeln(_labelLine(p))
      ..writeln()
      ..writeln(finding.content.trim());

    final fix = p.fixDiff;
    if (fix != null) {
      buf
        ..writeln()
        ..writeln('<details>')
        ..writeln('<summary>Proposed fix</summary>')
        ..writeln()
        ..writeln('```diff')
        ..writeln(_stripFence(fix))
        ..writeln('```')
        ..writeln()
        ..writeln('</details>');
    }

    final prompt = p.aiPrompt;
    if (prompt != null) {
      buf
        ..writeln()
        ..writeln('<details>')
        ..writeln('<summary>Prompt for AI agents</summary>')
        ..writeln()
        ..writeln('```')
        ..writeln(kAiAgentPromptGuardPreamble)
        ..writeln()
        ..writeln(_promptLocation(p))
        ..writeln(prompt.trim())
        ..writeln('```')
        ..writeln()
        ..writeln('</details>');
    }

    // The committable suggestion goes LAST, after the collapsed blocks, so the
    // comment reads as prose first and a patch second. GitHub renders it with
    // a "Commit suggestion" button, which is why it is only ever the
    // reviewer's own exact replacement lines and never something we derived.
    final suggestion = p.fixSuggestion;
    if (suggestion != null) {
      buf
        ..writeln()
        ..writeln('```suggestion')
        ..writeln(_stripFence(suggestion))
        ..writeln('```');
    }

    buf
      ..writeln()
      ..writeln('$conf% confidence · $inlineFooter')
      // Machine-readable, invisible to a reader. Recorded so the review's own
      // history can be mined later for how well-calibrated these scores are —
      // which is the only way to tune the gate on evidence rather than taste.
      ..writeln(
        '<!-- cc-review: confidence=${p.confidence.toStringAsFixed(2)}'
        '${p.category != null ? ' category=${p.category!.wireName}' : ''}'
        ' severity=${p.effectiveSeverity.wireName} -->',
      );
    return buf.toString().trimRight();
  }

  /// The three-axis triage line. Severity always renders (every finding has
  /// one, falling back to the priority mapping); category and effort only when
  /// the reviewer supplied them, so a legacy finding reads as it always did.
  String _labelLine(ReviewNodePayload p) {
    final parts = <String>[
      if (p.category != null) _categoryLabel(p.category!),
      _severityLabel(p.effectiveSeverity),
      if (p.effort != null) _effortLabel(p.effort!),
    ];
    return parts.map((s) => '_${s}_').join(' | ');
  }

  /// Where the agent should look. Named separately from the reviewer's prompt
  /// so the file and line come from the anchor we stored rather than from
  /// whatever the model remembered to type.
  String _promptLocation(ReviewNodePayload p) {
    final path = p.anchor.filePath;
    if (path == null) {
      return '';
    }
    final start = p.anchor.lineNumber;
    final end = p.anchor.lineEnd;
    final where = start == null
        ? ''
        : (end != null && end > start
              ? ' around lines $start-$end'
              : ' around line $start');
    return 'In `$path`$where:\n';
  }

  /// Strips an outer code fence if the reviewer wrapped the diff in one — it
  /// is about to be placed inside a fence of ours, and a nested fence closes
  /// the block early and spills raw markdown into the comment.
  String _stripFence(String raw) {
    final lines = raw.trim().split('\n');
    if (lines.length >= 2 &&
        lines.first.trimLeft().startsWith('```') &&
        lines.last.trim() == '```') {
      return lines.sublist(1, lines.length - 1).join('\n');
    }
    return raw.trim();
  }

  static String _categoryLabel(ReviewFindingCategory c) => switch (c) {
    ReviewFindingCategory.security => '🔒 Security',
    ReviewFindingCategory.stability => '🩺 Stability',
    ReviewFindingCategory.dataIntegrity => '🗄️ Data integrity',
    ReviewFindingCategory.correctness => '🎯 Correctness',
    ReviewFindingCategory.performance => '🚀 Performance',
    ReviewFindingCategory.maintainability => '📐 Maintainability',
  };

  // Shape as well as colour: the emoji differ from each other by more than
  // hue, so the severity survives a monochrome render and a colour-blind
  // reader.
  static String _severityLabel(ReviewFindingSeverity s) => switch (s) {
    ReviewFindingSeverity.critical => '🔴 Critical',
    ReviewFindingSeverity.major => '🟠 Major',
    ReviewFindingSeverity.minor => '🟡 Minor',
    ReviewFindingSeverity.trivial => '🔵 Trivial',
    ReviewFindingSeverity.info => '⚪ Info',
  };

  static String _effortLabel(ReviewFindingEffort e) => switch (e) {
    ReviewFindingEffort.quickWin => '⚡ Quick win',
    ReviewFindingEffort.moderate => '🔧 Moderate',
    ReviewFindingEffort.heavyLift => '🏗️ Heavy lift',
  };

  String _renderBody({
    required ReviewVerdict verdict,
    required List<ReviewFindingDraft> unanchored,
    required List<ReviewFindingDraft> findings,
    required List<ReviewFindingDraft> nitpicks,
    ReviewWalkthroughSummary? walkthrough,
  }) {
    // A review that found nothing is one line.
    //
    // This body is read in a PR timeline, not in the app. A reader who opens a
    // clean review and has to scroll a verdict banner and two empty sections
    // to learn nothing was found learns instead to stop opening them. The full
    // structure — walkthrough, area table, axes — stays on the review tab,
    // which is a reading surface and can afford it.
    //
    // Only when the verdict actually clears, though: a hold or a block with no
    // findings comes from a failing gate, and "no issues found" over the top of
    // a blocked pull request is the one shortening that would be a lie.
    if (findings.isEmpty &&
        nitpicks.isEmpty &&
        verdict.overall == ReviewVerdictOverall.ship) {
      return '**No issues found.**\n\n_${inlineFooter}_';
    }

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
    if (nitpicks.isNotEmpty) {
      // Collapsed, counted, and carrying each finding in full — the review
      // level decides what is worth interrupting a reader with, not what is
      // worth telling them.
      buf
        ..writeln()
        ..writeln('<details>')
        ..writeln('<summary>Nitpicks (${nitpicks.length})</summary>')
        ..writeln();
      for (final finding in nitpicks) {
        final path = finding.payload.anchor.filePath;
        final line = finding.payload.anchor.lineNumber;
        final where = path == null
            ? ''
            : ' `$path${line != null ? ':$line' : ''}`';
        buf
          ..writeln(
            '**${_severityLabel(finding.payload.effectiveSeverity)}**'
            '$where',
          )
          ..writeln()
          ..writeln(finding.content.trim())
          ..writeln();
      }
      buf.writeln('</details>');
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
    // Severity, not the P-tag: the published review speaks ONE vocabulary
    // throughout (banner, listing, inline label), and P0-P3 is the app's
    // internal verdict scale that means nothing to a reader on GitHub.
    return '- **${_severityLabel(p.effectiveSeverity)} · ${p.kind.name}** '
        '($conf%)$fileNote — $summary';
  }

  String _renderWalkthrough(ReviewWalkthroughSummary w) {
    final buf = StringBuffer()..writeln('## Summary');
    if (w.headline.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(w.headline);
    }
    if (w.effortScore != null) {
      buf
        ..writeln()
        ..writeln(
          '**Estimated review effort** — ${w.effortScore}'
          '${w.effortMinutes != null ? ' · ~${w.effortMinutes} min' : ''}',
        );
    }
    // Deliberately NO files-by-concern table here. GitHub already shows the
    // changed files directly above this comment, in a view built for it; a
    // second copy in prose is the kind of restatement that makes a bot's
    // output feel like filler. The table stays on the review tab, where the
    // reader has no file list of their own.
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
    // Named by severity rather than P0-P3 for the same reason the finding
    // lines are: this document is read on GitHub, where the app's internal
    // priority scale is undefined jargon. The numbers are the same counts.
    return '## Verdict: $tag ($pct% confidence)$explanation\n\n'
        '**Counts** — Critical: ${v.p0Count} · Major: ${v.p1Count} · '
        'Minor: ${v.p2Count} · Trivial: ${v.p3Count}';
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
