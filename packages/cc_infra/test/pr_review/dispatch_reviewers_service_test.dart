import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/pr_review/dispatch_reviewers_service.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/workspaces/workspace_filesystem_service.dart';
import 'package:test/test.dart';

Agent _agent({
  required String id,
  required String name,
  String title = 'Engineer',
  List<String> skills = const [],
  String workspaceId = 'ws',
}) => Agent(
  id: id,
  name: name,
  title: title,
  agentMdPath: '/agents/$id.md',
  workspaceId: workspaceId,
  skills: AgentSkills(skills),
  createdAt: DateTime.utc(2024, 1, 1),
);

ChannelParticipant _agentParticipant(String channelId, String agentId) =>
    ChannelParticipant(
      id: 'p-$agentId',
      channelId: channelId,
      principalId: agentId,
      participantType: PrincipalType.agent,
      role: 'reviewer',
      joinedAt: DateTime.utc(2024, 1, 1),
    );

Workspace _workspace({
  String id = 'ws',
  String name = 'Ws',
  int reviewConcurrency = 3,
}) => Workspace(
  id: id,
  name: name,
  reviewConcurrency: reviewConcurrency,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

ReviewChannelAssociation _assoc({
  String id = 'assoc-1',
  String channelId = 'ch',
  String workspaceId = 'ws',
  int prNumber = 42,
  String repoFullName = 'o/r',
  ReviewChannelStatus status = ReviewChannelStatus.requested,
}) => ReviewChannelAssociation(
  id: id,
  channelId: channelId,
  workspaceId: workspaceId,
  prExternalId: 'PR_node',
  prNumber: prNumber,
  repoFullName: repoFullName,
  status: status,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo(this._workspaceAgents);
  final Map<String, List<Agent>> _workspaceAgents;
  @override
  Stream<List<Agent>> watchAll() async* {
    yield _workspaceAgents.values.expand((l) => l).toList();
  }

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) async* {
    yield _workspaceAgents[workspaceId] ?? const [];
  }

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      (_workspaceAgents[workspaceId] ?? const <Agent>[]).firstWhereOrNull(
        (a) => a.id == id,
      );

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => (_workspaceAgents[workspaceId] ?? const [])
      .where((a) => a.name == name)
      .firstOrNull;

  @override
  Future<void> upsert(Agent agent) async {}

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }
}

class _FakeWorkspaceRepo implements WorkspaceRepository {
  _FakeWorkspaceRepo(this._workspaces);
  final List<Workspace> _workspaces;
  @override
  Stream<List<Workspace>> watchAll() async* {
    yield List.unmodifiable(_workspaces);
  }

  @override
  Future<List<Workspace>> getAll() async => List.unmodifiable(_workspaces);

  @override
  Future<Workspace?> getById(String id) async =>
      _workspaces.where((w) => w.id == id).firstOrNull;

  @override
  Future<String> upsert(Workspace workspace) async => workspace.id;

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) async* {
    yield const [];
  }

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {}

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => false;

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
}

class _FakeReviewChannelRepo implements ReviewChannelRepository {
  _FakeReviewChannelRepo(this._byChannel);
  final Map<String, ReviewChannelAssociation> _byChannel;
  final List<(String, String, ReviewChannelStatus)> updates = [];

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) async* {
    yield null;
  }

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) async* {
    final association = _byChannel[channelId];
    yield association?.workspaceId == workspaceId ? association : null;
  }

  @override
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) async* {
    final a = _byChannel[channelId];
    yield a == null ? const [] : [a];
  }

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(
    String workspaceId,
  ) async* {
    yield _byChannel.values.where((a) => a.workspaceId == workspaceId).toList();
  }

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async {
    updates.add((workspaceId, id, status));
  }
}

