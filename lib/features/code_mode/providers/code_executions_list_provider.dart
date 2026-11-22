import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/code_mode/providers/running_script_watch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The statuses a record can have, in the order the outcome filter offers
/// them: every status but `refused`. A script the host refused was never
/// admitted, so it has no record, and the server refuses a query for it.
final List<CodeExecutionStatus> kRecordedCodeExecutionStatuses = [
  for (final s in CodeExecutionStatus.values)
    if (s != CodeExecutionStatus.refused) s,
];

/// What the executions list shows: one workspace, optionally scoped to a run,
/// a conversation or an agent, and narrowed to some outcomes.
@immutable
class CodeExecutionsFilter {
  /// Creates a filter.
  const CodeExecutionsFilter({
    required this.workspaceId,
    this.runId,
    this.conversationId,
    this.agentId,
    this.statuses = const {},
  });

  /// The workspace whose executions these are.
  final String workspaceId;

  /// Only this run's executions.
  final String? runId;

  /// Only this conversation's executions.
  final String? conversationId;

  /// Only this agent's executions.
  final String? agentId;

  /// Only these outcomes; empty shows all.
  final Set<CodeExecutionStatus> statuses;

  /// Whether the list is scoped to a run, a conversation or an agent.
  bool get isScoped =>
      runId != null || conversationId != null || agentId != null;

  @override
  bool operator ==(Object other) =>
      other is CodeExecutionsFilter &&
      other.workspaceId == workspaceId &&
      other.runId == runId &&
      other.conversationId == conversationId &&
      other.agentId == agentId &&
      setEquals(other.statuses, statuses);

  @override
  int get hashCode => Object.hash(
    workspaceId,
    runId,
    conversationId,
    agentId,
    Object.hashAllUnordered(statuses),
  );
}

/// The executions loaded so far, newest first, and where the next page
/// starts.
@immutable
class CodeExecutionsListState {
  /// Creates a state.
  const CodeExecutionsListState({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.moreError,
  });

  /// The executions, newest first.
  final List<CodeExecution> items;

  /// The cursor of the next (older) page, or null at the end.
  final String? nextCursor;

  /// Whether a further page is being read.
  final bool loadingMore;

  /// Why the last further page failed, or null.
  final Object? moreError;

  /// Whether older executions remain.
  bool get hasMore => nextCursor != null;

  /// A copy with the given fields replaced.
  CodeExecutionsListState copyWith({
    List<CodeExecution>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    Object? moreError,
    bool clearMoreError = false,
  }) => CodeExecutionsListState(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loadingMore: loadingMore ?? this.loadingMore,
    moreError: clearMoreError ? null : (moreError ?? this.moreError),
  );
}

/// A workspace's executions for one [CodeExecutionsFilter], read a page at a
/// time.
final codeExecutionsListProvider = AsyncNotifierProvider.autoDispose
    .family<
      CodeExecutionsListNotifier,
      CodeExecutionsListState,
      CodeExecutionsFilter
    >(CodeExecutionsListNotifier.new);

/// Reads [filter]'s executions newest first and appends older pages on
/// demand, one request per page.
///
/// The server leaves out executions in spaces the caller cannot read inside
/// its query, so a page holds only rows the reader may see and the cursor
/// follows them; a short page is simply a short page.
///
/// A script still running is shown as such, and its row is read again when
/// its run's transcript shows it move on ([watchRunningScript]), until it
/// ends. Scripts that start after the list was read appear on the next read.
class CodeExecutionsListNotifier
    extends AsyncNotifier<CodeExecutionsListState> {
  /// Creates the notifier for [filter].
  CodeExecutionsListNotifier(this.filter);

  /// What this list shows.
  final CodeExecutionsFilter filter;

  /// Rows per page.
  static const int pageSize = 50;

  /// The runs whose running script this list already follows.
  final Set<String> _watchedRuns = {};

  @override
  Future<CodeExecutionsListState> build() async {
    // Subscribed here so a reconnect (a new client) re-reads the list; the
    // page reads below use `read`, which is what a later `loadMore` can do.
    ref.watch(codeModeRepositoryProvider);
    _watchedRuns.clear();
    final page = await _read(null);
    _watchRunning(page.items);
    return CodeExecutionsListState(
      items: page.items,
      nextCursor: page.nextCursor,
    );
  }

  /// Reads the next older page, once; a second call while one is in flight
  /// does nothing.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return;
    }
    state = AsyncData(
      current.copyWith(loadingMore: true, clearMoreError: true),
    );
    try {
      final page = await _read(current.nextCursor);
      _watchRunning(page.items);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
          clearMoreError: true,
        ),
      );
    } on Object catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false, moreError: e));
    }
  }

  Future<CodeExecutionPage> _read(String? cursor) => ref
      .read(codeModeRepositoryProvider)
      .listExecutions(
        filter.workspaceId,
        CodeExecutionQuery(
          cursor: cursor,
          limit: pageSize,
          runId: filter.runId,
          conversationId: filter.conversationId,
          agentId: filter.agentId,
          statuses: filter.statuses,
        ),
      );

  /// Follows the run of every running script in [items] not followed yet.
  /// A run runs one script at a time, so one watch per run is enough.
  void _watchRunning(List<CodeExecution> items) {
    for (final e in items) {
      if (e.status != CodeExecutionStatus.running ||
          !_watchedRuns.add(e.runId)) {
        continue;
      }
      watchRunningScript(
        ref,
        workspaceId: filter.workspaceId,
        runId: e.runId,
        toolCallId: e.toolCallId,
        onProgress: () => unawaited(_refreshRunning(e.runId)),
      );
    }
  }

  /// Reads again, in place, the running rows of [runId]: one request per
  /// row, narrowed to its call. A row the read fails for stays as it was; a
  /// row whose new status the filter excludes leaves the list.
  Future<void> _refreshRunning(String runId) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final stale = [
      for (final e in current.items)
        if (e.runId == runId && e.status == CodeExecutionStatus.running) e,
    ];
    final fresh = <String, CodeExecution>{};
    for (final e in stale) {
      try {
        final page = await ref
            .read(codeModeRepositoryProvider)
            .listExecutions(
              filter.workspaceId,
              CodeExecutionQuery(
                runId: e.runId,
                toolCallId: e.toolCallId,
                limit: _refreshLimit,
              ),
            );
        for (final item in page.items) {
          if (item.id == e.id) {
            fresh[e.id] = item;
          }
        }
      } on Object {
        // The row keeps what it showed; the next change asks again.
      }
    }
    final latest = state.value;
    if (fresh.isEmpty || latest == null || !ref.mounted) {
      return;
    }
    // A record that ended leaves a list filtered to outcomes it no longer
    // has (a running-only list loses it once it finishes).
    final wanted = filter.statuses;
    state = AsyncData(
      latest.copyWith(
        items: [
          for (final e in latest.items)
            if (fresh[e.id] ?? e case final row
                when wanted.isEmpty || wanted.contains(row.status))
              row,
        ],
      ),
    );
  }

  /// How many executions of one call a refresh reads: the running one is the
  /// newest, so a few cover repeats of the call id.
  static const int _refreshLimit = 5;
}
