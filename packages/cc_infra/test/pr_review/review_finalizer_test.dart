import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_infra/src/pr_review/review_finalizer.dart';
import 'package:test/test.dart';

const _workspaceId = 'ws';
const _spaceId = 'ch';
const _prExternalId = 'PR_node';

ReviewSpaceAssociation _assoc({
  ReviewSpaceStatus status = ReviewSpaceStatus.inProgress,
}) => ReviewSpaceAssociation(
  id: 'assoc-1',
  spaceId: _spaceId,
  workspaceId: _workspaceId,
  prExternalId: _prExternalId,
  prNumber: 42,
  repoFullName: 'o/r',
  status: status,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

Message _finding({
  required String id,
  required String title,
  String senderId = 'agent-a',
  String? filePath = 'lib/auth.dart',
  int? lineNumber,
  ReviewNodeKind kind = ReviewNodeKind.bug,
  ReviewNodePriority priority = ReviewNodePriority.p1,
  ReviewNodeStatus status = ReviewNodeStatus.open,
  List<String> confirmedBy = const [],
  ReviewAxis? axis,
  ReviewFindingProvenance provenance = ReviewFindingProvenance.agent,
  String? ruleId,
  double confidence = 0.8,
  ReviewFindingSeverity? severity,
}) => Message(
  id: id,
  spaceId: _spaceId,
  conversationId: _spaceId,
  senderId: senderId,
  senderType: SenderType.agent,
  content: title,
  messageType: MessageType.reviewNode,
  createdAt: DateTime.utc(2024, 1, 1),
  metadata: ReviewNodePayload(
    kind: kind,
    priority: severity?.toPriority() ?? priority,
    confidence: confidence,
    anchor: ReviewNodeAnchor(filePath: filePath, lineNumber: lineNumber),
    status: status,
    confirmedBy: confirmedBy,
    axis: axis,
    provenance: provenance,
    ruleId: ruleId,
    severity: severity,
  ).toMetadata(),
);

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this.messages);

  List<Message> messages;
  final sent = <Map<String, dynamic>>[];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => messages;

  // The finalizer gathers space-wide — findings are filed in each reviewer's
  // own stream, not the room's standing conversation.
  @override
  Future<List<Message>> getSpaceMessages(
    String workspaceId,
    String spaceId,
  ) async => messages;

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
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
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeReviewSpaces implements ReviewSpaceRepository {
  _FakeReviewSpaces(this.association);

  ReviewSpaceAssociation? association;
  final statusUpdates = <ReviewSpaceStatus>[];

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(association);

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
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

  /// Titles a human dismissed in past reviews, as the suppression loop reads
  /// them back.
  List<String> dismissedTitles = const [];

  @override
  Future<List<String>> dismissedFindingTitles(
    String workspaceId, {
    int limit = 200,
  }) async => dismissedTitles;

  @override
  Future<ReviewRunStats> statsForWorkspace(String workspaceId) async {
    var total = const ReviewRunStats();
    for (final s in recorded) {
      total = total + s.stats;
    }
    return total;
  }

  /// Status decisions written back onto a finalized pass, by message id.
  final appliedStatuses = <String, ReviewNodeStatus>{};

  @override
  Future<int> applyFindingStatus(
    String workspaceId,
    String prExternalId,
    String nodeMessageId,
    ReviewNodeStatus status,
  ) async {
    appliedStatuses[nodeMessageId] = status;
    return 1;
  }
}

