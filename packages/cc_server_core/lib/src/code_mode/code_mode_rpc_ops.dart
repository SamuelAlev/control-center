import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show
        CodeExecutionDetailDto,
        CodeExecutionPageDto,
        CodeModeStatusDto,
        NotFoundException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/code_mode/server_code_mode.dart';

/// The workspace settings only `codeMode.setWorkspaceSetting` writes.
///
/// `workspace_settings.set` stores any value raw, so it refuses these keys
/// (`code_mode_setting_reserved`): limits must sit inside [CodeModeLimits]'
/// bounds before they are stored, and only the dedicated op checks that.
const Set<String> kCodeModeWorkspaceSettingKeys = {kCodeModeLimitsSettingKey};

/// What this server knows about its runner, for `codeMode.status`. Host
/// facts only: nothing here is a path.
class CodeModeHostFacts {
  /// Creates the facts.
  const CodeModeHostFacts({
    required this.availability,
    required this.publicReason,
    required this.runnerVersion,
    required this.maxProcesses,
    required this.maxParkedProcesses,
    required this.maxWorkspaceProcesses,
    required this.maxHeapBytes,
  });

  /// Whether this server runs scripts: what the runner's boot self-test
  /// found, or unavailable on a public demo.
  final CodeRunnerAvailability Function() availability;

  /// Why this server runs no scripts, with host paths removed.
  final String? Function() publicReason;

  /// The runner's version line.
  final String? Function() runnerVersion;

  /// `--code-mode-max-processes`: scripts running at once.
  final int maxProcesses;

  /// Runners kept alive for scripts waiting on a person without a slot.
  final int maxParkedProcesses;

  /// The slots one workspace holds at most.
  final int maxWorkspaceProcesses;

  /// `--code-mode-max-heap-mb`, in bytes: every script's heap ceiling.
  final int maxHeapBytes;
}

/// Refuses [userId] reading space [spaceId] of [workspaceId]
/// (`PrDataGate.requireSpace`).
typedef CodeModeSpaceGate =
    Future<void> Function(String workspaceId, String userId, String spaceId);

/// The spaces of [workspaceId] that [userId] may not read
/// (`PrDataGate.hiddenSpaces`).
typedef CodeModeHiddenSpaces =
    Future<Set<String>> Function(String workspaceId, String userId);

/// Whether space [spaceId] exists in [workspaceId].
typedef CodeModeSpaceInWorkspace =
    Future<bool> Function(String workspaceId, String spaceId);

