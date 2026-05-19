import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/todos/providers/todo_command_controller.dart';
import 'package:control_center/features/todos/providers/todo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a modal editor for the active conversation's todo list.
///
/// The list is presented as an editable markdown checklist (`- [ ] item`,
/// `- [x] done`, `- [~] in progress`). On save it is parsed and written back
/// via `todos.replaceAll`. Used by `/todo edit` and `/todo import`.
Future<void> showTodoEditorDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String channelId,
  required String workspaceId,
}) async {
  final l10n = AppLocalizations.of(context);
  final current =
      ref.read(conversationTodosProvider(channelId)).asData?.value ??
      const <TodoItem>[];
  final controller = TextEditingController(text: todoListToMarkdown(current));

  await showCcDialog<void>(
    context: context,
    builder: (context) {
      final t = context.designSystem ?? DesignSystemTokens.light();
      return CcDialog(
        title: l10n.todoEditorTitle,
        onClose: () => Navigator.of(context).pop(),
        maxWidth: 560,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.todoEditorHint,
              style: TextStyle(color: t.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            // A multiline editor. Wrapped in a transparent Material so the
            // Material TextField resolves its ancestor inside the off-Material
            // dialog overlay.
            Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: AppRadii.brMd,
                  border: Border.all(color: t.borderPrimary),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: CcTextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 6,
                    maxLines: 16,
                    textStyle: CcFonts.code(
                      textStyle: TextStyle(color: t.textPrimary, fontSize: 13),
                      family: context.ccTheme?.monoFontFamily,
                    ),
                    chromeless: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () async {
              final parsed = parseTodoMarkdown(controller.text);
              final now = DateTime.now();
              final items = [
                for (var i = 0; i < parsed.length; i++)
                  TodoItem(
                    id: '${now.microsecondsSinceEpoch}-$i',
                    workspaceId: workspaceId,
                    conversationId: channelId,
                    content: parsed[i].content,
                    status: parsed[i].status,
                    position: i,
                    createdAt: now,
                    updatedAt: now,
                  ),
              ];
              await ref
                  .read(todoRepositoryProvider)
                  .replaceAll(workspaceId, channelId, items);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      );
    },
  );
  controller.dispose();
}
