import 'dart:convert';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:uuid/uuid.dart';

/// MCP tool used by the CEO to finalize a review. Gathers every
/// `review_node` message in the channel, classifies each as
/// `consensus_ready` (≥1 peer confirmation, author cannot self-confirm)
/// or `needs_adjudication`, computes the per-PR [ReviewVerdict] from
/// finding priorities + confidence, posts an editorial summary that
/// includes the verdict banner, and transitions the
/// [ReviewChannelAssociation] to `awaiting_approval`. Publishing to
/// GitHub stays user-gated and is not performed here.
class FinalizeReviewTool extends McpTool {
  /// Creates a new [FinalizeReviewTool].
  FinalizeReviewTool({
    required MessagingRepository messaging,
    required ReviewChannelRepository reviewChannels,
    ReviewAxisResultRepository? reviewAxisResults,
    ComputeReviewVerdictUseCase? computeVerdict,
  }) : _messaging = messaging,
       _reviewChannels = reviewChannels,
       _reviewAxisResults = reviewAxisResults,
       _computeVerdict = computeVerdict ?? const ComputeReviewVerdictUseCase();

  final MessagingRepository _messaging;
  final ReviewChannelRepository _reviewChannels;

  /// The deterministic + token axis results (contract/visual/correctness/…)
  /// that the finding-based verdict is escalated against. Null → verdict comes
  /// from findings alone (the two engines aren't unified).
  final ReviewAxisResultRepository? _reviewAxisResults;
  final ComputeReviewVerdictUseCase _computeVerdict;

  @override
  String get name => 'finalize_review';

  @override
  String get description =>
      'Finalize the review for a channel. Gathers all review nodes, '
      'computes per-node consensus (peer confirmation, author cannot '
      'self-confirm), computes the per-PR verdict (ship/hold/block) from '
      'finding priorities + confidence, posts a review summary message, '
      'and transitions the review to awaiting_approval. Does NOT publish '
      'to GitHub — the user does that explicitly from the UI.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the review channel belongs to.',
      },
      'channel_id': {'type': 'string', 'description': 'The review channel ID.'},
      'finalizer_id': {
        'type': 'string',
        'description': 'The agent id closing the review (usually the CEO).',
      },
      'editorial_note': {
        'type': 'string',
        'description':
            'Optional editorial framing the finalizer wants in the summary.',
      },
    },
    'required': ['workspace_id', 'channel_id', 'finalizer_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final rawFinalizerId = arguments['finalizer_id'];
    if (rawFinalizerId is! String) {
      return CallResult.error(
        'Missing or invalid argument: finalizer_id (expected string)',
      );
    }
    final note = arguments['editorial_note'];

    final workspaceId = rawWorkspaceId;
    final channelId = rawChannelId;
    final finalizerId = rawFinalizerId;

    final association = await _reviewChannels
        .watchByChannel(workspaceId, channelId)
        .first;
    if (association == null) {
      return CallResult.error(
        'Channel $channelId is not linked to a PR review.',
      );
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
    // which is exactly `association.prNodeId`.
    await _upsertTokenAxes(association, openPayloads);
    final axisResults = await _loadAxisResults(association);
    if (axisResults.isNotEmpty) {
      verdict = verdict.withAxisResults(axisResults);
    }

    final summary = _renderSummary(
      verdict: verdict,
      consensusReady: consensusReady,
      needsAdjudication: needsAdjudication,
      editorialNote: note is String ? note : null,
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
        'consensusReadyCount': consensusReady.length,
        'needsAdjudicationCount': needsAdjudication.length,
        'consensusReadyMessageIds': consensusReady
            .map((c) => c.message.id)
            .toList(),
        'needsAdjudicationMessageIds': needsAdjudication
            .map((c) => c.message.id)
            .toList(),
      },
    );

    await _reviewChannels.updateStatus(
      workspaceId,
      association.id,
      ReviewChannelStatus.awaitingApproval,
    );

    return CallResult.success(
      jsonEncode({
        'summary_message_id': summaryId,
        'channel_id': channelId,
        'review_id': association.id,
        'status': 'awaiting_approval',
        'verdict': verdict.overall.name,
        'verdict_confidence': verdict.confidence,
        'priority_counts': {
          'p0': verdict.p0Count,
          'p1': verdict.p1Count,
          'p2': verdict.p2Count,
          'p3': verdict.p3Count,
        },
        'consensus_ready': consensusReady.length,
        'needs_adjudication': needsAdjudication.length,
      }),
    );
  }

  /// The review-studio key for [association] — the PR's real GitHub node id,
  /// which the studio tables now key on too (migration 46), so the association's
  /// own `prNodeId` addresses its axis rows directly. Null when unset.
  String? _studioKey(ReviewChannelAssociation association) {
    final key = association.prNodeId;
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
          note: '',
        ),
      );
    }
  }

  String _renderSummary({
    required ReviewVerdict verdict,
    required List<_ClassifiedNode> consensusReady,
    required List<_ClassifiedNode> needsAdjudication,
    String? editorialNote,
  }) {
    final buf = StringBuffer();
    buf.writeln('# Review summary');
    buf
      ..writeln()
      ..writeln(_renderVerdictBanner(verdict));
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
