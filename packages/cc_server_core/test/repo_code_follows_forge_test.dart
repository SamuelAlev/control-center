import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_invite_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_ports_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_state.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_command_buffer.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show AgentRunGrant, AgentRunView, GoalSupervisor;
import 'package:cc_mcp/cc_mcp.dart' show GetSpaceMessagesTool;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/notification_feed_visibility.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:cc_server_core/src/catalog/repo_forge_read.dart';
import 'package:cc_server_core/src/catalog/rig_access.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/context/context_inspection_service.dart';
import 'package:cc_server_core/src/context/context_rpc_ops.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Repo _repo(String id, {String owner = 'acme', String? name}) => Repo(
  id: id,
  name: id,
  path: '/srv/$id',
  remoteOwner: owner,
  remoteName: owner.isEmpty ? '' : (name ?? id),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _widgets = _repo('widgets');
final _vault = _repo('vault');
// A checkout with no forge remote: no forge to ask.
final _notes = _repo('notes', owner: '');

const _owner = 'olga';

/// Code follows the reader's own forge access, through the real catalog and
/// a dispatcher wired as the server wires it: a grant (or an admin role)
/// opens a repository's code only as far as the caller's own sign-in can
/// read it. Someone in only part of an organization reads only that part.
/// The server owner is exempt; a repository without a forge remote is
/// governed by the grant alone; a forge that cannot be asked refuses.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _Members members;
  late _Access access;
  late PrRepoVisibility visibility;
  late SpaceRepoAccess spaceRead;
  late _Terminals terminals;
  late _Rigs rigs;
  late _RigPorts rigPorts;
  late RigAccess rigAccess;
  late RemoteRpcCatalog catalog;
  late RepoOpDispatcher dispatcher;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    final workspaces = _Workspaces([_widgets, _vault, _notes]);
    final repos = _Repos(workspaces);
    const all = {
      'widgets': RepoGrantLevel.read,
      'vault': RepoGrantLevel.read,
      'notes': RepoGrantLevel.read,
    };
    members = _Members()
      // In part of the organization: reads widgets on GitHub, not vault.
      ..add('gina', WorkspaceRole.member, all)
      // Reads both on GitHub.
      ..add('fran', WorkspaceRole.member, all)
      // Not signed in to GitHub.
      ..add('sol', WorkspaceRole.member, all)
      // GitHub cannot be asked about them right now.
      ..add('uma', WorkspaceRole.member, all)
      // Reads everything on GitHub, holds no grant.
      ..add('nora', WorkspaceRole.member, const {})
      // Writes everything and reads both on GitHub.
      ..add('wanda', WorkspaceRole.member, {
        for (final id in all.keys) id: RepoGrantLevel.write,
      })
      // An admin who, like gina, reads only widgets.
      ..add('adam', WorkspaceRole.admin, const {})
      // The server owner, signed in nowhere.
      ..add(_owner, WorkspaceRole.owner, const {});
    access = _Access()
      ..readable['gina'] = {'widgets'}
      ..readable['fran'] = {'widgets', 'vault'}
      ..readable['nora'] = {'widgets', 'vault'}
      ..readable['wanda'] = {'widgets', 'vault'}
      ..readable['adam'] = {'widgets'}
      ..unreachable.add('uma');
    visibility = PrRepoVisibility(
      workspaces: workspaces,
      members: members,
      access: access,
      initialWait: Duration.zero,
    );
    // The one space read gate, as the runtime builds it.
    spaceRead = SpaceRepoAccess(
      dbs: dbs,
      messaging: DaoMessagingRepository(dbs),
      workspaces: workspaces,
      members: members,
      forgeRead: repoForgeReadCheck(
        repos: repos,
        visibility: visibility,
        serverOwnerUserId: _owner,
      ),
    );
    terminals = _Terminals();
    rigs = _Rigs();
    rigPorts = _RigPorts();
    // As the runtime builds it: once, over the same space read gate.
    rigAccess = RigAccess(
      rigs: rigs,
      messaging: DaoMessagingRepository(dbs),
      gate: PrDataGate(
        reviewSpaces: DaoReviewSpaceRepository(dbs),
        resolve: visibility.resolve,
        watch: visibility.watch,
        spaceRead: spaceRead,
      ),
      spaceRepos: spaceRead,
      members: members,
      forgeRead: repoForgeReadCheck(
        repos: repos,
        visibility: visibility,
        serverOwnerUserId: _owner,
      ),
      standingChanges: visibility.changes,
    );
    catalog = _catalog(
      rigs: rigs,
      rigPorts: rigPorts,
      rigAccess: rigAccess,
      spaceRead: spaceRead,
      workspaces: workspaces,
      repos: repos,
      members: members,
      visibility: visibility,
      terminals: terminals,
      dbs: dbs,
    );
    dispatcher = RepoOpDispatcher(
      registry: catalog.ops,
      mapException: mapAppExceptionToRpc,
      workspaceExists: (ws) async => ws == 'ws1',
      resolveRole: (ws, user) async =>
          (await members.getMember(ws, user))?.role,
      resolveRepoGrant: (ws, user, repoId) async =>
          (await members.getRepoGrants(ws, user))[repoId] ??
          RepoGrantLevel.none,
      requireForgeRead: (ws, user, repoId) => repoForgeReadCheck(
        repos: repos,
        visibility: visibility,
        serverOwnerUserId: _owner,
      )(workspaceId: ws, userId: user, repoId: repoId),
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

  Map<String, dynamic>? error(Map<String, dynamic> res) =>
      (res['error'] as Map?)?.cast<String, dynamic>();

  Future<bool> reads(String user, String op, Map<String, dynamic> args) async {
    final res = await call(op, user, args);
    final err = error(res);
    if (err == null) {
      return true;
    }
    expect(err['code'], RpcErrorCodes.unauthorized, reason: '$op: $res');
    return false;
  }

  Future<bool> readsFile(String user, Repo repo) =>
      reads(user, 'repos.readFile', {'repo_id': repo.id, 'path': 'README.md'});

  group('a repository named by the call', () {
    test('a granted member reads only what their own sign-in reads', () async {
      expect(await readsFile('gina', _widgets), isTrue);
      expect(await readsFile('gina', _vault), isFalse);
      expect(await readsFile('fran', _vault), isTrue);
    });

    test('a refusal names the forge whose account cannot read it', () async {
      final res = await call('repos.readFile', 'gina', {
        'repo_id': _vault.id,
        'path': 'README.md',
      });
      expect(error(res)?['data'], {
        'kind': 'forge_cannot_read',
        'forge': _vault.forge.wire,
      });
    });

    test('stripping the forge remote does not take a repository out of the '
        'forge check', () async {
      final res = await call('repos.upsert', 'gina', {
        'repo': repoToWire(_vault.copyWith(remoteOwner: '', remoteName: '')),
      });
      expect(
        error(res)?['message'],
        'A linked forge repository keeps its forge remote.',
      );
      expect(error(res)?['code'], RpcErrorCodes.validation);
      expect(error(res)?['data'], {'kind': 'repo_link.forge_remote_required'});
      expect(await readsFile('gina', _vault), isFalse);
    });

    test('forge access is no grant', () async {
      expect(await readsFile('nora', _vault), isFalse);
      final res = await call('repos.readFile', 'nora', {
        'repo_id': _vault.id,
        'path': 'README.md',
      });
      expect(error(res)?['data'], {
        'kind': 'repo_grant_required',
        'level': 'read',
      });
    });

    test('a workspace admin is not exempt', () async {
      expect(await readsFile('adam', _widgets), isTrue);
      expect(await readsFile('adam', _vault), isFalse);
    });

    test('the server owner is exempt, signed in or not', () async {
      expect(await readsFile(_owner, _vault), isTrue);
    });

    test('a repository without a forge remote is governed by the grant '
        'alone', () async {
      expect(await readsFile('sol', _notes), isTrue);
      expect(await readsFile('adam', _notes), isTrue);
      expect(await readsFile('nora', _notes), isFalse);
    });

    test('without a sign-in the refusal asks for one', () async {
      final res = await call('repos.readFile', 'sol', {
        'repo_id': _widgets.id,
        'path': 'README.md',
      });
      expect(error(res)?['data'], containsPair('kind', 'needs_sign_in'));
    });

    test('a forge that cannot be asked refuses until it answers', () async {
      expect(await readsFile('uma', _widgets), isFalse);
      expect(await readsFile('uma', _notes), isTrue);
      final res = await call('repos.readFile', 'uma', {
        'repo_id': _widgets.id,
        'path': 'README.md',
      });
      expect(error(res)?['data'], {
        'kind': 'forge_unconfirmed',
        'forge': _widgets.forge.wire,
      });
    });
  });

  group('every linked repository at once', () {
    for (final op in ['repos.searchFiles', 'repos.listDirectory']) {
      test('$op needs the sign-in to read every forge repository', () async {
        final args = {'query': 'main', 'repo_id': _widgets.id};
        expect(await reads('gina', op, args), isFalse);
        expect(await reads('adam', op, args), isFalse);
        expect(await reads('fran', op, args), isTrue);
        expect(await reads(_owner, op, args), isTrue);
      });
    }
  });

  /// A space in ws1 selecting [repos] (none: every linked one), or exposing
  /// none at all with [noRepos].
  Future<void> select(
    String spaceId,
    List<Repo> repos, {
    bool noRepos = false,
  }) async {
    final db = dbs.of('ws1');
    // The selection's rows stand on a space and linked repo rows.
    await db
        .into(db.spacesTable)
        .insert(
          SpacesTableCompanion.insert(
            id: spaceId,
            name: spaceId,
            workspaceId: const Value('ws1'),
            noRepos: Value(noRepos),
          ),
        );
    for (final r in repos) {
      await DaoRepoRepository(dbs).upsert('ws1', r);
    }
    await db.spaceRepoDao.setReposForSpace(
      workspaceId: 'ws1',
      spaceId: spaceId,
      repoIds: [for (final r in repos) r.id],
    );
  }

  group("a space's content follows the repositories it exposes", () {
    setUp(() async {
      await select('s-all', [_widgets, _vault, _notes]);
      await select('s-open', [_widgets, _notes]);
      // No selection: every linked repository, vault included.
      await select('s-default', const []);
      await select('s-none', const [], noRepos: true);
    });

    Future<Map<String, dynamic>> watchFirst(
      String query,
      String user,
      Map<String, dynamic> args,
    ) {
      return catalog.watch
          .lookup(query)!
          .handler(
            WatchQueryContext(
              args: {'workspace_id': 'ws1', ...args},
              workspaceId: 'ws1',
              deviceId: 'dev-$user',
              userId: user,
            ),
          )
          .first
          .timeout(const Duration(seconds: 10));
    }

    Future<bool> readsSpace(String user, String spaceId) async {
      final ops = [
        await reads(user, 'messaging.getMessages', {'space_id': spaceId}),
        await reads(user, 'messaging.searchInSpace', {
          'space_id': spaceId,
          'query': 'plans',
        }),
        await reads(user, 'context.inspect', {
          'space_id': spaceId,
          'conversation_id': 'c-1',
          'agent_id': 'a-1',
        }),
      ];
      bool watched;
      try {
        await watchFirst('messaging.watchSpaceMessages', user, {
          'space_id': spaceId,
        });
        watched = true;
      } on AuthException {
        watched = false;
      }
      expect({...ops, watched}, hasLength(1), reason: '$user $spaceId');
      return watched;
    }

    Future<Set<String>> listed(String user) async {
      final res = await call('messaging.listSpaces', user);
      expect(error(res), isNull, reason: '$res');
      final listed = {
        for (final s
            in (((res['result'] as Map)['data'] as Map)['spaces'] as List))
          (s as Map)['id'] as String,
      };
      final watched = await watchFirst('messaging.watchSpaces', user, {});
      expect(
        {for (final s in watched['spaces'] as List) (s as Map)['id']},
        listed,
        reason: user,
      );
      return listed;
    }

    test('a member whose sign-in cannot read one of them is refused and '
        'sees no trace of the space', () async {
      for (final space in ['s-all', 's-default']) {
        expect(await readsSpace('gina', space), isFalse, reason: space);
      }
      expect(await listed('gina'), {'s-open', 's-none'});
    });

    test('a workspace admin is not exempt', () async {
      expect(await readsSpace('adam', 's-all'), isFalse);
      expect(await listed('adam'), {'s-open', 's-none'});
    });

    test('a member who reads every one of them is admitted', () async {
      expect(await readsSpace('gina', 's-open'), isTrue);
      for (final space in ['s-all', 's-default', 's-open', 's-none']) {
        expect(await readsSpace('fran', space), isTrue, reason: space);
      }
      expect(await listed('fran'), {'s-all', 's-default', 's-open', 's-none'});
    });

    test('a space without repositories is open to every member', () async {
      expect(await readsSpace('gina', 's-none'), isTrue);
      expect(await readsSpace('fran', 's-none'), isTrue);
      expect(await readsSpace('nora', 's-none'), isTrue);
    });

    test('forge access is no grant', () async {
      expect(await readsSpace('nora', 's-open'), isFalse);
    });

    test('the server owner is admitted', () async {
      expect(await readsSpace(_owner, 's-all'), isTrue);
      expect(await listed(_owner), {'s-all', 's-default', 's-open', 's-none'});
    });

    test('the first space-list frame does not wait for a PR visibility that '
        'has not answered', () async {
      // A forge listing that never lands: with no review space, nothing in
      // the list depends on it, so the frame comes from the gate alone.
      final gate = PrDataGate(
        reviewSpaces: DaoReviewSpaceRepository(dbs),
        resolve: (_, _) => Completer<RepoVisibility>().future,
        watch: (_, _) => StreamController<RepoVisibility>().stream,
        spaceRead: spaceRead,
      );
      final frame = await gate
          .spaceRows(
            'ws1',
            'gina',
            DaoMessagingRepository(dbs).watchSpacesByWorkspace('ws1'),
            (s) => s.id,
            (list) => {'spaces': list.map((s) => s.id).toSet()},
          )
          .first
          .timeout(const Duration(seconds: 2));
      expect(frame['spaces'], {'s-open', 's-none'});
    });

    test(
      'an agent run reads a space over MCP only as its requester may',
      () async {
        // As the runtime wires the agent lane: one PrDataGate carrying the
        // space read gate.
        final agentSpaces = AgentSpaceVisibility(
          PrDataGate(
            reviewSpaces: DaoReviewSpaceRepository(dbs),
            resolve: visibility.resolve,
            watch: visibility.watch,
            spaceRead: spaceRead,
          ),
        );
        const requesters = {
          'c-gina': 'gina',
          'c-fran': 'fran',
          'c-olga': _owner,
        };
        agentSpaces.openRuns =
            ({required workspaceId, required conversationId}) => [
              if (requesters[conversationId] case final person?)
                AgentRunView(
                  grant: AgentRunGrant(
                    workspaceId: workspaceId,
                    conversationId: conversationId,
                    actingUserId: person,
                  ),
                  pushedBranches: const {},
                ),
            ];
        final getMessages = GetSpaceMessagesTool(
          repository: DaoMessagingRepository(dbs),
          hiddenSpaces: agentSpaces.hiddenFor,
        );
        Future<bool> agentReads(String run, String space) async =>
            !(await getMessages.run({
              'workspace_id': 'ws1',
              'space_id': space,
              McpCallScope.callerConversationKey: run,
            })).isError;

        expect(await agentReads('c-gina', 's-all'), isFalse);
        expect(await agentReads('c-gina', 's-default'), isFalse);
        expect(await agentReads('c-gina', 's-open'), isTrue);
        expect(await agentReads('c-gina', 's-none'), isTrue);
        for (final space in ['s-all', 's-default', 's-open', 's-none']) {
          expect(await agentReads('c-fran', space), isTrue, reason: space);
          expect(await agentReads('c-olga', space), isTrue, reason: space);
        }
      },
    );

    test('web push and live frames deliver a space notification only as the '
        'feed would, the server owner included', () async {
      // The one check both delivery paths call (`canViewNotification`, and
      // `_notificationViewCheck` around it for live frames).
      final delivers = notificationDeliveryCheck(
        members: members,
        workspaces: _Workspaces([_widgets, _vault, _notes]),
        spaceRead: spaceRead,
        visibilityOf: visibility.resolve,
      );
      NotificationFeedItem about(String space) => NotificationFeedItem(
        id: 'n-$space',
        workspaceId: 'ws1',
        method: 'notifications/pr_review_requested',
        params: {'space_id': space},
        createdAt: DateTime(2026),
      );

      expect(await delivers(about('s-all'), 'gina'), isFalse);
      expect(await delivers(about('s-default'), 'adam'), isFalse);
      expect(await delivers(about('s-open'), 'gina'), isTrue);
      expect(await delivers(about('s-none'), 'gina'), isTrue);
      expect(await delivers(about('s-all'), 'fran'), isTrue);
      expect(await delivers(about('s-all'), _owner), isTrue);
    });
  });

  group('a space whose worktree holds the repositories', () {
    Future<bool> spawns(String user, String spaceId) => reads(
      user,
      'terminal.spawn',
      {'rows': 24, 'cols': 80, 'space_id': spaceId},
    );

    test('a terminal is refused while one of them is unreadable', () async {
      await select('s-all', [_widgets, _vault, _notes]);
      await select('s-open', [_widgets, _notes]);
      expect(await spawns('gina', 's-all'), isFalse);
      expect(await spawns('adam', 's-all'), isFalse);
      expect(terminals.spawned, isEmpty);
      expect(await spawns('gina', 's-open'), isTrue);
      expect(await spawns('fran', 's-all'), isTrue);
      expect(await spawns(_owner, 's-all'), isTrue);
      expect(terminals.spawned, ['gina', 'fran', _owner]);
    });
  });

  group("a rig is its space's machine", () {
    setUp(() async {
      await select('s-all', [_widgets, _vault, _notes]);
      await select('s-open', [_widgets, _notes]);
      rigs
        ..add('r-all', space: 's-all')
        ..add('r-open', space: 's-open')
        ..add('r-free');
    });

    Future<Set<String>> listedRigs(String user) async {
      final res = await call('rig.list', user);
      expect(error(res), isNull, reason: '$res');
      final listed = {
        for (final r in ((res['result'] as Map)['data'] as Map)['rigs'] as List)
          (r as Map)['id'] as String,
      };
      final frame = await catalog.watch
          .lookup('rig.watchSessions')!
          .handler(
            WatchQueryContext(
              args: const {'workspace_id': 'ws1'},
              workspaceId: 'ws1',
              deviceId: 'dev-$user',
              userId: user,
            ),
          )
          .first
          .timeout(const Duration(seconds: 10));
      expect(
        {for (final r in frame['rigs'] as List) (r as Map)['id']},
        listed,
        reason: user,
      );
      return listed;
    }

    WatchQueryContext watchAs(String user) => WatchQueryContext(
      args: const {'workspace_id': 'ws1'},
      workspaceId: 'ws1',
      deviceId: 'dev-$user',
      userId: user,
    );

    /// Each listed rig's per-caller flags as `(can_drive, holder_only)`,
    /// the same from `rig.list` and the first `rig.watchSessions` frame,
    /// and `can_drive` exactly what [RigAccess.mayDrive] answers.
    Future<Map<String, (bool, bool)>> flags(String user) async {
      Map<String, (bool, bool)> of(List<dynamic> rows) => {
        for (final r in rows.cast<Map<dynamic, dynamic>>())
          r['id'] as String: (r['can_drive'] as bool, r['holder_only'] as bool),
      };
      final res = await call('rig.list', user);
      expect(error(res), isNull, reason: '$res');
      final listed = of(
        ((res['result'] as Map)['data'] as Map)['rigs'] as List,
      );
      final frame = await catalog.watch
          .lookup('rig.watchSessions')!
          .handler(watchAs(user))
          .first
          .timeout(const Duration(seconds: 10));
      expect(of(frame['rigs'] as List), listed, reason: user);
      for (final MapEntry(key: rigId, value: (canDrive, _)) in listed.entries) {
        expect(
          await rigAccess.mayDrive('ws1', user, rigId),
          canDrive,
          reason: '$user $rigId',
        );
      }
      return listed;
    }

    Future<bool> sees(String user, String rigId) async {
      final viaOp = await reads(user, 'rig.browserState', {'rig_id': rigId});
      expect(await rigAccess.mayView('ws1', user, rigId), viaOp);
      return viaOp;
    }

    Future<bool> drives(
      String user,
      String rigId, {
      String action = 'reload',
    }) async {
      final viaOp = await reads(user, 'rig.act', {
        'rig_id': rigId,
        'action': action,
      });
      expect(await rigAccess.mayDrive('ws1', user, rigId), viaOp);
      return viaOp;
    }

    test('a member who cannot read a repository the space exposes neither '
        'sees its rig nor finds it listed', () async {
      expect(await listedRigs('gina'), {'r-open', 'r-free'});
      expect(await sees('gina', 'r-all'), isFalse);
      expect(await listedRigs('adam'), {'r-open', 'r-free'});
      expect(await sees('adam', 'r-all'), isFalse);
      expect(await listedRigs('fran'), {'r-all', 'r-open', 'r-free'});
      expect(await listedRigs(_owner), {'r-all', 'r-open', 'r-free'});
    });

    test(
      'a member with read but not write sees it and drives nothing',
      () async {
        expect(await sees('fran', 'r-all'), isTrue);
        expect(await drives('fran', 'r-all'), isFalse);
        final res = await call('rig.act', 'fran', {
          'rig_id': 'r-all',
          'action': 'reload',
        });
        expect(error(res)?['data'], {
          'kind': 'repo_grant_required',
          'level': 'write',
        });
        for (final op in ['rig.takeControl', 'rig.releaseControl']) {
          expect(await reads('fran', op, {'rig_id': 'r-all'}), isFalse);
        }
        expect(
          await reads('fran', 'rig.destroy', {'rig_id': 'r-all'}),
          isFalse,
        );
        expect(
          await reads('fran', 'rig.open', {
            'surface': 'browser',
            'conversation_id': 's-all',
          }),
          isFalse,
        );
        expect(rigs.driven, isEmpty);
      },
    );

    test('a member with write drives it, the server owner too', () async {
      expect(await drives('wanda', 'r-all'), isTrue);
      expect(await drives(_owner, 'r-all'), isTrue);
      expect(
        await reads('wanda', 'rig.open', {
          'surface': 'browser',
          'conversation_id': 's-all',
        }),
        isTrue,
      );
      expect(rigs.driven, ['wanda', _owner]);
      expect(rigs.opened, ['wanda']);
    });

    test('every row says whether the caller may drive it', () async {
      expect(await flags('fran'), {
        'r-all': (false, false),
        'r-open': (false, false),
        'r-free': (true, false),
      });
      expect(await flags('wanda'), {
        'r-all': (true, false),
        'r-open': (true, false),
        'r-free': (true, false),
      });
      expect((await flags('gina'))['r-open'], (false, false));
      // An op that returns a rig returns the caller's row.
      final opened = await call('rig.open', 'wanda', {
        'surface': 'browser',
        'conversation_id': 's-all',
      });
      final row = (opened['result'] as Map)['data'] as Map;
      expect(row['id'], 'r-all');
      expect(row['can_drive'], isTrue);
      expect(row['holder_only'], isFalse);
    });

    test('a grant change re-sends the watched frame with the new '
        'answer', () async {
      final frames = <Map<String, dynamic>>[];
      final sub = catalog.watch
          .lookup('rig.watchSessions')!
          .handler(watchAs('fran'))
          .listen(frames.add);
      addTearDown(sub.cancel);
      Future<Map<dynamic, dynamic>> rAll(int frame) async {
        for (var i = 0; i < 500 && frames.length <= frame; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(frames.length, greaterThan(frame));
        return (frames[frame]['rigs'] as List)
            .cast<Map<dynamic, dynamic>>()
            .singleWhere((r) => r['id'] == 'r-all');
      }

      expect((await rAll(0))['can_drive'], isFalse);
      for (final repo in [_widgets, _vault, _notes]) {
        final res = await call('members.setRepoGrant', _owner, {
          'user_id': 'fran',
          'repo_id': repo.id,
          'level': 'write',
        });
        expect(error(res), isNull, reason: '$res');
      }
      // Frames whose answer did not move are not re-sent; the last one is
      // the new standing.
      for (var i = 0; i < 500 && frames.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect((await rAll(frames.length - 1))['can_drive'], isTrue);
    });

    test('a rig bound to no space is any member\'s', () async {
      expect(await sees('nora', 'r-free'), isTrue);
      expect(await drives('gina', 'r-free'), isTrue);
      expect(await drives('gina', 'r-open'), isFalse);
    });

    group("a rig carrying a person's credentials", () {
      setUp(() {
        rigs
          // wanda's terminal machine: her sign-in, narrowed to the repo.
          ..add(
            'r-term',
            space: 's-all',
            spec: RigSpec.exec(
              conversationId: 's-all',
              openedByUserId: 'wanda',
            ),
          )
          // A browser wanda opened whose egress reaches a forge: the guest
          // mints against her forge access.
          ..add(
            'r-cred',
            space: 's-all',
            spec: RigSpec(
              surface: RigSurface.browser,
              conversationId: 's-all',
              openedByUserId: 'wanda',
              egressAllowlist: const ['github.com'],
            ),
          );
      });

      test('is driven by that person alone; others the space admits may '
          'watch it', () async {
        expect(await drives('wanda', 'r-cred'), isTrue);
        expect(await sees(_owner, 'r-cred'), isTrue);
        expect(await sees('fran', 'r-cred'), isTrue);
        expect(await drives(_owner, 'r-cred'), isFalse);
        final res = await call('rig.act', _owner, {
          'rig_id': 'r-cred',
          'action': 'reload',
        });
        expect(error(res)?['code'], RpcErrorCodes.unauthorized);
        expect(error(res)?['data'], {'kind': 'rig_holder_only'});
        for (final op in [
          'rig.takeControl',
          'rig.releaseControl',
          'rig.destroy',
          'rig.restartUnrestricted',
        ]) {
          expect(
            await reads(_owner, op, {'rig_id': 'r-cred'}),
            isFalse,
            reason: op,
          );
        }
        expect(rigs.driven, ['wanda']);
      });

      test('its row tells everyone else it is the holder\'s alone', () async {
        expect((await flags('wanda'))['r-cred'], (true, false));
        expect((await flags('fran'))['r-cred'], (false, true));
        expect((await flags(_owner))['r-cred'], (false, true));
      });

      test(
        "the guest's files and clipboard are read by the holder alone",
        () async {
          expect(
            await rigAccess.mayReadContents('ws1', 'wanda', 'r-cred'),
            isTrue,
          );
          expect(
            await rigAccess.mayReadContents('ws1', 'fran', 'r-cred'),
            isFalse,
          );
          expect(
            await rigAccess.mayReadContents('ws1', _owner, 'r-cred'),
            isFalse,
          );
          // Frames and the rest stay with everyone the space admits.
          expect(await rigAccess.mayView('ws1', 'fran', 'r-cred'), isTrue);
          // A rig carrying nobody's credentials: anyone who sees it reads it.
          expect(
            await rigAccess.mayReadContents('ws1', 'fran', 'r-all'),
            isTrue,
          );
          expect(
            await rigAccess.mayReadContents('ws1', 'gina', 'r-all'),
            isFalse,
          );
          // Somebody else's terminal machine is missing, so nothing to read.
          expect(
            await rigAccess.mayReadContents('ws1', 'fran', 'r-term'),
            isFalse,
          );
        },
      );

      test(
        "somebody else's terminal machine answers like a missing rig",
        () async {
          expect(await listedRigs('wanda'), contains('r-term'));
          expect(await drives('wanda', 'r-term', action: 'screenshot'), isTrue);
          for (final user in [_owner, 'fran']) {
            expect(await listedRigs(user), isNot(contains('r-term')));
            expect(await rigAccess.mayView('ws1', user, 'r-term'), isFalse);
            expect(await rigAccess.mayDrive('ws1', user, 'r-term'), isFalse);
            for (final op in ['rig.browserState', 'rig.act', 'rig.destroy']) {
              final term = await call(op, user, {
                'rig_id': 'r-term',
                'action': 'reload',
              });
              final missing = await call(op, user, {
                'rig_id': 'r-nope',
                'action': 'reload',
              });
              expect(error(term), isNotNull, reason: '$user $op');
              expect(
                jsonEncode(error(term)).replaceAll('r-term', 'ID'),
                jsonEncode(error(missing)).replaceAll('r-nope', 'ID'),
                reason: '$user $op',
              );
            }
          }
        },
      );

      test(
        'a rig carrying nobody\'s credentials keeps the space rule',
        () async {
          expect(await drives(_owner, 'r-all'), isTrue);
          expect(await drives('wanda', 'r-all'), isTrue);
          expect(await drives('fran', 'r-all'), isFalse);
        },
      );
    });

    test(
      'a space read by a member with no grant answers the grant kind',
      () async {
        for (final (op, args) in [
          ('rig.browserState', {'rig_id': 'r-open'}),
          ('messaging.getMessages', {'space_id': 's-open'}),
        ]) {
          final res = await call(op, 'nora', args);
          expect(error(res)?['code'], RpcErrorCodes.unauthorized, reason: op);
          expect(error(res)?['data'], {
            'kind': 'repo_grant_required',
            'level': 'read',
          }, reason: op);
        }
      },
    );
  });

  group("a person's terminal session's forwarded ports", () {
    setUp(() async {
      await select('s-all', [_widgets, _vault, _notes]);
      terminals.openers['tty-w'] = 'wanda';
      rigPorts.known.add('tty-w');
    });

    Map<String, dynamic> port(String session) => {
      'session_id': session,
      'space_id': 's-all',
      'guest_port': 3000,
    };

    Stream<Map<String, dynamic>> watchPorts(String user, String session) =>
        catalog.watch
            .lookup('terminal.watchPorts')!
            .handler(
              WatchQueryContext(
                args: {'workspace_id': 'ws1', ...port(session)},
                workspaceId: 'ws1',
                deviceId: 'dev-$user',
                userId: user,
              ),
            );

    test('answer a member the space admits who did not open it exactly as '
        'a missing session', () async {
      final theirs = await call('terminal.addPort', 'fran', port('tty-w'));
      final missing = await call('terminal.addPort', 'fran', port('tty-x'));
      expect(theirs, missing);
      expect((theirs['result'] as Map)['data'], {'ok': false});
      expect(rigPorts.touched, [('add', 'tty-x')]);

      final frames = <Map<String, dynamic>>[];
      final sub = watchPorts('fran', 'tty-w').listen(frames.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(frames, isEmpty);
      expect(rigPorts.touched, isNot(contains(('watch', 'tty-w'))));
    });

    test('are the opener\'s to change and watch', () async {
      final res = await call('terminal.addPort', 'wanda', port('tty-w'));
      expect((res['result'] as Map)['data'], {'ok': true});
      expect(
        await watchPorts(
          'wanda',
          'tty-w',
        ).first.timeout(const Duration(seconds: 10)),
        {'ports': <Object>[]},
      );
    });
  });

  group('granting', () {
    Future<Object?> warning(String user, Repo repo, {String level = 'read'}) =>
        call('members.setRepoGrant', 'adam', {
          'user_id': user,
          'repo_id': repo.id,
          'level': level,
        }).then((res) {
          expect(error(res), isNull, reason: '$res');
          return ((res['result'] as Map)['data'] as Map)['access_warning'];
        });

    test(
      'says when the member\'s own sign-in cannot read the repository',
      () async {
        expect(await warning('nora', _vault), isNull);
        expect(
          await warning('gina', _vault),
          containsPair('state', 'cannot_read'),
        );
        expect(
          await warning('sol', _vault),
          containsPair('state', 'not_signed_in'),
        );
        expect(
          await warning('uma', _vault),
          containsPair('state', 'unconfirmed'),
        );
        expect(await warning('gina', _notes), isNull);
        expect(await warning('gina', _vault, level: 'none'), isNull);
      },
    );
  });
}

class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.repos);
  final List<Repo> repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(workspaceId == 'ws1' ? repos : const []);

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => workspaceId == 'ws1' && repos.any((r) => r.id == repoId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repos implements RepoRepository {
  _Repos(this._workspaces);
  final _Workspaces _workspaces;

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async =>
      workspaceId == 'ws1'
      ? _workspaces.repos.where((r) => r.id == repoId).firstOrNull
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements WorkspaceMembershipRepository {
  final _members = <String, WorkspaceMember>{};
  final _grants = <String, Map<String, RepoGrantLevel>>{};

  void add(
    String userId,
    WorkspaceRole role,
    Map<String, RepoGrantLevel> grants,
  ) {
    _members[userId] = WorkspaceMember(
      id: 'ws1-$userId',
      workspaceId: 'ws1',
      userId: userId,
      role: role,
      joinedAt: DateTime(2026),
    );
    _grants[userId] = Map.of(grants);
  }

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      workspaceId == 'ws1' ? _members[userId] : null;

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => Map.of(_grants[userId] ?? const {});

  @override
  Future<void> setRepoGrant(
    String workspaceId,
    String userId,
    String repoId,
    RepoGrantLevel level,
  ) async => (_grants[userId] ??= {})[repoId] = level;

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async => [
    ?_members[userId],
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Each person's own GitHub reach; no entry is "not signed in".
class _Access implements PersonForgeAccess {
  final readable = <String, Set<String>>{};
  final unreachable = <String>{};

  @override
  Future<Set<String>?> readableRepoIds(
    String workspaceId,
    String userId,
    ForgeHost forge,
    List<Repo> repos,
  ) async {
    if (unreachable.contains(userId)) {
      throw const NetworkException('GitHub is down', statusCode: 503);
    }
    final set = readable[userId];
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
  ) async => readable.containsKey(userId) ? '$userId-gh' : '';

  @override
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  ) async => const {};
}

class _Terminals with _Unused implements TerminalSessionPort {
  @override
  ({String? spaceId})? ownedSessionOf(String sessionId) => null;

  /// Who opened each person session.
  final openers = <String, String>{};

  @override
  String? openerOf(String sessionId) => openers[sessionId];

  final spawned = <String>[];

  @override
  Future<String> spawn({
    required String workspaceId,
    required String actingUserId,
    required bool hostShellAllowed,
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
  }) async {
    spawned.add(actingUserId);
    return 'tty-${spawned.length}';
  }

  @override
  String? backendOf(String sessionId) => null;

  @override
  Future<TerminalWriteResult> write({
    required String workspaceId,
    required String userId,
    required String sessionId,
    required List<int> data,
  }) async => TerminalWriteResult.none;
}

RemoteRpcCatalog _catalog({
  required RigPort rigs,
  required RigPortsPort rigPorts,
  required RigAccess rigAccess,
  required SpaceRepoAccess spaceRead,
  required _Workspaces workspaces,
  required _Repos repos,
  required _Members members,
  required PrRepoVisibility visibility,
  required TerminalSessionPort terminals,
  required WorkspaceDatabaseManager dbs,
}) => buildRemoteRpcCatalog(
  serverOwnerUserId: _owner,
  membershipRepository: members,
  // The identity group, which `members.*` needs whole; only membership is
  // used here.
  userRepository: _Users(),
  inviteRepository: _Invites(),
  userActivityRepository: _Activity(),
  userPreferencesRepository: _Prefs(),
  inviteService: _InviteService(),
  prRepoVisibility: visibility,
  workspaceDbs: dbs,
  terminalSessions: terminals,
  rigs: rigs,
  rigPorts: rigPorts,
  rigAccess: rigAccess,
  repoFileContent: (workspaceId, repoId, path, {spaceId}) async =>
      (content: 'code of $repoId', binary: false),
  repoFileSearch: (workspaceId, query, {offset = 0, limit, spaceId}) async =>
      const [],
  repoDirectoryListing:
      (workspaceId, repoId, {path = '', cursor = '', limit, spaceId}) async =>
          const {'entries': <Object>[], 'has_more': false},
  reviewFindingStatus: _ReviewFindingStatus(),
  ticketRepository: _Tickets(),
  projectRepository: _Projects(),
  ticketWorkflow: _TicketWorkflow(),
  messagingRepository: DaoMessagingRepository(dbs),
  workspaceRepository: workspaces,
  newsfeedRepository: _Newsfeed(),
  agentRepository: _Agents(),
  repoRepository: repos,
  spaceRepoAccess: spaceRead,
  spaceReadRepository: _SpaceReads(),
  memoryDomainRepository: _MemoryDomains(),
  memoryAccessGrantRepository: _MemoryGrants(),
  agentWorkingMemoryRepository: _WorkingMemory(),
  memoryFactRepository: _MemoryFacts(),
  memoryPolicyRepository: _MemoryPolicies(),
  reviewSpaceRepository: DaoReviewSpaceRepository(dbs),
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
  extraOps: buildContextOps(
    inspection: _Inspection(DaoMessagingRepository(dbs)),
    workspaces: workspaces,
  ),
);

/// Three rigs of ws1 and who drove them.
class _Rigs with _Unused implements RigPort {
  final _rigs = <String, Rig>{};
  final driven = <String>[];
  final opened = <String>[];

  void add(String id, {String? space, RigSpec? spec}) => _rigs[id] = Rig(
    id: id,
    workspaceId: 'ws1',
    surface: spec?.surface ?? RigSurface.browser,
    backend: EnclosureBackend.qemuHvf,
    status: const RigReady(),
    spec: spec ?? RigSpec(surface: RigSurface.browser, conversationId: space),
    createdBy: const UserPrincipal('fran'),
    createdAt: DateTime.utc(2026),
    lastActivityAt: DateTime.utc(2026),
    conversationId: space,
  );

  @override
  Future<Rig?> get(String workspaceId, String rigId) async =>
      workspaceId == 'ws1' ? _rigs[rigId] : null;

  @override
  Future<List<Rig>> list(String workspaceId) async =>
      workspaceId == 'ws1' ? _rigs.values.toList() : const [];

  @override
  Stream<List<Rig>> watch(String workspaceId) =>
      Stream.fromFuture(list(workspaceId));

  @override
  Future<RigBrowserState?> browserState({
    required String workspaceId,
    required String rigId,
  }) async => null;

  @override
  Future<RigActionResult> act({
    required String workspaceId,
    required String rigId,
    required RigAction action,
    required Principal actor,
  }) async {
    driven.add(actor.id);
    return RigActionResult.ok('done');
  }

  @override
  Future<Rig> open({
    required String workspaceId,
    required RigSpec spec,
    required Principal openedBy,
  }) async {
    opened.add(openedBy.id);
    return _rigs['r-all']!;
  }
}

/// Knows only the sessions in [known]; answers anything else as missing
/// (`false`, a silent stream), as the real port service does.
class _RigPorts with _Unused implements RigPortsPort {
  final known = <String>{};
  final touched = <(String, String)>[];

  @override
  Future<bool> addTerminalPortForward(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required int guestPort,
    int? hostPort,
  }) async {
    touched.add(('add', sessionId));
    return known.contains(sessionId);
  }

  @override
  Stream<Map<String, dynamic>> watchTerminalPorts(
    String workspaceId,
    String sessionId, {
    required String spaceId,
  }) {
    touched.add(('watch', sessionId));
    return known.contains(sessionId)
        ? Stream.value(const {'ports': <Object>[]})
        : Stream<Map<String, dynamic>>.multi((_) {});
  }
}

mixin _Unused {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewFindingStatus with _Unused implements ReviewFindingStatusPort {}

class _Users with _Unused implements UserRepository {}

class _Invites with _Unused implements WorkspaceInviteRepository {}

class _Activity with _Unused implements UserActivityRepository {}

class _Prefs with _Unused implements UserPreferencesRepository {}

class _InviteService with _Unused implements WorkspaceInviteService {}

class _Tickets with _Unused implements TicketRepository {}

class _Projects with _Unused implements ProjectRepository {}

class _TicketWorkflow with _Unused implements TicketWorkflowService {}

class _Newsfeed with _Unused implements NewsfeedRepository {}

class _Agents with _Unused implements AgentRepository {}

class _SpaceReads with _Unused implements SpaceReadRepository {}

class _MemoryDomains with _Unused implements MemoryDomainRepository {}

class _MemoryGrants with _Unused implements MemoryAccessGrantRepository {}

class _WorkingMemory with _Unused implements AgentWorkingMemoryRepository {}

class _MemoryFacts with _Unused implements MemoryFactRepository {}

class _MemoryPolicies with _Unused implements MemoryPolicyRepository {}

class _RunLogs with _Unused implements AgentRunLogRepository {}

class _IsolatedRepos with _Unused implements IsolatedRepoRepository {}

class _VoiceProfiles with _Unused implements VoiceProfileRepository {}

class _Meetings with _Unused implements MeetingRepository {}

class _TicketLinks with _Unused implements TicketLinkRepository {}

class _PipelineRuns with _Unused implements PipelineRunRepository {}

class _PipelineTemplates with _Unused implements PipelineTemplateRepository {}

class _PipelineTriggers with _Unused implements PipelineTriggerRepository {}

class _Teams with _Unused implements TeamRepository {}

class _Orchestrations with _Unused implements OrchestrationRepository {}

class _Goals with _Unused implements GoalRepository {}

class _Approvals with _Unused implements ApprovalRepository {}

class _Presence with _Unused implements AgentPresenceService {}

class _Todos with _Unused implements TodoRepository {}

class _NotificationFeed with _Unused implements NotificationFeedRepository {}

class _GoalRuns with _Unused implements AgentGoalRunRepository {}

class _GoalSupervisor with _Unused implements GoalSupervisor {}

class _PairedDevices with _Unused implements PairedDeviceDao {}

class _PairedDeviceSecrets with _Unused implements PairedDeviceSecretsPort {}

class _Calendar with _Unused implements CalendarRepository {}

class _PrLifecycle with _Unused implements PrLifecycleRepository {}

/// `context.inspect` over the real space selection; the inspection itself is
/// beside the point here (who may ask is).
class _Inspection with _Unused implements ContextInspectionService {
  _Inspection(this._messaging);

  final MessagingRepository _messaging;

  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) => _messaging.spaceRepoSelection(workspaceId, spaceId);

  @override
  Future<ContextInspection> inspect({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String conversationId,
    bool includeContent = false,
  }) async => ContextInspection(
    workspaceId: workspaceId,
    spaceId: spaceId,
    agentId: agentId,
    agentName: 'Ada',
    mode: 'chat',
    windowTokens: 1,
    segments: const [],
  );
}
