import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_page.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show GoalSupervisor;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Repo _repo(
  String id,
  String owner,
  String name, {
  ForgeHost forge = ForgeHost.github,
}) => Repo(
  id: id,
  name: name,
  path: '/tmp/$id',
  remoteOwner: owner,
  remoteName: name,
  forge: forge,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

// ws1 links three repositories; ws2 links one nobody in ws1 may ever see.
final _widgets = _repo('r-widgets', 'acme', 'widgets');
final _vault = _repo('r-vault', 'acme', 'vault');
final _labyrinth = _repo(
  'r-labyrinth',
  'acme',
  'labyrinth',
  forge: ForgeHost.gitlab,
);
final _foreign = _repo('r-foreign', 'rival', 'foreign');

/// Every name and id a caller must not learn of a repository hidden from
/// them.
Set<String> _traces(Repo repo) => {repo.id, repo.remoteName};

PullRequest _pr(Repo repo, int number) => PullRequest(
  id: number,
  number: number,
  title: 'Change $number',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  repoFullName: repo.fullName,
  htmlUrl: 'https://example.test/${repo.fullName}/pull/$number',
);

List<Object?> _repoIds(Map<String, dynamic> frame) => [
  for (final r in (frame['repos'] as List).cast<Map>()) r['repo_id'],
];

/// Behavioral workspace isolation of the PR surfaces, through the real
/// catalog handlers and the real dispatcher: a member sees PRs, counts and
/// names only of the linked repos they hold a grant on AND their own forge
/// sign-in can read; the rest are `hidden_repos` counts; another
/// workspace's repos never appear; per-repo review ops refuse a caller
/// without forge access; an agent pull request's requester cannot approve
/// it. (`oauth.*` refusing a foreign or deleted workspace before membership
/// is covered by `connect/sign_in_ops_test.dart`.)
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _Members members;
  late _Access access;
  late PrRepoVisibility visibility;
  late DomainEventBus events;
  late _Fetchers fetchers;
  late _ReviewRepos reviews;
  late RemoteRpcCatalog catalog;
  late RepoOpDispatcher dispatcher;
  late List<(String, String)> unlinked;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');

    final workspaces = _Workspaces({
      'ws1': [_widgets, _vault, _labyrinth],
      'ws2': [_foreign],
    });
    members = _Members()
      ..add('ws1', 'ada', WorkspaceRole.admin)
      // A grant on every repo, but their GitHub sign-in reads only widgets
      // and they are not signed in to GitLab.
      ..add('ws1', 'gina', WorkspaceRole.member)
      // Forge reach on everything, but no grant at all.
      ..add('ws1', 'nora', WorkspaceRole.member)
      ..add('ws2', 'mallory', WorkspaceRole.admin);
    members.grants[('ws1', 'gina')] = {
      _widgets.id: RepoGrantLevel.read,
      _vault.id: RepoGrantLevel.read,
      _labyrinth.id: RepoGrantLevel.read,
    };
    access = _Access()
      ..readable[('ada', ForgeHost.github)] = {_widgets.id, _vault.id}
      ..readable[('ada', ForgeHost.gitlab)] = {_labyrinth.id}
      ..readable[('gina', ForgeHost.github)] = {_widgets.id}
      ..readable[('nora', ForgeHost.github)] = {_widgets.id, _vault.id}
      ..readable[('nora', ForgeHost.gitlab)] = {_labyrinth.id}
      ..readable[('mallory', ForgeHost.github)] = {_foreign.id}
      ..logins[('ada', ForgeHost.github)] = 'ada-gh'
      ..logins[('ada', ForgeHost.gitlab)] = 'ada-gl'
      ..logins[('gina', ForgeHost.github)] = 'gina-gh'
      ..logins[('nora', ForgeHost.github)] = 'nora-gh'
      ..logins[('nora', ForgeHost.gitlab)] = 'nora-gl';
    events = DomainEventBus();
    visibility = PrRepoVisibility(
      workspaces: workspaces,
      members: members,
      access: access,
      eventBus: events,
    );
    fetchers = _Fetchers();
    reviews = _ReviewRepos();
    unlinked = [];

    catalog = buildRemoteRpcCatalog(
      reviewFindingStatus: _ReviewFindingStatus(),
      membershipRepository: members,
      ticketRepository: _Tickets(),
      projectRepository: _Projects(),
      ticketWorkflow: _TicketWorkflow(),
      messagingRepository: _Messaging(),
      conversationRepository: _Conversations(),
      workspaceRepository: workspaces,
      newsfeedRepository: _Newsfeed(),
      agentRepository: _Agents(),
      repoRepository: _Repos(workspaces),
      // No workspace databases: no space selections, so the gate exposes
      // nothing and only review spaces are hidden here.
      spaceRepoAccess: SpaceRepoAccess(
        dbs: null,
        messaging: _Messaging(),
        workspaces: workspaces,
        members: members,
        forgeRead:
            ({required workspaceId, required userId, required repoId}) async {},
      ),
      memoryDomainRepository: _MemoryDomains(),
      memoryAccessGrantRepository: _MemoryGrants(),
      agentWorkingMemoryRepository: _WorkingMemory(),
      memoryFactRepository: _MemoryFacts(),
      memoryPolicyRepository: _MemoryPolicies(),
      reviewSpaceRepository: _ReviewSpaces(),
      agentRunLogRepository: _RunLogs(),
      isolatedRepoRepository: _IsolatedRepos(),
      voiceProfileRepository: _VoiceProfiles(),
      meetingRepository: _Meetings(),
      ticketLinkRepository: _TicketLinks(),
      pipelineRunRepository: _PipelineRuns(),
      pipelineTemplateRepository: _PipelineTemplates(),
      pipelineTriggerRepository: _PipelineTriggers(),
      teamRepository: _Teams(),
      orchestrationRepository: _Orchestrations(),
      goalRepository: _Goals(),
      approvalRepository: _Approvals(),
      agentPresenceService: _Presence(),
      todoRepository: _Todos(),
      notificationFeedRepository: _NotificationFeed(),
      agentGoalRunRepository: _GoalRuns(),
      goalSupervisor: _GoalSupervisor(),
      pairedDeviceDao: _PairedDevices(),
      pairedDeviceSecretsPort: _PairedDeviceSecrets(),
      pairingServerUrl: '',
      calendarRepository: _Calendar(),
      prLifecycleRepositoryFor: (_) => _PrLifecycle(),
      prRepoVisibility: visibility,
      openPrPoller: _Poller(),
      fetchOpenPrList: fetchers.openPrs,
      fetchReviewRequested: fetchers.reviewRequested,
      fetchReviewedBy: fetchers.reviewedBy,
      fetchPrSearch: fetchers.search,
      fetchMergedHistory: fetchers.mergedHistory,
      forgeProviderRegistryFor: (actingUserId, {workspaceId}) =>
          ForgeProviderRegistry([
            _ReviewFactory(ForgeHost.github, reviews),
            _ReviewFactory(ForgeHost.gitlab, reviews),
          ]),
      onRepoUnlinked: (workspaceId, repo) async =>
          unlinked.add((workspaceId, repo.id)),
    );
    dispatcher = RepoOpDispatcher(
      registry: catalog.ops,
      mapException: mapAppExceptionToRpc,
      workspaceExists: (ws) async => ws == 'ws1' || ws == 'ws2',
      resolveRole: (ws, user) async =>
          (await members.getMember(ws, user))?.role,
    );
  });

  tearDown(() async {
    visibility.dispose();
    await dbs.closeAll();
    await global.close();
  });

  Future<Map<String, dynamic>> call(
    String op,
    String user, [
    Map<String, dynamic> args = const {},
  ]) => dispatcher.call(
    id: 1,
    params: {
      'op': op,
      'args': {'workspace_id': 'ws1', ...args},
    },
    deviceId: 'dev-$user',
    userId: user,
    sessionCapability: SessionCapability.fullClient,
  );

  Map<String, dynamic> data(Map<String, dynamic> res) {
    expect(res['error'], isNull, reason: '$res');
    return ((res['result'] as Map)['data'] as Map).cast<String, dynamic>();
  }

  int? code(Map<String, dynamic> res) =>
      (res['error'] as Map?)?['code'] as int?;

  Future<Map<String, dynamic>> watchFirst(String query, String user) {
    final q = catalog.watch.lookup(query)!;
    return q
        .handler(
          WatchQueryContext(
            args: const {},
            workspaceId: 'ws1',
            deviceId: 'dev-$user',
            userId: user,
          ),
        )
        .first
        .timeout(const Duration(seconds: 10));
  }

  const searches = {
    'pr.listOpenForWorkspace': <String, dynamic>{},
    'pr.searchReviewRequestedForWorkspace': <String, dynamic>{},
    'pr.searchReviewedByForWorkspace': <String, dynamic>{},
    'pr.searchForWorkspace': <String, dynamic>{'query': 'is:open'},
    'pr.closedByAuthorForWorkspace': <String, dynamic>{},
  };

  /// What every workspace-wide surface answers [user]: the one-shot ops and
  /// the open-PR / repo-access watches, as encoded wire.
  Future<Map<String, String>> surfaces(String user) async => {
    for (final MapEntry(:key, :value) in searches.entries)
      key: jsonEncode(data(await call(key, user, value))),
    'pr.watchOpenForWorkspace': jsonEncode(
      await watchFirst('pr.watchOpenForWorkspace', user),
    ),
    'pr.watchRepoAccessForWorkspace': jsonEncode(
      await watchFirst('pr.watchRepoAccessForWorkspace', user),
    ),
    'pr.watchNeedsMyReviewCount': jsonEncode(
      await watchFirst('pr.watchNeedsMyReviewCount', user),
    ),
  };

  void expectNoTraceOf(Map<String, String> wire, Iterable<Repo> repos) {
    for (final MapEntry(:key, :value) in wire.entries) {
      for (final repo in repos) {
        for (final trace in _traces(repo)) {
          expect(value, isNot(contains(trace)), reason: '$key leaks $trace');
        }
      }
    }
  }

  test('a member without a grant gets no PRs, counts or names', () async {
    final wire = await surfaces('nora');
    expectNoTraceOf(wire, [_widgets, _vault, _labyrinth, _foreign]);

    final open = data(await call('pr.listOpenForWorkspace', 'nora'));
    expect(open['repos'], isEmpty);
    expect(open['hidden_repos'], [
      {'forge': 'github', 'reason': 'no_grant', 'count': 2},
      {'forge': 'gitlab', 'reason': 'no_grant', 'count': 1},
    ]);
    expect(
      jsonDecode(wire['pr.watchNeedsMyReviewCount']!),
      containsPair('count', 0),
    );
    expect(jsonDecode(wire['pr.watchRepoAccessForWorkspace']!), {
      'repo_access': <Object?>[],
    });
    // Nothing was even asked of the forge on their behalf.
    expect(fetchers.asked, isEmpty);
  });

  test('a member with a grant but no forge access sees only what their '
      'sign-in reads', () async {
    final wire = await surfaces('gina');
    expectNoTraceOf(wire, [_vault, _labyrinth, _foreign]);

    final open = data(await call('pr.listOpenForWorkspace', 'gina'));
    expect(_repoIds(open), [_widgets.id]);
    expect(open['hidden_repos'], [
      {'forge': 'github', 'reason': 'no_forge_access', 'count': 1},
      {'forge': 'gitlab', 'reason': 'sign_in_required', 'count': 1},
    ]);

    final watched =
        jsonDecode(wire['pr.watchOpenForWorkspace']!) as Map<String, dynamic>;
    expect(_repoIds(watched), [_widgets.id]);
    expect(watched['hidden_repos'], open['hidden_repos']);

    // Every PR requests gina; only the one on widgets counts.
    expect(
      jsonDecode(wire['pr.watchNeedsMyReviewCount']!),
      containsPair('count', 1),
    );
    final repoAccess =
        jsonDecode(wire['pr.watchRepoAccessForWorkspace']!)
            as Map<String, dynamic>;
    expect(
      [
        for (final e in (repoAccess['repo_access'] as List).cast<Map>())
          e['name'],
      ],
      ['widgets'],
    );

    // The forge fan-out itself only ever covered widgets.
    expect(fetchers.asked.values.expand((r) => r).toSet(), {_widgets.id});
  });

  test('another workspace\'s repos never appear, even for an admin', () async {
    final wire = await surfaces('ada');
    expectNoTraceOf(wire, [_foreign]);

    final open = data(await call('pr.listOpenForWorkspace', 'ada'));
    expect(_repoIds(open).toSet(), {_widgets.id, _vault.id, _labyrinth.id});
    expect(open['hidden_repos'], isEmpty);
    // The badge counts every ws1 PR requesting ada, never the foreign one.
    expect(
      jsonDecode(wire['pr.watchNeedsMyReviewCount']!),
      containsPair('count', 3),
    );
    expect(
      fetchers.asked.values.expand((r) => r).toSet(),
      isNot(contains(_foreign.id)),
    );

    // A per-repo op naming the foreign repo is a workspace mismatch.
    final res = await call('pr_review.listAssignableUsers', 'ada', {
      'owner': 'rival',
      'repo': 'foreign',
    });
    expect(code(res), RpcErrorCodes.workspaceMismatch);
    expect(reviews.calls, isEmpty);
  });

  test('unlinking a repository forgets its forge credentials in that '
      'workspace, and an id of another workspace forgets nothing', () async {
    final res = await call('workspace.unlinkRepoFromWorkspace', 'ada', {
      'repo_id': _vault.id,
    });
    expect(res['error'], isNull, reason: '$res');
    expect(unlinked, [('ws1', _vault.id)]);

    final foreign = await call('workspace.unlinkRepoFromWorkspace', 'mallory', {
      'workspace_id': 'ws2',
      'repo_id': _widgets.id,
    });
    expect(foreign['error'], isNull, reason: '$foreign');
    expect(unlinked, [('ws1', _vault.id)]);
  });

  test('a member of another workspace is refused outright', () async {
    for (final op in [...searches.keys, 'pr_review.listAssignableUsers']) {
      final res = await call(op, 'mallory', {
        ...searches[op] ?? const {},
        'owner': 'acme',
        'repo': 'widgets',
      });
      expect(code(res), RpcErrorCodes.unauthorized, reason: op);
    }
    expect(fetchers.asked, isEmpty);
  });

  test('a live watch re-reads the caller\'s role when it changes', () async {
    Stream<Map<String, dynamic>> watch(String query) => catalog.watch
        .lookup(query)!
        .handler(
          const WatchQueryContext(
            args: {},
            workspaceId: 'ws1',
            deviceId: 'dev-ada',
            userId: 'ada',
          ),
        );
    List<Object?> names(Map<String, dynamic> frame) => [
      for (final e in (frame['repo_access'] as List).cast<Map>()) e['name'],
    ];

    final access = <Map<String, dynamic>>[];
    final open = <Map<String, dynamic>>[];
    final subs = [
      watch('pr.watchRepoAccessForWorkspace').listen(access.add),
      watch('pr.watchOpenForWorkspace').listen(open.add),
    ];
    await _settle();
    // An admin sees every linked repo's access record, whatever their own
    // forge reach (fixing the installation is theirs to do).
    expect(
      names(access.last),
      unorderedEquals(['widgets', 'vault', 'labyrinth']),
    );
    expect(
      names(open.last),
      unorderedEquals(['widgets', 'vault', 'labyrinth']),
    );

    // Demoted to a member holding a grant on widgets only: the same
    // subscriptions narrow, through the declared role event alone.
    members
      ..add('ws1', 'ada', WorkspaceRole.member)
      ..grants[('ws1', 'ada')] = {_widgets.id: RepoGrantLevel.read};
    events.publish(
      WorkspaceMemberRoleChanged(
        workspaceId: 'ws1',
        userId: 'ada',
        role: WorkspaceRole.member,
        occurredAt: DateTime(2026),
      ),
    );
    await _settle();
    expect(names(access.last), ['widgets']);
    expect(names(open.last), ['widgets']);
    expect(_repoIds(open.last), [_widgets.id]);

    // Removed from the workspace: nothing at all.
    await members.remove('ws1', 'ada');
    events.publish(
      WorkspaceMemberRemoved(
        workspaceId: 'ws1',
        userId: 'ada',
        occurredAt: DateTime(2026),
      ),
    );
    await _settle();
    expect(names(access.last), isEmpty);
    expect(_repoIds(open.last), isEmpty);
    for (final sub in subs) {
      await sub.cancel();
    }
  });

  Future<Map<String, dynamic>> watchWith(
    String query,
    String user,
    Map<String, dynamic> args,
  ) => catalog.watch
      .lookup(query)!
      .handler(
        WatchQueryContext(
          args: args,
          workspaceId: 'ws1',
          deviceId: 'dev-$user',
          userId: user,
        ),
      )
      .first
      .timeout(const Duration(seconds: 10));

  test('review spaces follow PR visibility', () async {
    List<Object?> repos(Map<String, dynamic> frame) => [
      for (final a in (frame['associations'] as List).cast<Map>())
        a['repo_full_name'],
    ];

    // gina: granted everywhere, her own GitHub sign-in reads widgets only.
    final listed = await watchWith('review_space.watchByWorkspace', 'gina', {});
    expect(repos(listed), ['acme/widgets']);
    expectNoTraceOf({'list': jsonEncode(listed)}, [_vault, _labyrinth]);

    expect(
      (await watchWith('review_space.watchByPr', 'gina', {
        'pr_external_id': 'node-vault',
      }))['association'],
      isNull,
    );
    expect(
      (await watchWith('review_space.watchByPr', 'gina', {
        'pr_external_id': 'node-widgets',
      }))['association'],
      isNotNull,
    );
    expect(
      (await watchWith('review_space.watchBySpace', 'gina', {
        'space_id': 'space-labyrinth',
      }))['association'],
      isNull,
    );
    expect(
      repos(
        await watchWith('review_space.watchAllBySpace', 'gina', {
          'space_id': 'space-vault',
        }),
      ),
      isEmpty,
    );

    // nora: forge reach everywhere, no grant: nothing.
    expect(
      repos(await watchWith('review_space.watchByWorkspace', 'nora', {})),
      isEmpty,
    );
    // ada (admin, reads all three): everything.
    expect(
      repos(await watchWith('review_space.watchByWorkspace', 'ada', {})),
      unorderedEquals(['acme/widgets', 'acme/vault', 'acme/labyrinth']),
    );

    // Creating or moving one needs the same visibility.
    var res = await call('review_space.create', 'gina', {
      'space_id': 'space-vault',
      'pr_external_id': 'node-vault',
      'pr_number': 7,
      'repo_full_name': 'acme/vault',
    });
    expect(code(res), RpcErrorCodes.unauthorized);
    res = await call('review_space.updateStatus', 'gina', {
      'id': 'assoc-labyrinth',
      'status': 'completed',
    });
    expect(code(res), RpcErrorCodes.unauthorized);
    res = await call('review_space.updateStatus', 'gina', {
      'id': 'assoc-widgets',
      'status': 'completed',
    });
    expect(res['error'], isNull, reason: '$res');
  });

  test('a message watch refuses a conversation of another space', () async {
    // The space gate admits the caller to the space named; the conversation
    // named must be that space's, or the watch would stream another space's
    // messages. nora reads general only; gina reads widgets too, and is
    // refused the same way: the conversation is not general's.
    for (final user in ['nora', 'gina']) {
      await expectLater(
        watchWith('messaging.watchMessagesWindow', user, {
          'space_id': 'space-general',
          'conversation_id': 'conv-space-widgets',
        }),
        throwsA(isA<NotFoundException>()),
        reason: user,
      );
    }
  });

  group('PR data outside the PR surfaces', () {
    // gina: granted everywhere, her own GitHub sign-in reads widgets only, not
    // signed in to GitLab. nora: forge reach everywhere, no grant. ada: admin
    // who reads all three.
    List<Object?> ids(Map<String, dynamic> frame, String key) => [
      for (final row in (frame[key] as List).cast<Map>()) row['id'],
    ];

    test('space lists leave out review spaces of hidden PRs', () async {
      for (final user in ['gina', 'nora', 'ada']) {
        final listed = data(await call('messaging.listSpaces', user));
        final watched = await watchWith('messaging.watchSpaces', user, {});
        expect(ids(listed, 'spaces'), ids(watched, 'spaces'), reason: user);
        expect(ids(listed, 'spaces'), switch (user) {
          'gina' => ['space-widgets', 'space-general'],
          'nora' => ['space-general'],
          _ => [
            'space-widgets',
            'space-vault',
            'space-labyrinth',
            'space-general',
          ],
        }, reason: user);
      }
      final gina = jsonEncode(
        await watchWith('messaging.watchSpaces', 'gina', {}),
      );
      expect(gina, isNot(contains('vault')));
      expect(gina, isNot(contains('labyrinth')));
    });

    test('a hidden review space is not readable by id', () async {
      for (final space in ['space-vault', 'space-labyrinth']) {
        var res = await call('messaging.getMessages', 'gina', {
          'space_id': space,
        });
        expect(code(res), RpcErrorCodes.unauthorized, reason: space);
        expect(jsonEncode(res), isNot(contains('finding in')));
        res = await call('messaging.sendMessage', 'gina', {
          'space_id': space,
          'content': 'what does it say?',
        });
        expect(code(res), RpcErrorCodes.unauthorized, reason: space);
        await expectLater(
          watchWith('messaging.watchSpaceMessages', 'gina', {
            'space_id': space,
          }),
          throwsA(isA<AuthException>()),
        );
      }
      expect(
        data(
          await call('messaging.getMessages', 'gina', {
            'space_id': 'space-widgets',
          }),
        )['messages'],
        hasLength(1),
      );
      expect(
        data(
          await call('messaging.getMessages', 'nora', {
            'space_id': 'space-general',
          }),
        )['messages'],
        hasLength(1),
      );
      expect(
        code(
          await call('messaging.getMessages', 'nora', {
            'space_id': 'space-widgets',
          }),
        ),
        RpcErrorCodes.unauthorized,
      );
    });

    test('pipeline runs about hidden PRs are filtered or refused', () async {
      const ginaSees = ['run-widgets', 'run-plain'];
      expect(
        ids(
          await watchWith('pipeline_run.watchForWorkspace', 'gina', {}),
          'runs',
        ),
        ginaSees,
      );
      expect(
        ids(await watchWith('pipeline_run.watchAll', 'gina', {}), 'runs'),
        ginaSees,
      );
      expect(
        ids(
          await watchWith('pipeline_run.watchForWorkspace', 'nora', {}),
          'runs',
        ),
        ['run-plain'],
      );
      expect(
        ids(
          await watchWith('pipeline_run.watchForWorkspace', 'ada', {}),
          'runs',
        ),
        hasLength(5),
      );
      final wire = jsonEncode(
        await watchWith('pipeline_run.watchForWorkspace', 'gina', {}),
      );
      expectNoTraceOf({'runs': wire}, [_vault, _labyrinth]);

      for (final run in ['run-vault', 'run-labyrinth', 'run-message']) {
        expect(
          code(await call('pipeline_run.getRun', 'gina', {'id': run})),
          RpcErrorCodes.unauthorized,
          reason: run,
        );
        expect(
          (await watchWith('pipeline_run.watchRun', 'gina', {
            'id': run,
          }))['run'],
          isNull,
          reason: run,
        );
      }
      expect(
        data(
          await call('pipeline_run.getRun', 'gina', {'id': 'run-widgets'}),
        )['run'],
        isNotNull,
      );
    });

    test(
      'agent runs in hidden review spaces are filtered or refused',
      () async {
        expect(
          ids(
            await watchWith('agent_run_log.watchRecent', 'gina', {'limit': 50}),
            'logs',
          ),
          ['log-space-widgets', 'log-space-general'],
        );
        expect(
          ids(
            await watchWith('agent_run_log.watchBySpace', 'gina', {
              'space_id': 'space-vault',
            }),
            'logs',
          ),
          isEmpty,
        );
        expect(
          code(
            await call('agent_run_log.get', 'gina', {'id': 'log-space-vault'}),
          ),
          RpcErrorCodes.unauthorized,
        );
        expect(
          data(
            await call('agent_run_log.get', 'gina', {
              'id': 'log-space-widgets',
            }),
          )['log'],
          isNotNull,
        );
      },
    );

    test('repo listings follow the caller\'s grants, live', () async {
      List<Object?> repoIds(Map<String, dynamic> frame) => [
        for (final r in (frame['repos'] as List).cast<Map>()) r['id'],
      ];
      for (final query in [
        'repos.watchAll',
        'workspace.watchReposForWorkspace',
      ]) {
        // A grant shows the name even where the forge hides the PRs (the
        // member's way to ask for forge access); no grant shows nothing.
        expect(repoIds(await watchWith(query, 'gina', {})), [
          _widgets.id,
          _vault.id,
          _labyrinth.id,
        ], reason: query);
        expect(repoIds(await watchWith(query, 'nora', {})), isEmpty);
        expect(repoIds(await watchWith(query, 'ada', {})), hasLength(3));
      }
      expect(
        code(await call('repos.get', 'nora', {'repo_id': _vault.id})),
        RpcErrorCodes.unauthorized,
      );

      final frames = <Map<String, dynamic>>[];
      final sub = catalog.watch
          .lookup('repos.watchAll')!
          .handler(
            const WatchQueryContext(
              args: {},
              workspaceId: 'ws1',
              deviceId: 'dev-gina',
              userId: 'gina',
            ),
          )
          .listen(frames.add);
      await _settle();
      expect(repoIds(frames.last), hasLength(3));
      members.grants[('ws1', 'gina')] = {_widgets.id: RepoGrantLevel.read};
      visibility.memberChanged('ws1', 'gina');
      await _settle();
      expect(repoIds(frames.last), [_widgets.id]);
      await sub.cancel();
    });

    test('an open message watch ends when the space turns hidden', () async {
      final events = <Object>[];
      final done = Completer<void>();
      final sub = catalog.watch
          .lookup('messaging.watchSpaceMessages')!
          .handler(
            const WatchQueryContext(
              args: {'space_id': 'space-widgets'},
              workspaceId: 'ws1',
              deviceId: 'dev-gina',
              userId: 'gina',
            ),
          )
          .listen(events.add, onError: events.add, onDone: done.complete);
      await _settle();
      expect(events.whereType<Map>(), isNotEmpty);
      // Her GitHub sign-in loses the repository.
      access.readable[('gina', ForgeHost.github)] = {};
      visibility.invalidateUser('gina', workspaceId: 'ws1');
      await done.future.timeout(const Duration(seconds: 10));
      expect(events.last, isA<AuthException>());
      await sub.cancel();
    });
  });

  test('the notification feed hides PR rows of repos the caller cannot '
      'see', () async {
    List<Object?> ids(Map<String, dynamic> frame) => [
      for (final i in (frame['items'] as List).cast<Map>()) i['id'],
    ];

    final gina = await watchWith('notifications.watch', 'gina', {});
    expect(ids(gina), ['n-widgets', 'n-meeting']);
    expectNoTraceOf({'feed': jsonEncode(gina)}, [_vault, _labyrinth]);

    expect(ids(await watchWith('notifications.watch', 'nora', {})), [
      'n-meeting',
    ]);
    expect(ids(await watchWith('notifications.watch', 'ada', {})), [
      'n-widgets',
      'n-vault',
      'n-labyrinth',
      'n-meeting',
    ]);
  });

  test('the notification feed windows stored rows, and says when older '
      'ones exist', () async {
    List<Object?> ids(Map<String, dynamic> frame) => [
      for (final i in (frame['items'] as List).cast<Map>()) i['id'],
    ];

    // `has_more` is about the stored rows: gina's window of two holds a vault
    // row she cannot see, and the window is still not the end of the feed.
    final gina = await watchWith('notifications.watch', 'gina', {'limit': 2});
    expect(ids(gina), ['n-widgets']);
    expect(gina['has_more'], isTrue);

    final ada = await watchWith('notifications.watch', 'ada', {'limit': 4});
    expect(ids(ada), hasLength(4));
    expect(ada['has_more'], isFalse);

    // Clamped: a zero window still shows the newest row.
    final zero = await watchWith('notifications.watch', 'ada', {'limit': 0});
    expect(ids(zero), ['n-widgets']);
    expect(zero['has_more'], isTrue);
  });

  test('per-repo review ops refuse a caller without forge access', () async {
    // No grant.
    var res = await call('pr_review.listAssignableUsers', 'nora', {
      'owner': 'acme',
      'repo': 'widgets',
    });
    expect(code(res), RpcErrorCodes.unauthorized);

    // A grant, but their GitHub sign-in cannot read the repo.
    res = await call('pr_review.listAssignableUsers', 'gina', {
      'owner': 'acme',
      'repo': 'vault',
    });
    expect(code(res), RpcErrorCodes.unauthorized);

    // A grant, but no GitLab sign-in: told which lane to sign in to.
    res = await call('pr_review.listAssignableUsers', 'gina', {
      'owner': 'acme',
      'repo': 'labyrinth',
    });
    expect(code(res), RpcErrorCodes.unauthorized);
    expect((res['error'] as Map)['data'], {
      'kind': 'needs_sign_in',
      'lane': 'gitlab',
    });

    res = await call('pr_review.submitReview', 'gina', {
      'owner': 'acme',
      'repo': 'vault',
      'pr_number': 3,
      'event': 'COMMENT',
    });
    expect(code(res), RpcErrorCodes.unauthorized);
    expect(reviews.calls, isEmpty);

    // Their own readable repo works.
    res = await call('pr_review.listAssignableUsers', 'gina', {
      'owner': 'acme',
      'repo': 'widgets',
    });
    expect(res['error'], isNull, reason: '$res');
    expect(reviews.calls, ['listAssignableUsers acme/widgets gina']);
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.repos);
  final Map<String, List<Repo>> repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(repos[workspaceId] ?? const []);

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => (repos[workspaceId] ?? const []).any((r) => r.id == repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async => repos[workspaceId]?.removeWhere((r) => r.id == repoId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements WorkspaceMembershipRepository {
  final _members = <(String, String), WorkspaceMember>{};
  final grants = <(String, String), Map<String, RepoGrantLevel>>{};

  void add(String workspaceId, String userId, WorkspaceRole role) =>
      _members[(workspaceId, userId)] = WorkspaceMember(
        id: '$workspaceId-$userId',
        workspaceId: workspaceId,
        userId: userId,
        role: role,
        joinedAt: DateTime(2025),
      );

  @override
  Future<void> remove(String workspaceId, String userId) async {
    _members.remove((workspaceId, userId));
    grants.remove((workspaceId, userId));
  }

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      _members[(workspaceId, userId)];

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => Map.of(grants[(workspaceId, userId)] ?? const {});

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async => [
    for (final m in _members.values)
      if (m.userId == userId) m,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Each person's own reach per forge; a missing entry is "not signed in".
class _Access implements PersonForgeAccess {
  final readable = <(String, ForgeHost), Set<String>>{};
  final logins = <(String, ForgeHost), String>{};

  @override
  Future<Set<String>?> readableRepoIds(
    String workspaceId,
    String userId,
    ForgeHost forge,
    List<Repo> repos,
  ) async {
    final set = readable[(userId, forge)];
    return set == null
        ? null
        : {
            for (final r in repos)
              if (set.contains(r.id)) r.id,
          };
  }

  @override
  Future<String> viewerLogin(
    String workspaceId,
    String userId,
    ForgeHost forge,
  ) async => logins[(userId, forge)] ?? '';

  @override
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  ) async => const {};
}

/// The workspace-wide forge reads. Each answers for every repo it was given
/// AND every other repo it knows (ws2's included), so only the handler's
/// own filtering keeps the hidden ones out; [asked] records the fan-out.
class _Fetchers {
  final asked = <String, List<String>>{};
  static final _all = [_widgets, _vault, _labyrinth, _foreign];

  void _record(String op, List<Repo> repos) =>
      (asked[op] ??= []).addAll(repos.map((r) => r.id));

  Future<
    List<({Repo repo, List<PullRequest> prs, bool hasMore, int? totalCount})>
  >
  openPrs(List<Repo> repos, {required String workspaceId}) async {
    _record('open', repos);
    return [
      for (final r in _all)
        (repo: r, prs: [_pr(r, 1)], hasMore: false, totalCount: 1),
    ];
  }

  Future<List<({Repo repo, PullRequest pr})>> reviewRequested(
    List<Repo> repos,
    String actingUserId, {
    required String workspaceId,
  }) async {
    _record('reviewRequested', repos);
    return [for (final r in _all) (repo: r, pr: _pr(r, 2))];
  }

  Future<Set<String>> reviewedBy(
    List<Repo> repos,
    String actingUserId, {
    required String workspaceId,
  }) async {
    _record('reviewedBy', repos);
    return {for (final r in _all) '${r.fullName}#3'};
  }

  Future<List<({Repo repo, List<PullRequest> prs})>> search(
    List<Repo> repos,
    String query, {
    required String workspaceId,
    required String userId,
  }) async {
    _record('search', repos);
    return [
      for (final r in _all) (repo: r, prs: [_pr(r, 4)]),
    ];
  }

  Future<
    List<({Repo repo, List<PullRequest> prs, bool hasMore, int? totalCount})>
  >
  mergedHistory(List<Repo> repos, {String? userId, String? workspaceId}) async {
    _record('merged', repos);
    return [
      for (final r in _all)
        (repo: r, prs: [_pr(r, 6)], hasMore: false, totalCount: 1),
    ];
  }
}

/// The open-PR poller's snapshot and repo access record, over every repo it
/// knows (ws2's included): every PR requests every person's login.
class _Poller implements OpenPrPollingService {
  static final _all = [_widgets, _vault, _labyrinth, _foreign];

  @override
  Stream<Map<String, dynamic>> watchOpenForWorkspace(
    String workspaceId, {
    bool fastCadence = true,
  }) => Stream.value({
    'authenticated': true,
    'repos': [
      for (final r in _all)
        {
          'repo_id': r.id,
          'repo_full_name': r.fullName,
          'prs': [
            {
              'number': 7,
              'repo_full_name': r.fullName,
              'is_draft': false,
              'author': {'login': 'someone'},
              'requested_reviewers': [
                for (final login in [
                  'ada-gh',
                  'ada-gl',
                  'gina-gh',
                  'nora-gh',
                  'nora-gl',
                ])
                  {'login': login},
              ],
              'requested_team_slugs': const <String>[],
            },
          ],
        },
    ],
  });

  @override
  Stream<List<RepoAccessIssue>> watchRepoAccessForWorkspace(
    String workspaceId,
  ) => Stream.value([
    for (final r in _all)
      RepoAccessIssue(
        forge: r.forge,
        owner: r.remoteOwner,
        name: r.remoteName,
        repoId: r.id,
        state: RepoAccessState.appNotInstalled,
        since: DateTime.utc(2026),
        checkedAt: DateTime.utc(2026),
      ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Every space's standing conversation, `conv-<space id>`.
class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    if (workspaceId != 'ws1' || !conversationId.startsWith('conv-')) {
      return null;
    }
    return Conversation(
      id: conversationId,
      workspaceId: 'ws1',
      spaceId: conversationId.substring('conv-'.length),
      title: 'standing',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewRepos {
  final calls = <String>[];
}

class _ReviewFactory implements ForgeProviderFactory {
  _ReviewFactory(this.forge, this.reviews);

  @override
  final ForgeHost forge;
  final _ReviewRepos reviews;

  @override
  PrReviewRepository create(ForgeProviderContext ctx) =>
      _RecordingReview(reviews, '${ctx.repo.fullName} ${ctx.userId}');
}

class _RecordingReview extends EmptyPrReviewRepository {
  _RecordingReview(this.reviews, this.who);

  final _ReviewRepos reviews;
  final String who;

  @override
  Future<List<PrUser>> listAssignableUsers() async {
    reviews.calls.add('listAssignableUsers $who');
    return const [];
  }

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
    List<PendingReviewComment> comments = const [],
  }) async {
    reviews.calls.add('submitReview $who $prNumber $event');
  }
}

// The catalog's other dependencies: none of them is reached by the PR
// surfaces under test.
class _ReviewFindingStatus implements ReviewFindingStatusPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tickets implements TicketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Projects implements ProjectRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TicketWorkflow implements TicketWorkflowService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// ws1's spaces: one review space per repo (named as the pipeline names
/// them, title included) and one plain space.
class _Messaging implements MessagingRepository {
  static Space _space(String id, String name) => Space(
    id: id,
    name: name,
    workspaceId: 'ws1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  static final spaces = [
    for (final r in [_widgets, _vault, _labyrinth])
      _space('space-${r.remoteName}', 'Review: PR #7 - ${r.remoteName} fix'),
    _space('space-general', 'general'),
  ];

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(workspaceId == 'ws1' ? spaces : const []);

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async =>
      workspaceId == 'ws1'
      ? spaces.where((s) => s.id == spaceId).firstOrNull
      : null;

  List<Message> _messages(String spaceId) => [
    Message(
      id: 'msg-$spaceId',
      spaceId: spaceId,
      conversationId: 'conv-$spaceId',
      senderId: 'reviewer',
      senderType: SenderType.agent,
      content: 'finding in $spaceId',
      messageType: MessageType.text,
      createdAt: DateTime(2026),
    ),
  ];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => _messages(spaceId);

  // Live, like the drift watch: it never completes on its own.
  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => Stream.multi((out) => out.add(_messages(spaceId)));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Newsfeed implements NewsfeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repos implements RepoRepository {
  _Repos(this._workspaces);
  final _Workspaces _workspaces;

  @override
  Stream<List<Repo>> watchAll(String workspaceId) =>
      Stream.value(workspaceId == 'ws1' ? [_widgets, _vault, _labyrinth] : []);

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async =>
      (_workspaces.repos[workspaceId] ?? const <Repo>[])
          .where((r) => r.id == repoId)
          .firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryDomains implements MemoryDomainRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryGrants implements MemoryAccessGrantRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WorkingMemory implements AgentWorkingMemoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryFacts implements MemoryFactRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryPolicies implements MemoryPolicyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One review space per ws1 repo, each in its own space `space-<name>`.
class _ReviewSpaces implements ReviewSpaceRepository {
  final created = <String>[];
  final updated = <String>[];

  static ReviewSpaceAssociation _of(Repo repo) => ReviewSpaceAssociation(
    id: 'assoc-${repo.remoteName}',
    spaceId: 'space-${repo.remoteName}',
    workspaceId: 'ws1',
    prExternalId: 'node-${repo.remoteName}',
    prNumber: 7,
    repoFullName: repo.fullName,
    status: ReviewSpaceStatus.requested,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  static final _all = [
    for (final r in [_widgets, _vault, _labyrinth]) _of(r),
  ];

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value(workspaceId == 'ws1' ? _all : const []);

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(
    _all.where((a) => a.prExternalId == prExternalId).firstOrNull,
  );

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(_all.where((a) => a.spaceId == spaceId).firstOrNull);

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value([
    for (final a in _all)
      if (a.spaceId == spaceId) a,
  ]);

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    created.add(repoFullName);
    return _all.first;
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) async => updated.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One agent run per ws1 review space, plus one in the plain space.
class _RunLogs implements AgentRunLogRepository {
  static final logs = [
    for (final space in _Messaging.spaces)
      AgentRunLog(
        id: 'log-${space.id}',
        agentId: 'reviewer',
        workspaceId: 'ws1',
        spaceId: space.id,
        startedAt: DateTime(2026),
        status: RunStatus.completed,
        summary: 'summary of ${space.id}',
      ),
  ];

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => Stream.value(logs);

  @override
  Stream<List<AgentRunLog>> watchBySpace(String workspaceId, String spaceId) =>
      Stream.value([
        for (final l in logs)
          if (l.spaceId == spaceId) l,
      ]);

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      logs.where((l) => l.id == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IsolatedRepos implements IsolatedRepoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VoiceProfiles implements VoiceProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Meetings implements MeetingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TicketLinks implements TicketLinkRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A PR review run per ws1 repo (as the pipeline starts them: repo id,
/// full name, PR title), one run naming a review space only, and one run
/// about no repository.
class _PipelineRuns implements PipelineRunRepository {
  static PipelineRun _run(String id, Map<String, dynamic> payload) =>
      PipelineRun(
        id: id,
        templateId: 'pr_review',
        workspaceId: 'ws1',
        status: PipelineRunStatus.completed,
        triggerPayload: payload,
        startedAt: DateTime(2026),
      );

  static final runs = [
    for (final r in [_widgets, _vault, _labyrinth])
      _run('run-${r.remoteName}', {
        'repo_id': r.id,
        'repo_full_name': r.fullName,
        'pr_number': 7,
        'pr_title': '${r.remoteName} fix',
      }),
    _run('run-message', {'space_id': 'space-vault'}),
    _run('run-plain', {'ticket_id': 't-1'}),
  ];

  @override
  Future<PipelineRun?> getRun(String id) async =>
      runs.where((r) => r.id == id).firstOrNull;

  @override
  Stream<PipelineRun?> watchRun(String id) =>
      Stream.value(runs.where((r) => r.id == id).firstOrNull);

  @override
  Stream<List<PipelineRun>> watchAll() => Stream.value(runs);

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) =>
      Stream.value(workspaceId == 'ws1' ? runs : const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PipelineTemplates implements PipelineTemplateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PipelineTriggers implements PipelineTriggerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Teams implements TeamRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Orchestrations implements OrchestrationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Goals implements GoalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Approvals implements ApprovalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Presence implements AgentPresenceService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Todos implements TodoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A review request on every ws1 repo, plus one row that is not PR data.
///
/// Windowed like the real feed: the newest `limit` rows, and whether older
/// ones exist beyond them.
class _NotificationFeed implements NotificationFeedRepository {
  @override
  Stream<NotificationFeedPage> watchFeed(
    String workspaceId, {
    int limit = NotificationFeedRepository.pageSize,
  }) {
    final rows = _rows();
    return Stream.value(
      NotificationFeedPage(
        hasMore: rows.length > limit,
        items: rows.take(limit).toList(),
      ),
    );
  }

  List<NotificationFeedItem> _rows() => [
    for (final r in [_widgets, _vault, _labyrinth])
      NotificationFeedItem(
        id: 'n-${r.remoteName}',
        workspaceId: 'ws1',
        method: 'notifications/pr_review_requested',
        params: {
          'repo_owner': r.remoteOwner,
          'repo_name': r.remoteName,
          'pr_number': 7,
          'pr_title': 'Change on ${r.remoteName}',
          'workspace_id': 'ws1',
        },
        seq: 0,
        createdAt: DateTime(2026),
      ),
    NotificationFeedItem(
      id: 'n-meeting',
      workspaceId: 'ws1',
      method: 'notifications/meeting_starting_soon',
      params: const {'workspace_id': 'ws1'},
      seq: 0,
      createdAt: DateTime(2026),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GoalRuns implements AgentGoalRunRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GoalSupervisor implements GoalSupervisor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PairedDevices implements PairedDeviceDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PairedDeviceSecrets implements PairedDeviceSecretsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Calendar implements CalendarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PrLifecycle implements PrLifecycleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
