import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All / Open / Merged / Closed control for a profile PR queue.
///
/// Full-bleed canvas so rows sliding under the pinned sliver cannot peek
/// through the page gutters. Horizontal padding lives inside the fill.
class ProfilePrQueueFilter extends ConsumerWidget {
  /// Creates the profile PR state filter.
  const ProfilePrQueueFilter({
    super.key,
    required this.profileKey,
    required this.filter,
    required this.counts,
  });

  /// Stable key for the profile-local filter provider.
  final String profileKey;

  /// Currently selected state filter.
  final ProfilePrStateFilter filter;

  /// Per-state counts shown on each segment.
  final ({int all, int open, int merged, int closed}) counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: tokens.canvas,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: CcSegmentedToggle<ProfilePrStateFilter>(
            value: filter,
            semanticLabel: l10n.profilePrStateFilterLabel,
            onChanged: (next) => ref
                .read(profilePrStateFilterProvider(profileKey).notifier)
                .set(next),
            segments: [
              CcSegment(
                value: ProfilePrStateFilter.all,
                label: '${l10n.all} ${counts.all}',
              ),
              CcSegment(
                value: ProfilePrStateFilter.open,
                label: '${l10n.openLabel} ${counts.open}',
              ),
              CcSegment(
                value: ProfilePrStateFilter.merged,
                label: '${l10n.merged} ${counts.merged}',
              ),
              CcSegment(
                value: ProfilePrStateFilter.closed,
                label: '${l10n.closed} ${counts.closed}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
