import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_infra/src/pr_review/review_finalizer.dart';
import 'package:test/test.dart';

const _workspaceId = 'ws';
const _channelId = 'ch';
const _prExternalId = 'PR_node';

ReviewChannelAssociation _assoc({
  ReviewChannelStatus status = ReviewChannelStatus.inProgress,
}) => ReviewChannelAssociation(
  id: 'assoc-1',
  channelId: _channelId,
  workspaceId: _workspaceId,
  prExternalId: _prExternalId,
  prNumber: 42,
  repoFullName: 'o/r',
  status: status,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

ChannelMessage _finding({
  required String id,
  required String title,
  String senderId = 'agent-a',
  String? filePath = 'lib/auth.dart',
  ReviewNodeKind kind = ReviewNodeKind.bug,
  ReviewNodePriority priority = ReviewNodePriority.p1,
  ReviewNodeStatus status = ReviewNodeStatus.open,
  List<String> confirmedBy = const [],
  ReviewAxis? axis,
  ReviewFindingProvenance provenance = ReviewFindingProvenance.agent,
  String? ruleId,
  double confidence = 0.8,
}) => ChannelMessage(
  id: id,
  channelId: _channelId,
  conversationId: _channelId,
  senderId: senderId,
  senderType: ChannelSenderType.agent,
  content: title,
  messageType: ChannelMessageType.reviewNode,
  createdAt: DateTime.utc(2024, 1, 1),
  metadata: ReviewNodePayload(
    kind: kind,
    priority: priority,
    confidence: confidence,
    anchor: ReviewNodeAnchor(filePath: filePath),
    status: status,
    confirmedBy: confirmedBy,
    axis: axis,
    provenance: provenance,
    ruleId: ruleId,
  ).toMetadata(),
);

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this.messages);

  List<ChannelMessage> messages;
  final sent = <Map<String, dynamic>>[];

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async => messages;

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    sent.add({
      'content': content,
      'messageType': messageType,
      'metadata': metadata,
    });
    return id ?? 'msg-${sent.length}';
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReviewChannels implements ReviewChannelRepository {
  _FakeReviewChannels(this.association);

  ReviewChannelAssociation? association;
  final statusUpdates = <ReviewChannelStatus>[];

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(association);

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async => statusUpdates.add(status);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAxisResults implements ReviewAxisResultRepository {
  final rows = <String, ReviewAxisResult>{};

  @override
  Future<List<ReviewAxisResult>> forPr(
    String workspaceId,
    String prExternalId,
  ) async => rows.values.toList();

  @override
  Future<void> upsert(
    String workspaceId,
    String prExternalId,
    ReviewAxisResult result,
  ) async => rows[result.axis.wireName] = result;

  @override
  Stream<List<ReviewAxisResult>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(rows.values.toList());
}

class _FakeSnapshots implements ReviewRunSnapshotRepository {
  final recorded = <ReviewRunSnapshot>[];
  ReviewRunSnapshot? latest;

  @override
  Future<void> record(String workspaceId, ReviewRunSnapshot snapshot) async {
    recorded.add(snapshot);
    latest = snapshot;
  }

  @override
  Future<ReviewRunSnapshot?> latestForPr(
    String workspaceId,
    String prExternalId,
  ) async => latest;

  @override
  Future<List<ReviewRunSnapshot>> forPr(
    String workspaceId,
    String prExternalId, {
    int limit = 20,
  }) async => recorded.reversed.toList();

  @override
  Future<ReviewRunStats> statsForWorkspace(String workspaceId) async {
    var total = const ReviewRunStats();
    for (final s in recorded) {
      total = total + s.stats;
    }
    return total;
  }
}

void main() {
  group('ReviewFinalizer', () {
    late _FakeMessaging messaging;
    late _FakeReviewChannels channels;
    late _FakeAxisResults axes;
    late _FakeSnapshots snapshots;

    ReviewFinalizer build() => ReviewFinalizer(
      messaging: messaging,
      reviewChannels: channels,
      reviewAxisResults: axes,
      runSnapshots: snapshots,
    );

    setUp(() {
      messaging = _FakeMessaging([]);
      channels = _FakeReviewChannels(_assoc());
      axes = _FakeAxisResults();
      snapshots = _FakeSnapshots();
    });

    Map<String, dynamic>? summaryMetadata() {
      for (final m in messaging.sent.reversed) {
        if (m['messageType'] == 'review_summary') {
          return m['metadata'] as Map<String, dynamic>?;
        }
      }
      return null;
    }

    test('throws when the channel is not linked to a PR', () {
      channels.association = null;
      expect(
        () => build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        ),
        throwsArgumentError,
      );
    });

    test('classifies peer-confirmed findings as consensus-ready', () async {
      messaging.messages = [
        _finding(id: 'f1', title: 'Missing null check', confirmedBy: ['b']),
        _finding(id: 'f2', title: 'Unbounded loop'),
      ];
      final result = await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
      );
      expect(result.consensusReadyCount, 1);
      expect(result.needsAdjudicationCount, 1);
    });

    test('excludes the author from their own confirmation', () async {
      messaging.messages = [
        _finding(
          id: 'f1',
          title: 'Self confirmed',
          senderId: 'agent-a',
          confirmedBy: ['agent-a'],
        ),
      ];
      final result = await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
      );
      expect(result.consensusReadyCount, 0);
    });

    test('transitions the association to awaiting approval', () async {
      messaging.messages = [_finding(id: 'f1', title: 'A finding')];
      await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
      );
      expect(channels.statusUpdates, [ReviewChannelStatus.awaitingApproval]);
    });

    test('a gated failing axis escalates the verdict', () async {
      messaging.messages = [
        _finding(id: 'f1', title: 'Minor nit', priority: ReviewNodePriority.p3),
      ];
      axes.rows['api_contract'] = const ReviewAxisResult(
        axis: ReviewAxis.apiContract,
        verdict: ReviewAxisVerdict.fail,
        findingsCount: 1,
        gated: true,
        confidence: 1,
      );
      final result = await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
      );
      expect(result.verdict.overall, ReviewVerdictOverall.block);
    });

    test('derives advisory token axes from the findings', () async {
      messaging.messages = [
        _finding(
          id: 'f1',
          title: 'Injection',
          axis: ReviewAxis.security,
          priority: ReviewNodePriority.p0,
        ),
      ];
      await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
      );
      final security = axes.rows['security']!;
      expect(security.verdict, ReviewAxisVerdict.fail);
      expect(
        security.gated,
        isFalse,
        reason: 'token axes are advisory so they cannot double-count',
      );
    });

    test('attaches an axis note without inventing a verdict', () async {
      axes.rows['correctness'] = const ReviewAxisResult(
        axis: ReviewAxis.correctness,
        verdict: ReviewAxisVerdict.pass,
        findingsCount: 0,
        gated: false,
        confidence: 1,
      );
      messaging.messages = [_finding(id: 'f1', title: 'Unrelated')];
      await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
        axisNotes: const {ReviewAxis.correctness: 'CI failure points at x'},
      );
      final correctness = axes.rows['correctness']!;
      expect(correctness.note, contains('CI failure'));
      expect(
        correctness.verdict,
        ReviewAxisVerdict.pass,
        reason: 'a note annotates an axis, it does not re-judge it',
      );
    });

    test('embeds the walkthrough in the summary metadata', () async {
      messaging.messages = [_finding(id: 'f1', title: 'A finding')];
      await build().finalize(
        workspaceId: _workspaceId,
        channelId: _channelId,
        finalizerId: 'ceo',
        headSha: 'abc1234',
        walkthrough: const ReviewWalkthroughSummary(
          headline: 'Reworks token refresh',
          areas: [],
        ),
      );
      final restored = ReviewWalkthroughSummary.fromMetadata(summaryMetadata());
      expect(restored?.headline, 'Reworks token refresh');
      expect(restored?.headSha, 'abc1234');
    });

    group('delta-aware re-review', () {
      test('a first pass records a snapshot and reports no delta', () async {
        messaging.messages = [_finding(id: 'f1', title: 'Missing null check')];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
          headSha: 'sha1',
        );
        expect(result.delta, isNull);
        expect(snapshots.recorded, hasLength(1));
        expect(snapshots.recorded.single.fingerprints, hasLength(1));
        expect(summaryMetadata()?['deltaSinceLast'], isNull);
      });

      test('a second pass reports resolved, new and still-open', () async {
        messaging.messages = [
          _finding(id: 'f1', title: 'Missing null check'),
          _finding(id: 'f2', title: 'Unbounded retry loop'),
        ];
        await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
          headSha: 'sha1',
        );

        // Second pass: f1 restated (at a different id), f2 gone, one new.
        messaging = _FakeMessaging([
          _finding(id: 'f3', title: 'Missing null check'),
          _finding(id: 'f4', title: 'Race in the token cache'),
        ]);
        final second = await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
          headSha: 'sha2',
        );

        final delta = second.delta!;
        expect(delta.stillOpen, hasLength(1));
        expect(delta.resolvedSinceLast, hasLength(1));
        expect(delta.newFindings, hasLength(1));
        expect(delta.newFindings.single.title, 'Race in the token cache');

        final meta =
            summaryMetadata()!['deltaSinceLast'] as Map<String, dynamic>;
        expect(meta['previousHeadSha'], 'sha1');
        expect(meta['resolved'], 1);
        expect(meta['new'], 1);
        expect(meta['stillOpen'], 1);
        expect(meta['newMessageIds'], contains('f4'));
      });

      test('a rebase does not turn a carried finding into a new one', () async {
        messaging.messages = [
          _finding(id: 'f1', title: 'Missing null check on line 42'),
        ];
        await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
          headSha: 'sha1',
        );

        // Same finding, different line quoted in the title.
        messaging = _FakeMessaging([
          _finding(id: 'f2', title: 'Missing null check on line 87'),
        ]);
        final second = await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
          headSha: 'sha2',
        );
        expect(second.delta!.newFindings, isEmpty);
        expect(second.delta!.stillOpen, hasLength(1));
      });

      test('a static-rule finding matches on its rule id', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Downloads and pipes a remote script into a shell',
            provenance: ReviewFindingProvenance.staticRule,
            ruleId: 'curl_pipe_shell',
          ),
        ];
        await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        );

        // Completely reworded message, same rule and file.
        messaging = _FakeMessaging([
          _finding(
            id: 'f2',
            title: 'Remote script executed via a pipe',
            provenance: ReviewFindingProvenance.staticRule,
            ruleId: 'curl_pipe_shell',
          ),
        ]);
        final second = await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        );
        expect(
          second.delta!.newFindings,
          isEmpty,
          reason: 'the rule id is the identity, not the wording',
        );
      });

      test('a finding resolved between passes counts as resolved', () async {
        messaging.messages = [_finding(id: 'f1', title: 'Missing null check')];
        await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        );

        messaging = _FakeMessaging([
          _finding(
            id: 'f1',
            title: 'Missing null check',
            status: ReviewNodeStatus.resolved,
          ),
        ]);
        final second = await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        );
        expect(second.delta!.resolvedSinceLast, hasLength(1));
        expect(second.delta!.stillOpen, isEmpty);
      });

      test('the snapshot carries the pass counts', () async {
        messaging.messages = [
          _finding(id: 'f1', title: 'Open one'),
          _finding(
            id: 'f2',
            title: 'Dealt with',
            status: ReviewNodeStatus.resolved,
          ),
        ];
        await build().finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        );
        final stats = snapshots.recorded.single.stats;
        expect(stats.findingsTotal, 2);
        expect(stats.resolved, 1);
        expect(stats.stillOpen, 1);
        expect(stats.addressed, 1);
      });

      test('finalizing still succeeds with no snapshot store wired', () async {
        messaging.messages = [_finding(id: 'f1', title: 'A finding')];
        final finalizer = ReviewFinalizer(
          messaging: messaging,
          reviewChannels: channels,
          reviewAxisResults: axes,
        );
        final result = await finalizer.finalize(
          workspaceId: _workspaceId,
          channelId: _channelId,
          finalizerId: 'ceo',
        );
        expect(result.delta, isNull);
        expect(channels.statusUpdates, [ReviewChannelStatus.awaitingApproval]);
      });
    });
  });
}
