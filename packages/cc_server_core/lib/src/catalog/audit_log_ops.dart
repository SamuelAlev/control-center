import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/repositories/server_audit_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_host/cc_host.dart' show WatchQuery, WatchQueryContext;
import 'package:cc_server_core/src/catalog/audit_log_pager.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';

/// Default rows per audit log page.
const auditLogDefaultPageSize = 25;

/// The most rows one audit log page returns.
const auditLogMaxPageSize = 100;

/// The trails one person may read in the audit log, resolved per frame.
class AuditLogScopes {
  /// Creates the scopes.
  const AuditLogScopes({required this.server, required this.workspaces});

  /// Whether the server-scope trail is theirs to read (the server owner).
  final bool server;

  /// The live workspaces they administer, by id, with their names.
  final Map<String, String> workspaces;

  /// The wire listing of these scopes, server first.
  List<Map<String, dynamic>> toWire() => [
    if (server) {'key': auditServerSourceKey, 'kind': 'server'},
    for (final e in workspaces.entries)
      {
        'key': auditWorkspaceSourceKey(e.key),
        'kind': 'workspace',
        'workspace_id': e.key,
        'name': e.value,
      },
  ];
}

/// The audit log (`audit.watchLog`): one live, newest-first table over every
/// trail the caller may read, with keyset paging, filters and facet counts.
///
/// What a person reads is decided here, per frame, never by the client: the
/// server-scope trail (install-wide op calls; argument names, never values)
/// only for the server owner, and the trail of each live workspace they
/// administer. A workspace admin is not the server owner, so they never see
/// the server rows. A workspace record about a repository or review space
/// they cannot see loses its target and details ([PrDataView]).
///
/// CROSS-WORKSPACE BY DESIGN: one stream reads several workspace databases,
/// each only after the registry lists the workspace and membership names the
/// caller its admin. Scopes are re-resolved on every frame, so a demotion or
/// removal takes effect with the next change.
List<WatchQuery> buildAuditLogWatchQueries({
  required ServerAuditRepository? serverAudit,
  required UserActivityRepository activity,
  required WorkspaceMembershipRepository members,
  required WorkspaceRepository workspaces,
  required Future<bool> Function(String userId) isServerOwner,
  required PrDataGate prData,
  required DomainEventBus eventBus,
}) => [
  WatchQuery(
    name: 'audit.watchLog',
    // Self-scoped: every frame is narrowed to the caller's own scopes (see
    // [AuditLogScopes]); there is no workspace to bind and no install-wide
    // authority a workspace admin would lack for their own trail.
    workspaceScoped: false,
    handler: (ctx) {
      final AuditLogRequest request;
      try {
        request = AuditLogRequest.fromArgs(ctx.args);
      } on ValidationException catch (e) {
        return Stream.error(e);
      }
      return _AuditLogStream(
        ctx: ctx,
        request: request,
        serverAudit: serverAudit,
        activity: activity,
        members: members,
        workspaces: workspaces,
        isServerOwner: isServerOwner,
        prData: prData,
        eventBus: eventBus,
      ).stream;
    },
  ),
];

/// The arguments of one `audit.watchLog` subscription.
class AuditLogRequest {
  /// Creates a request.
  const AuditLogRequest({
    required this.filter,
    required this.limit,
    this.cursor,
    this.sources = const {},
  });

  /// Parses subscription [args]; a malformed filter is refused rather than
  /// dropped, so a page never silently ignores a condition the person set.
  factory AuditLogRequest.fromArgs(Map<String, dynamic> args) {
    Set<String> strings(String name) {
      final raw = args[name];
      if (raw == null) {
        return const {};
      }
      if (raw is! List) {
        throw ValidationException('$name must be a list');
      }
      return {
        for (final v in raw)
          if (v is String && v.isNotEmpty) v,
      };
    }

    String? text(String name) {
      final raw = args[name];
      return raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
    }

    final outcomes = <AuditOutcome>{};
    for (final name in strings('outcomes')) {
      final outcome = AuditOutcome.values.asNameMap()[name];
      if (outcome == null) {
        throw ValidationException('unknown outcome: $name');
      }
      outcomes.add(outcome);
    }

    final time = <AuditTimeCondition>[];
    final rawTime = args['time'];
    if (rawTime != null) {
      if (rawTime is! List) {
        throw const ValidationException('time must be a list');
      }
      for (final c in rawTime) {
        final op = c is Map ? AuditTimeOperator.fromWire(c['op']) : null;
        final at = c is Map && c['at'] is String
            ? DateTime.tryParse(c['at'] as String)
            : null;
        if (op == null || at == null) {
          throw const ValidationException(
            'each time condition needs an op (gte, gt, lt, lte) and an '
            'ISO-8601 instant',
          );
        }
        time.add(AuditTimeCondition(op: op, at: at));
      }
    }

    final rawLimit = args['limit'];
    return AuditLogRequest(
      cursor: ActivityCursor.decode(text('cursor')),
      limit: rawLimit is num
          ? rawLimit.toInt().clamp(1, auditLogMaxPageSize)
          : auditLogDefaultPageSize,
      sources: strings('sources'),
      filter: AuditLogFilter(
        query: text('query'),
        searchUserIds: strings('search_user_ids'),
        actorIds: strings('actor_ids'),
        outcomes: outcomes,
        ip: text('ip'),
        countryCode: text('country_code')?.toUpperCase(),
        localNetwork: args['local_network'] == true,
        time: time,
      ),
    );
  }

  /// The page's filters.
  final AuditLogFilter filter;

  /// Rows per page.
  final int limit;

  /// Where the page starts; null for the newest.
  final ActivityCursor? cursor;

