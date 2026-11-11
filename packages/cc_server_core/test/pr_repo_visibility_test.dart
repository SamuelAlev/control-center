import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, NeedsSignInException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

Repo _repo(String id, {ForgeHost forge = ForgeHost.github}) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: 'o',
  remoteName: id,
  forge: forge,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

Map<String, dynamic> _group(Repo repo, List<Map<String, dynamic>> prs) => {
  'repo_id': repo.id,
  'repo_full_name': repo.fullName,
  'prs': prs,
};

Map<String, dynamic> _pr(
  Repo repo,
  int number, {
  String author = 'someone',
  List<String> reviewers = const [],
}) => {
  'number': number,
  'repo_full_name': repo.fullName,
  'is_draft': false,
  'author': {'login': author},
  'requested_reviewers': [
    for (final r in reviewers) {'login': r},
  ],
  'requested_team_slugs': const <String>[],
};

void main() {
  final gh1 = _repo('gh1');
  final gh2 = _repo('gh2');
  final gl1 = _repo('gl1', forge: ForgeHost.gitlab);

  late _Workspaces workspaces;
  late _Members members;
  late _Access access;
  late StreamController<({String userId, String? workspaceId})> credentials;
  late PrRepoVisibility visibility;

  setUp(() {
    workspaces = _Workspaces({
      'ws1': [gh1, gh2, gl1],
      'ws2': [_repo('other')],
    });
    members = _Members()
      ..add('ws1', 'admin', WorkspaceRole.admin)
      ..add('ws1', 'member', WorkspaceRole.member)
      ..add('ws2', 'stranger', WorkspaceRole.admin);
    access = _Access();
    credentials = StreamController.broadcast();
    visibility = PrRepoVisibility(
      workspaces: workspaces,
      members: members,
      access: access,
      credentialChanges: credentials.stream,
      retryAfterFailure: const Duration(milliseconds: 10),
      initialWait: Duration.zero,
    );
  });

  tearDown(() async {
    visibility.dispose();
    await credentials.close();
  });

  group('the rule', () {
    test('an admin sees what their own forge sign-in can read', () async {
      access.readable[('admin', ForgeHost.github)] = {gh1.id};
      access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};

      final view = await visibility.resolve('ws1', 'admin');
      expect(view.visible.keys, unorderedEquals([gh1.id, gl1.id]));
      expect(view.hidden[gh2.id]?.reason, HiddenRepoReason.noForgeAccess);
      expect(view.hiddenReposWire(), [
        {'forge': 'github', 'reason': 'no_forge_access', 'count': 1},
      ]);
    });

    test('a member needs a read grant AND forge access', () async {
      members.grants[('ws1', 'member')] = {
        gh1.id: RepoGrantLevel.read,
        gh2.id: RepoGrantLevel.read,
      };
      access.readable[('member', ForgeHost.github)] = {gh1.id};
      access.readable[('member', ForgeHost.gitlab)] = {gl1.id};

      final view = await visibility.resolve('ws1', 'member');
      expect(view.visible.keys, [gh1.id]);
      expect(view.hidden[gh2.id]?.reason, HiddenRepoReason.noForgeAccess);
      expect(
        view.hidden[gl1.id]?.reason,
        HiddenRepoReason.noGrant,
        reason: 'forge access alone never out-privileges the grant',
      );
    });

    test(
      'not signed in to a forge hides its repos as sign-in required',
      () async {
        access.readable[('admin', ForgeHost.github)] = {gh1.id, gh2.id};
        // No GitLab entry: the fake answers null (not signed in).

        final view = await visibility.resolve('ws1', 'admin');
        expect(view.hidden[gl1.id]?.reason, HiddenRepoReason.signInRequired);
        expect(view.visible.keys, unorderedEquals([gh1.id, gh2.id]));
      },
    );

    test('a non-member sees nothing, and their forge is never asked', () async {
      final view = await visibility.resolve('ws1', 'stranger');
      expect(view.visible, isEmpty);
      expect(view.hidden.values.map((h) => h.reason).toSet(), {
        HiddenRepoReason.noGrant,
      });
      expect(access.calls, isEmpty);
    });

    test('a membership in another workspace grants nothing here', () async {
      access.readable[('stranger', ForgeHost.github)] = {gh1.id, gh2.id};
      final view = await visibility.resolve('ws1', 'stranger');
      expect(view.visible, isEmpty);
    });

    test(
      'an unknown reach is `checking`, never visible (fail closed)',
      () async {
        access.gate = Completer<void>();
        access.readable[('admin', ForgeHost.github)] = {gh1.id, gh2.id};

        final view = await visibility.current('ws1', 'admin');
        expect(view.visible, isEmpty);
        expect(view.settled, isFalse);
        expect(view.hidden.values.map((h) => h.reason).toSet(), {
          HiddenRepoReason.checking,
        });
        access.gate!.complete();
      },
    );

    test('a forge that cannot answer keeps repos `checking`', () async {
      access.failing.add(ForgeHost.github);
      access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};

      final view = await visibility.resolve('ws1', 'admin');
      expect(view.hidden[gh1.id]?.reason, HiddenRepoReason.checking);
      expect(view.visible.keys, [gl1.id]);
    });
  });

  group('live', () {
    test('watch re-emits once the listing lands', () async {
      access.gate = Completer<void>();
      access.readable[('admin', ForgeHost.github)] = {gh1.id};
      access.readable[('admin', ForgeHost.gitlab)] = {};

      final views = <RepoVisibility>[];
      final sub = visibility.watch('ws1', 'admin').listen(views.add);
      await _pump();
      expect(views, isNotEmpty);
      expect(views.first.visible, isEmpty, reason: 'checking first');

      access.gate!.complete();
      await _pump();
      expect(views.last.visible.keys, [gh1.id]);
      expect(views.last.settled, isTrue);
      await sub.cancel();
    });

    test('a credential change re-lists the person', () async {
      access.readable[('admin', ForgeHost.github)] = {gh1.id};
      access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};
      expect(
        (await visibility.resolve('ws1', 'admin')).visible.keys,
        unorderedEquals([gh1.id, gl1.id]),
      );

      access.readable.remove(('admin', ForgeHost.github));
      credentials.add((userId: 'admin', workspaceId: 'ws1'));
      await _pump();

      final view = await visibility.resolve('ws1', 'admin');
      expect(view.hidden[gh1.id]?.reason, HiddenRepoReason.signInRequired);
      expect(view.visible.keys, [gl1.id]);
    });

    test('a grant change applies on the next evaluation', () async {
      access.readable[('member', ForgeHost.github)] = {gh1.id, gh2.id};
      expect((await visibility.resolve('ws1', 'member')).visible, isEmpty);

      members.grants[('ws1', 'member')] = {gh2.id: RepoGrantLevel.read};
      visibility.memberChanged('ws1', 'member');
      expect((await visibility.resolve('ws1', 'member')).visible.keys, [
        gh2.id,
      ]);
    });
  });

  // The fresh window runs on a fake clock: real 100 ms timers fire late
  // under a loaded test run and turn these into coin flips.
  group('freshness', () {
    PrRepoVisibility quickAt(FakeAsync async) => PrRepoVisibility(
      workspaces: workspaces,
      members: members,
      access: access,
      freshFor: const Duration(milliseconds: 200),
      refreshAfter: const Duration(milliseconds: 80),
      retryAfterFailure: const Duration(milliseconds: 10),
      initialWait: Duration.zero,
      now: async.getClock(DateTime(2026)).now,
    );

    test('a reach that cannot be renewed stops serving once it expires '
        '(fail closed)', () {
      fakeAsync((async) {
        final quick = quickAt(async);
        access.readable[('admin', ForgeHost.github)] = {gh1.id, gh2.id};
        access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};
        expect(
          _settle(async, quick.resolve('ws1', 'admin')).visible.keys,
          unorderedEquals([gh1.id, gh2.id, gl1.id]),
        );

        // GitHub goes down. Still fresh: the last answer serves.
        access.failing.add(ForgeHost.github);
        async.elapse(const Duration(milliseconds: 100));
        expect(
          _settle(async, quick.resolve('ws1', 'admin')).visible.keys,
          unorderedEquals([gh1.id, gh2.id, gl1.id]),
          reason: 'a failed renewal inside the fresh window keeps serving',
        );

        // Past the fresh window with every renewal failing: unknown again.
        async.elapse(const Duration(milliseconds: 150));
        final view = _settle(async, quick.current('ws1', 'admin'));
        expect(view.hidden[gh1.id]?.reason, HiddenRepoReason.checking);
        expect(view.hidden[gh2.id]?.reason, HiddenRepoReason.checking);
        expect(view.visible.keys, [gl1.id], reason: 'GitLab renewed fine');
        quick.dispose();
      });
    });

    test('a quiet live view re-evaluates on its own when its reach '
        'expires', () {
      fakeAsync((async) {
        final quick = quickAt(async);
        access.readable[('admin', ForgeHost.github)] = {gh1.id, gh2.id};
        access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};
        final views = <RepoVisibility>[];
        final sub = quick.watch('ws1', 'admin').listen(views.add);
        async.elapse(const Duration(milliseconds: 20));
        expect(views.last.visible.keys, hasLength(3));

        access.failing.add(ForgeHost.github);
        // No credential change, no link, no grant change: only the clock.
        async.elapse(const Duration(milliseconds: 400));
        expect(views.last.hidden[gh1.id]?.reason, HiddenRepoReason.checking);
        expect(views.last.visible.keys, [gl1.id]);
        unawaited(sub.cancel());
        quick.dispose();
      });
    });

    test('a renewal that lands keeps the view without a gap', () {
      fakeAsync((async) {
        final quick = quickAt(async);
        access.readable[('admin', ForgeHost.github)] = {gh1.id};
        access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};
        final views = <RepoVisibility>[];
        final sub = quick.watch('ws1', 'admin').listen(views.add);
        async.elapse(const Duration(milliseconds: 400));
        expect(views, isNotEmpty);
        expect(
          views.where((v) => !v.settled),
          isEmpty,
          reason: 'renewed before expiry, so never `checking` again',
        );
        expect(
          access.calls.where((c) => c.$3 == ForgeHost.github).length,
          greaterThan(1),
          reason: 'renewed in the background',
        );
        unawaited(sub.cancel());
        quick.dispose();
      });
    });
  });

  group('listing joins', () {
    test('a repo linked while a listing runs is listed, not left '
        '`checking`', () async {
      access.readable[('admin', ForgeHost.github)] = {gh1.id, gh2.id, 'gh3'};
      access.readable[('admin', ForgeHost.gitlab)] = {gl1.id};
      access.gate = Completer<void>();

      // A listing over gh1+gh2 is in flight...
      final first = visibility.resolve('ws1', 'admin');
      await _pump();
      // ...when gh3 is linked, and someone asks again.
      final gh3 = _repo('gh3');
      workspaces.repos['ws1'] = [gh1, gh2, gl1, gh3];
      final second = visibility.resolve('ws1', 'admin');
      await _pump();
      access.gate!.complete();

      await first;
      final view = await second;
      expect(view.visible.keys, contains(gh3.id));
      expect(view.settled, isTrue);
    });
  });

  group('per-repo checks', () {
    test('requireForgeAccess refuses a repo the sign-in cannot read', () async {
      access.readable[('admin', ForgeHost.github)] = {gh1.id};
      await visibility.requireForgeAccess('ws1', 'admin', gh1);
      await expectLater(
        visibility.requireForgeAccess('ws1', 'admin', gh2),
        throwsA(isA<AuthException>()),
      );
    });

    test('requireForgeAccess asks for a sign-in when there is none', () async {
      await expectLater(
        visibility.requireForgeAccess('ws1', 'admin', gl1),
        throwsA(isA<NeedsSignInException>()),
      );
    });
  });

  group('surfaces', () {
    test('filterOpenPrFrame drops hidden repos and reports counts only', () {
      final view = RepoVisibility(
        visible: {gh1.id: gh1},
        hidden: {
          gh2.id: (forge: ForgeHost.github, reason: HiddenRepoReason.noGrant),
          gl1.id: (
            forge: ForgeHost.gitlab,
            reason: HiddenRepoReason.signInRequired,
          ),
        },
      );
      final filtered = view.filterOpenPrFrame({
        'authenticated': true,
        'sweep_in_flight': false,
        'repos': [
          _group(gh1, [_pr(gh1, 1)]),
          _group(gh2, [_pr(gh2, 2)]),
          _group(gl1, [_pr(gl1, 3)]),
        ],
        'terminal_prs': {'secret': 1},
      });
      expect((filtered['repos'] as List).map((r) => (r as Map)['repo_id']), [
        gh1.id,
      ]);
      expect(filtered.containsKey('terminal_prs'), isFalse);
      expect(filtered['hidden_repos'], [
        {'forge': 'github', 'reason': 'no_grant', 'count': 1},
        {'forge': 'gitlab', 'reason': 'sign_in_required', 'count': 1},
      ]);
      expect(
        filtered.toString(),
        isNot(contains('gh2')),
        reason: 'a hidden repo is never named on the wire',
      );
    });

    test('the badge counts only visible repos, per-forge logins', () {
      final view = RepoVisibility(
        visible: {gh1.id: gh1, gl1.id: gl1},
        hidden: {
          gh2.id: (forge: ForgeHost.github, reason: HiddenRepoReason.noGrant),
        },
      );
      final frame = {
        'repos': [
          _group(gh1, [
            _pr(gh1, 1, reviewers: ['octo']),
            _pr(gh1, 2, reviewers: ['someone-else']),
          ]),
          _group(gh2, [
            _pr(gh2, 3, reviewers: ['octo']),
          ]),
          _group(gl1, [
            _pr(gl1, 4, reviewers: ['octo-gl']),
            _pr(gl1, 5, reviewers: ['octo']),
          ]),
        ],
      };
      expect(
        PrRepoVisibility.needsMyReviewCount(
          frame,
          view,
          loginByForge: {ForgeHost.github: 'octo', ForgeHost.gitlab: 'octo-gl'},
          githubTeams: const {},
        ),
        2,
        reason:
            'gh1#1 and gl1#4: gh2 is hidden, and GitLab matches its own '
            'login only',
      );
    });

    test('combineWithVisibility re-filters when visibility moves', () async {
      final frames = StreamController<Map<String, dynamic>>();
      final views = StreamController<RepoVisibility>();
      final out = <Map<String, dynamic>>[];
      final sub = combineWithVisibility(
        frames.stream,
        views.stream,
        (frame, view) => view.filterOpenPrFrame(frame),
      ).listen(out.add);

      frames.add({
        'repos': [
          _group(gh1, [_pr(gh1, 1)]),
          _group(gh2, [_pr(gh2, 2)]),
        ],
      });
      await _pump();
      expect(out, isEmpty, reason: 'nothing before visibility is known');

      views.add(
        RepoVisibility(
          visible: const {},
          hidden: {
            gh1.id: (
              forge: ForgeHost.github,
              reason: HiddenRepoReason.checking,
            ),
            gh2.id: (
              forge: ForgeHost.github,
              reason: HiddenRepoReason.checking,
            ),
          },
        ),
      );
      await _pump();
      expect(out.last['repos'] as List, isEmpty);

      views.add(
        RepoVisibility(
          visible: {gh1.id: gh1},
          hidden: {
            gh2.id: (
              forge: ForgeHost.github,
              reason: HiddenRepoReason.noForgeAccess,
            ),
          },
        ),
      );
      await _pump();
      expect((out.last['repos'] as List).map((r) => (r as Map)['repo_id']), [
        gh1.id,
      ]);
      final emitted = out.length;
      views.add(
        RepoVisibility(
          visible: {gh1.id: gh1},
          hidden: {
            gh2.id: (
              forge: ForgeHost.github,
              reason: HiddenRepoReason.noForgeAccess,
            ),
          },
        ),
      );
      await _pump();
      expect(out, hasLength(emitted), reason: 'identical frames collapse');

      await sub.cancel().timeout(const Duration(seconds: 5));
      await frames.close();
      await views.close();
    });
  });
}

