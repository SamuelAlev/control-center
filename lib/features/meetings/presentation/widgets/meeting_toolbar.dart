import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The meetings-list toolbar: an inline search field at the start and the
/// All / Done / Processing status filter at the end.
///
/// It sits on the canvas above the day sections rather than inside a panel
/// header, so the filters read as page controls (which they are) instead of as
/// chrome belonging to one card. Below ~560px the search field takes its own
/// full-width line above the filter, which is the one arrangement that never
/// clips the segments.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          // Phone-width: the filter gets a full line of its own; the three
          // labels do not fit beside the search field.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.md),
              buildSegments(fullWidth: true),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 320, child: search),
            const Spacer(),
            const SizedBox(width: AppSpacing.md),
            buildSegments(),
          ],
        );
      },
    );
  }
}