/// The `codeMode.` op pack: the status a settings screen shows, the one
/// write that may set the workspace's limits, and the reads the
/// observability pages list and open executions through.
///
/// Every op is workspace-scoped: the dispatcher checks the workspace is
/// registered and not deleted, then the caller's membership, before a handler
/// runs. The reads need a member (a guest or viewer reads no script); the
/// write needs an admin of that workspace, like every other workspace setting.
///
/// An execution's source, output and nested-call arguments are content of
/// the space its run worked in, so they follow the space read gate the forge
/// decides ([requireSpace], [hiddenSpaces]): a member who cannot read a space
/// cannot open, or see listed, an execution recorded in it. An execution
/// with no space carries no space content and is readable by every member,
/// as a run log with no space is. Ids are looked up in the caller's
/// workspace only, so an id from another workspace is simply not found. A
/// `space_id` filter must name a space of the workspace ([spaceInWorkspace])
/// that the caller may read, and the spaces the caller may not read are left
/// out by the query itself, so a page and its cursor are made of rows the
/// caller may see.
///
/// A call refused before it was admitted is not recorded, so `refused` is no
/// status a listing can filter on.
///
/// Injected into the catalog via `extraOps`, so `remote_rpc_catalog.dart`
/// does not grow.
List<RepoOp> buildCodeModeOps({
  required CodeModeSettings settings,
  required WorkspaceSettingsRepository settingsStore,
  required CodeExecutionRepository executions,
  required CodeModeHostFacts host,
  required CodeModeSpaceInWorkspace spaceInWorkspace,
  required CodeModeSpaceGate requireSpace,
  required CodeModeHiddenSpaces hiddenSpaces,
}) => [
  RepoOp(
    name: 'codeMode.status',
    kind: RepoOpKind.read,
    minRole: WorkspaceRole.member,
    handler: (ctx) async => {
      'status': _status(
        host: host,
        limits: await settings.limitsFor(ctx.workspaceId!),
      ).toJson(),
    },
  ),
  RepoOp(
    name: 'codeMode.listExecutions',
    kind: RepoOpKind.read,
    minRole: WorkspaceRole.member,
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      final spaceId = _optionalString(ctx, 'space_id');
      if (spaceId != null) {
        if (!await spaceInWorkspace(workspaceId, spaceId)) {
          throw const WorkspaceMismatchException(
            'Space belongs to a different workspace',
          );
        }
        await requireSpace(workspaceId, ctx.userId, spaceId);
      }
      final hidden = await hiddenSpaces(workspaceId, ctx.userId);
      final page = await executions.list(
        workspaceId,
        _query(ctx, spaceId, hidden),
      );
      return CodeExecutionPageDto(
        items: page.items,
        nextCursor: page.nextCursor,
      ).toJson();
    },
  ),
  RepoOp(
    name: 'codeMode.getExecution',
    kind: RepoOpKind.read,
    minRole: WorkspaceRole.member,
    requiredArgs: const ['id'],
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      final id = ctx.args['id'];
      if (id is! String || id.isEmpty) {
        throw const ValidationException(
          'id must be an execution id.',
          code: 'code_mode_invalid_query',
        );
      }
      final detail = await executions.get(workspaceId, id);
      if (detail == null || detail.execution.id != id) {
        throw const NotFoundException(
          'No such code execution in this workspace.',
          code: 'code_execution_not_found',
        );
      }
      final spaceId = detail.execution.spaceId;
      if (spaceId != null) {
        await requireSpace(workspaceId, ctx.userId, spaceId);
      }
      return {'execution': CodeExecutionDetailDto.fromDetail(detail).toJson()};
    },
  ),
  RepoOp(
    name: 'codeMode.setWorkspaceSetting',
    kind: RepoOpKind.mutate,
    // A workspace setting: admin, like `workspace_settings.set`.
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['key'],
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      final key = ctx.args['key'];
      final value = ctx.args['value'];
      final Object? stored;
      switch (key) {
        case kCodeModeLimitsSettingKey:
          final overrides = _checkedLimits(value);
          stored = overrides;
          await settingsStore.set(
            workspaceId,
            key,
            overrides == null ? null : jsonEncode(overrides),
          );
        default:
          throw ValidationException(
            'Unknown code mode setting: $key. Use '
            '${kCodeModeWorkspaceSettingKeys.join(' or ')}.',
            code: 'code_mode_unknown_setting',
          );
      }
      return {'ok': true, 'key': key, 'value': stored};
    },
  ),
];

/// The status wire for one workspace.
CodeModeStatusDto _status({
  required CodeModeHostFacts host,
  required CodeModeLimits limits,
}) {
  final available = host.availability().isAvailable;
  return CodeModeStatusDto(
    available: available,
    // The public reason: the runner's own can name a path.
    reason: available ? null : host.publicReason(),
    limits: limits.heapBytes <= host.maxHeapBytes
        ? limits
        : CodeModeLimits(
            wallClockMs: limits.wallClockMs,
            cpuMs: limits.cpuMs,
            heapBytes: host.maxHeapBytes,
            maxNestedCalls: limits.maxNestedCalls,
            maxInFlightCalls: limits.maxInFlightCalls,
            maxOutputTokens: limits.maxOutputTokens,
          ),
    limitOverrides: limits.overridesToJson(),
    runnerVersion: host.runnerVersion(),
    maxProcesses: host.maxProcesses,
    maxParkedProcesses: host.maxParkedProcesses,
    maxWorkspaceProcesses: host.maxWorkspaceProcesses,
    maxHeapBytes: host.maxHeapBytes,
  );
}

