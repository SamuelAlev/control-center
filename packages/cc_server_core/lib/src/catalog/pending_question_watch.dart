import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show WorkspaceDatabaseManager;

/// Actionable questions with a live asker in the caller's workspace.
/// The catalog's workspace-scoped watch dispatcher checks registered workspace
/// membership before this query opens the workspace database. Per-space repo
/// grants are checked for each row before it crosses the subscription.
WatchQuery pendingQuestionWatchQuery({
  required WorkspaceDatabaseManager workspaceDbs,
  required bool Function(String messageId) isPending,
  required Stream<void> pendingChanges,
  required Future<bool> Function(
    String workspaceId,
    String spaceId,
    String userId,
  )
  viewerTraceRestricted,
}) => WatchQuery(
  name: 'questions.watchPending',
  minRole: WorkspaceRole.member,
  handler: (ctx) =>
      _withPendingChanges(
        workspaceDbs
            .of(ctx.workspaceId!)
            .messagingDao
            .watchPendingQuestions(ctx.workspaceId!),
        pendingChanges,
      ).asyncMap(
        (rows) async => {
          'questions': [
            for (final row in rows)
              if (isPending(row.id) &&
                  !await viewerTraceRestricted(
                    ctx.workspaceId!,
                    row.spaceId,
                    ctx.userId,
                  ))
                {
                  'id': row.id,
                  'space_id': row.spaceId,
                  'conversation_id': row.conversationId,
                  'content': row.content,
                  'metadata': row.metadata == null
                      ? null
                      : jsonDecode(row.metadata!),
                  'created_at': row.createdAt.toUtc().toIso8601String(),
                },
          ],
        },
      ),
);

Stream<T> _withPendingChanges<T>(Stream<T> rows, Stream<void> changes) {
  late final StreamController<T> controller;
  StreamSubscription<T>? rowSubscription;
  StreamSubscription<void>? changeSubscription;
  late T latest;
  var hasLatest = false;
  var active = true;
  void onError(Object error, StackTrace stack) {
    if (active) {
      controller.addError(error, stack);
    }
  }

  controller = StreamController<T>(
    onListen: () {
      changeSubscription = changes.listen((_) {
        if (active && hasLatest) {
          controller.add(latest);
        }
      }, onError: onError);
      rowSubscription = rows.listen(
        (value) {
          latest = value;
          hasLatest = true;
          if (active) {
            controller.add(value);
          }
        },
        onError: onError,
        onDone: () {
          active = false;
          unawaited(changeSubscription!.cancel());
          unawaited(controller.close());
        },
      );
    },
    onPause: () {
      rowSubscription?.pause();
      changeSubscription?.pause();
    },
    onResume: () {
      rowSubscription?.resume();
      changeSubscription?.resume();
    },
    onCancel: () async {
      active = false;
      await rowSubscription?.cancel();
      await changeSubscription?.cancel();
    },
  );
  return controller.stream;
}
