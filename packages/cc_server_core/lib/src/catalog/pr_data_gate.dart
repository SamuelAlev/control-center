/// Pull request data outside the PR surfaces themselves.
///
/// A review space (`Review: PR #N - <title>`) and its messages, a pipeline
/// run's trigger payload and step outputs, an agent run's summary: each one
/// carries a pull request's title, findings or repository name. They follow
/// the same rule as the PRs ([PrRepoVisibility]): a member sees them only
/// when they may see that repository's pull requests (admin or read grant,
/// AND their own forge sign-in can read it), failing closed while unknown.
///
/// A space is tied to a pull request through its [ReviewSpaceAssociation]s;
/// one whose association names a repository the caller cannot see is hidden
/// (lists) or refused (by id) whole. Any space carries the code of the
/// repositories it exposes, so a [SpaceReadGate] also hides and refuses one
/// whose repositories the caller cannot all read.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_host/cc_host.dart' show WatchQueryContext;
import 'package:cc_infra/cc_infra.dart' show AgentRunView;
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show agentRunLogToWire;
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';

/// Which spaces a person may read by the repositories they expose (see
/// `SpaceRepoAccess`): refused by id ([require], with the code ops' own
/// refusal), left out of lists ([unreadable]).
abstract interface class SpaceReadGate {
  /// Refuses [userId] reading space [spaceId] of [workspaceId] unless they
  /// may read every repository it exposes.
  Future<void> require(String workspaceId, String userId, String spaceId);

  /// The spaces of [workspaceId] [userId] may not read.
  Future<Set<String>> unreadable(String workspaceId, String userId);
}

/// What of a workspace's PR-derived data one person may see.
final class PrDataView {
  /// Creates a [PrDataView].
  const PrDataView({required this.visibility, required this.hiddenSpaceIds});

  /// The view [visibility] gives over [associations]: every space tied to a
  /// pull request of a repository the person cannot see is hidden.
  factory PrDataView.of(
    RepoVisibility visibility,
    Iterable<ReviewSpaceAssociation> associations,
  ) => PrDataView(
    visibility: visibility,
    hiddenSpaceIds: {
      for (final a in associations)
        if (!visibility.canSeeFullName(a.repoFullName)) a.spaceId,
    },
  );

  /// The person's PR visibility.
  final RepoVisibility visibility;

  /// Spaces tied to a pull request the person may not see.
  final Set<String> hiddenSpaceIds;

  /// Whether the person may see space [spaceId] (no space: nothing to hide).
  bool canSeeSpace(String? spaceId) =>
      spaceId == null || !hiddenSpaceIds.contains(spaceId);

  /// Whether the person may see [run]: neither its trigger payload nor its
  /// state names a repository (by `repo_full_name`, `repo_owner` +
  /// `repo_name`, or a linked forge repo's `repo_id`) or a space they may
  /// not see. A run naming no repository is not PR data.
  bool canSeeRun(PipelineRun run) =>
      _bagVisible(run.triggerPayload) && _bagVisible(run.state);

  /// Whether the person may see [log]: the run did not work in a space they
  /// may not see.
  bool canSeeRunLog(AgentRunLog log) => canSeeSpace(log.spaceId);

  /// Whether an audit [entry]'s recorded arguments name nothing the person
  /// may not see. A hidden one keeps who/what/when but loses its details.
  bool canSeeActivityDetails(UserActivityEntry entry) =>
      _bagVisible(entry.details) &&
      !(entry.targetId != null && hiddenSpaceIds.contains(entry.targetId));

  bool _bagVisible(Map<String, Object?>? bag) {
    if (bag == null || bag.isEmpty) {
      return true;
    }
    final fullName = _fullNameIn(bag);
    if (fullName != null && !visibility.canSeeFullName(fullName)) {
      return false;
    }
    final repoId = bag['repo_id'];
    if (repoId is String && visibility.hidden.containsKey(repoId)) {
      return false;
    }
    final spaceId = bag['space_id'];
    return spaceId is! String || !hiddenSpaceIds.contains(spaceId);
  }

