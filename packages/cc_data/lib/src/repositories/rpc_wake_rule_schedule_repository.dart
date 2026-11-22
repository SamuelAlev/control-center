import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_rpc/cc_rpc.dart';

T _enum<T>(T? parsed, Object? raw, String what) =>
    parsed ?? (throw FormatException('unknown wake rule $what $raw'));

DateTime? _at(Object? raw) => raw is String ? DateTime.parse(raw) : null;

/// A list of ISO 8601 instants; absent reads as none.
List<DateTime> _instants(Object? raw) => [
  if (raw is List)
    for (final v in raw)
      if (v is String) DateTime.parse(v),
];

/// Decodes one `wakeRules.*` rule row. Throws on a row the client cannot
/// read (an unknown status, origin or end reason), which `decodeRows` drops.
WakeRuleView wakeRuleViewFromWire(Map<String, dynamic> w) => WakeRuleView(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String,
  spaceId: w['space_id'] as String? ?? '',
  conversationId: w['conversation_id'] as String,
  agentId: w['agent_id'] as String,
  ownerUserId: w['owner_user_id'] as String?,
  createdByUserId: w['created_by_user_id'] as String?,
  createdByRunId: w['created_by_run_id'] as String?,
  origin: _enum(
    WakeRuleOriginWire.tryParse(w['origin'] as String?),
    w['origin'],
    'origin',
  ),
  trigger: w['trigger'] as String,
  triggerKind: w['trigger_kind'] as String? ?? '',
  timeZone: w['tz'] as String?,
  note: w['note'] as String? ?? '',
  deliver: _enum(
    WakeDeliverWire.tryParse(w['deliver'] as String?),
    w['deliver'],
    'deliver',
  ),
  whenBusy: _enum(
    WakeWhenBusyWire.tryParse(w['when_busy'] as String?),
    w['when_busy'],
    'when_busy',
  ),
  nextFireAt: _at(w['next_fire_at']),
  nextFires: _instants(w['next_fires']),
  lastFiredAt: _at(w['last_fired_at']),
  runCount: (w['run_count'] as num?)?.toInt() ?? 0,
  maxRuns: (w['max_runs'] as num?)?.toInt(),
  skipCount: (w['skip_count'] as num?)?.toInt() ?? 0,
  costMicros: (w['cost_micros'] as num?)?.toInt() ?? 0,
  costCapMicros: (w['cost_cap_micros'] as num?)?.toInt() ?? 0,
  goalId: w['goal_id'] as String?,
  status: _enum(
    WakeRuleStatusWire.tryParse(w['status'] as String?),
    w['status'],
    'status',
  ),
  endReason: switch (w['end_reason']) {
    null => null,
    final Object raw => _enum(
      WakeRuleEndReasonWire.tryParse(raw as String?),
      raw,
      'end reason',
    ),
  },
  expiresAt: DateTime.parse(w['expires_at'] as String),
  createdAt: DateTime.parse(w['created_at'] as String),
  // The server's answer for this viewer; absent reads as "not yours".
  canChange: w['can_change'] == true,
  // A row without `note_author` keeps its creator's words.
  noteAuthor:
      WakeRuleOriginWire.tryParse(w['note_author'] as String?) ??
      _enum(
        WakeRuleOriginWire.tryParse(w['origin'] as String?),
        w['origin'],
        'origin',
      ),
  noteEditedByUserId: w['note_edited_by_user_id'] as String?,
  rootRuleId: w['root_rule_id'] as String?,
  lineageRunsLeft: (w['lineage_runs_left'] as num?)?.toInt(),
  lineageEndsAt: _at(w['lineage_ends_at']),
);

/// Decodes one `wakeRules.listRuns` row. Throws [FormatException] (or
/// [ArgumentError] for an empty id) on a row without an id, reason, state
/// or times, which `decodeRows` drops.
WakeRuleRunView wakeRuleRunViewFromWire(Map<String, dynamic> w) {
  String need(Map<dynamic, dynamic> m, String key) => switch (m[key]) {
    final String v => v,
    final raw => throw FormatException('wake rule run: $key is $raw'),
  };
  final run = w['run'];
  return WakeRuleRunView(
    wakeId: need(w, 'id'),
    reason: need(w, 'reason'),
    state: need(w, 'state'),
    stateReason: w['state_reason'] as String?,
    slot: _at(w['slot']),
    eventKind: w['event_kind'] as String?,
    status: w['status'] as String?,
    subject: w['subject'] as String?,
    item: w['item'] as String?,
    exitCode: (w['exit_code'] as num?)?.toInt(),
    events: (w['events'] as num?)?.toInt(),
    dueAt: DateTime.parse(need(w, 'due_at')),
    createdAt: DateTime.parse(need(w, 'created_at')),
    settledAt: _at(w['settled_at']),
    run: run is Map
        ? WakeRuleRunFactsView(
            id: need(run, 'id'),
            status: need(run, 'status'),
            endReason: run['end_reason'] as String?,
            costMicros: (run['cost_micros'] as num?)?.toInt() ?? 0,
            startedAt: DateTime.parse(need(run, 'started_at')),
            endedAt: _at(run['ended_at']),
          )
        : null,
  );
}

