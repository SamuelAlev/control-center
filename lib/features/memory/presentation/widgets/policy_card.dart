part of 'policies_tab.dart';

class _PolicyCard extends StatefulWidget {
  const _PolicyCard({
    required this.policy,
    required this.workspaceId,
    required this.ref,
    this.inactive = false,
  });

  final MemoryPolicy policy;
  final String workspaceId;
  final WidgetRef ref;
  final bool inactive;

  @override
  State<_PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<_PolicyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final policy = widget.policy;

    return Opacity(
      opacity: widget.inactive ? 0.55 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _hovered ? tokens.bgPrimaryHover : tokens.bgPrimary,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      policy.rule.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.body.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (policy.requiredRole != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    MemoryMetaChip(
                      label: policy.requiredRole!.label,
                      icon: AppIcons.user,
                    ),
                  ],
                ],
              ),
              if (policy.sourceFactIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final id in policy.sourceFactIds)
                      MemoryMetaChip(
                        label: id.length > 8 ? id.substring(0, 8) : id,
                        monospace: true,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CcIconButton(
                    icon: AppIcons.pencil,
                    onPressed: () => _editPolicy(context, policy),
                    size: CcButtonSize.sm,
                    tooltip: l10n.edit,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcIconButton(
                    icon: AppIcons.trash2,
                    onPressed: () => _deletePolicy(context, policy),
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.destructive,
                    tooltip: l10n.delete,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    onPressed: () => _toggleActive(policy),
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.secondary,
                    icon: policy.active ? AppIcons.eyeOff : AppIcons.eye,
                    child: Text(
                      policy.active ? l10n.deactivate : l10n.activate,
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

  Future<void> _editPolicy(BuildContext context, MemoryPolicy policy) async {
    final edited = await showCcDialog<MemoryPolicy>(
      context: context,
      builder: (_) => PolicyEditDialog(policy: policy),
    );
    if (edited == null) {
      return;
    }
    final repo = widget.ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deletePolicy(BuildContext context, MemoryPolicy policy) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deletePolicy,
        content: Text(l10n.deletePolicyConfirm),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repo = widget.ref.read(memoryPolicyRepositoryProvider);
    await repo.delete(policy.workspaceId, policy.id);
  }

  Future<void> _toggleActive(MemoryPolicy policy) async {
    final repo = widget.ref.read(memoryPolicyRepositoryProvider);
    await repo.upsert(policy.copyWith(active: !policy.active));
  }
}