  /// A stable encoding, for collapsing identical re-emits.
  String get fingerprint => jsonEncode({
    'v': visibility.fingerprint,
    's': hiddenSpaceIds.toList()..sort(),
  });
}

/// [entry]'s wire (`userActivityToWire`) as [view] may show it: an entry
/// whose recorded arguments name a repository or review space the viewer
/// cannot see keeps who, what and when, but not its target or details.
Map<String, dynamic> activityEntryWireFor(
  UserActivityEntry entry,
  PrDataView view,
  Map<String, dynamic> Function(UserActivityEntry entry) toWire,
) {
  final wire = toWire(entry);
  if (view.canSeeActivityDetails(entry)) {
    return wire;
  }
  return {...wire}
    ..remove('target_id')
    ..remove('details');
}

/// The `owner/name` a payload names, when it names one.
String? _fullNameIn(Map<String, Object?> bag) {
  final full = bag['repo_full_name'];
  if (full is String && full.contains('/')) {
    return full;
  }
  final owner = bag['repo_owner'];
  final name = bag['repo_name'];
  if (owner is String &&
      owner.isNotEmpty &&
      name is String &&
      name.isNotEmpty) {
    return '$owner/$name';
  }
  return null;
}

/// Resolves and applies [PrDataView]s for one catalog.
class PrDataGate {
  /// Creates the gate. `resolve` answers a one-shot PR visibility (waiting
  /// briefly for forge listings), `watch` a live one.
  /// `spaceRead`, when given, also hides and refuses the spaces whose
  /// repositories the caller cannot all read.
  PrDataGate({
    required this._reviewSpaces,
    required this._resolve,
    required this._watch,
    this._spaceRead,
  });

  final ReviewSpaceRepository _reviewSpaces;
  final SpaceReadGate? _spaceRead;

  /// [view] with the spaces [_spaceRead] withholds from [userId] hidden too.
  Future<PrDataView> _withSpaceRead(
    String workspaceId,
    String userId,
    PrDataView view,
  ) async {
    final gate = _spaceRead;
    if (gate == null) {
      return view;
    }
    final unreadable = await gate.unreadable(workspaceId, userId);
    return unreadable.isEmpty
        ? view
        : PrDataView(
            visibility: view.visibility,
            hiddenSpaceIds: {...view.hiddenSpaceIds, ...unreadable},
          );
  }

  final Future<RepoVisibility> Function(String workspaceId, String userId)
  _resolve;
  final Stream<RepoVisibility> Function(String workspaceId, String userId)
  _watch;

  /// [userId]'s view in [workspaceId] now.
  Future<PrDataView> view(String workspaceId, String userId) async =>
      _withSpaceRead(
        workspaceId,
        userId,
        PrDataView.of(
          await _resolve(workspaceId, userId),
          await _reviewSpaces.watchByWorkspace(workspaceId).first,
        ),
      );

  /// [userId]'s view in [workspaceId], live: re-emits when their PR
  /// visibility or the workspace's review spaces change.
  Stream<PrDataView> watchView(String workspaceId, String userId) =>
      _combineLatest(
            _watch(workspaceId, userId),
            _reviewSpaces.watchByWorkspace(workspaceId),
            PrDataView.of,
          )
          .asyncMap((v) => _withSpaceRead(workspaceId, userId, v))
          .distinctBy((v) => v.fingerprint);

  /// The spaces of [workspaceId] hidden from [userId] now. Asks no forge
  /// while the workspace has no review space.
  Future<Set<String>> hiddenSpaces(String workspaceId, String userId) async {
    final associations = await _reviewSpaces
        .watchByWorkspace(workspaceId)
        .first;
    return {
      if (associations.isNotEmpty)
        ...PrDataView.of(
          await _resolve(workspaceId, userId),
          associations,
        ).hiddenSpaceIds,
      ...?await _spaceRead?.unreadable(workspaceId, userId),
    };
  }

