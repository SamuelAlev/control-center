import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_content.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class ProgressTodoRow extends StatelessWidget {
  const ProgressTodoRow({
    required this.scope,
    required this.todo,
    required this.canWrite,
    required this.editing,
    required this.editController,
    required this.mutate,
    required this.onError,
    required this.scopeIsCurrent,
    required this.onEdit,
    required this.onCloseEdit,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final ProgressScope scope;
  final TodoItem todo;
  final bool canWrite;
  final bool editing;
  final TextEditingController editController;
  final ProgressMutation mutate;
  final ValueChanged<String> onError;
  final bool Function() scopeIsCurrent;
  final VoidCallback onEdit;
  final VoidCallback onCloseEdit;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final statusLabel = switch (todo.status) {
      TodoStatus.pending => l.progressPending,
      TodoStatus.inProgress => l.progressInProgress,
      TodoStatus.completed => l.progressCompleted,
    };
    final statusIcon = switch (todo.status) {
      TodoStatus.pending => CcIcons.circleDashed,
      TodoStatus.inProgress => AppIcons.loader,
      TodoStatus.completed => AppIcons.circleCheck,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgPrimary,
          border: Border.all(color: t.borderSoft),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 18, color: t.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      todo.content,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textPrimary,
                        decoration: todo.status == TodoStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                statusLabel,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
              if (editing) ...[
                CcTextField(
                  controller: editController,
                  label: l.progressEditTodo,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CcButton(
                      size: CcButtonSize.lg,
                      onPressed: canWrite
                          ? () async {
                              final content = editController.text.trim();
                              if (content.isEmpty) {
                                onError(l.progressTodoRequired);
                                return;
                              }
                              final saved = await mutate((repo) async {
                                // A full-list replacement must preserve current order and statuses.
                                final latest = await repo.list(
                                  scope.workspaceId,
                                  scope.conversationId,
                                );
                                if (!latest.any((item) => item.id == todo.id)) {
                                  throw StateError(
                                    l.progressTodoNoLongerExists,
                                  );
                                }
                                if (!scopeIsCurrent()) {
                                  throw StateError(l.progressWorkspaceChanged);
                                }
                                await repo.replaceAll(
                                  scope.workspaceId,
                                  scope.conversationId,
                                  [
                                    for (final item in latest)
                                      item.id == todo.id
                                          ? item.copyWith(content: content)
                                          : item,
                                  ],
                                );
                              });
                              if (saved) onCloseEdit();
                            }
                          : null,
                      child: Text(l.save),
                    ),
                    CcButton(
                      size: CcButtonSize.lg,
                      variant: CcButtonVariant.secondary,
                      onPressed: onCloseEdit,
                      child: Text(l.cancel),
                    ),
                  ],
                ),
              ],
              if (canWrite)
                Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: [
                    CcButton(
                      size: CcButtonSize.lg,
                      variant: CcButtonVariant.secondary,
                      onPressed: onEdit,
                      child: Text(l.progressEditTodo),
                    ),
                    for (final next in TodoStatus.values)
                      if (next != todo.status)
                        CcButton(
                          size: CcButtonSize.lg,
                          variant: CcButtonVariant.secondary,
                          onPressed: () => mutate(
                            (repo) => repo.updateStatus(
                              scope.workspaceId,
                              scope.conversationId,
                              todo.id,
                              next,
                            ),
                          ),
                          child: Text(switch (next) {
                            TodoStatus.pending => l.progressPending,
                            TodoStatus.inProgress => l.progressInProgress,
                            TodoStatus.completed => l.progressCompleted,
                          }),
                        ),
                    CcTappable(
                      onPressed: onMoveUp,
                      semanticLabel: l.progressMoveUp,
                      builder: (context, _) => SizedBox(
                        width: kMinTouchTarget,
                        height: kMinTouchTarget,
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: Icon(
                              AppIcons.arrowDown,
                              size: 20,
                              color: t.fgSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    PhoneIconButton(
                      icon: AppIcons.arrowDown,
                      semanticLabel: l.progressMoveDown,
                      onPressed: onMoveDown,
                    ),
                    PhoneIconButton(
                      icon: CcIcons.trash2,
                      semanticLabel: l.progressRemoveTodo(todo.content),
                      onPressed: () => mutate(
                        (repo) => repo.remove(
                          scope.workspaceId,
                          scope.conversationId,
                          todo.id,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