/// The overrides to store for a limits write, or null to clear them.
///
/// Every key must be a known adjustable limit and every value an integer
/// inside its bound ([CodeModeLimits.withOverridesJson] refuses the rest). The
/// stored object holds only values that differ from the defaults, so a write
/// of the defaults clears the row.
Map<String, int>? _checkedLimits(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw const ValidationException(
      'code_mode_limits must be an object of limit overrides.',
      code: 'code_mode_limit_out_of_range',
    );
  }
  final CodeModeLimits limits;
  try {
    limits = CodeModeLimits.defaults.withOverridesJson(
      value.cast<String, dynamic>(),
    );
  } on ArgumentError catch (e) {
    throw ValidationException(
      'The code mode limits do not fit together: ${e.message}',
      code: 'code_mode_limit_out_of_range',
    );
  }
  final overrides = limits.overridesToJson();
  return overrides.isEmpty ? null : overrides;
}

/// The repository query `codeMode.listExecutions` asks for.
CodeExecutionQuery _query(
  RepoOpContext ctx,
  String? spaceId,
  Set<String> hiddenSpaceIds,
) {
  Never invalid(String what) =>
      throw ValidationException(what, code: 'code_mode_invalid_query');

  final rawLimit = ctx.args['limit'];
  final limit = switch (rawLimit) {
    null => 50,
    final int n when n >= 1 && n <= CodeExecutionQuery.maxLimit => n,
    _ => invalid('limit must be between 1 and ${CodeExecutionQuery.maxLimit}.'),
  };
  final statuses = <CodeExecutionStatus>{};
  final rawStatuses = ctx.args['statuses'];
  if (rawStatuses != null) {
    if (rawStatuses is! List) {
      invalid('statuses must be a list of execution statuses.');
    }
    for (final raw in rawStatuses) {
      final status = raw is String ? CodeExecutionStatus.tryParse(raw) : null;
      // A refused call is never recorded, so it is no status to list by.
      if (status == null || status == CodeExecutionStatus.refused) {
        invalid('Unknown execution status: $raw.');
      }
      statuses.add(status);
    }
  }
  final rawSurface = ctx.args['surface'];
  final surface = rawSurface == null
      ? null
      : (rawSurface is String
                ? CodeExecutionSurface.tryParse(rawSurface)
                : null) ??
            invalid('Unknown surface: $rawSurface.');
  DateTime? instant(String key) {
    final raw = ctx.args[key];
    if (raw == null) {
      return null;
    }
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    return parsed?.toUtc() ?? invalid('$key must be an ISO-8601 instant.');
  }

  return CodeExecutionQuery(
    cursor: _optionalString(ctx, 'cursor'),
    limit: limit,
    runId: _optionalString(ctx, 'run_id'),
    conversationId: _optionalString(ctx, 'conversation_id'),
    agentId: _optionalString(ctx, 'agent_id'),
    spaceId: spaceId,
    toolCallId: _optionalString(ctx, 'tool_call_id'),
    hiddenSpaceIds: hiddenSpaceIds,
    statuses: statuses,
    surface: surface,
    since: instant('since'),
    until: instant('until'),
  );
}

/// A string argument, or null when absent or empty. Anything else is the
/// caller's mistake.
String? _optionalString(RepoOpContext ctx, String key) {
  final raw = ctx.args[key];
  if (raw == null) {
    return null;
  }
  if (raw is! String) {
    throw ValidationException(
      '$key must be a string.',
      code: 'code_mode_invalid_query',
    );
  }
  return raw.isEmpty ? null : raw;
}
