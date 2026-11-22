import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        NotFoundException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        WakeLineageStatus,
        WakeRuleRequest,
        WakeRuleRunFacts,
        WakeRuleService;

/// The `wakeRules` pack: the Schedules screen's reads and a person's
/// controls over schedules, loops and watches (plan section 9). Members who
/// may read the rule's (or conversation's) space; the workspace of a rule
/// comes from its row, and an id outside the caller's workspace is not
/// found.
///
/// Who may change what: a rule acts for its person and runs with their
/// sign-in, so resuming it, changing its note or busy behaviour and changing
/// its limits are that person's (a bot's rule: a workspace admin's). Pausing
/// and deleting are open to every member who may read its space.
/// `setLimits` is a workspace admin's.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Empty when the host wires no rule service.
({List<RepoOp> ops, List<WatchQuery> watches}) buildWakeRuleOps({
  required WakeRuleService Function()? service,
  required WakeRuleRepository? rules,
  required ConversationRepository conversations,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required Stream<Map<String, dynamic>> Function(
    String workspaceId,
    String userId,
    String spaceId,
    Stream<Map<String, dynamic>> source,
  )
  guardSpace,
  // The viewer's role in a watch (a watch context carries none).
  required Future<WorkspaceRole?> Function(String workspaceId, String userId)
  roleOf,
}) {
  if (service == null || rules == null) {
    return (ops: const [], watches: const []);
  }

  // A rule on the wire with its lineage's standing.
  Future<Map<String, dynamic>> wire(
    WakeRule rule, {
    required bool canChange,
  }) async => wakeRuleToWire(
    rule,
    canChange: canChange,
    lineage: await service().lineageStatus(rule),
    nextFires: await service().nextFires(rule),
  );

  Future<WakeRule> requireRule(RepoOpContext ctx) async {
    final id = ctx.args['rule_id'];
    if (id is! String || id.isEmpty) {
      throw const ValidationException('Missing rule_id');
    }
    final rule = await rules.getById(ctx.workspaceId!, id);
    if (rule == null) {
      throw const NotFoundException('Wake rule not found in this workspace');
    }
    await requireSpace(ctx.workspaceId!, ctx.userId, rule.spaceId);
    return rule;
  }

  // Resume, terms and limits: the rule's own person (a bot's rule: an
  // admin).
  void requireOwner(RepoOpContext ctx, WakeRule rule) {
    final person = rule.requestedByUserId;
    if (!wakeRuleChangeableBy(rule, ctx.userId, ctx.role)) {
      throw AuthException(
        person == null
            ? 'Only a workspace admin may change a rule no person owns.'
            : 'Only the person this rule acts for may change it.',
        code: WakeRuleRefusals.notYours,
      );
    }
  }

  Future<String> requireConversation(
    String workspaceId,
    String userId,
    Object? conversationId,
  ) async {
    if (conversationId is! String || conversationId.isEmpty) {
      throw const ValidationException('Missing conversation_id');
    }
    final conversation = await conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null || conversation.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'Conversation not found in this workspace',
      );
    }
    await requireSpace(workspaceId, userId, conversation.spaceId);
    return conversation.spaceId;
  }

  int? intArg(RepoOpContext ctx, String key) => switch (ctx.args[key]) {
    null => null,
    final int v => v,
    final num v when v == v.roundToDouble() => v.toInt(),
    _ => throw ValidationException('$key must be a whole number'),
  };

  String? stringArg(RepoOpContext ctx, String key) => switch (ctx.args[key]) {
    null => null,
    final String v when v.trim().isNotEmpty => v.trim(),
    _ => throw ValidationException('$key must be text'),
  };

  return (
    ops: [
      RepoOp(
        name: 'wakeRules.create',
        kind: RepoOpKind.mutate,
        requiredArgs: ['conversation_id', 'agent_id', 'note'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          await requireConversation(
            ctx.workspaceId!,
            ctx.userId,
            ctx.args['conversation_id'],
          );
          final expiresRaw = stringArg(ctx, 'expires_in');
          final expiresIn = expiresRaw == null
              ? null
              : parseWakeDuration(expiresRaw);
          if (expiresRaw != null && expiresIn == null) {
            throw ValidationException(
              'expires_in "$expiresRaw" is not a duration (30d, 12h).',
              code: WakeRuleRefusals.invalidWhen,
            );
          }
          final clock = switch ((intArg(ctx, 'hour'), intArg(ctx, 'minute'))) {
            (final int h, final int m)
                when h >= 0 && h < 24 && m >= 0 && m < 60 =>
              (hour: h, minute: m),
            (null, null) => null,
            _ => throw const ValidationException(
              'hour is 0 to 23 and minute 0 to 59',
              code: WakeRuleRefusals.invalidWhen,
            ),
          };
          final rule = await service().create(
            WakeRuleRequest(
              workspaceId: ctx.workspaceId!,
              conversationId: ctx.args['conversation_id'] as String,
              agentId: ctx.args['agent_id'] as String,
              when: clock == null ? stringArg(ctx, 'when') : null,
              clock: clock,
              timeZone: stringArg(ctx, 'tz'),
              note: ctx.args['note'] as String,
              origin: WakeRuleOrigin.person,
              maxRuns: intArg(ctx, 'max_runs'),
              expiresIn: expiresIn,
              costCapMicros: intArg(ctx, 'cost_cap_micros'),
              whenBusy: switch (stringArg(ctx, 'when_busy')) {
                null => null,
                final raw =>
                  WakeWhenBusyWire.tryParse(raw) ??
                      (throw const ValidationException(
                        'when_busy is skip or queue',
                      )),
              },
              deliver: switch (stringArg(ctx, 'deliver')) {
                null => WakeDeliver.run,
                final raw =>
                  WakeDeliverWire.tryParse(raw) ??
                      (throw const ValidationException(
                        'deliver is run or notify',
                      )),
              },
              createdByUserId: ctx.userId,
              requestedByUserId: ctx.userId,
              fireNow: ctx.args['fire_now'] == true,
            ),
          );
          return {'rule': await wire(rule, canChange: true)};
        },
      ),
      RepoOp(
        name: 'wakeRules.update',
        kind: RepoOpKind.mutate,
        requiredArgs: ['rule_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final rule = await requireRule(ctx);
          requireOwner(ctx, rule);
          final expiresRaw = stringArg(ctx, 'expires_at');
          final expiresAt = expiresRaw == null
              ? null
              : parseWakeInstant(expiresRaw);
          if (expiresRaw != null && expiresAt == null) {
            throw const ValidationException(
              'expires_at must be an ISO time',
              code: WakeRuleRefusals.expiryTooLong,
            );
          }
          final updated = await service().update(
            ctx.workspaceId!,
            rule.id,
            note: ctx.args['note'] is String
                ? ctx.args['note'] as String
                : null,
            whenBusy: switch (stringArg(ctx, 'when_busy')) {
              null => null,
              final raw =>
                WakeWhenBusyWire.tryParse(raw) ??
                    (throw const ValidationException(
                      'when_busy is skip or queue',
                    )),
            },
            maxRuns: intArg(ctx, 'max_runs'),
            clearMaxRuns: ctx.args['clear_max_runs'] == true,
            costCapMicros: intArg(ctx, 'cost_cap_micros'),
            expiresAt: expiresAt,
            editedByUserId: ctx.userId,
          );
          return {'rule': await wire(updated, canChange: true)};
        },
      ),
      RepoOp(
        name: 'wakeRules.pause',
        kind: RepoOpKind.mutate,
        requiredArgs: ['rule_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final rule = await requireRule(ctx);
          return {
            'paused': await service().pause(
              ctx.workspaceId!,
              rule.id,
              pausedBy: ctx.userId,
            ),
          };
        },
      ),
      RepoOp(
        name: 'wakeRules.resume',
        kind: RepoOpKind.mutate,
        requiredArgs: ['rule_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final rule = await requireRule(ctx);
          requireOwner(ctx, rule);
          return {'resumed': await service().resume(ctx.workspaceId!, rule.id)};
        },
      ),
      RepoOp(
        name: 'wakeRules.delete',
        kind: RepoOpKind.mutate,
        requiredArgs: ['rule_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final rule = await requireRule(ctx);
          return {'deleted': await service().delete(ctx.workspaceId!, rule.id)};
        },
      ),
      RepoOp(
        name: 'wakeRules.get',
        kind: RepoOpKind.read,
        requiredArgs: ['rule_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final rule = await requireRule(ctx);
          return {
            'rule': await wire(
              rule,
              canChange: wakeRuleChangeableBy(rule, ctx.userId, ctx.role),
            ),
          };
        },
      ),
      RepoOp(
        name: 'wakeRules.listRuns',
        kind: RepoOpKind.read,
        requiredArgs: ['rule_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final rule = await requireRule(ctx);
          final cursor = ctx.args['cursor'];
          if (cursor != null && (cursor is! String || cursor.isEmpty)) {
            throw const ValidationException('cursor: a string');
          }
          final page = await service().history(
            rule,
            cursor: cursor as String?,
          );
          return {
            'rule_id': rule.id,
            'wakes': [
              for (final row in page.wakes)
                wakeRuleHistoryRowToWire(row.wake, row.run),
            ],
            'next_cursor': page.nextCursor,
          };
        },
      ),
      RepoOp(
        name: 'wakeRules.previewCron',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          // An absent or empty expression asks about the zone alone.
          final expression = ctx.args['expression'] ?? '';
          final zone = ctx.args['time_zone'] ?? '';
          if (expression is! String || zone is! String) {
            throw const ValidationException(
              'expression and time_zone are strings',
            );
          }
          // Reads no row: the next times of a draft, from the server's
          // clock and zone rules (the client carries no zone database).
          final preview = await service().previewCron(
            ctx.workspaceId!,
            expression: expression,
            timeZone: zone,
          );
          return {
            'next_fires': [
              for (final f in preview.nextFires) f.toUtc().toIso8601String(),
            ],
            'zone_known': preview.zoneKnown,
          };
        },
      ),
      RepoOp(
        name: 'wakeRules.getLimits',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.member,
        handler: (ctx) async => {
          'limits': (await service().limitsFor(ctx.workspaceId!)).toJson(),
        },
      ),
      RepoOp(
        name: 'wakeRules.setLimits',
        kind: RepoOpKind.mutate,
        requiredArgs: ['limits'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final raw = ctx.args['limits'];
          if (raw is! Map) {
            throw const ValidationException('limits must be an object');
          }
          final current = await service().limitsFor(ctx.workspaceId!);
          final WakeRuleLimits next;
          try {
            next = WakeRuleLimits.fromJson({
              ...current.toJson(),
              ...raw.cast<String, Object?>(),
            });
          } on ArgumentError catch (e) {
            throw ValidationException(
              '${e.message}',
              code: WakeRuleRefusals.limitOutOfRange,
            );
          } on FormatException catch (e) {
            throw ValidationException(
              e.message,
              code: WakeRuleRefusals.limitOutOfRange,
            );
          }
          return {
            'limits': (await service().setLimits(
              ctx.workspaceId!,
              next,
            )).toJson(),
          };
        },
      ),
    ],
    watches: [
      WatchQuery(
        name: 'wakeRules.watchForConversation',
        minRole: WorkspaceRole.member,
        handler: (ctx) async* {
          final workspaceId = ctx.workspaceId!;
          final spaceId = await requireConversation(
            workspaceId,
            ctx.userId,
            ctx.args['conversation_id'],
          );
          final role = await roleOf(workspaceId, ctx.userId);
          yield* guardSpace(
            workspaceId,
            ctx.userId,
            spaceId,
            rules
                .watchForConversation(
                  workspaceId,
                  ctx.args['conversation_id'] as String,
                )
                .asyncMap(
                  (list) async => {
                    'rules': [
                      for (final rule in list)
                        if (rule.workspaceId == workspaceId)
                          await wire(
                            rule,
                            canChange: wakeRuleChangeableBy(
                              rule,
                              ctx.userId,
                              role,
                            ),
                          ),
                    ],
                  },
                ),
          );
        },
      ),
      // Every rule of the workspace whose space the caller may read; each
      // emission re-checks the spaces, so a lost grant drops its rows.
      WatchQuery(
        name: 'wakeRules.watchForWorkspace',
        minRole: WorkspaceRole.member,
        handler: (ctx) async* {
          final workspaceId = ctx.workspaceId!;
          final role = await roleOf(workspaceId, ctx.userId);
          await for (final list in rules.watchForWorkspace(workspaceId)) {
            final readable = <String, bool>{};
            final rows = <Map<String, dynamic>>[];
            for (final rule in list) {
              if (rule.workspaceId != workspaceId) {
                continue;
              }
              final ok = readable[rule.spaceId] ??= await () async {
                try {
                  await requireSpace(workspaceId, ctx.userId, rule.spaceId);
                  return true;
                } on Object {
                  return false;
                }
              }();
              if (ok) {
                rows.add(
                  await wire(
                    rule,
                    canChange: wakeRuleChangeableBy(rule, ctx.userId, role),
                  ),
                );
              }
            }
            yield {'rules': rows};
          }
        },
      ),
    ],
  );
}

