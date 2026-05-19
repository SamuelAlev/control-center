import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The meetings-list toolbar: the live result count, an inline search field and
/// the All / Done / Processing status filter.
///
/// It sits on the canvas above the day sections rather than inside a panel
/// header, so the filters read as page controls (which they are) instead of as
/// chrome belonging to one card. Below ~560px the search field takes its own
/// full-width line above the count and the filter, which is the one arrangement
/// that never clips the segments.
class MeetingToolbar extends StatelessWidget {
  /// Creates a [MeetingToolbar].
  const MeetingToolbar({
    super.key,
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
    this.resultCount,
  });

  /// The active status filter.
  final MeetingListFilter filter;

  /// Controller for the inline search field. The owning screen listens to it
  /// to drive live filtering.
  final TextEditingController searchController;

  /// Invoked when a status segment is chosen.
  final ValueChanged<MeetingListFilter> onFilterChanged;

  /// How many meetings currently match, shown as a mono count. Null hides it.
  final int? resultCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = resultCount;

    final search = CcTextField(
      controller: searchController,
      hintText: l10n.meetingsSearchHint,
      prefix: Icon(AppIcons.search, size: 14, color: context.ds.muted),
    );
    // `fullWidth` makes the track fill its constraints and share them between
    // the three segments, which is what lets the narrow layout give the filter
    // a line of its own instead of overflowing when the labels alone are wider
    // than the viewport.
    CcSegmentedToggle<MeetingListFilter> buildSegments({
      bool fullWidth = false,
    }) => CcSegmentedToggle<MeetingListFilter>(
      value: filter,
      onChanged: onFilterChanged,
      fullWidth: fullWidth,
      // Field height: on the wide layout these sit in the same row as the
      // search field, and a shorter control leaves a visible jog.
      size: CcSegmentedToggleSize.md,
      segments: [
        CcSegment(value: MeetingListFilter.all, label: l10n.meetingsFilterAll),
        CcSegment(
          value: MeetingListFilter.done,
          label: l10n.meetingsFilterDone,
        ),
        CcSegment(
          value: MeetingListFilter.processing,
          label: l10n.meetingsFilterProcessing,
        ),
      ],
    );
    // The count is the only element here that is not a control, so it takes
    // the flexible slot: it ellipsizes (and at the narrowest widths disappears
    // into nothing) rather than pushing the filter segments off the row.
    final countLabel = Expanded(
      child: count == null
          ? const SizedBox.shrink()
          : Text(
              l10n.meetingsCountLabel(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: meetingMono(context, fontSize: 12),
            ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          // Phone-width: the filter gets a full line of its own. Sharing a row
          // with the count only works while the three labels fit beside it —
          // below roughly 400px they do not, and the flexible count had already
          // shrunk to nothing, so there was nothing left to give and the track
          // overflowed the row.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.md),
              if (count != null) ...[
                Row(children: [countLabel]),
                const SizedBox(height: AppSpacing.sm),
              ],
              buildSegments(fullWidth: true),
            ],
          );
        }
        return Row(
          children: [
            countLabel,
            SizedBox(width: 260, child: search),
            const SizedBox(width: AppSpacing.md),
            buildSegments(),
          ],
        );
      },
    );
  }
}
