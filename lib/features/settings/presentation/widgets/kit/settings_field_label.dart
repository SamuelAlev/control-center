part of 'settings_field.dart';

class _LabelBlock extends StatelessWidget {
  const _LabelBlock({
    required this.label,
    required this.description,
    required this.optional,
    required this.badge,
  });

  final String label;
  final String? description;
  final bool optional;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: CcTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            if (optional)
              Text(
                l10n.settingsFieldOptional,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ?badge,
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: CcTypography.caption.copyWith(
              color: tokens.textTertiary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}