/// One wake of a rule's history (`wakeRules.listRuns`): what it was for (a
/// slot, or a watch's event: its kind, status, subject, item, exit code and
/// how many events it gathered), what became of it and, when it started
/// one, the run. Every time is UTC ISO 8601. The payload is not sent.
Map<String, dynamic> wakeRuleHistoryRowToWire(
  Wake wake,
  WakeRuleRunFacts? run,
) {
  String? at(DateTime? t) => t?.toUtc().toIso8601String();
  final detail = wake.detail;
  final events = detail.fields[WakeFields.events];
  final exitCode = detail.fields[WakeFields.exitCode];
  String? text(String key) => switch (detail.fields[key]) {
    final String v when v.isNotEmpty => v,
    _ => null,
  };
  return {
    'id': wake.id,
    'reason': wake.reason.wire,
    'state': wake.state.wire,
    'state_reason': wake.stateReason,
    'slot': at(detail.slot),
    'event_kind': detail.eventKind?.wire,
    'status': detail.status,
    'subject': text(WakeFields.subject),
    'item': text(WakeFields.item),
    'exit_code': exitCode is int ? exitCode : null,
    'events': events is int ? events : null,
    'due_at': at(wake.notBefore),
    'created_at': at(wake.createdAt),
    'settled_at': at(wake.settledAt),
    'run': run == null
        ? null
        : {
            'id': run.id,
            'status': run.status,
            'end_reason': run.endReason,
            'cost_micros': run.costMicros,
            'started_at': at(run.startedAt),
            'ended_at': at(run.endedAt),
          },
  };
}

