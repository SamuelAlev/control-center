/// Which of a workspace's linked repositories one person may see pull
/// requests for.
///
/// Workspace membership never out-privileges the forge. A member sees a
/// repository's pull requests only when both hold:
///
/// 1. they are an admin of the workspace, or hold a read grant on the repo;
/// 2. their OWN sign-in on the repo's forge can read it.
///
/// Admins and the owner included. Anything not yet known (a person whose
/// forge reach has not been listed, a repo linked a moment ago, a listing
/// older than [PrRepoVisibility.freshFor] that could not be renewed) is
/// hidden as `checking` until it is, and every live surface re-emits once it
/// is: the service fails closed, never open.
///
/// Every workspace-wide PR surface filters through here and reports what it
/// left out only as counts per forge and reason (`hidden_repos`), never the
/// names of repositories the caller cannot see.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ForgeAccessRefusedException, NeedsSignInException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show prCountsTowardNeedsMyReview;

/// The [AuthException.code] of a [PrRepoVisibility.requireForgeAccess]
/// refusal because the forge could not be asked.
const forgeAccessUnconfirmedCode = 'forge_unconfirmed';

/// The [AuthException.code] of a [PrRepoVisibility.requireForgeAccess]
/// refusal because the person's sign-in cannot read the repository.
const forgeCannotReadCode = 'forge_cannot_read';

/// Why a linked repository is left out of a person's PR surfaces.
enum HiddenRepoReason {
  /// The person is not signed in to the repo's forge in this workspace.
  signInRequired('sign_in_required'),

  /// Their own forge sign-in cannot read the repository.
  noForgeAccess('no_forge_access'),

  /// They are not an admin and hold no read grant on it.
  noGrant('no_grant'),

  /// Their forge reach has not been checked yet (or the forge has not
  /// answered); the surface re-emits once it has.
  checking('checking');

  const HiddenRepoReason(this.wire);

  /// The wire spelling.
  final String wire;
}

/// One person's view of a workspace's linked forge repositories.
final class RepoVisibility {
  /// Creates a [RepoVisibility].
  const RepoVisibility({required this.visible, required this.hidden});

  /// Nothing visible, nothing hidden (a workspace with no forge repos).
  static const RepoVisibility empty = RepoVisibility(visible: {}, hidden: {});

  /// The repositories the person may see, by repo id.
  final Map<String, Repo> visible;

  /// The repositories left out, by repo id. Server-side only: the wire
  /// carries [hiddenReposWire] (counts), never these ids or names.
  final Map<String, ({ForgeHost forge, HiddenRepoReason reason})> hidden;

  /// Whether the person may see [repoId].
  bool canSee(String repoId) => visible.containsKey(repoId);

  /// Whether the person may see the pull requests of the visible repository
  /// named [repoFullName] (`owner/name`, any case). A name no visible repo
  /// carries — hidden, or not linked at all — reads as not visible.
  bool canSeeFullName(String repoFullName) {
    final wanted = repoFullName.toLowerCase();
    return visible.values.any((r) => r.fullName.toLowerCase() == wanted);
  }

  /// The visible repositories.
  List<Repo> get visibleRepos => visible.values.toList();

  /// Whether every repository's standing is known (nothing `checking`).
  bool get settled =>
      !hidden.values.any((h) => h.reason == HiddenRepoReason.checking);

  /// `hidden_repos`: how many repositories are left out, per forge and
  /// reason, in a stable order.
  List<Map<String, dynamic>> hiddenReposWire() {
    final counts = SplayTreeMap<String, int>();
    for (final h in hidden.values) {
      final key = '${h.forge.wire}\u0000${h.reason.wire}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [
      for (final MapEntry(:key, :value) in counts.entries)
        {
          'forge': key.split('\u0000').first,
          'reason': key.split('\u0000').last,
          'count': value,
        },
    ];
  }

