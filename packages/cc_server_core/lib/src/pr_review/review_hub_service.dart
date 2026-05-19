import 'dart:async';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_static_scanner.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';

/// The minimal PR facts the hub needs before a channel exists.
typedef ReviewHubResolvePr =
    Future<ReviewHubPrContext> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
    });

/// Resolved PR context for a hub start.
class ReviewHubPrContext {
  /// Creates a [ReviewHubPrContext].
  const ReviewHubPrContext({
    required this.externalId,
    required this.headSha,
    required this.title,
  });

  /// The PR's real GitHub node id (the studio tables' key).
  final String externalId;

  /// The PR's current head SHA (stamps the summary; pushes invalidate).
  final String headSha;

  /// The PR title (used for channel naming when the channel is fresh).
  final String title;
}

/// Reads a PR's per-file unified diffs (`path` → patch text), for the
/// deterministic scan over its added lines.
typedef ReviewHubFetchPatches =
    Future<Map<String, String>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
    });

/// Ensures the PR's backing review channel; mirrors the runtime's
/// `ensurePrChannel` closure contract. Returns the channel id.
typedef ReviewHubEnsureChannel =
    Future<String> Function({
      required String workspaceId,
      required String repoFullName,
      required int prNumber,
      required String prExternalId,
      String? createdByUserId,
      String title,
    });

/// Computes the deterministic review context (cohorts + contract/visual axes)
/// BEFORE the reviewer fan-out, so reviewers walk areas in impact order. Same
/// contract as the runtime's `computeReviewStudioFn`, typed.
typedef ReviewHubComputeCohorts =
    Future<List<ReviewCohort>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
    });

/// The one canonical AI review flow (the merged Findings + Studio engines).
///
/// `review_hub.start` is deliberately manual (the Ask-AI action): ensure the
/// PR channel → compute the deterministic review context → fan out reviewers
/// into THE PR channel with the area map in their briefs (findings get
/// `cohort_key`/`axis` stamped) → await the reviewer runs → author the
/// structured walkthrough with a CEO editorial pass → run the deterministic
/// [ReviewFinalizer] → optionally auto-publish (workspace opt-in).
///
/// The synchronous [start] only resolves the PR, ensures the channel and kicks
/// the orchestration into the background — the RPC must not hang for the
/// minutes a review takes. Progress is narrated into the channel as system
/// messages, which is exactly what the Review Hub renders.
class ReviewHubService {
  /// Creates a [ReviewHubService].
  ReviewHubService({
    required ReviewHubResolvePr resolvePr,
    required ReviewHubEnsureChannel ensureChannel,
    required ReviewHubComputeCohorts computeCohorts,
    required DispatchReviewersService dispatchReviewers,
    required ReviewFinalizer finalizer,
    required MessagingRepository messaging,
    required MessagingPort messagingPort,
    required ReviewChannelRepository reviewChannels,
    required AgentRunLogRepository runLogs,
    required AgentRepository agents,
    required WorkspaceRepository workspaces,
    required ReviewPublisherPort publisher,
    ReviewHubFetchPatches? fetchPatches,
    ReviewRunSnapshotRepository? runSnapshots,
    ReviewCohortRepository? cohortRepository,
    DiffStaticScanner staticScanner = const DiffStaticScanner(),
    this.reviewerRoles = const ['qa', 'architect', 'engineer'],
    this.reviewerWaitTimeout = const Duration(minutes: 60),
    this.editorialTimeout = const Duration(minutes: 10),
    this.pollInterval = const Duration(seconds: 3),
  }) : _resolvePr = resolvePr,
       _ensureChannel = ensureChannel,
       _computeCohorts = computeCohorts,
       _dispatchReviewers = dispatchReviewers,
       _finalizer = finalizer,
       _messaging = messaging,
       _messagingPort = messagingPort,
       _reviewChannels = reviewChannels,
       _runLogs = runLogs,
       _agents = agents,
       _workspaces = workspaces,
       _publisher = publisher,
       _fetchPatches = fetchPatches,
       _runSnapshots = runSnapshots,
       _cohortRepository = cohortRepository,
       _staticScanner = staticScanner;