  /// Every review space of [workspaceId] (what an unidentified caller is
  /// refused).
  Future<Set<String>> reviewSpaceIds(String workspaceId) async => {
    for (final a in await _reviewSpaces.watchByWorkspace(workspaceId).first)
      a.spaceId,
  };

  /// [hiddenSpaces], live. Follows [userId]'s PR visibility once the
  /// workspace has a review space or a [SpaceReadGate] judges its spaces
  /// (their grants and sign-ins move it), but waits for its first answer only
  /// for review spaces; the gate asks a forge only about repositories a space
  /// exposes.
  Stream<Set<String>> watchHiddenSpaces(String workspaceId, String userId) =>
      Stream<Set<String>>.multi((out) {
        List<ReviewSpaceAssociation>? associations;
        RepoVisibility? visibility;
        StreamSubscription<RepoVisibility>? visSub;
        String? last;
        var chain = Future<void>.value();
        void emit() {
          final a = associations;
          if (a == null) {
            return;
          }
          final gate = _spaceRead;
          var hidden = const <String>{};
          if (a.isNotEmpty || gate != null) {
            // Followed for its changes (a grant or sign-in moves the gate's
            // answer too); only review spaces wait for its first answer.
            visSub ??= _watch(workspaceId, userId).listen((v) {
              visibility = v;
              emit();
            }, onError: out.addError);
          }
          if (a.isNotEmpty) {
            final v = visibility;
            if (v == null) {
              return;
            }
            hidden = PrDataView.of(v, a).hiddenSpaceIds;
          }
          // Serialized, so an older evaluation never lands after a newer one.
          chain = chain
              .then((_) async {
                final all = {
                  ...hidden,
                  ...?await gate?.unreadable(workspaceId, userId),
                };
                final key = (all.toList()..sort()).join(',');
                if (!out.isClosed && key != last) {
                  last = key;
                  out.add(all);
                }
              })
              .catchError((Object e, StackTrace st) => out.addError(e, st));
        }

        final assocSub = _reviewSpaces.watchByWorkspace(workspaceId).listen((
          a,
        ) {
          associations = a;
          emit();
        }, onError: out.addError);
        out.onCancel = () async {
          await assocSub.cancel();
          await visSub?.cancel();
        };
      });

  /// Whether [userId] may read space [spaceId] of [workspaceId]. Cheap for a
  /// space tied to no pull request (one indexed read, no forge question).
  Future<bool> canReadSpace(
    String workspaceId,
    String userId,
    String spaceId,
  ) async {
    final associations = await _reviewSpaces
        .watchAllBySpace(workspaceId, spaceId)
        .first;
    if (associations.isEmpty) {
      return true;
    }
    final visibility = await _resolve(workspaceId, userId);
    return associations.every((a) => visibility.canSeeFullName(a.repoFullName));
  }

  /// Refuses [userId] reading or acting in space [spaceId] when it is tied
  /// to a pull request they may not see.
  Future<void> requireSpace(
    String workspaceId,
    String userId,
    String spaceId,
  ) async {
    if (!await canReadSpace(workspaceId, userId, spaceId)) {
      throw const AuthException(
        'This space reviews a pull request you cannot see. Sign in to its '
        'forge with an account that can read the repository, or ask an '
        'admin for access.',
      );
    }
    await _spaceRead?.require(workspaceId, userId, spaceId);
  }

  /// Refuses [userId] reading [run] when it is tied to a pull request,
  /// repository or space they may not see.
  Future<void> requireRun(
    String workspaceId,
    String userId,
    PipelineRun run,
  ) async {
    if (!(await view(workspaceId, userId)).canSeeRun(run)) {
      throw const AuthException(
        'This pipeline run is about a pull request you cannot see.',
      );
    }
  }

