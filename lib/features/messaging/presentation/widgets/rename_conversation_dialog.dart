import 'dart:async';

import 'package:cc_domain/features/messaging/domain/ports/conversation_title_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Opens the rename dialog for a conversation titled [initialValue].
///
/// [suggest] asks the workspace's short-task runner for a title; its result
/// only fills the field, so the human still edits or discards it before
/// saving. Returns null for cancellation, an empty title or an unchanged one.
Future<String?> showRenameConversationDialog(
  BuildContext context, {
  required String initialValue,
  required Future<ConversationTitleSuggestion> Function() suggest,
}) async {
  final title = await showCcDialog<String>(
    context: context,
    builder: (_) =>
        RenameConversationDialog(initialValue: initialValue, suggest: suggest),
  );
  if (title == null || title.isEmpty || title == initialValue) {
    return null;
  }
  return title;
}

/// A single title field with a "Generate" action beside it.
class RenameConversationDialog extends StatefulWidget {
  /// Creates a [RenameConversationDialog].
  const RenameConversationDialog({
    required this.initialValue,
    required this.suggest,
    super.key,
  });

  /// The conversation's current title.
  final String initialValue;

  /// Proposes a title on the workspace's short-task runner.
  final Future<ConversationTitleSuggestion> Function() suggest;

  @override
  State<RenameConversationDialog> createState() =>
      _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<RenameConversationDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  var _generating = false;

  /// Why the last generation produced nothing, shown under the field.
  String? _problem;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _generating = true;
      _problem = null;
    });
    String? problem;
    try {
      final result = await widget.suggest();
      final title = result.title;
      if (result.unavailable) {
        problem = l10n.shortTaskUnavailable;
      } else if (result.empty) {
        problem = l10n.conversationTitleNoMessages;
      } else if (title == null) {
        problem = l10n.conversationTitleGenerateFailed;
      } else {
        _controller.value = TextEditingValue(
          text: title,
          selection: TextSelection.collapsed(offset: title.length),
        );
      }
    } on Object {
      problem = l10n.conversationTitleGenerateFailed;
    }
    if (mounted) {
      setState(() {
        _generating = false;
        _problem = problem;
      });
    }
  }

  void _save() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.renameConversation,
      content: SizedBox(
        width: 400,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CcTextField(
                controller: _controller,
                hintText: l10n.untitledConversation,
                autofocus: true,
                enabled: !_generating,
                warnText: _problem,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CcButton(
              variant: CcButtonVariant.secondary,
              icon: AppIcons.sparkles,
              loading: _generating,
              onPressed: _generating ? null : () => unawaited(_generate()),
              child: Text(l10n.conversationTitleGenerate),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _generating ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}