/// Drives [future] to completion on [async]'s clock without advancing it.
T _settle<T>(FakeAsync async, Future<T> future) {
  T? value;
  Object? error;
  var done = false;
  future.then(
    (v) {
      value = v;
      done = true;
    },
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  async.elapse(Duration.zero);
  if (!done) {
    throw StateError('future did not complete without the clock moving');
  }
  if (error != null) {
    throw error!;
  }
  return value as T;
}

Future<void> _pump() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.repos);
  final Map<String, List<Repo>> repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(repos[workspaceId] ?? const []);

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
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      _members[(workspaceId, userId)];

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => Map.of(grants[(workspaceId, userId)] ?? const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Each person's reach per forge; a missing entry means "not signed in".
class _Access implements PersonForgeAccess {
  final readable = <(String, ForgeHost), Set<String>>{};
  final failing = <ForgeHost>{};
  final calls = <(String, String, ForgeHost)>[];
  Completer<void>? gate;

  @override
  Future<Set<String>?> readableRepoIds(
    String workspaceId,
    String userId,
    ForgeHost forge,
    List<Repo> repos,
  ) async {
    calls.add((workspaceId, userId, forge));
    await gate?.future;
    if (failing.contains(forge)) {
      throw StateError('${forge.wire} is down');
    }
    final set = readable[(userId, forge)];
    if (set == null) {
      return null;
    }
    return {
      for (final r in repos)
        if (set.contains(r.id)) r.id,
    };
  }

  @override
  Future<String> viewerLogin(
    String workspaceId,
    String userId,
    ForgeHost forge,
  ) async => '';

  @override
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  ) async => const {};
}
