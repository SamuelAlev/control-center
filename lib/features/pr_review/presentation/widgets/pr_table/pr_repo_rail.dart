import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:control_center/shared/widgets/count_rail_item.dart';
import 'package:flutter/widgets.dart';

/// One rail entry: a repo and its (filtered) PR count.
typedef PrRepoRailEntry = ({Repo repo, int count});

/// The repo-grouped PR table's left rail — the inbox rail keyed by repository:
/// one entry per repo with its live PR count. Clicking an entry scrolls the
/// section list to that repo's card (the sections are the source of truth; the
/// rail is pure navigation and the always-complete repo map).
class PrRepoRail extends StatelessWidget {
  /// Creates a [PrRepoRail].
  const PrRepoRail({
    super.key,
    required this.entries,
    required this.selectedRepoId,
    required this.onSelect,
  });

  /// The repos to list, in display order, each with its count.
  final List<PrRepoRailEntry> entries;

  /// The last-jumped-to repo id (highlight only; every section stays visible).
  final String? selectedRepoId;

  /// Invoked with the tapped repo id.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          CountRailItem(
            label: entry.repo.fullName,
            count: entry.count,
            selected: entry.repo.id == selectedRepoId,
            onPressed: () => onSelect(entry.repo.id),
          ),
      ],
    );
  }
}
