import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_content.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_todo_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressTodos extends ConsumerStatefulWidget {
  const ProgressTodos({
    required this.scope,
    required this.canWrite,
    required this.mutate,
    required this.onError,
    super.key,
  });

  final ProgressScope scope;
  final bool canWrite;
  final ProgressMutation mutate;
  final ValueChanged<String> onError;

  @override
  ConsumerState<ProgressTodos> createState() => _ProgressTodosState();
}

class _ProgressTodosState extends ConsumerState<ProgressTodos> {
  final _newTodo = TextEditingController();
  final _todoEdit = TextEditingController();
  String? _editingTodoId;

  @override
  void dispose() {
    _newTodo.dispose();
    _todoEdit.dispose();
    super.dispose();
  }

  Future<void> _move(List<TodoItem> items, int from, int to) async {
    final scope = widget.scope;
    final ids = [for (final item in items) item.id];
    ids.insert(to, ids.removeAt(from));
    await widget.mutate(
      (repo) => repo.reorder(scope.workspaceId, scope.conversationId, ids),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final todos = ref.watch(progressTodosProvider(scope));
    if (todos.hasError) {
      return progressError(
        l,
        todos.error!,
        () => ref.invalidate(progressTodosProvider(scope)),
      );
    }
    if (todos.isLoading) return const CcSpinner(size: 18);
    final items = todos.value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Text(
            l.progressNoTodos,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
        for (var index = 0; index < items.length; index++)
          ProgressTodoRow(
            scope: scope,
            todo: items[index],
            canWrite: widget.canWrite,
            editing: _editingTodoId == items[index].id,
            editController: _todoEdit,
            mutate: widget.mutate,
            scopeIsCurrent: () =>
                mounted &&
                widget.scope == scope &&
                ref.read(activeWorkspaceIdProvider).value == scope.workspaceId,
            onError: widget.onError,
            onEdit: () {
              _todoEdit.text = items[index].content;
              setState(() => _editingTodoId = items[index].id);
            },
            onCloseEdit: () => setState(() => _editingTodoId = null),
            onMoveUp: index == 0 ? null : () => _move(items, index, index - 1),
            onMoveDown: index == items.length - 1
                ? null
                : () => _move(items, index, index + 1),
          ),
        if (widget.canWrite) ...[
          const SizedBox(height: 12),
          CcTextField(
            controller: _newTodo,
            label: l.progressNewTodo,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),
          CcButton(
            size: CcButtonSize.lg,
            onPressed: () async {
              final value = _newTodo.text.trim();
              if (value.isEmpty) return;
              final saved = await widget.mutate((repo) async {
                await repo.append(
                  scope.workspaceId,
                  scope.conversationId,
                  value,
                );
              });
              if (mounted && saved) _newTodo.clear();
            },
            child: Text(l.progressAddTodo),
          ),
        ],
      ],
    );
  }
}