/// Whether [userId] (with [role]) may resume [rule] or change its note,
/// busy behaviour and limits: the person it acts for, or a workspace admin
/// for a rule no person owns.
bool wakeRuleChangeableBy(WakeRule rule, String userId, WorkspaceRole? role) {
  final person = rule.requestedByUserId;
  return person == null ? (role?.isAdmin ?? false) : person == userId;
}

/// A rule as the Schedules screen reads it: whose (owner, agent,
/// conversation), what (trigger, note, and whose words the note is), when
/// it fires next, how far it got (runs, skips, cost), where it stands
/// (status, end reason), the lineage it belongs to ([lineage]: its root, the
/// runs it has left, when it ends), whether the viewer may change it
/// ([canChange]), and a cron rule's next fire times ([nextFires], from
/// `WakeRuleService.nextFires`; sent only when there are any).
Map<String, dynamic> wakeRuleToWire(
  WakeRule rule, {
  required bool canChange,
  required WakeLineageStatus? lineage,
  required List<DateTime> nextFires,
}) => {
  'id': rule.id,
  'workspace_id': rule.workspaceId,
  'space_id': rule.spaceId,
  'conversation_id': rule.conversationId,
  'agent_id': rule.agentId,
  'owner_user_id': ?rule.requestedByUserId,
  'created_by_user_id': ?rule.createdByUserId,
  'created_by_run_id': ?rule.createdByRunId,
  'origin': rule.origin.wire,
  'trigger': formatWakeWhen(rule.trigger),
  'trigger_kind': rule.trigger.kind,
  'tz': ?formatWakeZone(rule.trigger),
  'note': rule.note,
  // `agent`: the agent's own words (data, never a person's request);
  // `person`: the creator's, or [note_edited_by_user_id]'s after an edit.
  'note_author':
      rule.noteEditedByUserId == null && rule.origin == WakeRuleOrigin.agent
      ? 'agent'
      : 'person',
  'note_edited_by_user_id': ?rule.noteEditedByUserId,
  'deliver': rule.deliver.wire,
  'when_busy': rule.whenBusy.wire,
  'next_fire_at': ?(rule.isWatch ? null : rule.nextFireAt)
      ?.toUtc()
      .toIso8601String(),
  if (nextFires.isNotEmpty)
    'next_fires': [for (final f in nextFires) f.toUtc().toIso8601String()],
  'last_fired_at': ?rule.lastFiredAt?.toUtc().toIso8601String(),
  'run_count': rule.runCount,
  'max_runs': ?rule.maxRuns,
  'skip_count': rule.skipCount,
  'cost_micros': rule.costMicros,
  'cost_cap_micros': rule.costCapMicros,
  'goal_id': ?rule.goalId,
  'root_rule_id': ?rule.rootRuleId,
  'lineage_runs_left': ?lineage?.runsLeft,
  'lineage_ends_at': ?lineage?.endsAt.toUtc().toIso8601String(),
  'status': rule.status.wire,
  'end_reason': ?rule.endReason?.wire,
  'expires_at': rule.expiresAt.toUtc().toIso8601String(),
  'created_at': rule.createdAt.toUtc().toIso8601String(),
  'updated_at': rule.updatedAt.toUtc().toIso8601String(),
  'can_change': canChange,
};