void main() {
  group('ReviewFinalizer', () {
    late _FakeMessaging messaging;
    late _FakeReviewSpaces spaces;
    late _FakeAxisResults axes;
    late _FakeSnapshots snapshots;

    ReviewFinalizer build() => ReviewFinalizer(
      messaging: messaging,
      reviewSpaces: spaces,
      reviewAxisResults: axes,
      runSnapshots: snapshots,
    );

    setUp(() {
      messaging = _FakeMessaging([]);
      spaces = _FakeReviewSpaces(_assoc());
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

    test('throws when the space is not linked to a PR', () {
      spaces.association = null;
      expect(
        () => build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
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
        spaceId: _spaceId,
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
        spaceId: _spaceId,
        finalizerId: 'ceo',
      );
      expect(result.consensusReadyCount, 0);
    });

    test('transitions the association to awaiting approval', () async {
      messaging.messages = [_finding(id: 'f1', title: 'A finding')];
      await build().finalize(
        workspaceId: _workspaceId,
        spaceId: _spaceId,
        finalizerId: 'ceo',
      );
      expect(spaces.statusUpdates, [ReviewSpaceStatus.awaitingApproval]);
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
        spaceId: _spaceId,
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
        spaceId: _spaceId,
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
        spaceId: _spaceId,
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
        spaceId: _spaceId,
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

    // The review level is a REPORTING dial. It decides where a finding is
    // rendered, never whether it exists and never whether the PR ships.
    group('review level demotion', () {
      Future<ReviewFinalization> finalizeAt(ReviewLevel level) => build()
          .finalize(
            workspaceId: _workspaceId,
            spaceId: _spaceId,
            finalizerId: 'ceo',
            level: level,
          );

      String summaryBody() {
        for (final m in messaging.sent.reversed) {
          if (m['messageType'] == 'review_summary') {
            return m['content'] as String;
          }
        }
        return '';
      }

      test('balanced demotes trivial and info, keeps minor', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
          _finding(
            id: 'f2',
            title: 'Handle the empty list',
            severity: ReviewFindingSeverity.minor,
          ),
        ];
        final result = await finalizeAt(ReviewLevel.balanced);
        expect(result.nitpickMessageIds, ['f1']);
      });

      test('light also demotes minor', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Handle the empty list',
            severity: ReviewFindingSeverity.minor,
          ),
        ];
        final result = await finalizeAt(ReviewLevel.light);
        expect(result.nitpickMessageIds, ['f1']);
      });

      test('thorough demotes nothing', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
          _finding(
            id: 'f2',
            title: 'Drop the unused import',
            severity: ReviewFindingSeverity.info,
          ),
        ];
        final result = await finalizeAt(ReviewLevel.thorough);
        expect(result.nitpickMessageIds, isEmpty);
      });

      test('critical and major are never demoted, at any level', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Await the future',
            severity: ReviewFindingSeverity.critical,
          ),
          _finding(
            id: 'f2',
            title: 'Guard the cast',
            severity: ReviewFindingSeverity.major,
          ),
        ];
        for (final level in ReviewLevel.values) {
          messaging.sent.clear();
          final result = await finalizeAt(level);
          expect(result.nitpickMessageIds, isEmpty, reason: level.name);
        }
      });

      test('a demoted finding is still counted, never dropped', () async {
        // Demotion is a rendering decision. If it removed findings from the
        // counts, the review would under-report itself.
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
          _finding(
            id: 'f2',
            title: 'Handle the empty list',
            severity: ReviewFindingSeverity.minor,
          ),
        ];
        final result = await finalizeAt(ReviewLevel.balanced);
        expect(
          result.consensusReadyCount + result.needsAdjudicationCount,
          2,
        );
      });

      test('the verdict is identical with and without demotion', () async {
        // The dial must not be able to change whether a PR ships.
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Await the future',
            severity: ReviewFindingSeverity.critical,
          ),
          _finding(
            id: 'f2',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
        ];
        final thorough = await finalizeAt(ReviewLevel.thorough);
        messaging.sent.clear();
        final light = await finalizeAt(ReviewLevel.light);

        expect(light.verdict.overall, thorough.verdict.overall);
        expect(light.verdict.p0Count, thorough.verdict.p0Count);
        expect(light.verdict.p1Count, thorough.verdict.p1Count);
        expect(light.verdict.p2Count, thorough.verdict.p2Count);
        expect(light.verdict.p3Count, thorough.verdict.p3Count);
      });

      test('demoted findings render in a collapsed, counted group', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
        ];
        await finalizeAt(ReviewLevel.balanced);
        final body = summaryBody();
        expect(body, contains('<details>'));
        expect(body, contains('Nitpicks (1)'));
        expect(body, contains('Rename the local'));
      });

      test('stamps the level and the demoted ids on the summary', () async {
        // The publisher reads both, so the GitHub review collapses exactly
        // what the app collapsed.
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
        ];
        await finalizeAt(ReviewLevel.balanced);
        final meta = summaryMetadata();
        expect(meta?['reviewLevel'], 'balanced');
        expect(meta?['nitpickMessageIds'], ['f1']);
      });

      test('a legacy priority-only finding demotes on its priority', () async {
        // No severity stored: the payload falls back to the priority mapping,
        // so an old review still groups sensibly instead of treating every
        // finding as top-severity.
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Nice to have',
            priority: ReviewNodePriority.p3,
          ),
        ];
        final result = await finalizeAt(ReviewLevel.balanced);
        expect(result.nitpickMessageIds, ['f1']);
      });

      test('defaults to balanced when no level is given', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
          _finding(
            id: 'f2',
            title: 'Handle the empty list',
            severity: ReviewFindingSeverity.minor,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.nitpickMessageIds, ['f1']);
      });

      test('reports an effort estimate on the summary', () async {
        messaging.messages = [_finding(id: 'f1', title: 'A finding')];
        await finalizeAt(ReviewLevel.balanced);
        final meta = summaryMetadata();
        expect(meta?['summaryEffortScore'], isA<int>());
        expect(meta?['summaryEffortMinutes'], isA<int>());
        expect(summaryBody(), contains('Estimated review effort'));
      });
    });

    group('confidence gate', () {
      test('a low-confidence minor finding is demoted', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Handle the empty list',
            severity: ReviewFindingSeverity.minor,
            confidence: 0.4,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.nitpickMessageIds, ['f1']);
      });

      test('the same finding held confidently is reported', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Handle the empty list',
            severity: ReviewFindingSeverity.minor,
            confidence: 0.95,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.nitpickMessageIds, isEmpty);
      });

      test('a shaky critical finding is still reported', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Leaks the token',
            severity: ReviewFindingSeverity.critical,
            confidence: 0.2,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.nitpickMessageIds, isEmpty);
      });
    });

    // The fan-out points several reviewers at one diff with overlapping
    // remits, so the same defect arriving twice is the system working.
    // Publishing it twice is the system leaking its architecture at the reader.
    group('cross-reviewer dedup', () {
      test('collapses two findings on overlapping lines', () async {
        messaging.messages = [
          _finding(
            id: 'weak',
            title: 'Guard the cast',
            senderId: 'agent-a',
            filePath: 'lib/a.dart',
            lineNumber: 10,
            severity: ReviewFindingSeverity.minor,
          ),
          _finding(
            id: 'strong',
            title: 'Guard the cast before dereferencing',
            senderId: 'agent-b',
            filePath: 'lib/a.dart',
            lineNumber: 10,
            severity: ReviewFindingSeverity.critical,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        // The strongest survives; the weaker is demoted, not deleted.
        expect(result.nitpickMessageIds, ['weak']);
        expect(
          result.consensusReadyCount + result.needsAdjudicationCount,
          2,
        );
      });

      test('leaves findings on different lines alone', () async {
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'One',
            filePath: 'lib/a.dart',
            lineNumber: 10,
            severity: ReviewFindingSeverity.minor,
          ),
          _finding(
            id: 'f2',
            title: 'Two',
            filePath: 'lib/a.dart',
            lineNumber: 90,
            severity: ReviewFindingSeverity.minor,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.nitpickMessageIds, isEmpty);
      });

      test('never collapses two file-level findings', () async {
        // They share a file but no position; merging them would silently drop
        // an unrelated observation.
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'One',
            filePath: 'lib/a.dart',
            severity: ReviewFindingSeverity.minor,
          ),
          _finding(
            id: 'f2',
            title: 'Two',
            filePath: 'lib/a.dart',
            severity: ReviewFindingSeverity.minor,
          ),
        ];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.nitpickMessageIds, isEmpty);
      });
    });

    group('clean review', () {
      String summaryBody() {
        for (final m in messaging.sent.reversed) {
          if (m['messageType'] == 'review_summary') {
            return m['content'] as String;
          }
        }
        return '';
      }

      test('a review that found nothing is one line', () async {
        // The most-read review is the one that found nothing, and a reader who
        // must scroll to learn that stops opening them.
        messaging.messages = [];
        await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        final body = summaryBody().trim();
        expect(body, contains('No issues found'));
        expect(body, isNot(contains('# Review summary')));
        expect(body, isNot(contains('Consensus-ready')));
        expect(body, isNot(contains('Walkthrough')));
        expect(body.split('\n').where((l) => l.trim().isNotEmpty), hasLength(1));
      });

      test('a review with only nitpicks still renders in full', () async {
        // Something was found; the reader gets the structure to read it in.
        messaging.messages = [
          _finding(
            id: 'f1',
            title: 'Rename the local',
            severity: ReviewFindingSeverity.trivial,
          ),
        ];
        await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(summaryBody(), contains('# Review summary'));
        expect(summaryBody(), contains('Nitpicks (1)'));
      });
    });

    group('delta-aware re-review', () {
      test('a first pass records a snapshot and reports no delta', () async {
        messaging.messages = [_finding(id: 'f1', title: 'Missing null check')];
        final result = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          spaceId: _spaceId,
          finalizerId: 'ceo',
          headSha: 'sha1',
        );

        // Same finding, different line quoted in the title.
        messaging = _FakeMessaging([
          _finding(id: 'f2', title: 'Missing null check on line 87'),
        ]);
        final second = await build().finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          spaceId: _spaceId,
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
          reviewSpaces: spaces,
          reviewAxisResults: axes,
        );
        final result = await finalizer.finalize(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          finalizerId: 'ceo',
        );
        expect(result.delta, isNull);
        expect(spaces.statusUpdates, [ReviewSpaceStatus.awaitingApproval]);
      });
    });
  });
}