  /// The source keys to read; empty reads every visible one.
  final Set<String> sources;
}

/// The frames of one subscription: recomputed when a trail changes, the
/// caller's membership changes, or their PR view of a workspace changes.
/// Recomputes are serialized and a burst of changes collapses into one.
class _AuditLogStream {
  _AuditLogStream({
    required this.ctx,
    required this.request,
    required this.serverAudit,
    required this.activity,
    required this.members,
    required this.workspaces,
    required this.isServerOwner,
    required this.prData,
    required this.eventBus,
  });

  final WatchQueryContext ctx;
  final AuditLogRequest request;
  final ServerAuditRepository? serverAudit;
  final UserActivityRepository activity;
  final WorkspaceMembershipRepository members;
  final WorkspaceRepository workspaces;
  final Future<bool> Function(String userId) isServerOwner;
  final PrDataGate prData;
  final DomainEventBus eventBus;

  final _out = StreamController<Map<String, dynamic>>();
  final _watched = <String, List<StreamSubscription<Object?>>>{};
  final _views = <String, PrDataView>{};
  Timer? _debounce;
  bool _running = false;
  bool _dirty = false;
  bool _closed = false;
  String? _last;

  Stream<Map<String, dynamic>> get stream {
    _out
      ..onListen = _start
      ..onCancel = _close;
    return _out.stream;
  }

  void _start() {
    final userId = ctx.userId;
    // A membership of the caller changing (or a new workspace) can change
    // their scopes before any trail does.
    _watched['_members'] = [
      eventBus
          .on<WorkspaceMemberAdded>()
          .where((e) => e.userId == userId)
          .listen((_) => _schedule()),
      eventBus
          .on<WorkspaceMemberRemoved>()
          .where((e) => e.userId == userId)
          .listen((_) => _schedule()),
      eventBus
          .on<WorkspaceMemberRoleChanged>()
          .where((e) => e.userId == userId)
          .listen((_) => _schedule()),
      eventBus.on<WorkspaceCreated>().listen((_) => _schedule()),
    ];
    unawaited(_run());
  }

  void _schedule() {
    if (_closed) {
      return;
    }
    _debounce ??= Timer(const Duration(milliseconds: 150), () {
      _debounce = null;
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    if (_running) {
      _dirty = true;
      return;
    }
    _running = true;
    try {
      do {
        _dirty = false;
        final frame = await _frame();
        if (_closed) {
          return;
        }
        final encoded = jsonEncode(frame);
        if (encoded != _last) {
          _last = encoded;
          _out.add(frame);
        }
      } while (_dirty && !_closed);
    } catch (e, st) {
      if (!_closed) {
        _out.addError(e, st);
      }
    } finally {
      _running = false;
    }
  }

  Future<AuditLogScopes> _scopes() async {
    final userId = ctx.userId;
    final owner = serverAudit != null && await isServerOwner(userId);
    // The registry first: a membership row of a deleted workspace opens no
    // database.
    final live = {for (final w in await workspaces.getAll()) w.id: w.name};
    final admin = <String, String>{};
    for (final m in await members.getForUser(userId)) {
      final name = live[m.workspaceId];
      if (name != null && m.role.isAdmin) {
        admin[m.workspaceId] = name;
      }
    }
    return AuditLogScopes(server: owner, workspaces: admin);
  }

  /// Follows the change streams of [scopes] and drops those it left.
  void _follow(AuditLogScopes scopes) {
    final keep = <String>{
      '_members',
      if (scopes.server) auditServerSourceKey,
      for (final id in scopes.workspaces.keys) auditWorkspaceSourceKey(id),
    };
    for (final key in _watched.keys.toList()) {
      if (!keep.contains(key)) {
        for (final sub in _watched.remove(key)!) {
          unawaited(sub.cancel());
        }
        _views.remove(key);
      }
    }
    final audit = serverAudit;
    if (scopes.server && audit != null) {
      _watched.putIfAbsent(
        auditServerSourceKey,
        () => [audit.watchChanges().listen((_) => _schedule())],
      );
    }
    for (final id in scopes.workspaces.keys) {
      final key = auditWorkspaceSourceKey(id);
      _watched.putIfAbsent(
        key,
        () => [
          activity.watchChanges(id).listen((_) => _schedule()),
          prData.watchView(id, ctx.userId).listen((view) {
            final changed = _views[key]?.fingerprint != view.fingerprint;
            _views[key] = view;
            if (changed) {
              _schedule();
            }
          }, onError: (Object _) {}),
        ],
      );
    }
  }

  Future<Map<String, dynamic>> _frame() async {
    final scopes = await _scopes();
    _follow(scopes);
    final visible = <AuditLogSource>[
      if (scopes.server && serverAudit != null)
        ServerAuditLogSource(serverAudit!),
      for (final id in scopes.workspaces.keys)
        WorkspaceAuditLogSource(
          activity,
          id,
          _views[auditWorkspaceSourceKey(id)] ??=
              await prData.view(id, ctx.userId),
        ),
    ];
    final selected = request.sources.isEmpty
        ? visible
        : [
            for (final s in visible)
              if (request.sources.contains(s.key)) s,
          ];
    final page = await readAuditLogPage(
      selected: selected,
      visible: visible,
      limit: request.limit,
      cursor: request.cursor,
      filter: request.filter,
    );
    return {...page.toWire(), 'scopes': scopes.toWire()};
  }

  Future<void> _close() async {
    _closed = true;
    _debounce?.cancel();
    for (final subs in _watched.values) {
      for (final sub in subs) {
        await sub.cancel();
      }
    }
    _watched.clear();
  }
}
