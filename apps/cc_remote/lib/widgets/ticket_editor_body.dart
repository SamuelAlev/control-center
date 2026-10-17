import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/ticket_creation_options.dart';
import 'package:cc_remote/widgets/ticket_fields_form.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scrollable ticket form; the screen keeps write state and workspace scope.
class TicketEditorBody extends StatelessWidget {
  const TicketEditorBody({
    super.key,
    required this.title,
    required this.description,
    required this.labels,
    required this.priority,
    required this.onPriorityChanged,
    required this.titleInvalid,
    required this.saving,
    required this.canWrite,
    required this.onSave,
    this.providerName,
    this.status,
    this.onStatusChanged,
    this.assignee,
    this.onAssigneeChanged,
    this.agents,
    this.error,
  });

  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController labels;
  final String priority;
  final ValueChanged<String> onPriorityChanged;
  final bool titleInvalid;
  final bool saving;
  final bool canWrite;
  final VoidCallback onSave;
  final String? providerName;
  final String? status;
  final ValueChanged<String>? onStatusChanged;
  final String? assignee;
  final ValueChanged<String?>? onAssigneeChanged;
  final AsyncValue<List<AgentDto>>? agents;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (providerName != null) ...[
          Text(
            l10n.mobileTicketWorkspaceProvider(
              providerName == 'local'
                  ? l10n.mobileTicketProviderLocal
                  : providerName!,
            ),
            style: TextStyle(fontSize: 13, color: t.textSecondary),
          ),
          const SizedBox(height: 16),
        ],
        TicketFieldsForm(
          title: title,
          description: description,
          labels: labels,
          priority: priority,
          enabled: canWrite,
          onPriorityChanged: onPriorityChanged,
          titleError: titleInvalid ? l10n.mobileTicketTitleRequired : null,
        ),
        if (status != null)
          TicketCreationOptions(
            status: status!,
            onStatusChanged: onStatusChanged!,
            assignee: assignee,
            onAssigneeChanged: onAssigneeChanged!,
            agents: agents!,
            enabled: canWrite,
          ),
        if (error != null) ...[
          const SizedBox(height: 20),
          Text(error!, style: TextStyle(color: t.textErrorPrimary)),
        ],
        if (!canWrite) ...[
          const SizedBox(height: 16),
          Text(
            l10n.mobileTicketReadOnly,
            style: TextStyle(color: t.textSecondary),
          ),
        ],
        const SizedBox(height: 24),
        CcButton(
          fullWidth: true,
          size: CcButtonSize.lg,
          loading: saving,
          onPressed: saving || !canWrite ? null : onSave,
          child: Text(status != null ? l10n.mobileTicketCreate : l10n.save),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