  /// Refuses [userId] reading [log] when its run worked in a space they may
  /// not see.
  Future<void> requireRunLog(
    String workspaceId,
    String userId,
    AgentRunLog log,
  ) async {
    final space = log.spaceId;
    if (space != null) {
      await requireSpace(workspaceId, userId, space);
    }
  }

  /// [source] while [userId] may read space [spaceId]; once the space turns
  /// hidden (their sign-in, grant or the space's pull request changed) the
  /// stream ends with an [AuthException]. The caller has already checked
  /// the space once ([requireSpace]).
  Stream<T> guardSpace<T>(
    String workspaceId,
    String userId,
    String spaceId,
    Stream<T> source,
  ) => Stream<T>.multi((out) {
    StreamSubscription<T>? sourceSub;
    StreamSubscription<List<ReviewSpaceAssociation>>? assocSub;
    StreamSubscription<RepoVisibility>? visSub;
    var associations = const <ReviewSpaceAssociation>[];
    RepoVisibility? visibility;
    var closed = false;

    Future<void> shut() async {
      closed = true;
      await sourceSub?.cancel();
      await assocSub?.cancel();
      await visSub?.cancel();
    }

    void check() {
      if (closed || associations.isEmpty) {
        return;
      }
      final v = visibility;
      if (v == null) {
        visSub ??= _watch(workspaceId, userId).listen((next) {
          visibility = next;
          check();
        }, onError: out.addError);
        return;
      }
      if (!associations.every((a) => v.canSeeFullName(a.repoFullName))) {
        out.addError(
          const AuthException(
            'This space reviews a pull request you can no longer see.',
          ),
        );
        unawaited(shut().whenComplete(out.close));
      }
    }

    sourceSub = source.listen(
      out.add,
      onError: out.addError,
      onDone: () {
        unawaited(shut());
        out.close();
      },
    );
    assocSub = _reviewSpaces.watchAllBySpace(workspaceId, spaceId).listen((
      list,
    ) {
      associations = list;
      check();
    }, onError: out.addError);
    out.onCancel = shut;
  });

  /// Live frames of [rows] in [workspaceId] as [userId] may see them: only
  /// the rows [keep] admits under their current view, rendered by [render].
  /// Re-renders when the rows or the view change; identical frames collapse.
  Stream<Map<String, dynamic>> rows<T>(
    String workspaceId,
    String userId,
    Stream<List<T>> rows,
    bool Function(PrDataView view, T row) keep,
    Map<String, dynamic> Function(List<T> rows) render,
  ) => _filter(rows, watchView(workspaceId, userId), keep, render);

  /// Live [render] of each [source] value under [userId]'s current view in
  /// [workspaceId]; re-renders when either changes, identical frames
  /// collapse.
  Stream<Map<String, dynamic>> render<T>(
    String workspaceId,
    String userId,
    Stream<T> source,
    Map<String, dynamic> Function(T value, PrDataView view) render,
  ) => _combineLatest(
    source,
    watchView(workspaceId, userId),
    render,
  ).distinctBy(_encode);

  /// Like [rows] for rows that are hidden only through their space
  /// ([spaceOf]): never waits on a forge while there is no review space.
  Stream<Map<String, dynamic>> spaceRows<T>(
    String workspaceId,
    String userId,
    Stream<List<T>> rows,
    String? Function(T row) spaceOf,
    Map<String, dynamic> Function(List<T> rows) render,
  ) => _filter(
    switch (_spaceRead) {
      // A row of a space the gate has not judged yet (a new space) is
      // judged as it arrives, not on the next grant change.
      final gate? => rows.asyncMap((list) async {
        final unreadable = await gate.unreadable(workspaceId, userId);
        return [
          for (final r in list)
            if (!unreadable.contains(spaceOf(r))) r,
        ];
      }),
      null => rows,
    },
    watchHiddenSpaces(workspaceId, userId),
    (Set<String> hidden, T row) => !hidden.contains(spaceOf(row)),
    render,
  );