  final ReviewHubResolvePr _resolvePr;
  final ReviewHubEnsureChannel _ensureChannel;
  final ReviewHubComputeCohorts _computeCohorts;
  final DispatchReviewersService _dispatchReviewers;
  final ReviewFinalizer _finalizer;
  final MessagingRepository _messaging;
  final MessagingPort _messagingPort;
  final ReviewChannelRepository _reviewChannels;
  final AgentRunLogRepository _runLogs;
  final AgentRepository _agents;
  final WorkspaceRepository _workspaces;
  final ReviewPublisherPort _publisher;

  /// Reads the PR's per-file patches for the static scan. Null → the scan is
  /// skipped entirely (no patches, nothing deterministic to say).
  final ReviewHubFetchPatches? _fetchPatches;

  /// Previous finalized passes, for the "previously flagged" brief. Null → the
  /// review is independent, as it was before delta-aware re-review.
  final ReviewRunSnapshotRepository? _runSnapshots;

  /// Reads already-computed cohorts (for [askArea], which must not recompute
  /// the whole studio just to answer a question about one area).
  final ReviewCohortRepository? _cohortRepository;
  final DiffStaticScanner _staticScanner;

  Future<List<ReviewCohort>> _cohortsFor(
    String workspaceId,
    String prExternalId,
  ) async {
    final repo = _cohortRepository;
    if (repo == null || prExternalId.isEmpty) {
      return const [];
    }
    try {
      return await repo.forPr(workspaceId, prExternalId);
    } on Object catch (e) {
      CcHostLog.warning('review_hub: cohort read failed: $e');
      return const [];
    }
  }

  /// Roles fanned out per review, in order. Default matches the seeded
  /// specialists (qa / architect / engineer).
  final List<String> reviewerRoles;

  /// How long the background orchestration waits for the reviewer runs before
  /// finalizing anyway (the findings recorded so far still count).
  final Duration reviewerWaitTimeout;

  /// How long the CEO editorial pass may run before the summary falls back to
  /// the deterministic-only rendering.
  final Duration editorialTimeout;

  /// Run-idle polling cadence.
  final Duration pollInterval;

  /// Starts a review. Returns `{status, channel_id, pr_external_id}`;
  /// `status` is `already_running` when a review is in flight for the PR.
  Future<Map<String, dynamic>> start({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    String? requestedByUserId,
  }) async {
    final pr = await _resolvePr(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
    );
    final channelId = await _ensureChannel(
      workspaceId: workspaceId,
      repoFullName: '$owner/$repo',
      prNumber: prNumber,
      prExternalId: pr.externalId,
      createdByUserId: requestedByUserId,
      title: pr.title,
    );

    final association = await _reviewChannels
        .watchByPr(workspaceId, pr.externalId)
        .first;
    if (association != null &&
        association.status == ReviewChannelStatus.inProgress) {
      return {
        'status': 'already_running',
        'channel_id': channelId,
        'pr_external_id': pr.externalId,
      };
    }

    unawaited(
      _orchestrate(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        channelId: channelId,
        pr: pr,
      ),
    );
    return {
      'status': 'started',
      'channel_id': channelId,
      'pr_external_id': pr.externalId,
    };
  }