class _FakeMessagingRepo implements MessagingRepository {
  _FakeMessagingRepo({this.participants = const []});
  List<ChannelParticipant> participants;
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    participants = [
      ...participants,
      ChannelParticipant(
        id: 'p-$principalId',
        channelId: channelId,
        principalId: principalId,
        participantType: participantType,
        role: 'reviewer',
        joinedAt: DateTime.utc(2024, 1, 1),
      ),
    ];
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => participants.where((p) => p.channelId == channelId).toList();

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
      'workspaceId': workspaceId,
      'channelId': channelId,
      'content': content,
      'senderId': senderId,
      'messageType': messageType,
    });
    return id ?? 'msg-${sent.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessagingPort implements MessagingPort {
  _FakeMessagingPort();
  final List<Map<String, dynamic>> dispatched = [];

  @override
  Future<String?> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
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
    dispatched.add({
      'channelId': channelId,
      'agentId': agentId,
      'prompt': prompt,
      'workspaceId': workspaceId,
    });
    return 'run-${dispatched.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dispatch_reviewers_test_');
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  DispatchReviewersService service({
    required _FakeAgentRepo agents,
    required _FakeMessagingRepo messaging,
    required _FakeReviewChannelRepo reviewChannels,
    required _FakeMessagingPort messagingPort,
    required _FakeWorkspaceRepo workspaces,
  }) => DispatchReviewersService(
    agents: agents,
    messaging: messaging,
    reviewChannels: reviewChannels,
    messagingPort: messagingPort,
    workspaces: workspaces,
    filesystemPort: WorkspaceFilesystemService(CcPaths(temp.path)),
  );

  group('DispatchReviewersService.dispatch', () {
    test('matches agents by role and dispatches', () async {
      final agents = _FakeAgentRepo({
        'ws': [
          _agent(id: 'a1', name: 'Alice', title: 'Senior Flutter Engineer'),
          _agent(id: 'a2', name: 'Bob', title: 'Security Reviewer'),
        ],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'security'},
        ],
      );

      expect(result['channel_id'], 'ch');
      expect(result['concurrency'], 3);
      final dispatched = result['dispatched'] as List;
      expect(dispatched, hasLength(2));
      final dispatchedRoles = dispatched.map((d) => (d as Map)['role']).toSet();
      expect(dispatchedRoles, {'flutter', 'security'});
      expect(result['unmatched'], isEmpty);
      expect(messagingPort.dispatched, hasLength(2));
      // Each agent got a system mention message + a dispatch.
      expect(
        messaging.sent.where((m) => m['messageType'] == 'system').length,
        2,
      );
      // Association was advanced to inProgress.
      expect(reviewChannels.updates.single, (
        'ws',
        'assoc-1',
        ReviewChannelStatus.inProgress,
      ));
    });

    test('unmatched roles are reported without dispatching', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
          {'role': 'nonexistent'},
        ],
      );

      final dispatched = result['dispatched'] as List;
      expect(dispatched, hasLength(1));
      final unmatched = result['unmatched'] as List;
      expect(unmatched, hasLength(1));
      expect((unmatched.first as Map)['role'], 'nonexistent');
      expect(messagingPort.dispatched, hasLength(1));
    });

    test('reviewer entries with missing/empty role are skipped', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': ''},
          {'role': 42},
          {'foo': 'bar'},
          {'role': 'flutter'},
        ],
      );

      final dispatched = result['dispatched'] as List;
      expect(dispatched, hasLength(1));
      expect(result['unmatched'], isEmpty);
    });

    test('scope and prompt_override are honored', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {
            'role': 'flutter',
            'scope': 'lib/**',
            'prompt_override': 'Custom brief',
          },
        ],
      );

      final dispatched = result['dispatched'] as List;
      expect(dispatched, hasLength(1));
      expect(messagingPort.dispatched.first['prompt'], 'Custom brief');
    });

    test('default brief references PR number and repo', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatched.first['prompt'] as String;
      expect(prompt, contains('PR #42'));
      expect(prompt, contains('o/r'));
      expect(prompt, contains('add_review_node'));
    });

    test('default brief without prNumber uses generic phrasing', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      // No association → prNumber null → generic phrasing.
      final reviewChannels = _FakeReviewChannelRepo({});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatched.first['prompt'] as String;
      // No association → prNumber null → generic phrasing with empty repo.
      expect(prompt, contains('the PR in .'));
      expect(prompt, isNot(contains('PR #')));
    });

    test('uses workspace reviewConcurrency when concurrency is null', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace(reviewConcurrency: 7)]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );
      expect(result['concurrency'], 7);
    });

    test('explicit concurrency overrides workspace', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace(reviewConcurrency: 7)]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
        concurrency: 2,
      );
      expect(result['concurrency'], 2);
    });

    test('default concurrency 3 when workspace missing', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      // Workspace list missing the workspace id.
      final workspaces = _FakeWorkspaceRepo([
        _workspace(id: 'other', name: 'Other'),
      ]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      final result = await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );
      expect(result['concurrency'], 3);
    });

    test('existing participant is not re-added', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo(
        participants: [_agentParticipant('ch', 'a1')],
      );
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      // a1 already present — no second addParticipant.
      expect(
        messaging.participants.where((p) => p.principalId == 'a1').length,
        1,
      );
    });

    test('status is not advanced when no reviewers dispatched', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'nomatch'},
        ],
      );

      expect(reviewChannels.updates, isEmpty);
    });

    test('status not advanced when association already inProgress', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({
        'ch': _assoc(status: ReviewChannelStatus.inProgress),
      });
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(reviewChannels.updates, isEmpty);
    });

    test('status not advanced when association is null', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      expect(reviewChannels.updates, isEmpty);
    });

    test('default brief references local repo path when present', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      // Materialize a fake worktree under the provisioner's layout
      // (<root>/<ws>/conversations/<ch>/repos/<slug>) so _resolveRepoPath
      // finds it. The assoc's repoFullName is 'o/r' → slug 'r'. A sibling
      // worktree proves the slug match wins over "the only one".
      final repoDir = Directory('${temp.path}/ws/conversations/ch/repos/r');
      await repoDir.create(recursive: true);
      await Directory(
        '${temp.path}/ws/conversations/ch/repos/other',
      ).create(recursive: true);

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter'},
        ],
      );

      final prompt = messagingPort.dispatched.first['prompt'] as String;
      expect(prompt, contains('The repository is cloned at'));
      expect(prompt, contains(repoDir.path));
    });

    test('scope produces a scope-note line in the brief', () async {
      final agents = _FakeAgentRepo({
        'ws': [_agent(id: 'a1', name: 'Alice', title: 'Flutter Engineer')],
      });
      final messaging = _FakeMessagingRepo();
      final reviewChannels = _FakeReviewChannelRepo({'ch': _assoc()});
      final messagingPort = _FakeMessagingPort();
      final workspaces = _FakeWorkspaceRepo([_workspace()]);

      final svc = service(
        agents: agents,
        messaging: messaging,
        reviewChannels: reviewChannels,
        messagingPort: messagingPort,
        workspaces: workspaces,
      );

      await svc.dispatch(
        channelId: 'ch',
        workspaceId: 'ws',
        reviewers: [
          {'role': 'flutter', 'scope': 'lib/src/**'},
        ],
      );

      final prompt = messagingPort.dispatched.first['prompt'] as String;
      expect(prompt, contains('Scope filter: lib/src/**'));
    });
  });
}