/// [WakeRuleScheduleRepository] over the `wakeRules.*` RPC ops.
class RpcWakeRuleScheduleRepository implements WakeRuleScheduleRepository {
  /// Creates the repository over [_client].
  RpcWakeRuleScheduleRepository(this._client);

  final RemoteRpcClient _client;

  List<WakeRuleView> _rows(Map<String, dynamic> data) => decodeRows(
    [
      for (final row in (data['rules'] as List?) ?? const [])
        if (row is Map) row.cast<String, dynamic>(),
    ],
    wakeRuleViewFromWire,
    what: 'wake rule',
  );

  WakeRuleView _rule(Map<String, dynamic> data) =>
      wakeRuleViewFromWire((data['rule'] as Map).cast<String, dynamic>());

  @override
  Stream<List<WakeRuleView>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('wakeRules.watchForConversation', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map(_rows);

  @override
  Stream<List<WakeRuleView>> watchForWorkspace(String workspaceId) => _client
      .subscribe('wakeRules.watchForWorkspace', {'workspace_id': workspaceId})
      .map(_rows);

  @override
  Future<WakeRuleView> get(String workspaceId, String ruleId) async => _rule(
    await _client.call('wakeRules.get', {
      'workspace_id': workspaceId,
      'rule_id': ruleId,
    }),
  );

  @override
  Future<WakeRuleRunPage> listRuns(
    String workspaceId,
    String ruleId, {
    String? cursor,
  }) async {
    final data = await _client.call('wakeRules.listRuns', {
      'workspace_id': workspaceId,
      'rule_id': ruleId,
      'cursor': ?cursor,
    });
    return (
      wakes: decodeRows(
        [
          for (final row in (data['wakes'] as List?) ?? const [])
            if (row is Map) row.cast<String, dynamic>(),
        ],
        wakeRuleRunViewFromWire,
        what: 'wake rule run',
      ),
      nextCursor: data['next_cursor'] as String?,
    );
  }

  @override
  Future<WakeRuleView> create(String workspaceId, WakeRuleDraft draft) async =>
      _rule(
        await _client.call('wakeRules.create', {
          'workspace_id': workspaceId,
          'conversation_id': draft.conversationId,
          'agent_id': draft.agentId,
          'note': draft.note,
          'when': ?draft.when,
          'hour': ?draft.hour,
          'minute': ?draft.minute,
          'tz': ?draft.timeZone,
          'max_runs': ?draft.maxRuns,
          'expires_in': ?draft.expiresIn,
          'cost_cap_micros': ?draft.costCapMicros,
          'when_busy': ?draft.whenBusy?.wire,
          'deliver': draft.deliver.wire,
          if (draft.fireNow) 'fire_now': true,
        }),
      );

  @override
  Future<WakeRuleView> update(
    String workspaceId,
    String ruleId, {
    String? note,
    WakeWhenBusy? whenBusy,
    int? maxRuns,
    bool clearMaxRuns = false,
    int? costCapMicros,
    DateTime? expiresAt,
  }) async => _rule(
    await _client.call('wakeRules.update', {
      'workspace_id': workspaceId,
      'rule_id': ruleId,
      'note': ?note,
      'when_busy': ?whenBusy?.wire,
      'max_runs': ?maxRuns,
      if (clearMaxRuns) 'clear_max_runs': true,
      'cost_cap_micros': ?costCapMicros,
      'expires_at': ?expiresAt?.toUtc().toIso8601String(),
    }),
  );

  Future<bool> _flag(String op, String key, String ws, String ruleId) async =>
      (await _client.call(op, {'workspace_id': ws, 'rule_id': ruleId}))[key] ==
      true;

  @override
  Future<bool> pause(String workspaceId, String ruleId) =>
      _flag('wakeRules.pause', 'paused', workspaceId, ruleId);

  @override
  Future<bool> resume(String workspaceId, String ruleId) =>
      _flag('wakeRules.resume', 'resumed', workspaceId, ruleId);

  @override
  Future<bool> delete(String workspaceId, String ruleId) =>
      _flag('wakeRules.delete', 'deleted', workspaceId, ruleId);

  @override
  Future<WakeRuleLimits> limits(String workspaceId) async =>
      WakeRuleLimits.fromJson(
        ((await _client.call('wakeRules.getLimits', {
                  'workspace_id': workspaceId,
                }))['limits']
                as Map)
            .cast<String, Object?>(),
      );

  @override
  Future<CronPreview> previewCron(
    String workspaceId, {
    required String expression,
    required String timeZone,
  }) async {
    final data = await _client.call('wakeRules.previewCron', {
      'workspace_id': workspaceId,
      'expression': expression,
      'time_zone': timeZone,
    });
    return (
      nextFires: _instants(data['next_fires']),
      // Only the server's explicit "unknown" marks the zone as unknown.
      zoneKnown: data['zone_known'] != false,
    );
  }

  @override
  Future<WakeRuleLimits> setLimits(
    String workspaceId,
    WakeRuleLimits limits,
  ) async => WakeRuleLimits.fromJson(
    ((await _client.call('wakeRules.setLimits', {
              'workspace_id': workspaceId,
              'limits': limits.toJson(),
            }))['limits']
            as Map)
        .cast<String, Object?>(),
  );
}
