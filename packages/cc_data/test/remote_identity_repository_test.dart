import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteIdentityRepository] — the identity & membership surface —
/// over an in-process JSON-RPC host. Each method is a thin `_client.call(...)`
/// or `_client.subscribe(...)` delegate that decodes the `identity.*` /
/// `users.*` / `members.*` / `invites.*` / `prefs.*` / `activity.*` wire shapes.
/// These tests pin the op name, the args shape and the return-value mapping.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteIdentityRepository me + users', () {
    test('me decodes the full identity payload', () async {
      host.callResults['identity.me'] = {
        'user': {
          'id': 'u-1',
          'handle': 'sam',
          'display_name': 'Sam',
          'email': 'sam@example.com',
        },
        'device_id': 'dev-1',
        'is_server_owner': true,
        'memberships': [
          {
            'id': 'm-1',
            'workspace_id': 'ws-1',
            'user_id': 'u-1',
            'role': 'admin',
          },
        ],
      };
      final repo = RemoteIdentityRepository(client);
      final me = await repo.me();
      expect(me.user.id, 'u-1');
      expect(me.user.displayName, 'Sam');
      expect(me.deviceId, 'dev-1');
      expect(me.isServerOwner, isTrue);
      expect(me.memberships.length, 1);
      expect(me.memberships.first.workspaceId, 'ws-1');
      expect(me.memberships.first.role, 'admin');
      expect(me.roleIn('ws-1'), 'admin');
      expect(me.roleIn('ws-other'), isNull);
    });

    test('me tolerates a missing memberships array', () async {
      host.callResults['identity.me'] = {
        'user': {'id': 'u-1'},
      };
      final repo = RemoteIdentityRepository(client);
      final me = await repo.me();
      expect(me.user.id, 'u-1');
      expect(me.isServerOwner, isFalse);
      expect(me.deviceId, '');
      expect(me.memberships, isEmpty);
    });

    test('me skips non-Map membership entries', () async {
      host.callResults['identity.me'] = {
        'user': {'id': 'u-1'},
        'memberships': ['junk', 3],
      };
      final repo = RemoteIdentityRepository(client);
      expect((await repo.me()).memberships, isEmpty);
    });

    test('listUsers maps the users array', () async {
      host.callResults['users.list'] = {
        'users': [
          {'id': 'u-1', 'display_name': 'Sam'},
          {'id': 'u-2', 'display_name': 'Jo'},
        ],
      };
      final repo = RemoteIdentityRepository(client);
      final users = await repo.listUsers();
      expect(users.length, 2);
      expect(users[0].id, 'u-1');
      expect(users[1].displayName, 'Jo');
    });

    test('watchUsers streams the users array', () async {
      host.snapshotFor('users.watchAll', {
        'users': [
          {'id': 'u-1', 'display_name': 'Sam'},
        ],
      });
      final repo = RemoteIdentityRepository(client);
      final users = await repo.watchUsers().first;
      expect(users.first.id, 'u-1');
      final sub = host.lastSubscribe!;
      expect(sub.query, 'users.watchAll');
      expect(sub.args, isEmpty);
    });
  });

  group('RemoteIdentityRepository profile', () {
    test('updateProfile sends only the non-null fields', () async {
      host.callResults['users.updateProfile'] = {
        'user': {'id': 'u-1'},
      };
      final repo = RemoteIdentityRepository(client);
      await repo.updateProfile(displayName: 'Sam', email: 'sam@example.com');
      final call = host.lastCall('users.updateProfile')!;
      expect(call.args['display_name'], 'Sam');
      expect(call.args['email'], 'sam@example.com');
      expect(call.args.containsKey('avatar_ref'), isFalse);
      expect(call.args.containsKey('git_author_name'), isFalse);
      expect(call.args.containsKey('git_author_email'), isFalse);
    });

    test('markOnboardingFinished names the op and sends no arguments', () async {
      // The target is always the session's own user, server-side. A `user_id`
      // argument here would be a way to mark somebody else onboarded.
      host.callResults['users.markOnboardingFinished'] = {
        'onboarding_finished_at': '2026-01-02T03:04:05.000',
      };
      final repo = RemoteIdentityRepository(client);
      await repo.markOnboardingFinished();
      expect(host.lastCall('users.markOnboardingFinished')!.args, isEmpty);
    });

    test('me decodes onboarding_finished_at', () async {
      // The flag the onboarding gate reads: it lives on the USER, not in a
      // synced preference, so it arrives on `identity.me` and nowhere else.
      host.callResults['identity.me'] = {
        'user': {
          'id': 'u-1',
          'onboarding_finished_at': '2026-01-02T03:04:05.000',
        },
      };
      final repo = RemoteIdentityRepository(client);
      expect(
        (await repo.me()).user.onboardingFinishedAt,
        DateTime(2026, 1, 2, 3, 4, 5),
      );
    });

    test('me leaves onboarding_finished_at null when absent', () async {
      host.callResults['identity.me'] = {
        'user': {'id': 'u-1'},
      };
      final repo = RemoteIdentityRepository(client);
      expect((await repo.me()).user.onboardingFinishedAt, isNull);
    });

    test('updateProfile returns the decoded user', () async {
      host.callResults['users.updateProfile'] = {
        'user': {'id': 'u-1', 'display_name': 'New'},
      };
      final repo = RemoteIdentityRepository(client);
      final user = await repo.updateProfile(displayName: 'New');
      expect(user.id, 'u-1');
      expect(user.displayName, 'New');
    });

    test('updateProfile forwards the avatar + git author fields', () async {
      host.callResults['users.updateProfile'] = {
        'user': {'id': 'u-1'},
      };
      final repo = RemoteIdentityRepository(client);
      await repo.updateProfile(
        avatarRef: 'avatar-1',
        gitAuthorName: 'Sam',
        gitAuthorEmail: 'sam@example.com',
      );
      final call = host.lastCall('users.updateProfile')!;
      expect(call.args['avatar_ref'], 'avatar-1');
      expect(call.args['git_author_name'], 'Sam');
      expect(call.args['git_author_email'], 'sam@example.com');
      expect(call.args.containsKey('display_name'), isFalse);
      expect(call.args.containsKey('email'), isFalse);
    });
  });

  group('RemoteIdentityRepository members', () {
    test('watchMembers streams members for the workspace', () async {
      host.snapshotFor('members.watchForWorkspace', {
        'members': [
          {
            'id': 'm-1',
            'workspace_id': 'ws-1',
            'user_id': 'u-1',
            'role': 'admin',
          },
        ],
      });
      final repo = RemoteIdentityRepository(client);
      final members = await repo.watchMembers('ws-1').first;
      expect(members.first.id, 'm-1');
      expect(members.first.userId, 'u-1');
      final sub = host.lastSubscribe!;
      expect(sub.args['workspace_id'], 'ws-1');
    });

    test('setMemberRole forwards the workspace + user + role', () async {
      final repo = RemoteIdentityRepository(client);
      await repo.setMemberRole('ws-1', 'u-1', 'admin');
      final call = host.lastCall('members.setRole')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['user_id'], 'u-1');
      expect(call.args['role'], 'admin');
    });

    test('removeMember forwards the workspace + user', () async {
      final repo = RemoteIdentityRepository(client);
      await repo.removeMember('ws-1', 'u-1');
      final call = host.lastCall('members.remove')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['user_id'], 'u-1');
    });

    test('getRepoGrants returns the grants map', () async {
      host.callResults['members.getRepoGrants'] = {
        'grants': {'repo-1': 'write', 'repo-2': 'read'},
      };
      final repo = RemoteIdentityRepository(client);
      final grants = await repo.getRepoGrants('ws-1', 'u-1');
      expect(grants['repo-1'], 'write');
      expect(grants['repo-2'], 'read');
      final call = host.lastCall('members.getRepoGrants')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['user_id'], 'u-1');
    });

    test('getRepoGrants returns empty when grants is absent', () async {
      host.callResults['members.getRepoGrants'] = const {};
      final repo = RemoteIdentityRepository(client);
      expect(await repo.getRepoGrants('ws-1', 'u-1'), isEmpty);
    });

    test('setRepoGrant forwards the full grant tuple', () async {
      final repo = RemoteIdentityRepository(client);
      await repo.setRepoGrant('ws-1', 'u-1', 'repo-1', 'write');
      final call = host.lastCall('members.setRepoGrant')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['user_id'], 'u-1');
      expect(call.args['repo_id'], 'repo-1');
      expect(call.args['level'], 'write');
    });
  });

  group('RemoteIdentityRepository invites', () {
    test('createInvite returns the invite + code + url + descriptor', () async {
      host.callResults['invites.create'] = {
        'invite': {'id': 'inv-1', 'workspace_id': 'ws-1', 'role': 'member'},
        'code': 'ABC123',
        'redeem_url': 'https://join/x#ABC123',
        'descriptor': {
          'sid': 'srv-1',
          'n': 'Acme',
          'fp': 'fp-1',
          'p': [
            {'t': 'lo', 'port': 7000},
          ],
        },
      };
      final repo = RemoteIdentityRepository(client);
      final result = await repo.createInvite('ws-1', role: 'member');
      expect(result.invite.id, 'inv-1');
      expect(result.invite.workspaceId, 'ws-1');
      expect(result.code, 'ABC123');
      expect(result.redeemUrl, 'https://join/x#ABC123');
      expect(result.descriptor, isNotNull);
      expect(result.descriptor!.serverId, 'srv-1');
      expect(result.descriptor!.serverName, 'Acme');
      final call = host.lastCall('invites.create')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['role'], 'member');
      expect(call.args['repo_grants'], isEmpty);
      expect(call.args.containsKey('ttl_hours'), isFalse);
    });

    test(
      'createInvite forwards repoGrants + ttlHours + null descriptor',
      () async {
        host.callResults['invites.create'] = {
          'invite': {'id': 'inv-1', 'workspace_id': 'ws-1', 'role': 'member'},
          'code': 'ABC',
        };
        final repo = RemoteIdentityRepository(client);
        final result = await repo.createInvite(
          'ws-1',
          role: 'member',
          repoGrants: {'repo-1': 'write'},
          ttlHours: 24,
        );
        expect(result.descriptor, isNull);
        expect(result.redeemUrl, '');
        final call = host.lastCall('invites.create')!;
        expect(call.args['repo_grants'], {'repo-1': 'write'});
        expect(call.args['ttl_hours'], 24);
      },
    );

    test('watchInvites streams invites for the workspace', () async {
      host.snapshotFor('invites.watchForWorkspace', {
        'invites': [
          {'id': 'inv-1', 'workspace_id': 'ws-1', 'role': 'member'},
        ],
      });
      final repo = RemoteIdentityRepository(client);
      final invites = await repo.watchInvites('ws-1').first;
      expect(invites.first.id, 'inv-1');
      final sub = host.lastSubscribe!;
      expect(sub.args['workspace_id'], 'ws-1');
    });

    test('revokeInvite forwards the workspace + invite', () async {
      final repo = RemoteIdentityRepository(client);
      await repo.revokeInvite('ws-1', 'inv-1');
      final call = host.lastCall('invites.revoke')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['invite_id'], 'inv-1');
    });
  });

  group('RemoteIdentityRepository prefs', () {
    test('prefsGetAll returns the prefs map', () async {
      host.callResults['prefs.getAll'] = {
        'prefs': {'theme': 'dark', 'lang': 'en'},
      };
      final repo = RemoteIdentityRepository(client);
      final prefs = await repo.prefsGetAll();
      expect(prefs['theme'], 'dark');
      expect(prefs['lang'], 'en');
    });

    test('prefsGetAll returns empty when prefs is absent', () async {
      host.callResults['prefs.getAll'] = const {};
      final repo = RemoteIdentityRepository(client);
      expect(await repo.prefsGetAll(), isEmpty);
    });

    test('prefsSet sends key + value', () async {
      final repo = RemoteIdentityRepository(client);
      await repo.prefsSet('theme', 'dark');
      final call = host.lastCall('prefs.set')!;
      expect(call.args['key'], 'theme');
      expect(call.args['value'], 'dark');
    });

    test('prefsSet sends a null value (delete)', () async {
      final repo = RemoteIdentityRepository(client);
      await repo.prefsSet('theme', null);
      final call = host.lastCall('prefs.set')!;
      expect(call.args['key'], 'theme');
      expect(call.args.containsKey('value'), isFalse);
    });

    test('watchOwnPrefs streams the prefs map', () async {
      host.snapshotFor('prefs.watchOwn', {
        'prefs': {'theme': 'dark'},
      });
      final repo = RemoteIdentityRepository(client);
      final prefs = await repo.watchOwnPrefs().first;
      expect(prefs['theme'], 'dark');
    });

    test('watchOwnPrefs returns empty when prefs is absent', () async {
      host.snapshotFor('prefs.watchOwn', const {});
      final repo = RemoteIdentityRepository(client);
      expect(await repo.watchOwnPrefs().first, isEmpty);
    });
  });

  group('RemoteIdentityRepository activity', () {
    test('watchActivity streams the audit trail for the workspace', () async {
      host.snapshotFor('activity.watchForWorkspace', {
        'entries': [
          {
            'id': 'act-1',
            'workspace_id': 'ws-1',
            'user_id': 'u-1',
            'action': 'login',
          },
        ],
      });
      final repo = RemoteIdentityRepository(client);
      final entries = await repo.watchActivity('ws-1').first;
      expect(entries.first.id, 'act-1');
      expect(entries.first.userId, 'u-1');
      expect(entries.first.action, 'login');
      final sub = host.lastSubscribe!;
      expect(sub.args['workspace_id'], 'ws-1');
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted snapshots keyed by watch query (pushed on subscribe).
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed to the next subscription for [query].
  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        // Immediately push the scripted snapshot for this query (if any).
        final snapshot = snapshots[query];
        if (snapshot != null) {
          space.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        final data = callResults[op] ?? const <String, dynamic>{};
        _reply(id, {'op': op, 'data': data});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
