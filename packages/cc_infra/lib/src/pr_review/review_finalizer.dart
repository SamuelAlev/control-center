import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_fingerprint.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:uuid/uuid.dart';

/// The outcome of a finalized review.
class ReviewFinalization {
  /// Creates a [ReviewFinalization].
  const ReviewFinalization({
    required this.summaryMessageId,
    required this.channelId,
    required this.reviewId,
    required this.verdict,
    required this.consensusReadyCount,
    required this.needsAdjudicationCount,
    this.delta,
  });

  /// The posted `review_summary` message id.
  final String summaryMessageId;

  /// The review channel the summary landed in.
  final String channelId;

  /// The association row id.
  final String reviewId;

  /// The authoritative verdict (findings escalated by axis results).
  final ReviewVerdict verdict;

  /// Findings with ≥1 peer confirmation (author excluded).
  final int consensusReadyCount;

  /// Findings awaiting a human or peer adjudication.
  final int needsAdjudicationCount;

  /// What moved since the previous finalized pass, when there was one.
  final FindingDelta? delta;
}

/// Deterministic review finalization shared by the `finalize_review` MCP tool
/// and the review hub: gathers every `review_node` message in the channel,
/// classifies consensus, computes the verdict (escalated by the studio axis
/// results), posts the `review_summary` message and transitions the
/// association to `awaiting_approval`.
///
/// The narrative [ReviewWalkthroughSummary], when supplied, is embedded in the
/// summary message metadata (and rendered into its markdown body) — the hub
/// flow authors it with an editorial agent pass before calling this; the MCP
/// tool path passes only the agent's free-form editorial note.
class ReviewFinalizer {
  /// Creates a [ReviewFinalizer].
  ReviewFinalizer({
    required MessagingRepository messaging,
    required ReviewChannelRepository reviewChannels,
    ReviewAxisResultRepository? reviewAxisResults,
    ReviewRunSnapshotRepository? runSnapshots,
    ComputeReviewVerdictUseCase? computeVerdict,
    FindingFingerprinter fingerprinter = const FindingFingerprinter(),
  }) : _messaging = messaging,
       _reviewChannels = reviewChannels,
       _reviewAxisResults = reviewAxisResults,
       _runSnapshots = runSnapshots,
       _fingerprinter = fingerprinter,
       _computeVerdict = computeVerdict ?? const ComputeReviewVerdictUseCase();

  final MessagingRepository _messaging;
  final ReviewChannelRepository _reviewChannels;

  /// The deterministic + token axis results (contract/visual/correctness/…)
  /// that the finding-based verdict is escalated against. Null → verdict comes
  /// from findings alone (the two engines aren't unified).
  final ReviewAxisResultRepository? _reviewAxisResults;

  /// Finalized-pass records. Null → each review is independent and reports no
  /// delta (the behavior before delta-aware re-review).
  final ReviewRunSnapshotRepository? _runSnapshots;
  final FindingFingerprinter _fingerprinter;
  final ComputeReviewVerdictUseCase _computeVerdict;