  /// Asks one question about one review area.
  ///
  /// Deliberately a single read-only turn rather than a persistent chat: the
  /// question and its answer land in the PR channel as ordinary messages, so
  /// they sit in the same transcript as the findings they are about and stay
  /// there when the reader comes back tomorrow. A separate chat session would
  /// put the one sentence that explained the change somewhere nobody looks.
  ///
  /// Returns `{status, channel_id}`; `status` is `no_agent` when the workspace
  /// has nobody to answer.
  Future<Map<String, dynamic>> askArea({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String cohortKey,
    required String question,
    String? requestedByUserId,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('question must not be empty');
    }
    final pr = await _resolvePr(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
    );
    final channelId = await _ensureChannel(
      workspaceId: workspaceId,
      repoFullName: '$owner/$repo',
      prNumber: prNumber,
      prExternalId: pr.externalId,
      createdByUserId: requestedByUserId,
      title: pr.title,
    );

    final cohorts = await _cohortsFor(workspaceId, pr.externalId);
    ReviewCohort? area;
    for (final c in cohorts) {
      if (c.cohortKey == cohortKey) {
        area = c;
        break;
      }
    }

    // The question is posted as the ASKER, not as the agent: attribution is
    // the point of a shared transcript.
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      channelId: channelId,
      content: trimmed,
      senderId: requestedByUserId ?? 'system',
      senderType: requestedByUserId == null ? 'agent' : 'user',
      messageType: 'text',
      metadata: {
        'reviewAsk': {'cohortKey': cohortKey},
      },
    );

    final responder =
        await _agents.findByWorkspaceAndName(workspaceId, 'engineer') ??
        await _agents.findByWorkspaceAndName(workspaceId, 'ceo');
    if (responder == null) {
      await _narrate(
        workspaceId,
        channelId,
        'No agent is available to answer questions in this workspace.',
      );
      return {'status': 'no_agent', 'channel_id': channelId};
    }

    unawaited(
      _messagingPort
          .dispatchAgent(
            workspaceId: workspaceId,
            agentId: responder.id,
            channelId: channelId,
            prompt: _buildAskBrief(area: area, question: trimmed, pr: pr),
          )
          .catchError((Object e, StackTrace st) {
            CcHostLog.error('review_hub: askArea dispatch failed', e, st);
            return '';
          }),
    );