  /// [frame] (the open-PR snapshot wire: `{authenticated, repos, …}`) with
  /// only the visible repositories' groups, plus `hidden_repos`. Only the
  /// keys a client reads are carried over; poller bookkeeping never leaks.
  Map<String, dynamic> filterOpenPrFrame(Map<String, dynamic> frame) => {
    'authenticated': frame['authenticated'] ?? true,
    'repos': [
      for (final raw in (frame['repos'] as List?) ?? const [])
        if (raw is Map && raw['repo_id'] is String && canSee(raw['repo_id']))
          raw,
    ],
    if (frame.containsKey('sweep_in_flight'))
      'sweep_in_flight': frame['sweep_in_flight'],
    'hidden_repos': hiddenReposWire(),
  };

  /// A stable encoding, for collapsing identical re-emits.
  String get fingerprint => jsonEncode({
    'v': visible.keys.toList()..sort(),
    'h': [
      for (final e
          in hidden.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        '${e.key}:${e.value.reason.wire}',
    ],
  });
}

/// A person's own reach on each forge: the reads [PrRepoVisibility] asks
/// with that person's own sign-in and nobody else's.
abstract interface class PersonForgeAccess {
  /// Which of [repos] (all on [forge]) [userId]'s own [forge] sign-in in
  /// [workspaceId] can read, as repo ids. Null when they are not signed in
  /// to [forge] there (or the forge refused their credential outright).
  /// Throws when the forge could not answer.
  Future<Set<String>?> readableRepoIds(
    String workspaceId,
    String userId,
    ForgeHost forge,
    List<Repo> repos,
  );

  /// [userId]'s account name on [forge] in [workspaceId], or `''` when they
  /// are not signed in there.
  Future<String> viewerLogin(
    String workspaceId,
    String userId,
    ForgeHost forge,
  );

  /// [userId]'s GitHub teams in [workspaceId] (org → slugs, lower-cased);
  /// empty when they belong to none or are not signed in.
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  );
}

typedef _ReachKey = ({String workspaceId, String userId, ForgeHost forge});

/// One listing in flight: the person's forge reach over one exact repo set,
/// so a caller asking about a different set (a repo linked a moment ago)
/// starts its own listing instead of joining one that leaves it out.
typedef _ListingKey = ({_ReachKey reach, String repos});

/// What one person's sign-in on one forge could read, as last listed.
final class _ForgeReach {
  _ForgeReach({
    required this.signedIn,
    required this.checked,
    required this.readable,
    required this.at,
  });

  final bool signedIn;
  final Set<String> checked;
  final Set<String> readable;

  /// When the listing was asked (not when it answered), so its age is never
  /// understated.
  final DateTime at;

  bool covers(Iterable<String> repoIds) => repoIds.every(checked.contains);
}

/// Per-subscriber PR visibility (see the library doc).
///
/// Forge reach is cached per (workspace, person, forge). After
/// [refreshAfter] it is re-listed in the background while it still serves;
/// once [freshFor] has passed without a successful re-listing (the forge is
/// down, the credential was refused) it no longer serves and its repos read
/// as `checking` until a listing lands. Live surfaces re-evaluate at both
/// marks on their own. Reach is dropped on the person's credential change or
/// removal, and re-checked for a repo the cache has not listed (a new link).
/// Listings run at most [maxConcurrentListings] at a time across the server.
class PrRepoVisibility {
  /// Creates the service.
  PrRepoVisibility({
    required this._workspaces,
    required this._members,
    required this._access,
    Stream<({String userId, String? workspaceId})>? credentialChanges,
    DomainEventBus? eventBus,
    this.freshFor = const Duration(minutes: 10),
    Duration? refreshAfter,
    this.retryAfterFailure = const Duration(minutes: 1),
    this.maxConcurrentListings = 4,
    this.initialWait = const Duration(seconds: 5),
    DateTime Function()? now,
  }) : refreshAfter = refreshAfter ?? freshFor ~/ 2,
       _now = now ?? DateTime.now {
    _subscriptions
      ..add(
        credentialChanges?.listen(
          (c) => invalidateUser(c.userId, workspaceId: c.workspaceId),
        ),
      )
      ..add(
        eventBus?.on<WorkspaceMemberRemoved>().listen(
          (e) => invalidateUser(e.userId, workspaceId: e.workspaceId),
        ),
      )
      ..add(
        eventBus?.on<WorkspaceMemberRoleChanged>().listen(
          (e) => memberChanged(e.workspaceId, e.userId),
        ),
      )
      ..add(
        eventBus?.on<WorkspaceMemberAdded>().listen(
          (e) => memberChanged(e.workspaceId, e.userId),
        ),
      );
  }