  /// Finalizes the review for [channelId]. See the class doc. Publishing to
  /// GitHub is NOT performed here — it stays a separate, deliberate step.
  Future<ReviewFinalization> finalize({
    required String workspaceId,
    required String channelId,
    required String finalizerId,
    String? editorialNote,
    ReviewWalkthroughSummary? walkthrough,
    String? headSha,
    Map<ReviewAxis, String> axisNotes = const {},
  }) async {
    final association = await _reviewChannels
        .watchByChannel(workspaceId, channelId)
        .first;
    if (association == null) {
      throw ArgumentError('Channel $channelId is not linked to a PR review.');
    }

    final messages = await _messaging.getMessages(workspaceId, channelId);
    final nodes = messages
        .where((m) => m.messageType == ChannelMessageType.reviewNode)
        .toList(growable: false);

    final consensusReady = <_ClassifiedNode>[];
    final needsAdjudication = <_ClassifiedNode>[];
    for (final node in nodes) {
      final payload = ReviewNodePayload.fromMetadata(node.metadata);
      if (payload == null) {
        continue;
      }
      // Defensive: drop the author from confirmedBy in case a buggy caller
      // wrote it in.
      final peers = payload.confirmedBy
          .where((id) => id != node.senderId)
          .toList(growable: false);
      final classified = _ClassifiedNode(
        message: node,
        payload: payload.copyWith(confirmedBy: peers),
      );
      if (peers.isNotEmpty &&
          payload.status != ReviewNodeStatus.dismissed &&
          payload.status != ReviewNodeStatus.resolved) {
        consensusReady.add(classified);
      } else if (payload.status != ReviewNodeStatus.dismissed) {
        needsAdjudication.add(classified);
      }
    }

    final openPayloads = [
      ...consensusReady.map((c) => c.payload),
      ...needsAdjudication
          .where((c) => c.payload.status != ReviewNodeStatus.resolved)
          .map((c) => c.payload),
    ];
    var verdict = _computeVerdict.execute(openPayloads);

    // Populate the token axes (correctness/security/testGap) from the findings,
    // then fold ALL axes — these plus the deterministic contract/visual axes
    // written by `review_studio.compute` — into ONE authoritative verdict.
    // `withAxisResults` only ever escalates (a gated failing axis can't be
    // out-voted by findings), so a clean axis set leaves the finding verdict
    // untouched. Studio rows key on the PR's real GitHub node id (migration 46),
    // which is exactly `association.prExternalId`.
    await _upsertTokenAxes(association, openPayloads, axisNotes);
    final axisResults = await _loadAxisResults(association);
    if (axisResults.isNotEmpty) {
      verdict = verdict.withAxisResults(axisResults);
    }

    // What moved since the previous pass. Computed over EVERY parsed finding,
    // not just the open ones, so a finding the author resolved between passes
    // is reported as resolved rather than silently vanishing.
    final allClassified = [...consensusReady, ...needsAdjudication];
    final currentFingerprints = [
      for (final c in allClassified) _fingerprintOf(c),
    ];
    final previous = await _latestSnapshot(association);
    final delta = previous == null
        ? null
        : _fingerprinter.classify(
            previous: previous.fingerprints,
            current: currentFingerprints,
          );

    final effectiveWalkthrough =
        walkthrough ?? const ReviewWalkthroughSummary(headline: '', areas: []);
    final summary = _renderSummary(
      verdict: verdict,
      consensusReady: consensusReady,
      needsAdjudication: needsAdjudication,
      editorialNote: editorialNote,
      walkthrough: effectiveWalkthrough.isAbsent ? null : effectiveWalkthrough,
      delta: delta,
      previousHeadSha: previous?.headSha,
    );

    final summaryId = const Uuid().v4();
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      channelId: channelId,
      content: summary,
      senderId: finalizerId,
      senderType: 'agent',
      messageType: 'review_summary',
      id: summaryId,
      metadata: {
        ...verdict.toMetadata(),
        if (!effectiveWalkthrough.isAbsent)
          ...effectiveWalkthrough.copyWith(headSha: headSha).toMetadata(),
        'consensusReadyCount': consensusReady.length,
        'needsAdjudicationCount': needsAdjudication.length,
        'consensusReadyMessageIds': consensusReady
            .map((c) => c.message.id)
            .toList(),
        'needsAdjudicationMessageIds': needsAdjudication
            .map((c) => c.message.id)
            .toList(),
        if (delta != null) 'deltaSinceLast': _deltaMetadata(delta, previous),
      },
    );

    await _reviewChannels.updateStatus(
      workspaceId,
      association.id,
      ReviewChannelStatus.awaitingApproval,
    );

    await _recordSnapshot(
      association: association,
      channelId: channelId,
      headSha: headSha,
      verdict: verdict,
      fingerprints: currentFingerprints,
      classified: allClassified,
      delta: delta,
    );

