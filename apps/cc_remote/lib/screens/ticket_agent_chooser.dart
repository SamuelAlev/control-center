part of 'ticket_detail_screen.dart';

class _AgentChooser extends StatelessWidget {
  const _AgentChooser({
    required this.agents,
    required this.onPick,
    required this.onCancel,
    required this.acting,
    this.error,
  });

  final List<AgentDto> agents;
  final ValueChanged<AgentDto> onPick;
  final VoidCallback onCancel;
  final bool acting;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (agents.isEmpty)
          CcEmptyState(
            icon: AppIcons.user,
            message: AppLocalizations.of(context).noAgents,
            description: AppLocalizations.of(context).noAgentsDescription,
          ),
        for (final a in agents)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CcCard(
              interactive: true,
              semanticLabel: a.name,
              onPressed: acting ? null : () => onPick(a),
              child: Row(
                children: [
                  Icon(AppIcons.user, size: 18, color: t.fgSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      a.name,
                      style: TextStyle(fontSize: 15, color: t.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (error != null) ...[
          Text(error!, style: TextStyle(color: t.textErrorPrimary)),
          const SizedBox(height: 12),
        ],
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: onCancel,
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ],
    );
  }
}
