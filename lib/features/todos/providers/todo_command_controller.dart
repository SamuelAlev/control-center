import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/todos/presentation/todo_editor_dialog.dart';
import 'package:control_center/features/todos/providers/todo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a todo list as a GitHub-style markdown checklist.
String todoListToMarkdown(List<TodoItem> items) {
  if (items.isEmpty) {
    return '';
  }
  return items
      .map((t) {
        final box = switch (t.status) {
          TodoStatus.completed => '[x]',
          TodoStatus.inProgress => '[~]',
          TodoStatus.pending => '[ ]',
        };
        return '- $box ${t.content}';
      })
      .join('\n');
}

/// Parses a markdown checklist into `(content, status)` pairs. Non-checklist
/// lines are treated as pending items; blank lines are skipped.
List<({String content, TodoStatus status})> parseTodoMarkdown(String md) {
  final out = <({String content, TodoStatus status})>[];
  for (final rawLine in md.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    // Match "- [ ] text" / "* [x] text" / "[~] text" and bare "text".
    final match = RegExp(r'^[-*]?\s*\[( |x|X|~)\]\s*(.*)$').firstMatch(line);
    if (match != null) {
      final flag = match.group(1);
      final content = match.group(2)!.trim();
      if (content.isEmpty) {
        continue;
      }
      final status = switch (flag) {
        'x' || 'X' => TodoStatus.completed,
        '~' => TodoStatus.inProgress,
        _ => TodoStatus.pending,
      };
      out.add((content: content, status: status));
    } else {
      final content = line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim();
      if (content.isNotEmpty) {
        out.add((content: content, status: TodoStatus.pending));
      }
    }
  }
  return out;
}

/// Handles a user-typed `/todo <subcommand> [args]` command against the active
/// conversation's persisted list. Intercepted by the composer BEFORE the
/// message reaches the agent, so it never triggers a run.
///
/// Subcommands: edit, copy, export, import, append, start, done, drop, rm.
Future<void> handleTodoSlashCommand({
  required WidgetRef ref,
  required BuildContext context,
  required String spaceId,
  required String workspaceId,
  required String args,
}) async {
  final l10n = AppLocalizations.of(context);
  final trimmed = args.trim();
  final spaceIdx = trimmed.indexOf(RegExp(r'\s'));
  final sub = (spaceIdx == -1 ? trimmed : trimmed.substring(0, spaceIdx))
      .toLowerCase();
  final rest = spaceIdx == -1 ? '' : trimmed.substring(spaceIdx + 1).trim();

  final repo = ref.read(todoRepositoryProvider);
  List<TodoItem> current() =>
      ref.read(conversationTodosProvider(spaceId)).asData?.value ??
      const <TodoItem>[];

  void toast(
    String message, {
    CcToastVariant variant = CcToastVariant.neutral,
  }) {
    CcToastScope.maybeOf(context)?.show(message, variant: variant);
  }

  // Resolves a target item by 1-based index or a case-insensitive content
  // substring. Returns null when nothing matches.
  TodoItem? resolve(String selector, List<TodoItem> items) {
    if (items.isEmpty) {
      return null;
    }
    final n = int.tryParse(selector);
    if (n != null) {
      return (n >= 1 && n <= items.length) ? items[n - 1] : null;
    }
    final needle = selector.toLowerCase();
    for (final t in items) {
      if (t.content.toLowerCase().contains(needle)) {
        return t;
      }
    }
    return null;
  }

  switch (sub) {
    case '':
    case 'edit':
      await showTodoEditorDialog(
        context: context,
        ref: ref,
        spaceId: spaceId,
        workspaceId: workspaceId,
      );

    case 'append':
    case 'add':
      if (rest.isEmpty) {
        toast(l10n.todoNeedsText, variant: CcToastVariant.warning);
        return;
      }
      await repo.append(workspaceId, spaceId, rest);
      toast(l10n.todoAdded(rest));

    case 'start':
      final item = resolve(rest, current());
      if (item == null) {
        toast(l10n.todoNotFound, variant: CcToastVariant.warning);
        return;
      }
      await repo.updateStatus(
        workspaceId,
        spaceId,
        item.id,
        TodoStatus.inProgress,
      );
      toast(l10n.todoStarted(item.content));

    case 'done':
    case 'complete':
      final item = resolve(rest, current());
      if (item == null) {
        toast(l10n.todoNotFound, variant: CcToastVariant.warning);
        return;
      }
      await repo.updateStatus(
        workspaceId,
        spaceId,
        item.id,
        TodoStatus.completed,
      );
      toast(l10n.todoCompleted(item.content), variant: CcToastVariant.success);

    case 'drop':
    case 'rm':
    case 'remove':
      if (rest.isEmpty) {
        // Bare drop clears the whole list.
        await repo.clear(workspaceId, spaceId);
        toast(l10n.todoCleared, variant: CcToastVariant.warning);
        return;
      }
      final item = resolve(rest, current());
      if (item == null) {
        toast(l10n.todoNotFound, variant: CcToastVariant.warning);
        return;
      }
      await repo.remove(workspaceId, spaceId, item.id);
      toast(l10n.todoRemoved(item.content));

    case 'copy':
    case 'export':
      final md = todoListToMarkdown(current());
      if (md.isEmpty) {
        toast(l10n.todoNothingToCopy, variant: CcToastVariant.warning);
        return;
      }
      await Clipboard.setData(ClipboardData(text: md));
      toast(l10n.todoCopied(current().length), variant: CcToastVariant.success);

    case 'import':
      if (rest.isEmpty) {
        // No inline markdown → open the editor prefilled with the current list.
        await showTodoEditorDialog(
          context: context,
          ref: ref,
          spaceId: spaceId,
          workspaceId: workspaceId,
        );
        return;
      }
      final parsed = parseTodoMarkdown(rest);
      final now = DateTime.now();
      final items = [
        for (var i = 0; i < parsed.length; i++)
          TodoItem(
            id: '${now.microsecondsSinceEpoch}-$i',
            workspaceId: workspaceId,
            spaceId: spaceId,
            content: parsed[i].content,
            status: parsed[i].status,
            position: i,
            createdAt: now,
            updatedAt: now,
          ),
      ];
      await repo.replaceAll(workspaceId, spaceId, items);
      toast(l10n.todoImported(items.length), variant: CcToastVariant.success);

    default:
      toast(l10n.todoUnknownSubcommand(sub), variant: CcToastVariant.warning);
  }
}