    return ReviewFinalization(
      summaryMessageId: summaryId,
      channelId: channelId,
      reviewId: association.id,
      verdict: verdict,
      consensusReadyCount: consensusReady.length,
      needsAdjudicationCount: needsAdjudication.length,
      delta: delta,
    );
  }

  /// The fingerprint of one classified finding.
  ///
  /// The title is the message's first line: a finding's body often runs to a
  /// paragraph of explanation, and the explanation is exactly the part that
  /// gets reworded between passes.
  FindingFingerprint _fingerprintOf(_ClassifiedNode node) {
    final title = _firstLine(node.message.content);
    final payload = node.payload;
    return FindingFingerprint(
      fingerprint: _fingerprinter.fingerprintOf(
        filePath: payload.anchor.filePath,
        kind: payload.kind,
        title: title,
        ruleId: payload.ruleId ?? '',
      ),
      messageId: node.message.id,
      title: title,
      filePath: payload.anchor.filePath,
      kind: payload.kind,
      priority: payload.priority,
      status: payload.status,
      provenance: payload.provenance.wireName,
      ruleId: payload.ruleId ?? '',
    );
  }

  String _firstLine(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final newline = trimmed.indexOf('\n');
    final line = newline < 0 ? trimmed : trimmed.substring(0, newline);
    // Findings are commonly written as a markdown heading or bullet.
    return line.replaceFirst(RegExp(r'^[#>\-*\s]+'), '').trim();
  }

  Map<String, dynamic> _deltaMetadata(
    FindingDelta delta,
    ReviewRunSnapshot? previous,
  ) => {
    if (previous?.headSha != null) 'previousHeadSha': previous!.headSha,
    'resolved': delta.resolvedSinceLast.length,
    'new': delta.newFindings.length,
    'stillOpen': delta.stillOpen.length,
    'newMessageIds': delta.newMessageIds.toList(),
    'stillOpenMessageIds': delta.stillOpenMessageIds.toList(),
  };

  Future<ReviewRunSnapshot?> _latestSnapshot(
    ReviewChannelAssociation association,
  ) async {
    final repo = _runSnapshots;
    final key = _studioKey(association);
    if (repo == null || key == null) {
      return null;
    }
    return repo.latestForPr(association.workspaceId, key);
  }

  /// Records this pass so the NEXT one can report its delta.
  ///
  /// Failure here must not fail the review: the summary is already posted and
  /// the association already transitioned, so throwing would lose a completed
  /// review to lose a bookkeeping row.
  Future<void> _recordSnapshot({
    required ReviewChannelAssociation association,
    required String channelId,
    required String? headSha,
    required ReviewVerdict verdict,
    required List<FindingFingerprint> fingerprints,
    required List<_ClassifiedNode> classified,
    required FindingDelta? delta,
  }) async {
    final repo = _runSnapshots;
    final key = _studioKey(association);
    if (repo == null || key == null) {
      return;
    }
    final resolved = classified
        .where((c) => c.payload.status == ReviewNodeStatus.resolved)
        .length;
    final dismissed = classified
        .where((c) => c.payload.status == ReviewNodeStatus.dismissed)
        .length;
    try {
      await repo.record(
        association.workspaceId,
        ReviewRunSnapshot(
          id: const Uuid().v4(),
          workspaceId: association.workspaceId,
          prExternalId: key,
          channelId: channelId,
          finalizedAt: DateTime.now(),
          headSha: headSha,
          verdict: verdict,
          fingerprints: fingerprints,
          stats: ReviewRunStats(
            findingsTotal: fingerprints.length,
            resolved: resolved,
            dismissed: dismissed,
            stillOpen: fingerprints.where((f) => f.isOpen).length,
            newCount: delta?.newFindings.length ?? fingerprints.length,
          ),
        ),
      );
    } catch (_) {
      // Bookkeeping only — the review itself already succeeded.
    }
  }

  /// Renders what moved since the previous pass.
  ///
  /// Named findings rather than bare counts: "2 new" tells a reviewer they
  /// have work but not where, and the whole point of the delta is to send them
  /// straight to the part they have not read.
  String _renderDelta(FindingDelta delta, String? previousHeadSha) {
    final buf = StringBuffer()..writeln('## Since last review');
    final since = previousHeadSha == null || previousHeadSha.isEmpty
        ? ''
        : ' (previously reviewed at `${_shortSha(previousHeadSha)}`)';
    buf
      ..writeln()
      ..writeln(
        '${delta.resolvedSinceLast.length} resolved · '
        '${delta.newFindings.length} new · '
        '${delta.stillOpen.length} still open$since',
      );
    if (delta.newFindings.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('**New in this pass**');
      for (final f in delta.newFindings.take(10)) {
        buf.writeln('- ${_findingLine(f)}');
      }
    }
    if (delta.stillOpen.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('**Still open from the previous pass**');
      for (final m in delta.stillOpen.take(10)) {
        buf.writeln('- ${_findingLine(m.current)}');
      }
    }
    return buf.toString();
  }

  String _findingLine(FindingFingerprint f) {
    final where = f.filePath == null ? '' : ' — `${f.filePath}`';
    final title = f.title.isEmpty ? '(untitled finding)' : f.title;
    return '[${f.priority.wireName.toUpperCase()}] $title$where';
  }

  String _shortSha(String sha) => sha.length <= 7 ? sha : sha.substring(0, 7);

  /// The review-studio key for [association] — the PR's real GitHub node id,
  /// which the studio tables now key on too (migration 46), so the association's
  /// own `prExternalId` addresses its axis rows directly. Null when unset.
  String? _studioKey(ReviewChannelAssociation association) {
    final key = association.prExternalId;
    return key.isEmpty ? null : key;
  }

  /// Loads the PR's axis results (contract/visual/correctness/security/…) from
  /// the review-studio store. Returns empty when no axis repository is wired or
  /// the key can't be derived.
  Future<List<ReviewAxisResult>> _loadAxisResults(
    ReviewChannelAssociation association,
  ) async {
    final repo = _reviewAxisResults;
    final key = _studioKey(association);
    if (repo == null || key == null) {
      return const [];
    }
    return repo.forPr(association.workspaceId, key);
  }

  /// Derives the three token axes (correctness/security/testGap) from the open
  /// findings and upserts them so the review dashboard shows all six axes from
  /// both engines. Token axes are advisory (`gated: false`) — the finding
  /// priorities already drive the verdict, so they must not double-count.
  Future<void> _upsertTokenAxes(
    ReviewChannelAssociation association,
    List<ReviewNodePayload> openPayloads,
    Map<ReviewAxis, String> axisNotes,
  ) async {
    final repo = _reviewAxisResults;
    final key = _studioKey(association);
    if (repo == null || key == null) {
      return;
    }
    const tokenAxes = [
      ReviewAxis.correctness,
      ReviewAxis.security,
      ReviewAxis.testGap,
    ];
    for (final axis in tokenAxes) {
      final forAxis = openPayloads
          .where((p) => p.axis == axis)
          .toList(growable: false);
      if (forAxis.isEmpty) {
        // No findings on this axis, but an external signal (a failing CI job,
        // say) may still have something to say about it. Never invent a
        // verdict here — that is the deterministic pass's job — only attach
        // the note to whatever row already exists.
        final note = axisNotes[axis];
        if (note != null && note.isNotEmpty) {
          final existing = await repo.forPr(association.workspaceId, key);
          for (final row in existing) {
            if (row.axis != axis) {
              continue;
            }
            await repo.upsert(
              association.workspaceId,
              key,
              row.copyWith(note: _mergeNote(row.note, note)),
            );
            break;
          }
        }
        continue;
      }
      final hasP0 = forAxis.any((p) => p.priority == ReviewNodePriority.p0);
      final hasP1 = forAxis.any((p) => p.priority == ReviewNodePriority.p1);
      final avgConfidence =
          forAxis.map((p) => p.confidence).reduce((a, b) => a + b) /
          forAxis.length;
      await repo.upsert(
        association.workspaceId,
        key,
        ReviewAxisResult(
          axis: axis,
          verdict: hasP0
              ? ReviewAxisVerdict.fail
              : (hasP1 ? ReviewAxisVerdict.warn : ReviewAxisVerdict.pass),
          findingsCount: forAxis.length,
          // Advisory: the finding priorities already drive the verdict, so
          // token axes surface in the dashboard without re-gating it.
          gated: false,
          confidence: avgConfidence,
          note: axisNotes[axis] ?? '',
        ),
      );
    }
  }

  String _mergeNote(String existing, String addition) {
    if (existing.isEmpty) {
      return addition;
    }
    if (existing.contains(addition)) {
      return existing;
    }
    return '$existing; $addition';
  }

  String _renderSummary({
    required ReviewVerdict verdict,
    required List<_ClassifiedNode> consensusReady,
    required List<_ClassifiedNode> needsAdjudication,
    String? editorialNote,
    ReviewWalkthroughSummary? walkthrough,
    FindingDelta? delta,
    String? previousHeadSha,
  }) {
    final buf = StringBuffer();
    buf.writeln('# Review summary');
    buf
      ..writeln()
      ..writeln(_renderVerdictBanner(verdict));
    if (delta != null && !delta.isEmpty) {
      buf
        ..writeln()
        ..writeln(_renderDelta(delta, previousHeadSha));
    }
    if (walkthrough != null) {
      buf
        ..writeln()
        ..writeln(_renderWalkthrough(walkthrough));
    }
    if (verdict.axisResults.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(_renderAxes(verdict));
    }
    if (editorialNote != null && editorialNote.trim().isNotEmpty) {
      buf
        ..writeln()
        ..writeln(editorialNote.trim());
    }
    buf
      ..writeln()
      ..writeln('## Consensus-ready (${consensusReady.length})');
    if (consensusReady.isEmpty) {
      buf.writeln('_None._');
    } else {
      for (final c in consensusReady) {
        buf.writeln(_renderNodeLine(c));
      }
    }
    buf
      ..writeln()
      ..writeln('## Needs adjudication (${needsAdjudication.length})');
    if (needsAdjudication.isEmpty) {
      buf.writeln('_None._');
    } else {
      for (final c in needsAdjudication) {
        buf.writeln(_renderNodeLine(c));
      }
    }
    return buf.toString();
  }

  String _renderWalkthrough(ReviewWalkthroughSummary w) {
    final buf = StringBuffer()..writeln('## Walkthrough');
    if (w.headline.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(w.headline);
    }
    for (final area in w.areas) {
      buf
        ..writeln()
        ..writeln('### ${area.title}');
      for (final bullet in area.bullets) {
        buf.writeln('- $bullet');
      }
    }
    if (w.riskNotes.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('### Risks');
      for (final risk in w.riskNotes) {
        buf.writeln('- $risk');
      }
    }
    return buf.toString().trimRight();
  }

  String _renderVerdictBanner(ReviewVerdict v) {
    final pct = (v.confidence * 100).round();
    final tag = switch (v.overall) {
      ReviewVerdictOverall.ship => 'SHIP',
      ReviewVerdictOverall.hold => 'HOLD',
      ReviewVerdictOverall.block => 'BLOCK',
    };
    return '## Verdict: $tag ($pct% confidence)\n\n${v.explanation}\n\n'
        '**Counts** — P0: ${v.p0Count} · P1: ${v.p1Count} · P2: ${v.p2Count} '
        '· P3: ${v.p3Count}';
  }

  String _renderAxes(ReviewVerdict v) {
    final buf = StringBuffer()..writeln('## Axes');
    for (final a in v.axisResults) {
      final gate = a.blocks ? ' — **blocking**' : (a.gated ? ' (gated)' : '');
      buf.writeln(
        '- **${a.axis.wireName}**: ${a.verdict.name}'
        '${a.findingsCount > 0 ? ' · ${a.findingsCount} finding(s)' : ''}'
        '$gate',
      );
    }
    return buf.toString().trimRight();
  }

  String _renderNodeLine(_ClassifiedNode c) {
    final p = c.payload;
    final anchor = p.anchor.filePath != null
        ? ' (`${p.anchor.filePath}${p.anchor.lineNumber != null ? ':${p.anchor.lineNumber}' : ''}`)'
        : '';
    final summary = c.message.content.split('\n').first;
    final conf = (p.confidence * 100).round();
    return '- **${p.kind.name}** · ${p.priority.name.toUpperCase()} '
        '($conf%) $summary$anchor';
  }
}

class _ClassifiedNode {
  _ClassifiedNode({required this.message, required this.payload});

  final ChannelMessage message;
  final ReviewNodePayload payload;
}
