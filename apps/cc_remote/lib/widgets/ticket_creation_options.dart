import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace's creation status and optional agent assignment.
class TicketCreationOptions extends StatelessWidget {
  const TicketCreationOptions({
    super.key,
    required this.status,
    required this.onStatusChanged,
    required this.assignee,
    required this.onAssigneeChanged,
    required this.agents,
    this.enabled = true,
  });

  final String status;
  final ValueChanged<String> onStatusChanged;
  final String? assignee;
  final ValueChanged<String?> onAssigneeChanged;
  final AsyncValue<List<AgentDto>> agents;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(l10n.status, style: TextStyle(color: t.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in ['open', 'backlog'])
              CcButton(
                size: CcButtonSize.lg,
                variant: status == choice
                    ? CcButtonVariant.line
                    : CcButtonVariant.secondary,
                onPressed: enabled ? () => onStatusChanged(choice) : null,
                child: Text(
                  choice == 'open' ? l10n.statusOpen : l10n.statusBacklog,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.assign, style: TextStyle(color: t.textSecondary)),
        const SizedBox(height: 8),
        if (agents.isLoading)
          const CcSpinner(size: 20)
        else if (agents.hasError)
          Text(
            agents.error.toString(),
            style: TextStyle(color: t.textErrorPrimary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CcButton(
                size: CcButtonSize.lg,
                variant: assignee == null
                    ? CcButtonVariant.line
                    : CcButtonVariant.secondary,
                onPressed: enabled ? () => onAssigneeChanged(null) : null,
                child: Text(l10n.mobileTicketUnassigned),
              ),
              for (final agent in agents.value ?? <AgentDto>[])
                CcButton(
                  size: CcButtonSize.lg,
                  variant: assignee == agent.id
                      ? CcButtonVariant.line
                      : CcButtonVariant.secondary,
                  onPressed: enabled ? () => onAssigneeChanged(agent.id) : null,
                  child: Text(agent.name),
                ),
            ],
          ),
      ],
    );
  }
}
