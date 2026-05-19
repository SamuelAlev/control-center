import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_fingerprint.dart';
import 'package:cc_domain/features/pr_review/domain/services/review_suppression_matcher.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/estimate_review_effort_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
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
    required this.spaceId,
    required this.reviewId,
    required this.verdict,
    required this.consensusReadyCount,
    required this.needsAdjudicationCount,
    this.delta,
    this.nitpickMessageIds = const [],
  });

  /// The posted `review_summary` message id.
  final String summaryMessageId;

  /// The review space the summary landed in.
  final String spaceId;

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

  /// Message ids of the findings this level demoted into the nitpick group.
  ///
  /// A subset of the counted findings, not a removal from them: the publisher
  /// reads this to decide what to collapse, and a reader can always expand it.
  final List<String> nitpickMessageIds;
}

/// Deterministic review finalization shared by the `finalize_review` MCP tool
/// and the review hub: gathers every `review_node` message in the space,
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
    required ReviewSpaceRepository reviewSpaces,
    ReviewAxisResultRepository? reviewAxisResults,
    ReviewRunSnapshotRepository? runSnapshots,
    ReviewCohortRepository? reviewCohorts,
    ReviewSuppressionMatcher? suppressionMatcher,
    ComputeReviewVerdictUseCase? computeVerdict,
    FindingFingerprinter fingerprinter = const FindingFingerprinter(),
    EstimateReviewEffortUseCase estimateEffort =
        const EstimateReviewEffortUseCase(),
  }) : _messaging = messaging,
       _reviewSpaces = reviewSpaces,
       _reviewAxisResults = reviewAxisResults,
       _runSnapshots = runSnapshots,
       _reviewCohorts = reviewCohorts,
       _suppressionMatcher = suppressionMatcher,
       _fingerprinter = fingerprinter,
       _estimateEffort = estimateEffort,
       _computeVerdict = computeVerdict ?? const ComputeReviewVerdictUseCase();

  final MessagingRepository _messaging;
  final ReviewSpaceRepository _reviewSpaces;

  /// The deterministic + token axis results (contract/visual/correctness/…)
  /// that the finding-based verdict is escalated against. Null → verdict comes
  /// from findings alone (the two engines aren't unified).
  final ReviewAxisResultRepository? _reviewAxisResults;

  /// Finalized-pass records. Null → each review is independent and reports no
  /// delta (the behavior before delta-aware re-review).
  final ReviewRunSnapshotRepository? _runSnapshots;

  /// The PR's semantic cohorts, which give the walkthrough its
  /// files-by-concern table. Null → the walkthrough renders without it.
  final ReviewCohortRepository? _reviewCohorts;

  /// Matches candidate findings against what this workspace has already
  /// dismissed. Null → nothing is suppressed, which is what happened before
  /// the loop was closed.
  final ReviewSuppressionMatcher? _suppressionMatcher;

  final FindingFingerprinter _fingerprinter;
  final EstimateReviewEffortUseCase _estimateEffort;
  final ComputeReviewVerdictUseCase _computeVerdict;

  /// Finalizes the review for [spaceId]. See the class doc. Publishing to
  /// GitHub is NOT performed here — it stays a separate, deliberate step.
  ///
  /// [conversationId] is the stream the `review_summary` posts into — the
  /// pipeline's consolidate conversation, resolved by the caller by title.
  /// Null (the `finalize_review` MCP tool path, or a space the pipeline never
  /// ran in) falls back to the space's standing conversation.
  Future<ReviewFinalization> finalize({
    required String workspaceId,
    required String spaceId,
    required String finalizerId,
    String? editorialNote,
    ReviewWalkthroughSummary? walkthrough,
    String? headSha,
    Map<ReviewAxis, String> axisNotes = const {},
    ReviewLevel level = ReviewLevel.balanced,
    String? conversationId,
  }) async {
    final association = await _reviewSpaces
        .watchBySpace(workspaceId, spaceId)
        .first;
    if (association == null) {
      throw ArgumentError('Channel $spaceId is not linked to a PR review.');
    }

    // Space-wide, not the standing conversation: each reviewer files its
    // findings in its own stream, and a verdict computed from one thread's
    // findings would silently be a verdict on one reviewer.
    final messages = await _messaging.getSpaceMessages(workspaceId, spaceId);
    final nodes = messages
        .where((m) => m.messageType == MessageType.reviewNode)
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

    // Demote what this level reports quietly. Demotion is a rendering
    // decision, never a deletion: the findings stay filed, stay counted and
    // stay in the verdict inputs, and the group they move into is labelled
    // with its own count so a reader can see what was set aside. Critical and
    // major are exempt at every level (see [ReviewLevelProfile.nitpickFloor]),
    // which is what keeps a reporting dial from changing whether a PR ships.
    final profile = level.profile;
    final allClassifiedNodes = [...consensusReady, ...needsAdjudication];
    final suppressedIds = await _suppressedIds(association, allClassifiedNodes);
    final nitpickIds = <String>{
      ...suppressedIds,
      for (final c in [...consensusReady, ...needsAdjudication])
        if (profile.demotes(
          c.payload.effectiveSeverity,
          confidence: c.payload.confidence,
        ))
          c.message.id,
      // Findings a peer reviewer already reported for the same lines. The
      // fan-out gives several reviewers overlapping remits on purpose, so the
      // same defect arriving twice is expected — publishing it twice is not.
      ..._duplicateIds([...consensusReady, ...needsAdjudication]),
    };

    final cohorts = await _loadCohorts(association);
    final effort = _estimateEffort(
      fileCount: cohorts.expand((c) => c.filePaths).toSet().length,
      areaCount: cohorts.length,
      findings: openPayloads,
    );

    final effectiveWalkthrough =
        (walkthrough ?? const ReviewWalkthroughSummary(headline: '', areas: []))
            .copyWith(
              effortScore: effort.score,
              effortMinutes: effort.minutes,
              areas: _mergeCohortFiles(walkthrough?.areas ?? const [], cohorts),
            );
    final summary = _renderSummary(
      verdict: verdict,
      consensusReady: consensusReady,
      needsAdjudication: needsAdjudication,
      editorialNote: editorialNote,
      walkthrough: effectiveWalkthrough.isAbsent ? null : effectiveWalkthrough,
      delta: delta,
      previousHeadSha: previous?.headSha,
      nitpickIds: nitpickIds,
      effort: effort,
    );

    final summaryId = const Uuid().v4();
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: summary,
      senderId: finalizerId,
      senderType: 'agent',
      messageType: 'review_summary',
      id: summaryId,
      metadata: {
        ...verdict.toMetadata(),
        if (!effectiveWalkthrough.isAbsent)
          ...effectiveWalkthrough.copyWith(headSha: headSha).toMetadata(),
        // Stamped whether or not a narrative walkthrough was authored: the
        // estimate is computed from the diff and the findings, so it exists
        // for every review, and the summary body already prints it.
        'summaryEffortScore': effort.score,
        'summaryEffortMinutes': effort.minutes,
        // The commit this review read. Not decoration and not part of the
        // narrative: it is the review's identity, and it is the only thing
        // that lets a reader — or the UI — tell a current review from one
        // about code the author has since replaced.
        if (headSha != null && headSha.isNotEmpty) 'summaryHeadSha': headSha,
        'consensusReadyCount': consensusReady.length,
        'needsAdjudicationCount': needsAdjudication.length,
        'consensusReadyMessageIds': consensusReady
            .map((c) => c.message.id)
            .toList(),
        'needsAdjudicationMessageIds': needsAdjudication
            .map((c) => c.message.id)
            .toList(),
        // The level this pass ran at, and what it demoted. The publisher reads
        // both so the GitHub review collapses exactly what the app collapsed —
        // two surfaces disagreeing about which findings matter is worse than
        // either choice on its own.
        'reviewLevel': level.wireName,
        if (nitpickIds.isNotEmpty) 'nitpickMessageIds': nitpickIds.toList(),
        if (delta != null) 'deltaSinceLast': _deltaMetadata(delta, previous),
      },
    );

    await _reviewSpaces.updateStatus(
      workspaceId,
      association.id,
      ReviewSpaceStatus.awaitingApproval,
    );

    await _recordSnapshot(
      association: association,
      spaceId: spaceId,
      headSha: headSha,
      verdict: verdict,
      fingerprints: currentFingerprints,
      classified: allClassified,
      delta: delta,
    );

    return ReviewFinalization(
      summaryMessageId: summaryId,
      spaceId: spaceId,
      reviewId: association.id,
      verdict: verdict,
      consensusReadyCount: consensusReady.length,
      needsAdjudicationCount: needsAdjudication.length,
      delta: delta,
      nitpickMessageIds: nitpickIds.toList(),
    );
  }

  /// The message ids of findings this workspace has already told us it does
  /// not want to hear again.
  ///
  /// Never throws and never blocks the review: without an embedder, without a
  /// snapshot store, or on any failure, it suppresses nothing. Degrading
  /// toward "report it" is the only safe direction — the opposite turns a
  /// missing model into a reviewer that silently finds nothing.
  Future<Set<String>> _suppressedIds(
    ReviewSpaceAssociation association,
    List<_ClassifiedNode> nodes,
  ) async {
    final matcher = _suppressionMatcher;
    final snapshots = _runSnapshots;
    if (matcher == null || snapshots == null || nodes.isEmpty) {
      return const {};
    }
    try {
      final dismissed = await snapshots.dismissedFindingTitles(
        association.workspaceId,
      );
      if (dismissed.isEmpty) {
        return const {};
      }
      final candidates = [
        for (final n in nodes)
          ReviewSuppressionCandidate(
            title: _firstLine(n.message.content),
            severity: n.payload.effectiveSeverity,
          ),
      ];
      final hits = await matcher.suppressed(
        candidates: candidates,
        dismissedTitles: dismissed,
      );
      return {for (final i in hits) nodes[i].message.id};
    } on Object catch (_) {
      return const {};
    }
  }

  /// The message ids of findings that duplicate a stronger one on the same
  /// lines, so only the strongest of a cluster is reported up front.
  ///
  /// Several reviewers are pointed at one diff with deliberately overlapping
  /// remits, so the same defect reaching the finalizer three times is the
  /// system working. Publishing it three times is the system leaking its own
  /// architecture into the reader's inbox.
  ///
  /// Two findings collide when they anchor to the same file with overlapping
  /// line ranges. The survivor is the most severe, then the most confident,
  /// then the longest-standing — deterministic on every axis, because a dedup
  /// that picks a different winner per run makes a re-review look like it
  /// found something new.
  Set<String> _duplicateIds(List<_ClassifiedNode> nodes) {
    // Both a file AND a line are required. Two findings that name only a file
    // share no position to compare, and collapsing them would silently merge
    // two unrelated file-level observations into one.
    final anchored = nodes
        .where(
          (n) =>
              n.payload.anchor.filePath != null &&
              n.payload.anchor.lineNumber != null,
        )
        .toList(growable: false);
    final byPath = <String, List<_ClassifiedNode>>{};
    for (final n in anchored) {
      byPath.putIfAbsent(n.payload.anchor.filePath!, () => []).add(n);
    }

    final duplicates = <String>{};
    for (final group in byPath.values) {
      final clusters = <List<_ClassifiedNode>>[];
      for (final node in group) {
        List<_ClassifiedNode>? hit;
        for (final cluster in clusters) {
          final collides = cluster.any(
            (other) => _overlaps(node.payload, other.payload),
          );
          if (collides) {
            hit = cluster;
            break;
          }
        }
        if (hit == null) {
          clusters.add([node]);
        } else {
          hit.add(node);
        }
      }
      for (final cluster in clusters) {
        if (cluster.length < 2) {
          continue;
        }
        final sorted = [...cluster]..sort(_strongestFirst);
        duplicates.addAll(sorted.skip(1).map((n) => n.message.id));
      }
    }
    return duplicates;
  }

  /// Whether two anchored findings cover overlapping lines.
  static bool _overlaps(ReviewNodePayload a, ReviewNodePayload b) {
    final aStart = a.anchor.lineNumber!;
    final bStart = b.anchor.lineNumber!;
    final aEnd = a.anchor.lineEnd ?? aStart;
    final bEnd = b.anchor.lineEnd ?? bStart;
    return aStart <= bEnd && bStart <= aEnd;
  }

  static int _strongestFirst(_ClassifiedNode a, _ClassifiedNode b) {
    final bySeverity = a.payload.effectiveSeverity.index.compareTo(
      b.payload.effectiveSeverity.index,
    );
    if (bySeverity != 0) {
      return bySeverity;
    }
    final byConfidence = b.payload.confidence.compareTo(a.payload.confidence);
    if (byConfidence != 0) {
      return byConfidence;
    }
    return a.message.createdAt.compareTo(b.message.createdAt);
  }

  /// The PR's cohorts, or empty when none are wired or computed.
  ///
  /// Never throws: the cohorts decorate the walkthrough, and losing a finalized
  /// review because a decorative lookup failed is the wrong trade.
  Future<List<ReviewCohort>> _loadCohorts(
    ReviewSpaceAssociation association,
  ) async {
    final repo = _reviewCohorts;
    final key = _studioKey(association);
    if (repo == null || key == null) {
      return const [];
    }
    try {
      return await repo.forPr(association.workspaceId, key);
    } on Object catch (_) {
      return const [];
    }
  }

  /// Attaches each cohort's changed files to the matching authored area, and
  /// keeps cohorts the narrative did not cover as file-only rows.
  ///
  /// The files are deterministic and the narrative is not, so they are joined
  /// here rather than asked of the model: a walkthrough that lists files the
  /// diff does not contain is worse than one with no file list.
  List<ReviewWalkthroughArea> _mergeCohortFiles(
    List<ReviewWalkthroughArea> authored,
    List<ReviewCohort> cohorts,
  ) {
    if (cohorts.isEmpty) {
      return authored;
    }
    final byKey = {for (final a in authored) a.cohortKey: a};
    final merged = <ReviewWalkthroughArea>[];
    final claimed = <String>{};
    for (final cohort in cohorts) {
      final area = byKey[cohort.cohortKey];
      claimed.add(cohort.cohortKey);
      merged.add(
        ReviewWalkthroughArea(
          cohortKey: cohort.cohortKey,
          title: area?.title.isNotEmpty ?? false ? area!.title : cohort.title,
          bullets: area?.bullets ?? const [],
          files: cohort.filePaths,
        ),
      );
    }
    // An authored area with no matching cohort still belongs in the
    // walkthrough — the narrative is the part a human wrote.
    for (final a in authored) {
      if (!claimed.contains(a.cohortKey)) {
        merged.add(a);
      }
    }
    return merged;
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
    ReviewSpaceAssociation association,
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
    required ReviewSpaceAssociation association,
    required String spaceId,
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
          spaceId: spaceId,
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
  String? _studioKey(ReviewSpaceAssociation association) {
    final key = association.prExternalId;
    return key.isEmpty ? null : key;
  }

  /// Loads the PR's axis results (contract/visual/correctness/security/…) from
  /// the review-studio store. Returns empty when no axis repository is wired or
  /// the key can't be derived.
  Future<List<ReviewAxisResult>> _loadAxisResults(
    ReviewSpaceAssociation association,
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
    ReviewSpaceAssociation association,
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
    Set<String> nitpickIds = const {},
    ReviewEffortEstimate? effort,
  }) {
    final demoted = <_ClassifiedNode>[];
    void split(List<_ClassifiedNode> from, List<_ClassifiedNode> into) {
      for (final c in from) {
        (nitpickIds.contains(c.message.id) ? demoted : into).add(c);
      }
    }

    final readyPromoted = <_ClassifiedNode>[];
    final adjudicationPromoted = <_ClassifiedNode>[];
    split(consensusReady, readyPromoted);
    split(needsAdjudication, adjudicationPromoted);
    final promotedCount = readyPromoted.length + adjudicationPromoted.length;

    // A clean review is one line.
    //
    // The most-read review is the one that found nothing, and a reader who has
    // to scroll a verdict banner, a walkthrough and two empty sections to learn
    // that stops opening them. Everything the review computed is still in the
    // message metadata for the app to render; the body just stops narrating it.
    if (promotedCount == 0 && demoted.isEmpty) {
      final buf = StringBuffer()..writeln(_renderCleanLine(verdict, delta));
      if (delta != null && !delta.isEmpty) {
        buf
          ..writeln()
          ..writeln(_renderDelta(delta, previousHeadSha));
      }
      return buf.toString();
    }

    final buf = StringBuffer();
    buf.writeln('# Review summary');
    buf
      ..writeln()
      ..writeln(_renderVerdictBanner(verdict, effort));
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
      ..writeln('## Consensus-ready (${readyPromoted.length})');
    if (readyPromoted.isEmpty) {
      buf.writeln('_None._');
    } else {
      for (final c in readyPromoted) {
        buf.writeln(_renderNodeLine(c));
      }
    }
    buf
      ..writeln()
      ..writeln('## Needs adjudication (${adjudicationPromoted.length})');
    if (adjudicationPromoted.isEmpty) {
      buf.writeln('_None._');
    } else {
      for (final c in adjudicationPromoted) {
        buf.writeln(_renderNodeLine(c));
      }
    }
    if (demoted.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(_renderNitpicks(demoted));
    }
    return buf.toString();
  }

  /// The whole body of a review that found nothing worth reporting.
  ///
  /// States the outcome and stops. The verdict, the axes and the counts are all
  /// still in the message metadata — this is the narration, and there is
  /// nothing to narrate.
  String _renderCleanLine(ReviewVerdict v, FindingDelta? delta) {
    final resolved = delta?.resolvedSinceLast.length ?? 0;
    if (resolved > 0) {
      return '**All reported issues were addressed.**';
    }
    final tag = switch (v.overall) {
      ReviewVerdictOverall.ship => '',
      ReviewVerdictOverall.hold => ' Holding on a non-finding signal.',
      ReviewVerdictOverall.block => ' Blocked by a failing gate.',
    };
    return '**No issues found.**$tag';
  }

  /// The findings this level set aside, in a collapsed group.
  ///
  /// Collapsed rather than omitted, and counted in its own heading, so the
  /// reader can see there is something there and decide for themselves. Both
  /// surfaces that render this markdown expand `<details>`.
  String _renderNitpicks(List<_ClassifiedNode> demoted) {
    final buf = StringBuffer()
      ..writeln('<details>')
      ..writeln('<summary>Nitpicks (${demoted.length})</summary>')
      ..writeln();
    for (final c in demoted) {
      buf.writeln(_renderNodeLine(c));
    }
    buf
      ..writeln()
      ..writeln('</details>');
    return buf.toString().trimRight();
  }

  String _renderWalkthrough(ReviewWalkthroughSummary w) {
    final buf = StringBuffer()..writeln('## Walkthrough');
    if (w.headline.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(w.headline);
    }
    // Areas first as a table, so the change can be read as a handful of
    // concerns rather than a file list. Twelve files that moved for one reason
    // are one row.
    final withFiles = w.areas.where((a) => a.files.isNotEmpty).toList();
    if (withFiles.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('| Area | Files | Summary |')
        ..writeln('|---|---|---|');
      for (final area in withFiles) {
        buf.writeln(
          '| ${_cell(area.title)} | ${_renderFileCell(area.files)} '
          '| ${_cell(area.bullets.join(' '))} |',
        );
      }
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

  /// One table cell's worth of text: pipes escaped and newlines flattened, so
  /// a bullet containing either does not break the row it sits in.
  String _cell(String raw) =>
      raw.replaceAll('|', r'\|').replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();

  /// The files for one area. Capped, because a cohort can carry hundreds and a
  /// table cell listing them all is a table nobody can read; the remainder is
  /// counted rather than silently dropped.
  String _renderFileCell(List<String> files) {
    const cap = 6;
    final shown = files.take(cap).map((f) => '`${_cell(f)}`').join('<br>');
    final rest = files.length - cap;
    return rest > 0 ? '$shown<br>_+$rest more_' : shown;
  }

  String _renderVerdictBanner(ReviewVerdict v, [ReviewEffortEstimate? effort]) {
    final pct = (v.confidence * 100).round();
    final tag = switch (v.overall) {
      ReviewVerdictOverall.ship => 'SHIP',
      ReviewVerdictOverall.hold => 'HOLD',
      ReviewVerdictOverall.block => 'BLOCK',
    };
    final effortLine = effort == null
        ? ''
        : '\n\n**Estimated review effort** — ${effort.score} '
              '(${effort.band}) · ~${effort.minutes} min';
    return '## Verdict: $tag ($pct% confidence)\n\n${v.explanation}\n\n'
        '**Counts** — P0: ${v.p0Count} · P1: ${v.p1Count} · P2: ${v.p2Count} '
        '· P3: ${v.p3Count}$effortLine';
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
    // Category and effort ride along when the reviewer supplied them. Severity
    // is already carried by the priority tag, so it is not repeated.
    final labels = <String>[
      if (p.category != null) _categoryLabel(p.category!),
      if (p.effort != null) _effortLabel(p.effort!),
    ];
    final labelPart = labels.isEmpty ? '' : ' · ${labels.join(' · ')}';
    return '- **${p.kind.name}** · ${p.priority.name.toUpperCase()}$labelPart '
        '($conf%) $summary$anchor';
  }

  static String _categoryLabel(ReviewFindingCategory c) => switch (c) {
    ReviewFindingCategory.security => 'security',
    ReviewFindingCategory.stability => 'stability',
    ReviewFindingCategory.dataIntegrity => 'data integrity',
    ReviewFindingCategory.correctness => 'correctness',
    ReviewFindingCategory.performance => 'performance',
    ReviewFindingCategory.maintainability => 'maintainability',
  };

  static String _effortLabel(ReviewFindingEffort e) => switch (e) {
    ReviewFindingEffort.quickWin => 'quick win',
    ReviewFindingEffort.moderate => 'moderate',
    ReviewFindingEffort.heavyLift => 'heavy lift',
  };
}

class _ClassifiedNode {
  _ClassifiedNode({required this.message, required this.payload});

  final Message message;
  final ReviewNodePayload payload;
}
