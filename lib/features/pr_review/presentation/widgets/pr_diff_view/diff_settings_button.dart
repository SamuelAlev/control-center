import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The diff-settings dropdown: a sliders trigger opening a panel with the
/// split/unified view-mode picker plus the persisted diff toggles (file
/// tree, line wrapping, code ligatures).
class DiffSettingsButton extends ConsumerStatefulWidget {
  /// Creates a [DiffSettingsButton].
  const DiffSettingsButton({
    super.key,
    required this.splitView,
    required this.onSplitViewChanged,
    required this.treeVisible,
    required this.onTreeVisibleChanged,
  });

  /// Whether split (side-by-side) view is active.
  final bool splitView;

  /// Called when the view mode changes.
  final ValueChanged<bool> onSplitViewChanged;

  /// Whether the file-tree sidebar is shown.
  final bool treeVisible;

  /// Called when the file-tree toggle changes.
  final ValueChanged<bool> onTreeVisibleChanged;

  @override
  ConsumerState<DiffSettingsButton> createState() => _DiffSettingsButtonState();
}

class _DiffSettingsButtonState extends ConsumerState<DiffSettingsButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wrapLines =
        ref.watch(diffOverflowModeProvider) == DiffOverflowMode.wrap;
    final ligatures = ref.watch(fontSettingsProvider).codeFontLigatures;
    final splitView = widget.splitView;
    return CcPopover(
      controller: _controller,
      // The trigger is a real icon button, so it owns the tap and the hover.
      // CcPopover's wrapper would cover that wash and fight the gesture.
      toggleOnTargetTap: false,
      targetAnchor: AlignmentDirectional.bottomEnd,
      followerAnchor: AlignmentDirectional.topEnd,
      semanticLabel: l10n.diffViewSettings,
      target: CcIconButton(
        icon: AppIcons.slidersHorizontal,
        size: CcButtonSize.sm,
        variant: CcButtonVariant.ghost,
        tooltip: l10n.diffViewSettings,
        onPressed: _controller.toggle,
      ),
      overlayBuilder: (context, _) => SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: _ViewModeOption(
                      icon: AppIcons.columns,
                      label: l10n.splitViewLabel,
                      tooltip: l10n.splitDiff,
                      active: splitView,
                      onTap: () => widget.onSplitViewChanged(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ViewModeOption(
                      icon: AppIcons.alignJustify,
                      label: l10n.unifiedViewLabel,
                      tooltip: l10n.unifiedDiff,
                      active: !splitView,
                      onTap: () => widget.onSplitViewChanged(false),
                    ),
                  ),
                ],
              ),
            ),
            const CcDivider(),
            const SizedBox(height: AppSpacing.xs),
            _SettingToggleRow(
              label: l10n.treeLabel,
              value: widget.treeVisible,
              onChanged: widget.onTreeVisibleChanged,
            ),
            _SettingToggleRow(
              label: l10n.wrapLines,
              value: wrapLines,
              onChanged: (v) => ref
                  .read(diffOverflowModeProvider.notifier)
                  .setMode(v ? DiffOverflowMode.wrap : DiffOverflowMode.scroll),
            ),
            _SettingToggleRow(
              label: l10n.codeFontLigatures,
              value: ligatures,
              onChanged: (v) => ref
                  .read(fontSettingsProvider.notifier)
                  .setCodeFontLigatures(enabled: v),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// One of the two view-mode buttons at the top of the settings panel.
class _ViewModeOption extends StatelessWidget {
  const _ViewModeOption({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = active ? t.textPrimary : t.textTertiary;
    return CcTooltip(
      message: tooltip,
      child: CcTappable(
        onPressed: active ? null : onTap,
        builder: (context, states) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? t.bgSecondary : const Color(0x00000000),
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadii.pill),
            ),
            border: Border.all(
              color: active ? t.borderPrimary : t.borderSecondary,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: fg,
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

/// A label + switch row for one persisted diff setting.
class _SettingToggleRow extends StatelessWidget {
  const _SettingToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: t.textPrimary),
            ),
          ),
          CcSwitch(value: value, onChanged: onChanged, semanticLabel: label),
        ],
      ),
    );
  }
}
