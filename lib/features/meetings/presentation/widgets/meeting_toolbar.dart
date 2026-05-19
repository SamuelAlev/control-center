import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The meetings-list panel toolbar: a scope label, an inline search
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
            child: CcTextField(
              controller: searchController,
              hintText: l10n.meetingsSearchHint,
              prefix: Icon(LucideIcons.search, size: 14, color: ds.muted),
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
