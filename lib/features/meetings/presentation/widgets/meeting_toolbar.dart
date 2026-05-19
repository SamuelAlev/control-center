import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/segmented_toggle.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The meetings-list panel toolbar: a scope label, an inline forui search
/// field, and the All / Done / Processing status [SegmentedToggle].
class MeetingToolbar extends StatelessWidget {
  /// Creates a [MeetingToolbar].
  const MeetingToolbar({
    super.key,
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
  });

  /// The active status filter.
  final MeetingListFilter filter;

  /// Controller for the inline search field. The owning screen listens to it
  /// to drive live filtering.
  final TextEditingController searchController;

  /// Invoked when a status segment is chosen.
  final ValueChanged<MeetingListFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ds.borderSecondary)),
      ),
      child: Row(
        children: [
          Text(
            l10n.meetingsScopeAll,
            style: TextStyle(fontSize: 13, color: ds.fg),
          ),
          const Spacer(),
          SizedBox(
            width: 240,
            child: FTextField(
              control: FTextFieldControl.managed(controller: searchController),
              hint: l10n.meetingsSearchHint,
              size: FTextFieldSizeVariant.sm,
              prefixBuilder: (context, style, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(LucideIcons.search, size: 14, color: ds.muted),
              ),
              clearable: (value) => value.text.isNotEmpty,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SegmentedToggle<MeetingListFilter>(
            value: filter,
            onChanged: onFilterChanged,
            segments: [
              (value: MeetingListFilter.all, label: l10n.meetingsFilterAll),
              (value: MeetingListFilter.done, label: l10n.meetingsFilterDone),
              (
                value: MeetingListFilter.processing,
                label: l10n.meetingsFilterProcessing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
