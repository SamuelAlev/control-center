import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The display-options popover shared by the PR queue and the inbox (one
/// identical popover, one shared store): grouping and ordering selects, draft
/// visibility, the recently-merged window, and the display-property chips
/// controlling what each PR row renders. Grouping, drafts, the merged window,
/// and properties persist across restarts; ordering mirrors the queue
/// toolbar's sort segment (same provider) and drives the inbox's default row
/// order.
///
/// The popover target is a real [CcIconButton] matching the rest of the
/// toolbar (filter, refresh). The popover is driven by an explicit controller
/// with `toggleOnTargetTap` off: `CcPopover`'s own target `CcTappable` would
/// otherwise wrap the button, forward no hover states, and two recognizers
/// would fight over the tap.
class PrDisplayOptionsButton extends StatefulWidget {
  /// Creates a [PrDisplayOptionsButton].
  const PrDisplayOptionsButton({super.key});

  @override
  State<PrDisplayOptionsButton> createState() => _PrDisplayOptionsButtonState();
}

class _PrDisplayOptionsButtonState extends State<PrDisplayOptionsButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      target: CcIconButton(
        icon: AppIcons.slidersHorizontal,
        tooltip: l10n.prDisplayOptions,
        onPressed: _controller.toggle,
      ),
      overlayBuilder: (context, _) => const _DisplayOptionsPanel(),
    );
  }
}

class _DisplayOptionsPanel extends ConsumerWidget {
  const _DisplayOptionsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final prefs = ref.watch(prListDisplayPrefsProvider);
    final sort = ref.watch(prListSortProvider);

    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectRow<PrListGrouping>(
              label: l10n.prDisplayGrouping,
              value: prefs.grouping,
              options: [
                CcSelectOption(
                  value: PrListGrouping.repository,
                  label: l10n.prGroupingRepository,
                ),
                CcSelectOption(
                  value: PrListGrouping.author,
                  label: l10n.prGroupingAuthor,
                ),
                CcSelectOption(
                  value: PrListGrouping.status,
                  label: l10n.prGroupingStatus,
                ),
                CcSelectOption(
                  value: PrListGrouping.none,
                  label: l10n.prGroupingNone,
                ),
              ],
              onChanged: (g) =>
                  ref.read(prListDisplayPrefsProvider.notifier).setGrouping(g),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SelectRow<PrListSort>(
              label: l10n.prDisplayOrdering,
              value: sort,
              options: [
                CcSelectOption(
                  value: PrListSort.recent,
                  label: l10n.sortRecent,
                ),
                CcSelectOption(
                  value: PrListSort.oldest,
                  label: l10n.sortOldest,
                ),
                CcSelectOption(
                  value: PrListSort.largest,
                  label: l10n.sortLargest,
                ),
              ],
              onChanged: (s) => ref.read(prListSortProvider.notifier).set(s),
            ),
            const SizedBox(height: AppSpacing.md),
            const CcDivider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.prDisplayShowDrafts,
                    style: CcTypography.bodySm.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                CcSwitch(
                  value: prefs.showDrafts,
                  semanticLabel: l10n.prDisplayShowDrafts,
                  onChanged: (v) => ref
                      .read(prListDisplayPrefsProvider.notifier)
                      .setShowDrafts(showDrafts: v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const CcDivider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.prDisplayMergedWindow,
              style: CcTypography.label.copyWith(color: tokens.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedToggle<PrMergedWindow>(
              segments: [
                (
                  value: PrMergedWindow.day,
                  label: l10n.prDisplayMergedWindowDay,
                ),
                (
                  value: PrMergedWindow.week,
                  label: l10n.prDisplayMergedWindowWeek,
                ),
                (
                  value: PrMergedWindow.month,
                  label: l10n.prDisplayMergedWindowMonth,
                ),
              ],
              value: prefs.mergedWindow,
              onChanged: (w) => ref
                  .read(prListDisplayPrefsProvider.notifier)
                  .setMergedWindow(w),
            ),
            const SizedBox(height: AppSpacing.md),
            const CcDivider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.prDisplayProperties,
              style: CcTypography.label.copyWith(color: tokens.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final property in PrRowProperty.values)
                  CcChip(
                    label: _propertyLabel(l10n, property),
                    selected: prefs.properties.contains(property),
                    onTap: () => ref
                        .read(prListDisplayPrefsProvider.notifier)
                        .toggleProperty(property),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _propertyLabel(AppLocalizations l10n, PrRowProperty property) =>
      switch (property) {
        PrRowProperty.repository => l10n.prPropertyRepository,
        PrRowProperty.id => l10n.prPropertyId,
        PrRowProperty.branch => l10n.prPropertyBranch,
        PrRowProperty.updated => l10n.prPropertyUpdated,
        PrRowProperty.author => l10n.prPropertyAuthor,
        PrRowProperty.checks => l10n.prPropertyChecks,
        PrRowProperty.diff => l10n.prPropertyDiff,
        PrRowProperty.comments => l10n.prPropertyComments,
      };
}

/// A dense "label left, select right" row for the popover.
class _SelectRow<T> extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<CcSelectOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
          ),
        ),
        SizedBox(
          width: 160,
          child: CcSelect<T>(
            options: options,
            value: value,
            semanticLabel: label,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
