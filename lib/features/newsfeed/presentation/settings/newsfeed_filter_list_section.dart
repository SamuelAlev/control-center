import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Newsfeed: status of the host-cached ad-block filter lists
/// (rule counts, last update, manual refresh). Only shown while content
/// blocking is on.
class NewsfeedFilterListSection extends ConsumerWidget {
  /// Creates a [NewsfeedFilterListSection].
  const NewsfeedFilterListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filterListUpdateProvider);
    return _FilterListStatus(state: state);
  }
}

class _FilterListStatus extends ConsumerWidget {
  const _FilterListStatus({required this.state});

  final FilterListUpdateState state;

  String _lastUpdatedLabel(AppLocalizations l10n) {
    if (state.lastSuccess == null) {
      return l10n.bundledDefaultsNeverUpdated;
    }
    final ago = DateTime.now().difference(state.lastSuccess!);
    if (ago.inDays > 0) {
      return l10n.updatedDaysAgo(ago.inDays);
    } else if (ago.inHours > 0) {
      return l10n.updatedHoursAgo(ago.inHours);
    } else if (ago.inMinutes > 0) {
      return l10n.updatedMinutesAgo(ago.inMinutes);
    }
    return l10n.updatedJustNow;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isUpdating = state.isUpdating;
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.filterLists,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      headerPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 8),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.lastSuccess == null)
            Text(
              _lastUpdatedLabel(l10n),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            )
          else
            AppTimestamp(
              dateTime: state.lastSuccess!,
              child: Text(
                _lastUpdatedLabel(l10n),
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ),
          const SizedBox(width: 8),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            loading: isUpdating,
            icon: AppIcons.refreshCw,
            onPressed: isUpdating
                ? null
                : () => ref.read(filterListUpdateProvider.notifier).refresh(),
            child: Text(l10n.checkForUpdates),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _CountChip(
                  icon: AppIcons.cookie,
                  label: l10n.cookieRulesCount(state.cookieHidingRules),
                ),
                _CountChip(
                  icon: AppIcons.shield,
                  label: l10n.adRulesCount(state.adHidingRules),
                ),
                _CountChip(
                  icon: AppIcons.globe,
                  label: l10n.networkBlockCount(state.networkBlockRules),
                ),
                _CountChip(
                  icon: AppIcons.link,
                  label: l10n.trackingParamsCount(state.removeParamsCount),
                ),
              ],
            ),
          ),
          if (state.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final error in state.errors)
                    Text(
                      error,
                      style: CcTypography.caption.copyWith(
                        color: t.textErrorPrimary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: t.fgTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: CcTypography.caption.copyWith(
              color: t.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