  /// How long a listing may serve at all. Past it, a reach that could not be
  /// renewed is unknown again: its repos are `checking` (fail closed).
  final Duration freshFor;

  /// How old a listing gets before it is re-listed in the background (it
  /// keeps serving until [freshFor]).
  final Duration refreshAfter;

  /// How long after a failed listing the next try waits.
  final Duration retryAfterFailure;

  /// Listings in flight at once, server-wide.
  final int maxConcurrentListings;

  /// How long a new [watch] waits for its first listings before emitting
  /// what is known (`checking` for the rest).
  final Duration initialWait;

  final WorkspaceRepository _workspaces;
  final WorkspaceMembershipRepository? _members;
  final PersonForgeAccess _access;
  final DateTime Function() _now;
  final List<StreamSubscription<Object?>?> _subscriptions = [];

  final Map<_ReachKey, _ForgeReach> _reach = {};
  final Map<_ReachKey, DateTime> _failedAt = {};
  final Map<_ListingKey, Future<void>> _inflight = {};
  final Map<_ReachKey, Timer> _rechecks = {};
  final Set<Timer> _retries = {};
  final Map<String, StreamController<void>> _ticks = {};
  int _listingsActive = 0;
  final Queue<Completer<void>> _listingWaiters = Queue();

  static String _tickKey(String workspaceId, String userId) =>
      '$workspaceId\u0000$userId';

  StreamController<void> _tickController(String workspaceId, String userId) =>
      _ticks.putIfAbsent(
        _tickKey(workspaceId, userId),
        StreamController<void>.broadcast,
      );

  void _tick(String workspaceId, String userId) {
    // Owned by [_ticks]; closed in [forgetWorkspace] / [dispose].
    // ignore: close_sinks
    final controller = _ticks[_tickKey(workspaceId, userId)];
    if (controller != null && !controller.isClosed) {
      controller.add(null);
    }
  }

  /// Ticks whenever [userId]'s standing in [workspaceId] may have moved: a
  /// listing landed, their credential changed, their membership or grants
  /// changed. Surfaces that read more than [watch] carries (the badge's
  /// per-forge logins) re-evaluate on it.
  Stream<void> changes(String workspaceId, String userId) =>
      _tickController(workspaceId, userId).stream;

  /// Drops [userId]'s cached forge reach (in [workspaceId], or everywhere
  /// when null — a global credential changed) and re-checks it.
  void invalidateUser(String userId, {String? workspaceId}) {
    final touched = <String>{};
    _reach.removeWhere((key, _) {
      final hit =
          key.userId == userId &&
          (workspaceId == null || key.workspaceId == workspaceId);
      if (hit) {
        touched.add(key.workspaceId);
      }
      return hit;
    });
    _failedAt.removeWhere(
      (key, _) =>
          key.userId == userId &&
          (workspaceId == null || key.workspaceId == workspaceId),
    );
    _rechecks.removeWhere((key, timer) {
      final hit =
          key.userId == userId &&
          (workspaceId == null || key.workspaceId == workspaceId);
      if (hit) {
        timer.cancel();
      }
      return hit;
    });
    for (final key in _ticks.keys.toList()) {
      final parts = key.split('\u0000');
      if (parts.last == userId &&
          (workspaceId == null || parts.first == workspaceId)) {
        touched.add(parts.first);
      }
    }
    for (final ws in touched) {
      _tick(ws, userId);
    }
  }

