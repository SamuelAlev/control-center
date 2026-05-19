import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/pr_review/review_hub_service.dart';
import 'package:test/test.dart';

/// Hand-written fakes (the repo's convention): only the members the hub touches
/// carry behaviour; the rest forward to [noSuchMethod] and throw.

class _MessagingRepo implements MessagingRepository {
  final messages = <ChannelMessage>[];
  final sent = <String>[];

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
    sent.add(messageType);
    return '';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessagingPort implements MessagingPort {
  final dispatched =
      <({String agentId, String prompt, Map<String, dynamic>? schema})>[];

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    dispatched.add((
      agentId: agentId,
      prompt: prompt,
      schema: expectedOutputSchema,
    ));
    return 'run-$agentId';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewChannels implements ReviewChannelRepository {
  ReviewChannelAssociation? byPr;

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(byPr);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RunLogs implements AgentRunLogRepository {
  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(const []);

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  _Agents({this.ceo});

  final Agent? ceo;

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => name == 'ceo' ? ceo : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workspaces implements WorkspaceRepository {
  _Workspaces({this.autoPublish = false});

  final bool autoPublish;

  @override
  Future<Workspace?> getById(String id) async => Workspace(
    id: id,
    name: 'ws',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    autoPublishReview: autoPublish,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Publisher implements ReviewPublisherPort {
  int calls = 0;

  @override
  Future<PublishReviewResult> publish({
    required String workspaceId,
    required String channelId,
    ReviewPublishSelection selection = ReviewPublishSelection.consensus,
    bool approveOnShip = false,
  }) async {
    calls++;
    return const PublishReviewResult(
      reviewId: 1,
      event: 'COMMENT',
      findingCount: 0,
      inlineCount: 0,
      usedFallback: false,
    );
  }
}

class _FakeDispatchers implements DispatchReviewersService {
  Map<String, dynamic>? lastCall;
  bool dispatchEmpty = false;

  @override
  Future<Map<String, dynamic>> dispatch({
    required String channelId,
    required String workspaceId,
    required List<Map<String, dynamic>> reviewers,
    int? concurrency,
    String? cohortBrief,
  }) async {
    lastCall = {
      'channelId': channelId,
      'reviewers': reviewers,
      'cohortBrief': cohortBrief,
    };
    return {
      'dispatched': dispatchEmpty
          ? []
          : [
              {'role': 'qa'},
            ],
      'unmatched': const [],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingFinalizer implements ReviewFinalizer {
  final calls = <({String? headSha, ReviewWalkthroughSummary? walkthrough})>[];

  @override
  Future<ReviewFinalization> finalize({
    required String workspaceId,
    required String channelId,
    required String finalizerId,
    String? editorialNote,
    ReviewWalkthroughSummary? walkthrough,
    String? headSha,
    Map<ReviewAxis, String> axisNotes = const {},
  }) async {
    calls.add((headSha: headSha, walkthrough: walkthrough));
    return ReviewFinalization(
      summaryMessageId: 's-1',
      channelId: channelId,
      reviewId: 'r-1',
      verdict: const ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 1,
        explanation: '',
        counts: {},
      ),
      consensusReadyCount: 0,
      needsAdjudicationCount: 0,
    );
  }
}

const _cohort = ReviewCohort(
  id: 'c-1',
  workspaceId: 'ws',
  prExternalId: 'node-1',
  cohortKey: 'auth',
  title: 'Auth flow',
  orderIndex: 0,
  impactScore: 7,
  filePaths: ['lib/a.dart'],
);

Agent _ceo() => Agent(
  id: 'ceo',
  name: 'ceo',
  title: 'CEO',
  agentMdPath: '/tmp/ceo.md',
  workspaceId: 'ws',
  skills: AgentSkills(const []),
  createdAt: DateTime.utc(2026),
);

ReviewHubService _hub({
  required _RecordingFinalizer finalizer,
  required _Publisher publisher,
  required _FakeDispatchers dispatchers,
  required _MessagingPort messagingPort,
  _ReviewChannels? channels,
  _Workspaces? workspaces,
  _Agents? agents,
  _MessagingRepo? messaging,
}) {
  return ReviewHubService(
    resolvePr:
        ({
          required workspaceId,
          required owner,
          required repo,
          required prNumber,
        }) async => const ReviewHubPrContext(
          externalId: 'node-1',
          headSha: 'sha-1',
          title: 'A PR',
        ),
    ensureChannel:
        ({
          required workspaceId,
          required repoFullName,
          required prNumber,
          required prExternalId,
          String? createdByUserId,
          String title = '',
        }) async => 'ch-1',
    computeCohorts:
        ({
          required workspaceId,
          required owner,
          required repo,
          required prNumber,
        }) async => [_cohort],
    dispatchReviewers: dispatchers,
    finalizer: finalizer,
    messaging: messaging ?? _MessagingRepo(),
    messagingPort: messagingPort,
    reviewChannels: channels ?? _ReviewChannels(),
    runLogs: _RunLogs(),
    agents: agents ?? _Agents(ceo: _ceo()),
    workspaces: workspaces ?? _Workspaces(),
    publisher: publisher,
    pollInterval: const Duration(milliseconds: 1),
  );
}

/// Waits until [check] passes (the orchestration runs in the background).
Future<void> _until(bool Function() check) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met before timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  test(
    'start returns started and runs the orchestration to finalize',
    () async {
      final finalizer = _RecordingFinalizer();
      final publisher = _Publisher();
      final dispatchers = _FakeDispatchers();
      final hub = _hub(
        finalizer: finalizer,
        publisher: publisher,
        dispatchers: dispatchers,
        messagingPort: _MessagingPort(),
      );

      final result = await hub.start(
        workspaceId: 'ws',
        owner: 'org',
        repo: 'repo',
        prNumber: 7,
      );

      expect(result['status'], 'started');
      expect(result['channel_id'], 'ch-1');
      await _until(() => finalizer.calls.isNotEmpty);

      // The reviewer fan-out received the deterministic area map.
      expect(dispatchers.lastCall?['cohortBrief'], contains('Auth flow'));
      expect(dispatchers.lastCall?['cohortBrief'], contains('cohort_key'));
      // Finalize carries the head SHA stamp (pushes invalidate the summary).
      expect(finalizer.calls.single.headSha, 'sha-1');
      // Auto-publish is OFF by default.
      expect(publisher.calls, 0);
    },
  );

  test('auto-publish fires only when the workspace opted in', () async {
    final finalizer = _RecordingFinalizer();
    final publisher = _Publisher();
    final hub = _hub(
      finalizer: finalizer,
      publisher: publisher,
      dispatchers: _FakeDispatchers(),
      messagingPort: _MessagingPort(),
      workspaces: _Workspaces(autoPublish: true),
    );

    await hub.start(workspaceId: 'ws', owner: 'org', repo: 'repo', prNumber: 7);
    await _until(() => publisher.calls > 0);
    expect(finalizer.calls, hasLength(1));
  });

  test('a review already in progress is not double-started', () async {
    final channels = _ReviewChannels()
      ..byPr = ReviewChannelAssociation(
        id: 'r-1',
        channelId: 'ch-1',
        workspaceId: 'ws',
        prExternalId: 'node-1',
        prNumber: 7,
        repoFullName: 'org/repo',
        status: ReviewChannelStatus.inProgress,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
    final finalizer = _RecordingFinalizer();
    final dispatchers = _FakeDispatchers();
    final hub = _hub(
      finalizer: finalizer,
      publisher: _Publisher(),
      dispatchers: dispatchers,
      messagingPort: _MessagingPort(),
      channels: channels,
    );

    final result = await hub.start(
      workspaceId: 'ws',
      owner: 'org',
      repo: 'repo',
      prNumber: 7,
    );

    expect(result['status'], 'already_running');
    // Give a stray orchestration a chance to fire — none was scheduled.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(dispatchers.lastCall, isNull);
    expect(finalizer.calls, isEmpty);
  });

  test('no CEO agent → finalize still runs, without a walkthrough', () async {
    final finalizer = _RecordingFinalizer();
    final hub = _hub(
      finalizer: finalizer,
      publisher: _Publisher(),
      dispatchers: _FakeDispatchers(),
      messagingPort: _MessagingPort(),
      agents: _Agents(ceo: null),
    );

    await hub.start(workspaceId: 'ws', owner: 'org', repo: 'repo', prNumber: 7);
    await _until(() => finalizer.calls.isNotEmpty);

    expect(finalizer.calls.single.walkthrough, isNull);
  });

  test('no matched reviewers → narrates and never finalizes', () async {
    final finalizer = _RecordingFinalizer();
    final messaging = _MessagingRepo();
    final dispatchers = _FakeDispatchers()..dispatchEmpty = true;
    final hub = _hub(
      finalizer: finalizer,
      publisher: _Publisher(),
      dispatchers: dispatchers,
      messagingPort: _MessagingPort(),
      messaging: messaging,
    );

    await hub.start(workspaceId: 'ws', owner: 'org', repo: 'repo', prNumber: 7);
    await _until(
      () => messaging.sent.contains('system') && messaging.sent.length >= 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(finalizer.calls, isEmpty);
  });
}
