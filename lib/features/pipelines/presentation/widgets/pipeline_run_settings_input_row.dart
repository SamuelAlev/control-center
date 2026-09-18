part of 'pipeline_run_settings_dialog.dart';

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.input,
    required this.onEdit,
    required this.onDelete,
  });

  final PipelineInput input;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  input.required ? '${input.label} *' : input.label,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${input.key} · ${input.type.name}',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          CcIconButton(
            icon: AppIcons.pencil,
            size: CcButtonSize.sm,
            tooltip: l10n.edit,
            onPressed: onEdit,
          ),
          CcIconButton(
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.delete,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