  /// `{logs}` of [logs] as [userId] may see them in [workspaceId]: none run
  /// in a review space they may not see.
  Future<Map<String, dynamic>> runLogsWire(
    String workspaceId,
    String userId,
    List<AgentRunLog> logs,
  ) async {
    final hidden = await hiddenSpaces(workspaceId, userId);
    return {
      'logs': [
        for (final l in logs)
          if (!hidden.contains(l.spaceId)) agentRunLogToWire(l),
      ],
    };
  }

  /// Live `{logs}` frames of [logs] (rows of [ctx]'s workspace) for its
  /// caller ([runLogsWire], re-evaluated).
  Stream<Map<String, dynamic>> runLogFrames(
    WatchQueryContext ctx,
    Stream<List<AgentRunLog>> logs,
  ) => spaceRows(
    ctx.workspaceId!,
    ctx.userId,
    logs,
    (l) => l.spaceId,
    (l) => {'logs': l.map(agentRunLogToWire).toList()},
  );

  /// [runLogFrames] for a cross-workspace source, each row judged in its
  /// own workspace.
  Stream<Map<String, dynamic>> runLogFramesAcross(
    WatchQueryContext ctx,
    Stream<List<AgentRunLog>> logs,
  ) => rowsAcrossWorkspaces(
    logs,
    (l) => l.workspaceId,
    (ws) => watchHiddenSpaces(ws, ctx.userId),
    (Set<String> hidden, AgentRunLog l) => !hidden.contains(l.spaceId),
    (l) => {'logs': l.map(agentRunLogToWire).toList()},
  );

  /// Like [rows] for a cross-workspace source (rows already narrowed to the
  /// caller's workspaces): each row is judged by the caller's view in its
  /// own workspace ([workspaceOf], views from [viewOf]). No frame is sent
  /// until every workspace in it has a view (fail closed, never a misleading
  /// empty frame); a row with no workspace passes.
  Stream<Map<String, dynamic>> rowsAcrossWorkspaces<T, V>(
    Stream<List<T>> rows,
    String? Function(T row) workspaceOf,
    Stream<V> Function(String workspaceId) viewOf,
    bool Function(V view, T row) keep,
    Map<String, dynamic> Function(List<T> rows) render,
  ) => Stream<Map<String, dynamic>>.multi((out) {
    final views = <String, V>{};
    final viewSubs = <String, StreamSubscription<V>>{};
    List<T>? latest;
    String? last;

    void emit() {
      final list = latest;
      // Nothing until every workspace in the frame has a view: a first frame
      // of withheld rows would read as "there are none".
      if (list == null ||
          list.any((r) {
            final ws = workspaceOf(r);
            return ws != null && !views.containsKey(ws);
          })) {
        return;
      }
      final frame = render([
        for (final r in list)
          if (switch (workspaceOf(r)) {
            null => true,
            final ws => views.containsKey(ws) && keep(views[ws] as V, r),
          })
            r,
      ]);
      final encoded = _encode(frame);
      if (!out.isClosed && encoded != last) {
        last = encoded;
        out.add(frame);
      }
    }

    final rowSub = rows.listen(
      (list) {
        latest = list;
        for (final r in list) {
          final ws = workspaceOf(r);
          if (ws != null && !viewSubs.containsKey(ws)) {
            viewSubs[ws] = viewOf(ws).listen((v) {
              views[ws] = v;
              emit();
            }, onError: out.addError);
          }
        }
        emit();
      },
      onError: out.addError,
      // A source that answers once and ends still follows the views: a
      // visibility change must re-filter, and the first frame may still be
      // waiting on one.
      onDone: () => viewSubs.isEmpty ? out.close() : null,
    );
    out.onCancel = () async {
      await rowSub.cancel();
      for (final sub in viewSubs.values) {
        await sub.cancel();
      }
    };
  });

