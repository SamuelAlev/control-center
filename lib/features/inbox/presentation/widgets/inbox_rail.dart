import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_section_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/count_rail_item.dart';
import 'package:flutter/widgets.dart';

/// The inbox's left rail: one entry per section with its live count. Clicking
/// an entry scrolls the section list to that card and the highlight tracks
/// the scroll position (scrollspy) so the active entry always mirrors the
/// section at the top of the viewport (the sections themselves are the single
/// source of truth; the rail is pure navigation).
class InboxRail extends StatelessWidget {
  /// Creates an [InboxRail].
  const InboxRail({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  /// Item count per section.
  final Map<PrInboxSection, int> counts;

  /// The currently-active section — the one at the top of the scroll
  /// viewport (highlight only; sections all stay visible).
  final PrInboxSection? selected;

  /// Invoked with the tapped section.
  final ValueChanged<PrInboxSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in PrInboxSection.values)
          CountRailItem(
            label: inboxSectionLabel(l10n, section),
            count: counts[section] ?? 0,
            selected: section == selected,
            onPressed: () => onSelect(section),
          ),
      ],
    );
  }
}