    return {'status': 'asked', 'channel_id': channelId};
  }

  /// The read-only Q&A brief for [askArea].
  String _buildAskBrief({
    required ReviewCohort? area,
    required String question,
    required ReviewHubPrContext pr,
  }) {
    final buf = StringBuffer()
      ..writeln(
        'You are answering ONE question about ONE area of a pull '
        'request under review.',
      )
      ..writeln()
      ..writeln('## Pull request')
      ..writeln('- ${pr.title}')
      ..writeln('- head: `${pr.headSha}`')
      ..writeln();
    if (area == null) {
      buf
        ..writeln('## Area')
        ..writeln(
          'The named area could not be resolved — answer from the pull '
          "request's diff and say so if the question assumed an area.",
        );
    } else {
      buf
        ..writeln('## Area: ${area.title}')
        ..writeln();
      if (area.summaryMarkdown.isNotEmpty) {
        buf
          ..writeln(area.summaryMarkdown)
          ..writeln();
      }
      buf.writeln('### Files');
      for (final path in area.filePaths.take(40)) {
        buf.writeln('- `$path`');
      }
      final changed = area.insights.changedSymbols;
      if (changed.isNotEmpty) {
        buf
          ..writeln()
          ..writeln('### Symbols this change touches');
        for (final c in changed.take(20)) {
          buf.writeln(
            '- `${c.symbol.qualifiedName}` (${c.symbol.filePath}:'
            '${c.symbol.startLine}) — ${c.changedLines} line(s) changed',
          );
        }
      }
      if (area.layers.isNotEmpty) {
        buf
          ..writeln()
          ..writeln('### Reading order');
        for (var i = 0; i < area.layers.length && i < 20; i++) {
          final l = area.layers[i];
          buf.writeln('${i + 1}. ${l.title} — `${l.filePath}`');
        }
      }
    }
    buf
      ..writeln()
      ..writeln('## Question')
      ..writeln(question)
      ..writeln()
      ..writeln('## How to answer')
      ..writeln(
        '- Answer in this channel, concisely, in prose. Read the checked-out '
        'worktree and use the code-graph tools if you need to.',
      )
      ..writeln(
        '- Do NOT record review findings (no `add_review_node`) — this is a '
        'question, not a review pass.',
      )
      ..writeln(
        '- If the answer is not in the change, say what you would need to '
        'look at rather than guessing.',
      );
    return buf.toString();
  }

  Future<void> _orchestrate({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String channelId,
    required ReviewHubPrContext pr,
  }) async {
    try {
      await _narrate(
        workspaceId,
        channelId,
        'Review started — computing review areas from the code graph…',
      );

      // 1. Deterministic context first: cohorts + contract/visual axes. The
      //    area map is the skeleton reviewers walk and findings stamp onto.
      final cohorts = await _computeCohorts(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
      );
      await _narrate(
        workspaceId,
        channelId,
        cohorts.isEmpty
            ? 'No changed areas computed (empty diff or repo not indexed) — '
                  'reviewers will work from the raw diff.'
            : '${cohorts.length} review area(s) computed — dispatching '
                  'reviewers…',
      );

      // 2. Deterministic security rules over the PR's added lines. Runs BEFORE
      //    the fan-out so reviewers see these findings in-channel and can
      //    corroborate or dismiss them rather than re-discovering them.
      final staticCount = await _runStaticScan(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        channelId: channelId,
        cohorts: cohorts,
      );
      if (staticCount > 0) {
        await _narrate(
          workspaceId,
          channelId,
          'Static scan: $staticCount deterministic finding(s) on the added '
          'lines.',
        );
      }

      // 3. Fan out into THE PR channel (not a hidden conversation): findings,
      //    reviewer bubbles and the human discussion share one transcript.
      final previouslyFlagged = await _previouslyFlaggedBrief(
        workspaceId: workspaceId,
        prExternalId: pr.externalId,
      );
      final dispatched = await _dispatchReviewers.dispatch(
        channelId: channelId,
        workspaceId: workspaceId,
        reviewers: [
          for (final role in reviewerRoles) {'role': role},
        ],
        cohortBrief: _buildCohortBrief(cohorts) + previouslyFlagged,
      );
      final unmatched = (dispatched['unmatched'] as List? ?? const []).length;
      if ((dispatched['dispatched'] as List? ?? const []).isEmpty) {
        await _narrate(
          workspaceId,
          channelId,
          'No reviewer agents matched the review roles — aborting. Seed the '
          'specialist agents (qa / architect / engineer) or adjust their '
          'skills.',
        );
        return;
      }
      if (unmatched > 0) {
        await _narrate(
          workspaceId,
          channelId,
          '$unmatched reviewer role(s) unmatched — continuing with the '
          'matched reviewers.',
        );
      }

      // 3. Await the reviewer runs (their findings are review nodes in this
      //    channel). A timeout finalizes with whatever was recorded so far.
      final idle = await _waitForIdleRuns(
        workspaceId,
        channelId,
        reviewerWaitTimeout,
      );
      if (!idle) {
        await _narrate(
          workspaceId,
          channelId,
          'Reviewer wait timed out — finalizing with the findings recorded '
          'so far.',
        );
      }

      // 4. CEO editorial pass: the structured, CodeRabbit-style walkthrough
      //    authored from the deterministic digest. Best-effort — a failure
      //    falls back to the deterministic-only summary.
      final walkthrough = await _editorialPass(
        workspaceId: workspaceId,
        channelId: channelId,
        cohorts: cohorts,
      );

      // 5. Deterministic finalize: verdict (findings escalated by axes),
      //    summary message, awaiting_approval.
      final ceo = await _agents.findByWorkspaceAndName(workspaceId, 'ceo');
      await _finalizer.finalize(
        workspaceId: workspaceId,
        channelId: channelId,
        finalizerId: ceo?.id ?? 'system',
        walkthrough: walkthrough,
        headSha: pr.headSha,
      );

      // 6. Opt-in auto-publish (workspace setting, off by default).
      final workspace = await _workspaces.getById(workspaceId);
      if (workspace?.autoPublishReview ?? false) {
        final published = await _publisher.publish(
          workspaceId: workspaceId,
          channelId: channelId,
        );
        await _narrate(
          workspaceId,
          channelId,
          'Review published to GitHub (${published.event}, '
          '${published.findingCount} findings).',
        );
      }
    } on Object catch (e, st) {
      CcHostLog.error('review_hub: orchestration failed', e, st);
      try {
        await _narrate(workspaceId, channelId, 'Review failed: $e');
      } on Object catch (_) {}
    }
  }

  /// Runs the deterministic rules over the PR's added lines and files each hit
  /// as a `review_node` in the channel, stamped `provenance: static`.
  ///
  /// Filed as ordinary review nodes on purpose: they then flow through the
  /// same routing, verdict, publish and dismissal machinery as an agent's
  /// findings, and a human dismisses one exactly the same way — which is what
  /// feeds the suppression memory so the same false positive is not re-filed
  /// next time.
  ///
  /// Best-effort: a scanner failure must not abort a review.
  Future<int> _runStaticScan({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String channelId,
    required List<ReviewCohort> cohorts,
  }) async {
    final fetch = _fetchPatches;
    if (fetch == null) {
      return 0;
    }
    try {
      final patches = await fetch(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
      );
      if (patches.isEmpty) {
        return 0;
      }
      final findings = _staticScanner.scan(patches);
      if (findings.isEmpty) {
        return 0;
      }
      // Cohort routing is stamped here so the deterministic findings land in
      // the same areas the reviewers are told to walk.
      final cohortByFile = <String, String>{};
      for (final c in cohorts) {
        for (final path in c.filePaths) {
          cohortByFile.putIfAbsent(path, () => c.cohortKey);
        }
      }
      for (final f in findings) {
        await _messaging.sendMessage(
          workspaceId: workspaceId,
          channelId: channelId,
          content: _renderStaticFinding(f),
          senderId: 'system',
          senderType: 'agent',
          messageType: 'review_node',
          metadata: ReviewNodePayload(
            kind: ReviewNodeKind.bug,
            priority: f.priority,
            confidence: f.confidence,
            anchor: ReviewNodeAnchor(filePath: f.filePath, lineNumber: f.line),
            status: ReviewNodeStatus.open,
            cohortKey: cohortByFile[f.filePath],
            axis: ReviewAxis.security,
            provenance: ReviewFindingProvenance.staticRule,
            ruleId: f.ruleId,
          ).toMetadata(),
        );
      }
      return findings.length;
    } on Object catch (e, st) {
      CcHostLog.warning('review_hub: static scan failed: $e\n$st');
      return 0;
    }
  }

  String _renderStaticFinding(StaticFinding f) {
    final buf = StringBuffer()..writeln(f.message);
    if (f.snippet.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('```')
        ..writeln(f.snippet)
        ..writeln('```');
    }
    buf
      ..writeln()
      ..writeln(
        '_Deterministic rule `${f.ruleId}` — matched on a line this pull '
        'request adds._',
      );
    return buf.toString();
  }

  /// The "already flagged, re-verify rather than re-discover" section of the
  /// reviewer brief.
  ///
  /// Asking reviewers to re-raise a still-open finding **with the same title**
  /// is what keeps the fingerprint match working across passes: the matcher is
  /// heuristic on wording, so the cheapest way to make it accurate is to tell
  /// the writers not to reword.
  Future<String> _previouslyFlaggedBrief({
    required String workspaceId,
    required String prExternalId,
  }) async {
    final repo = _runSnapshots;
    if (repo == null || prExternalId.isEmpty) {
      return '';
    }
    try {
      final previous = await repo.latestForPr(workspaceId, prExternalId);
      final open = previous?.openFingerprints ?? const [];
      if (open.isEmpty) {
        return '';
      }
      final buf = StringBuffer()
        ..writeln()
        ..writeln('## Previously flagged (re-verify, do not re-discover)')
        ..writeln()
        ..writeln(
          'A previous review pass left these open. For each one, either '
          'confirm it is fixed (say so explicitly) or re-raise it WITH THE '
          'SAME TITLE so it is tracked as the same finding rather than a new '
          'one.',
        )
        ..writeln();
      for (final f in open.take(25)) {
        final where = f.filePath == null ? '' : ' — `${f.filePath}`';
        final title = f.title.isEmpty ? '(untitled finding)' : f.title;
        buf.writeln('- [${f.priority.wireName.toUpperCase()}] $title$where');
      }
      if (open.length > 25) {
        buf.writeln('- …and ${open.length - 25} more.');
      }
      return buf.toString();
    } on Object catch (e) {
      CcHostLog.warning('review_hub: previous-pass lookup failed: $e');
      return '';
    }
  }

  /// Renders the deterministic area map appended to every reviewer brief.
  /// Reviewers walk areas in this (impact) order and stamp each finding with
  /// its `cohort_key` so the hub routes findings into areas.
  String _buildCohortBrief(List<ReviewCohort> cohorts) {
    if (cohorts.isEmpty) {
      return '';
    }
    final buf = StringBuffer()
      ..writeln('## Review areas (code-graph computed; walk in this order)')
      ..writeln();
    for (var i = 0; i < cohorts.length; i++) {
      final c = cohorts[i];
      buf
        ..writeln(
          '${i + 1}. **${c.title}** — impact ${c.impactScore} — '
          'cohort_key: `${c.cohortKey}`',
        )
        ..writeln('   Files: ${c.filePaths.join(', ')}');
      for (final layer in c.layers.take(5)) {
        final range = layer.startLine != null
            ? ':${layer.startLine}-${layer.endLine ?? layer.startLine}'
            : '';
        buf.writeln('   Read `${layer.filePath}$range` — ${layer.title}');
      }
    }
    buf
      ..writeln()
      ..writeln(
        'Stamp EVERY `add_review_node` with the finding\'s `cohort_key` (the '
        'area above it belongs to) and an `axis` — the closest match of '
        '`correctness`, `security` or `testGap`.',
      );
    return buf.toString();
  }

  /// The CEO editorial pass: dispatch the CEO with the deterministic digest
  /// and a strict output contract, await it, harvest the structured
  /// walkthrough. Returns null whenever any step degrades (no CEO, dispatch
  /// failure, timeout, malformed output) — the finalizer then renders the
  /// deterministic-only summary.
  Future<ReviewWalkthroughSummary?> _editorialPass({
    required String workspaceId,
    required String channelId,
    required List<ReviewCohort> cohorts,
  }) async {
    try {
      final ceo = await _agents.findByWorkspaceAndName(workspaceId, 'ceo');
      if (ceo == null) {
        return null;
      }
      final digest = await _buildEditorialDigest(
        workspaceId: workspaceId,
        channelId: channelId,
        cohorts: cohorts,
      );
      final runId = await _messagingPort.dispatchAgent(
        workspaceId: workspaceId,
        channelId: channelId,
        agentId: ceo.id,
        prompt: digest,
        expectedOutputSchema: _walkthroughSchema,
        outputContractMode: OutputContractMode.strict,
      );
      if (runId == null) {
        return null;
      }
      final idle = await _waitForIdleRuns(
        workspaceId,
        channelId,
        editorialTimeout,
      );
      if (!idle) {
        return null;
      }
      final run = await _runLogs.getById(workspaceId, runId);
      return _parseWalkthrough(run?.outputJson);
    } on Object catch (e, st) {
      CcHostLog.warning('review_hub: editorial pass degraded: $e\n$st');
      return null;
    }
  }

  /// Builds the CEO's editorial prompt: the deterministic digest (areas,
  /// findings so far, axis state) plus the output contract instructions.
  Future<String> _buildEditorialDigest({
    required String workspaceId,
    required String channelId,
    required List<ReviewCohort> cohorts,
  }) async {
    final buf = StringBuffer()
      ..writeln(
        'Write the review walkthrough for PR. You are summarizing for the '
        'human reviewer — concise, factual, grounded in the data below. '
        'Do NOT invent findings: every bullet must trace to a finding or a '
        'computed area.',
      )
      ..writeln();
    if (cohorts.isNotEmpty) {
      buf
        ..writeln('## Areas (impact order)')
        ..writeln();
      for (final c in cohorts) {
        buf
          ..writeln(
            '- `${c.cohortKey}` — ${c.title} (impact ${c.impactScore}; '
            '${c.filePaths.length} files)',
          )
          ..writeln('  Files: ${c.filePaths.join(', ')}');
      }
      buf.writeln();
    }
    final messages = await _messaging.getMessages(workspaceId, channelId);
    final findings = messages
        .where((m) => m.messageType == ChannelMessageType.reviewNode)
        .map((m) => m.content.split('\n').first)
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (findings.isNotEmpty) {
      buf
        ..writeln('## Findings recorded by the reviewers')
        ..writeln();
      for (final f in findings) {
        buf.writeln('- $f');
      }
      buf.writeln();
    }
    buf.writeln(
      'Return ONLY the JSON object matching the output contract: a one-line '
      '`headline` ("what this PR does"), one `areas` entry per area above '
      '(same `cohortKey`, a short `title`, 1-3 `bullets` narrating what '
      'changed using the findings that belong to it), and optional '
      '`riskNotes` for cross-cutting risks.',
    );
    return buf.toString();
  }

  /// Validates a harvested `submit_output` payload into a
  /// [ReviewWalkthroughSummary]; null on absent/malformed shapes.
  ReviewWalkthroughSummary? _parseWalkthrough(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final headline = json['headline'];
    if (headline is! String) {
      return null;
    }
    final rawAreas = json['areas'];
    final areas = <ReviewWalkthroughArea>[
      for (final raw in rawAreas is List ? rawAreas : const <Object?>[])
        if (raw is Map<String, dynamic> &&
            raw['cohortKey'] is String &&
            (raw['cohortKey'] as String).isNotEmpty)
          ReviewWalkthroughArea(
            cohortKey: raw['cohortKey'] as String,
            title: raw['title'] is String ? raw['title'] as String : '',
            bullets: (raw['bullets'] as List? ?? const [])
                .whereType<String>()
                .toList(),
          ),
    ];
    if (areas.isEmpty) {
      return null;
    }
    return ReviewWalkthroughSummary(
      headline: headline,
      areas: areas,
      riskNotes: (json['riskNotes'] as List? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  static const Map<String, dynamic> _walkthroughSchema = {
    'type': 'object',
    'properties': {
      'headline': {'type': 'string'},
      'areas': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'cohortKey': {'type': 'string'},
            'title': {'type': 'string'},
            'bullets': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': ['cohortKey', 'title', 'bullets'],
        },
      },
      'riskNotes': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
    'required': ['headline', 'areas'],
  };

  /// Waits until the channel has no active agent runs. Returns false on
  /// timeout (the caller decides whether to proceed anyway).
  Future<bool> _waitForIdleRuns(
    String workspaceId,
    String channelId,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final active = await _runLogs
          .watchActiveByConversation(workspaceId, channelId)
          .first;
      if (active.isEmpty) {
        return true;
      }
      if (DateTime.now().isAfter(deadline)) {
        return false;
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<void> _narrate(String workspaceId, String channelId, String text) {
    return _messaging.sendMessage(
      workspaceId: workspaceId,
      channelId: channelId,
      content: text,
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );
  }
}