  static Stream<Map<String, dynamic>> _filter<T, V>(
    Stream<List<T>> rows,
    Stream<V> views,
    bool Function(V view, T row) keep,
    Map<String, dynamic> Function(List<T> rows) render,
  ) => _combineLatest(
    rows,
    views,
    (List<T> list, V view) => render([
      for (final r in list)
        if (keep(view, r)) r,
    ]),
  ).distinctBy(_encode);
}

String _encode(Object? frame) =>
    jsonEncode(frame, toEncodable: (o) => o.toString());

/// Which spaces an agent run may not read over MCP (`list_spaces`,
/// `get_messages`, the space notes tools): an agent acts for its requester,
/// so every space that person may not read is withheld from the run as well
/// (a review space of a pull request they cannot see, a space exposing a
/// repository they cannot read: the same gate as the RPC surface).
///
/// A run nobody requested (a schedule, a webhook) acts for no person and is
/// bounded only by the workspace. A caller that is not an open run (or names
/// no attested conversation) is refused every review space.
class AgentSpaceVisibility {
  /// Creates the resolver over a [PrDataGate] carrying the space read gate.
  AgentSpaceVisibility(this._gate);

  final PrDataGate _gate;

  /// The runs open in a conversation (the agent run gateway's `openRuns`);
  /// wired once the gateway exists. Unset: no caller is a known run.
  List<AgentRunView> Function({
    required String workspaceId,
    required String conversationId,
  })?
  openRuns;

  /// The spaces of [workspaceId] the run calling from
  /// [callerConversationId] may not read.
  Future<Set<String>> hiddenFor({
    required String workspaceId,
    required String? callerConversationId,
  }) async {
    final lookup = openRuns;
    final runs = callerConversationId == null || lookup == null
        ? const <AgentRunView>[]
        : lookup(
            workspaceId: workspaceId,
            conversationId: callerConversationId,
          );
    if (runs.isEmpty) {
      return _gate.reviewSpaceIds(workspaceId);
    }
    final hidden = <String>{};
    for (final person in {for (final r in runs) r.grant.actingUserId}) {
      if (person != null) {
        hidden.addAll(await _gate.hiddenSpaces(workspaceId, person));
      }
    }
    return hidden;
  }

  /// Whom the runs open in [callerConversationId] act for: one entry per
  /// run, null for a run nobody is accountable for; empty when the caller
  /// is no known run. The rig tools' `RunPeopleForCaller`.
  Future<Set<String?>> peopleFor({
    required String workspaceId,
    required String? callerConversationId,
  }) async {
    final lookup = openRuns;
    if (callerConversationId == null || lookup == null) {
      return const {};
    }
    return {
      for (final run in lookup(
        workspaceId: workspaceId,
        conversationId: callerConversationId,
      ))
        run.grant.actingUserId,
    };
  }
}

/// Emits [combine] of the latest [a] and [b] values once both have arrived,
/// then on either change. Cancelling the result cancels both inputs.
Stream<R> _combineLatest<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combine,
) => Stream<R>.multi((out) {
  A? lastA;
  B? lastB;
  var hasA = false;
  var hasB = false;
  void emit() {
    if (hasA && hasB) {
      out.add(combine(lastA as A, lastB as B));
    }
  }

  final subA = a.listen((v) {
    lastA = v;
    hasA = true;
    emit();
  }, onError: out.addError);
  final subB = b.listen((v) {
    lastB = v;
    hasB = true;
    emit();
  }, onError: out.addError);
  out.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
  };
});

extension _DistinctBy<T> on Stream<T> {
  /// Drops an event whose [key] equals the previous one's.
  Stream<T> distinctBy(Object? Function(T event) key) {
    Object? previous;
    var first = true;
    return where((event) {
      final k = key(event);
      if (!first && k == previous) {
        return false;
      }
      first = false;
      previous = k;
      return true;
    });
  }
}
