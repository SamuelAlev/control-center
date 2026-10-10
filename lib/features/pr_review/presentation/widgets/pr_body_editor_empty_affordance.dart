part of 'pr_body_editor.dart';

/// [PrBodyEditor]'s empty-body read state.
extension _PrBodyEditorEmptyAffordance on _PrBodyEditorState {
  /// The empty-body read state when the user may edit: the
  /// "No description provided." placeholder paired with an always-visible
  /// "Add a description" action. Tapping anywhere opens the editor.
  Widget _buildEmptyAffordance(BuildContext context, DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: CcTappable(
        focusNode: _editButtonFocus,
        onPressed: _startEdit,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.noDescriptionProvided,
                style: CcTypography.body.copyWith(color: t.textTertiary),
              ),
              const SizedBox(width: 12),
              Icon(AppIcons.pencil, size: 13, color: t.textBrandPrimary),
              const SizedBox(width: 5),
              Text(
                l10n.addDescription,
                style: CcTypography.body.copyWith(
                  color: t.textBrandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