  /// [userId]'s membership, role or repo grants in [workspaceId] changed.
  void memberChanged(String workspaceId, String userId) =>
      _tick(workspaceId, userId);

  /// [userId]'s account name on [forge] in [workspaceId], or `''`.
  Future<String> viewerLogin(
    String workspaceId,
    String userId,
    ForgeHost forge,
  ) async {
    try {
      return await _access.viewerLogin(workspaceId, userId, forge);
    } on Object catch (e) {
      CcHostLog.warning(
        'pr_visibility: ${forge.displayName} login for $userId unavailable: '
        '$e',
      );
      return '';
    }
  }

  /// [userId]'s GitHub teams in [workspaceId] (org → slugs, lower-cased).
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  ) async {
    try {
      return await _access.githubTeams(workspaceId, userId);
    } on Object catch (e) {
      CcHostLog.warning('pr_visibility: GitHub teams for $userId: $e');
      return const {};
    }
  }

  /// [workspaceId] is gone: everything cached for it goes too.
  void forgetWorkspace(String workspaceId) {
    _reach.removeWhere((key, _) => key.workspaceId == workspaceId);
    _failedAt.removeWhere((key, _) => key.workspaceId == workspaceId);
    _rechecks.removeWhere((key, timer) {
      final hit = key.workspaceId == workspaceId;
      if (hit) {
        timer.cancel();
      }
      return hit;
    });
    for (final key in _ticks.keys.toList()) {
      if (key.startsWith('$workspaceId\u0000')) {
        unawaited(_ticks.remove(key)?.close());
      }
    }
  }

  /// Releases the subscriptions. The service must not be used afterwards.
  void dispose() {
    for (final sub in _subscriptions) {
      unawaited(sub?.cancel());
    }
    for (final timer in [..._rechecks.values, ..._retries]) {
      timer.cancel();
    }
    _rechecks.clear();
    _retries.clear();
    for (final controller in _ticks.values) {
      unawaited(controller.close());
    }
    _ticks.clear();
  }

  /// [userId]'s visibility in [workspaceId] as known now. Never waits on a
  /// forge: a repo whose reach is unknown is `checking`, and a listing for it
  /// starts in the background ([changes] ticks when it lands).
  Future<RepoVisibility> current(String workspaceId, String userId) =>
      _evaluate(workspaceId, userId, wait: false);

  /// Like [current], but waits (up to [timeout]) for the listings it starts,
  /// so a one-shot read answers with settled visibility where it can.
  Future<RepoVisibility> resolve(
    String workspaceId,
    String userId, {
    Duration timeout = const Duration(seconds: 20),
  }) => _evaluate(workspaceId, userId, wait: true, timeout: timeout);

  /// [userId]'s visibility in [workspaceId], live: the current view first,
  /// then a new one whenever it changes (a listing lands, a repo is linked
  /// or unlinked, the person's credential, membership or grants change).
  Stream<RepoVisibility> watch(String workspaceId, String userId) {
    late final StreamController<RepoVisibility> out;
    StreamSubscription<Object?>? reposSub;
    StreamSubscription<void>? tickSub;
    String? last;
    var running = false;
    var again = false;
    var first = true;

    Future<void> emit() async {
      if (running) {
        again = true;
        return;
      }
      running = true;
      try {
        do {
          again = false;
          // The first view waits briefly for its listings, so a surface does
          // not open on an all-`checking` frame; later ones never wait (a
          // landed listing ticks [changes]).
          final view = first
              ? await resolve(workspaceId, userId, timeout: initialWait)
              : await current(workspaceId, userId);
          first = false;
          if (out.isClosed) {
            return;
          }
          final print = view.fingerprint;
          if (print != last) {
            last = print;
            out.add(view);
          }
        } while (again && !out.isClosed);
      } on Object catch (e) {
        CcHostLog.warning('pr_visibility: evaluation failed: $e');
      } finally {
        running = false;
      }
    }

    out = StreamController<RepoVisibility>(
      onListen: () {
        reposSub = _workspaces
            .watchReposForWorkspace(workspaceId)
            .listen((_) => unawaited(emit()));
        tickSub = changes(workspaceId, userId).listen((_) => unawaited(emit()));
        unawaited(emit());
      },
      onCancel: () async {
        await reposSub?.cancel();
        await tickSub?.cancel();
        unawaited(out.close());
      },
    );
    return out.stream;
  }

  /// Refuses [userId] reading [repo]'s pull requests in [workspaceId] unless
  /// their own sign-in on its forge can read it (waiting for the listing
  /// when it is not cached). The grant half is the caller's
  /// (`requireRepoReadGrant`).
  ///
  /// Throws [NeedsSignInException] when they are not signed in to that forge
  /// and [ForgeAccessRefusedException] when their sign-in cannot read it
  /// ([forgeCannotReadCode]) or the forge could not be asked
  /// ([forgeAccessUnconfirmedCode]).
  Future<void> requireForgeAccess(
    String workspaceId,
    String userId,
    Repo repo,
  ) async {
    if (!repo.hasForgeRemote) {
      return;
    }
    final key = (workspaceId: workspaceId, userId: userId, forge: repo.forge);
    var reach = _live(key);
    if (reach == null || !reach.covers([repo.id]) || _refreshDue(reach)) {
      final linked = await _linkedForgeRepos(workspaceId);
      final sameForge = [
        for (final r in linked)
          if (r.forge == repo.forge) r,
      ];
      if (!sameForge.any((r) => r.id == repo.id)) {
        sameForge.add(repo);
      }
      if (reach == null || !reach.covers([repo.id])) {
        await _list(
          key,
          sameForge,
        ).timeout(const Duration(seconds: 20), onTimeout: () {});
        reach = _live(key);
      } else {
        unawaited(_list(key, sameForge));
      }
    }
    if (reach == null || !reach.covers([repo.id])) {
      throw ForgeAccessRefusedException(
        '${repo.forge.displayName} could not confirm that your sign-in can '
        'read ${repo.fullName}. Try again in a moment.',
        code: forgeAccessUnconfirmedCode,
        forge: repo.forge,
      );
    }
    if (!reach.signedIn) {
      throw NeedsSignInException(
        repo.forge.wire,
        'Sign in to ${repo.forge.displayName} to see ${repo.fullName}.',
      );
    }
    if (!reach.readable.contains(repo.id)) {
      throw ForgeAccessRefusedException(
        'Your ${repo.forge.displayName} account cannot read ${repo.fullName}.',
        code: forgeCannotReadCode,
        forge: repo.forge,
      );
    }
  }

  /// [key]'s reach while it may still serve (younger than [freshFor]).
  _ForgeReach? _live(_ReachKey key) {
    final reach = _reach[key];
    return reach == null || _now().difference(reach.at) >= freshFor
        ? null
        : reach;
  }

  bool _refreshDue(_ForgeReach reach) =>
      _now().difference(reach.at) >= refreshAfter;

  /// Whether [key]'s last listing failed less than [retryAfterFailure] ago.
  bool _backingOff(_ReachKey key) {
    final failed = _failedAt[key];
    return failed != null && _now().difference(failed) < retryAfterFailure;
  }

  Future<List<Repo>> _linkedForgeRepos(String workspaceId) async => [
    for (final r in await _workspaces.watchReposForWorkspace(workspaceId).first)
      if (r.hasForgeRemote) r,
  ];

  Future<RepoVisibility> _evaluate(
    String workspaceId,
    String userId, {
    required bool wait,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final linked = await _linkedForgeRepos(workspaceId);
    if (linked.isEmpty) {
      return RepoVisibility.empty;
    }
    final hidden = <String, ({ForgeHost forge, HiddenRepoReason reason})>{};
    final members = _members;
    final member = members == null
        ? null
        : await members.getMember(workspaceId, userId);
    if (members == null || member == null) {
      // No membership wiring, or not a member: nothing is granted.
      return RepoVisibility(
        visible: const {},
        hidden: {
          for (final r in linked)
            r.id: (forge: r.forge, reason: HiddenRepoReason.noGrant),
        },
      );
    }
    final isAdmin = member.role.isAdmin;
    final grants = isAdmin
        ? const <String, RepoGrantLevel>{}
        : await members.getRepoGrants(workspaceId, userId);
    final granted = <ForgeHost, List<Repo>>{};
    for (final r in linked) {
      if (isAdmin || (grants[r.id] ?? RepoGrantLevel.none).allowsRead) {
        (granted[r.forge] ??= []).add(r);
      } else {
        hidden[r.id] = (forge: r.forge, reason: HiddenRepoReason.noGrant);
      }
    }

    // Start (or join) a listing for every forge whose cached reach is
    // missing, expired, due for renewal, or does not cover a granted repo.
    final pending = <Future<void>>[];
    for (final MapEntry(key: forge, value: repos) in granted.entries) {
      final key = (workspaceId: workspaceId, userId: userId, forge: forge);
      final reach = _live(key);
      final covered = reach != null && reach.covers(repos.map((r) => r.id));
      if (covered && !_refreshDue(reach)) {
        continue;
      }
      if (_backingOff(key)) {
        continue;
      }
      final listing = _list(key, repos);
      if (!covered) {
        pending.add(listing);
      }
    }
    if (wait && pending.isNotEmpty) {
      await Future.wait(pending).timeout(timeout, onTimeout: () => const []);
    }

    final visible = <String, Repo>{};
    for (final MapEntry(key: forge, value: repos) in granted.entries) {
      // An expired reach is unknown, not "what it was ten minutes ago".
      final reach = _live((
        workspaceId: workspaceId,
        userId: userId,
        forge: forge,
      ));
      for (final r in repos) {
        final HiddenRepoReason? reason;
        if (reach == null || !reach.checked.contains(r.id)) {
          reason = HiddenRepoReason.checking;
        } else if (!reach.signedIn) {
          reason = HiddenRepoReason.signInRequired;
        } else if (!reach.readable.contains(r.id)) {
          reason = HiddenRepoReason.noForgeAccess;
        } else {
          reason = null;
        }
        if (reason == null) {
          visible[r.id] = r;
        } else {
          hidden[r.id] = (forge: forge, reason: reason);
        }
      }
    }
    return RepoVisibility(visible: visible, hidden: hidden);
  }

  /// Lists [key]'s reach over [repos] (joining a listing already running for
  /// exactly that repo set), then ticks the person's surfaces when the answer
  /// moved.
  Future<void> _list(_ReachKey key, List<Repo> repos) {
    final ids = {for (final r in repos) r.id};
    final listingKey = (reach: key, repos: (ids.toList()..sort()).join(','));
    return _inflight[listingKey] ??= () async {
      try {
        await _acquireListing();
        final DateTime startedAt;
        final Set<String>? readable;
        try {
          startedAt = _now();
          readable = await _access.readableRepoIds(
            key.workspaceId,
            key.userId,
            key.forge,
            repos,
          );
        } finally {
          _releaseListing();
        }
        final previous = _reach[key];
        if (previous != null &&
            previous.at.isAfter(startedAt) &&
            previous.covers(ids)) {
          // A listing asked later already answered for these repos.
          return;
        }
        final next = _ForgeReach(
          signedIn: readable != null,
          checked: ids,
          readable: readable ?? const {},
          at: startedAt,
        );
        _reach[key] = next;
        _failedAt.remove(key);
        _scheduleRechecks(key, next);
        if (previous == null ||
            previous.signedIn != next.signedIn ||
            !_sameSet(previous.readable, next.readable) ||
            !_sameSet(previous.checked, next.checked)) {
          _tick(key.workspaceId, key.userId);
        }
      } on Object catch (e) {
        // A failed listing keeps what was known only while it is younger
        // than [freshFor] ([_live]); past that its repos read `checking`
        // (fail closed). Either way the next try waits [retryAfterFailure],
        // and the person's surfaces re-evaluate then.
        _failedAt[key] = _now();
        CcHostLog.warning(
          'pr_visibility: ${key.forge.displayName} reach for '
          '${key.userId} in ${key.workspaceId} unavailable: $e',
        );
        late final Timer retry;
        retry = Timer(retryAfterFailure, () {
          _retries.remove(retry);
          _tick(key.workspaceId, key.userId);
        });
        _retries.add(retry);
      } finally {
        unawaited(_inflight.remove(listingKey));
      }
    }();
  }

  /// Re-evaluates [key]'s person's live surfaces when [reach] is due for
  /// renewal (their next evaluation re-lists it) and again when it expires
  /// (an unrenewed reach then reads `checking`), so a quiet subscription
  /// never keeps serving an answer older than [freshFor].
  void _scheduleRechecks(_ReachKey key, _ForgeReach reach) {
    _rechecks.remove(key)?.cancel();
    Duration until(Duration mark) {
      final left = mark - _now().difference(reach.at);
      return left.isNegative ? Duration.zero : left;
    }

    _rechecks[key] = Timer(until(refreshAfter), () {
      if (!identical(_reach[key], reach)) {
        return;
      }
      _tick(key.workspaceId, key.userId);
      _rechecks[key] = Timer(until(freshFor), () {
        _rechecks.remove(key);
        if (identical(_reach[key], reach)) {
          _tick(key.workspaceId, key.userId);
        }
      });
    });
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _acquireListing() async {
    if (_listingsActive < maxConcurrentListings) {
      _listingsActive++;
      return;
    }
    final slot = Completer<void>();
    _listingWaiters.add(slot);
    await slot.future;
  }

  void _releaseListing() {
    if (_listingWaiters.isNotEmpty) {
      _listingWaiters.removeFirst().complete();
    } else {
      _listingsActive--;
    }
  }

  /// How many PRs in [frame] (open-PR snapshot shape) need the person's
  /// review, across every forge: each repo is matched against that person's
  /// own login on the repo's forge ([loginByForge]), GitHub repos also
  /// against their [githubTeams]. Only repos [visibility] shows count.
  static int needsMyReviewCount(
    Map<String, dynamic> frame,
    RepoVisibility visibility, {
    required Map<ForgeHost, String> loginByForge,
    required Map<String, Set<String>> githubTeams,
  }) {
    var count = 0;
    for (final raw in (frame['repos'] as List?) ?? const []) {
      if (raw is! Map) {
        continue;
      }
      final repo = visibility.visible[raw['repo_id']];
      if (repo == null) {
        continue;
      }
      final login = loginByForge[repo.forge]?.toLowerCase() ?? '';
      if (login.isEmpty) {
        continue;
      }
      final teams = repo.forge == ForgeHost.github
          ? githubTeams
          : const <String, Set<String>>{};
      for (final pr in (raw['prs'] as List?) ?? const []) {
        if (pr is Map &&
            prCountsTowardNeedsMyReview(pr, login, viewerTeamsByOrg: teams)) {
          count++;
        }
      }
    }
    return count;
  }
}

/// [entries] (`RepoAccessIssue.toJson` maps) narrowed to the repositories
/// linked in the workspace ([linked]) that the subscriber may see: every one
/// for an admin (fixing an App installation is theirs to do, whatever their
/// own forge reach), else only those [visibility] shows them. An entry for a
/// repository no longer linked is shown to nobody.
List<Map<String, dynamic>> filterRepoAccessEntries(
  Iterable<Object?> entries, {
  required List<Repo> linked,
  required bool isAdmin,
  required RepoVisibility visibility,
}) {
  bool shown(Map<String, dynamic> entry) {
    final forge = entry['forge'];
    final owner = (entry['owner'] as String? ?? '').toLowerCase();
    final name = (entry['name'] as String? ?? '').toLowerCase();
    for (final repo in linked) {
      if (repo.forge.wire == forge &&
          repo.remoteOwner.toLowerCase() == owner &&
          repo.remoteName.toLowerCase() == name) {
        return isAdmin || visibility.canSee(repo.id);
      }
    }
    return false;
  }

  return [
    for (final e in entries)
      if (e is Map<String, dynamic> && shown(e)) e,
  ];
}

/// [frames] with the latest [access] list joined in under `repo_access`, so
/// one subscription carries both the open PRs and why some repositories are
/// missing from them. Emits once a frame has arrived, then on either change.
Stream<Map<String, dynamic>> withRepoAccess(
  Stream<Map<String, dynamic>> frames,
  Stream<List<Map<String, dynamic>>> access,
) => Stream.multi((out) {
  Map<String, dynamic>? frame;
  var entries = const <Map<String, dynamic>>[];
  void emit() {
    final f = frame;
    if (f != null) {
      out.add({...f, 'repo_access': entries});
    }
  }

  final frameSub = frames.listen(
    (f) {
      frame = f;
      emit();
    },
    onError: out.addError,
    onDone: out.close,
  );
  final accessSub = access.listen((a) {
    entries = a;
    emit();
  }, onError: out.addError);
  out.onCancel = () async {
    await frameSub.cancel();
    await accessSub.cancel();
  };
});

/// Re-emits [render] of the latest [frames] value and the latest
/// [visibilities] value whenever either moves (or [reevaluate] ticks), once
/// both have arrived, collapsing identical outputs. Cancelling the result
/// cancels every input.
Stream<Map<String, dynamic>> combineWithVisibility(
  Stream<Map<String, dynamic>> frames,
  Stream<RepoVisibility> visibilities,
  FutureOr<Map<String, dynamic>> Function(
    Map<String, dynamic> frame,
    RepoVisibility visibility,
  )
  render, {
  Stream<void>? reevaluate,
}) {
  late final StreamController<Map<String, dynamic>> out;
  StreamSubscription<Map<String, dynamic>>? frameSub;
  StreamSubscription<RepoVisibility>? visSub;
  StreamSubscription<void>? tickSub;
  Map<String, dynamic>? frame;
  RepoVisibility? visibility;
  String? last;
  var chain = Future<void>.value();

  void update() {
    final f = frame;
    final v = visibility;
    if (f == null || v == null) {
      return;
    }
    // Serialized, so an older render can never land after a newer one.
    chain = chain.then((_) async {
      try {
        final rendered = await render(f, v);
        if (out.isClosed) {
          return;
        }
        final encoded = jsonEncode(rendered);
        if (encoded != last) {
          last = encoded;
          out.add(rendered);
        }
      } on Object catch (e, st) {
        if (!out.isClosed) {
          out.addError(e, st);
        }
      }
    });
  }

  out = StreamController<Map<String, dynamic>>(
    onListen: () {
      frameSub = frames.listen(
        (f) {
          frame = f;
          update();
        },
        onError: out.addError,
        onDone: () {
          // The snapshot feed ended (a token-less host answers once): keep
          // following visibility so the frame still re-filters.
        },
      );
      visSub = visibilities.listen((v) {
        visibility = v;
        update();
      }, onError: out.addError);
      tickSub = reevaluate?.listen((_) => update());
    },
    onCancel: () async {
      await frameSub?.cancel();
      await visSub?.cancel();
      await tickSub?.cancel();
      unawaited(out.close());
    },
  );
  return out.stream;
}
