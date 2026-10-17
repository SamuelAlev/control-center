import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

/// Shared, touch-sized fields for creating or editing a ticket.
class TicketFieldsForm extends StatelessWidget {
  const TicketFieldsForm({
    super.key,
    required this.title,
    required this.description,
    required this.labels,
    required this.priority,
    required this.onPriorityChanged,
    this.titleError,
    this.enabled = true,
  });

  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController labels;
  final String priority;
  final ValueChanged<String> onPriorityChanged;
  final String? titleError;
  final bool enabled;

  static const priorities = ['none', 'urgent', 'high', 'medium', 'low'];

  /// Preserve order while removing blank and duplicate entries.
  static List<String> parseLabels(String text) => text
      .split('\n')
      .map((label) => label.trim())
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList();

  static String priorityLabel(AppLocalizations l10n, String value) =>
      switch (value) {
        'urgent' => l10n.mobileTicketPriorityUrgent,
        'high' => l10n.mobileTicketPriorityHigh,
        'medium' => l10n.mobileTicketPriorityMedium,
        'low' => l10n.mobileTicketPriorityLow,
        'none' => l10n.mobileTicketPriorityNone,
        _ => value,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTextField(
          controller: title,
          label: l10n.mobileTicketTitle,
          readOnly: !enabled,
          autofocus: true,
          textInputAction: TextInputAction.next,
          errorText: titleError,
        ),
        const SizedBox(height: 16),
        CcTextField(
          controller: description,
          label: l10n.mobileTicketDescription,
          hintText: l10n.mobileTicketMarkdownHint,
          minLines: 4,
          maxLines: 10,
          readOnly: !enabled,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.mobileTicketPriority,
          style: TextStyle(color: t.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in priorities)
              CcButton(
                size: CcButtonSize.lg,
                variant: priority == value
                    ? CcButtonVariant.line
                    : CcButtonVariant.secondary,
                onPressed: enabled ? () => onPriorityChanged(value) : null,
                child: Text(priorityLabel(l10n, value)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CcTextField(
          controller: labels,
          label: l10n.mobileTicketLabels,
          readOnly: !enabled,
          hintText: l10n.mobileTicketLabelsHint,
          helperText: l10n.mobileTicketLabelsHelp,
          minLines: 2,
          maxLines: 5,
        ),
      ],
    );
  }
}
