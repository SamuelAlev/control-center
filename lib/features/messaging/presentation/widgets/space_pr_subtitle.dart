import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/cap_centered.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_sidebar_status.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One pull request as a space row's subtitle shows it.
typedef SpaceRowPr = ({
  String repoFullName,
  int number,
  PrSidebarStatus status,
  PrChecksStatus checks,
});

/// One entry of the subtitle: a lone pull request, or a stack of them whose
/// layers each target the branch of the one below, bottom first.
@immutable
class SpaceRowPrGroup {
  /// Creates a [SpaceRowPrGroup]. [prs] is never empty.
  SpaceRowPrGroup(List<SpaceRowPr> prs)
    : prs = prs.isEmpty ? throw ArgumentError('Empty') : List.unmodifiable(prs);

  /// Bottom to top. One entry when the pull request is not stacked.
  final List<SpaceRowPr> prs;

  /// Whether this entry collapses a stack.
  bool get isStack => prs.length > 1;

  @override
  bool operator ==(Object other) =>
      other is SpaceRowPrGroup && listEquals(other.prs, prs);

  @override
  int get hashCode => Object.hashAll(prs);
}

/// The pull requests a space row lists under its name, compared by value.
///
/// The linked-PR list is rebuilt on every association or PR refresh and the
/// branch matches on every poller sweep, yet the subtitle rarely changes, so
/// the row repaints only when it does.
@immutable
class SpaceRowPrs {
  /// Creates a [SpaceRowPrs].
  const SpaceRowPrs(this.groups);

  /// Ordered by repository, then by the bottom pull request's number.
  final List<SpaceRowPrGroup> groups;

  /// Whether the space has no pull request.
  bool get isEmpty => groups.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is SpaceRowPrs && listEquals(other.groups, groups);

  @override
  int get hashCode => Object.hashAll(groups);
}

/// Every pull request linked to or branch-matched with a space, projected to
/// what the row's subtitle draws, with each stack folded into one entry.
final spaceRowPrsProvider = Provider.autoDispose.family<SpaceRowPrs, String>((
  ref,
  spaceId,
) {
  return SpaceRowPrs(
    groupSpaceRowPrs(ref.watch(spacePullRequestsProvider(spaceId))),
  );
});

/// Folds [prs] into stacks: within a repository, a pull request whose base
/// is another one's head sits on top of it. Each chain becomes one group,
/// bottom first; where two layers share a parent, the lower number comes
/// first. Groups sort by repository, then by their bottom number.
List<SpaceRowPrGroup> groupSpaceRowPrs(List<PullRequest> prs) {
  final sorted = [...prs]
    ..sort((a, b) {
      final repo = a.repoFullName.compareTo(b.repoFullName);
      return repo != 0 ? repo : a.number.compareTo(b.number);
    });
  String key(String repo, String ref) => '$repo\u0000$ref';
  final byHead = <String, PullRequest>{};
  for (final pr in sorted) {
    byHead.putIfAbsent(key(pr.repoFullName, pr.headRef), () => pr);
  }
  PullRequest? parentOf(PullRequest pr) {
    final parent = byHead[key(pr.repoFullName, pr.baseRef)];
    return identical(parent, pr) ? null : parent;
  }

  final children = <PullRequest, List<PullRequest>>{};
  for (final pr in sorted) {
    if (parentOf(pr) case final parent?) {
      children.putIfAbsent(parent, () => []).add(pr);
    }
  }
  final placed = <PullRequest>{};
  final groups = <List<PullRequest>>[];
  void collect(PullRequest pr, List<PullRequest> into) {
    if (!placed.add(pr)) {
      return;
    }
    into.add(pr);
    for (final child in children[pr] ?? const <PullRequest>[]) {
      collect(child, into);
    }
  }

  void start(PullRequest pr) {
    final group = <PullRequest>[];
    collect(pr, group);
    groups.add(group);
  }

  sorted.where((pr) => parentOf(pr) == null).forEach(start);
  // Only a base cycle leaves a pull request unplaced; it starts its own.
  sorted.where((pr) => !placed.contains(pr)).forEach(start);
  groups.sort((a, b) {
    final repo = a.first.repoFullName.compareTo(b.first.repoFullName);
    return repo != 0 ? repo : a.first.number.compareTo(b.first.number);
  });
  return [
    for (final group in groups)
      SpaceRowPrGroup([
        for (final pr in group)
          (
            repoFullName: pr.repoFullName,
            number: pr.number,
            status: PrSidebarStatus.fromPullRequest(pr)!,
            checks: pr.checksStatus,
          ),
      ]),
  ];
}

/// Space between a glyph and the number beside it.
const double _kGlyphGap = 3;

/// Space either side of the middle dot between entries.
const double _kEntryGap = 6;

/// The second line of a space row: each pull request's state glyph and
/// number, with its checks glyph while it is still open. A stack folds into
/// one entry: the layers glyph, its bottom and top numbers, and the worst
/// checks among its open layers. Entries are separated by a middle dot.
///
/// Inherits the caption style and colour from the row's subtitle slot.
class SpacePrSubtitle extends StatelessWidget {
  /// Creates a [SpacePrSubtitle].
  const SpacePrSubtitle({super.key, required this.prs, required this.selected});

  /// The space's pull requests. Never empty: the row drops the line instead.
  final SpaceRowPrs prs;

  /// On the solid brand fill the status hues lose contrast, so every glyph
  /// takes the fill's foreground, as the old leading badge did.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = DefaultTextStyle.of(context).style;
    final glyphSize = style.fontSize ?? CcTypography.caption.fontSize!;

    // Centred on the digits' cap height, not on the line box: the box's
    // middle depends on the font's ascent and descent and sits below the
    // numbers, so a middle-aligned glyph reads low beside them.
    final fontSize = style.fontSize ?? glyphSize;
    WidgetSpan glyph(IconData icon, Color color) => WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: CapCentered(
        baseline: (glyphSize + fontSize * kCapHeight) / 2,
        child: Icon(
          icon,
          size: glyphSize,
          color: selected ? t.accentOn : color,
        ),
      ),
    );
    WidgetSpan gap(double width) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: SizedBox(width: width),
    );

    final spans = <InlineSpan>[];
    final described = <String>[];
    for (final group in prs.groups) {
      if (spans.isNotEmpty) {
        spans
          ..add(gap(_kEntryGap))
          ..add(const TextSpan(text: '·'))
          ..add(gap(_kEntryGap));
      }
      final status = _groupStatus(group);
      final checks = _checks(group, t, l10n);
      spans
        ..add(
          glyph(group.isStack ? AppIcons.layers : status.icon, status.color),
        )
        ..add(gap(_kGlyphGap))
        // The range is digits around a dash: isolated left to right, or an
        // RTL paragraph would print it top first.
        ..add(
          TextSpan(
            text: group.isStack
                ? '\u2066${group.prs.first.number}–${group.prs.last.number}'
                      '\u2069'
                : '${group.prs.first.number}',
          ),
        );
      if (checks != null) {
        spans
          ..add(gap(_kGlyphGap))
          ..add(glyph(checks.icon, checks.color));
      }
      for (final pr in group.prs) {
        described.add(
          [
            '${pr.repoFullName}#${pr.number}',
            pr.status.label(l10n),
            ?_checks(SpaceRowPrGroup([pr]), t, l10n)?.label,
          ].join(' · '),
        );
      }
    }
    final description = described.join('\n');
    return CcTooltip(
      message: description,
      showDelay: const Duration(milliseconds: 700),
      placement: CcTooltipPlacement.end,
      child: Semantics(
        label: description,
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(children: spans),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// A stack reads as its liveliest layer: open, then draft, then merged.
  /// It is closed only when every layer is.
  static PrSidebarStatus _groupStatus(SpaceRowPrGroup group) {
    final statuses = {for (final pr in group.prs) pr.status};
    for (final status in const [
      PrSidebarStatus.open,
      PrSidebarStatus.draft,
      PrSidebarStatus.merged,
    ]) {
      if (statuses.contains(status)) {
        return status;
      }
    }
    return PrSidebarStatus.closed;
  }

  /// Checks only matter while a PR can still merge. A stack shows its worst
  /// open layer: failing, then running, then passing.
  static ({IconData icon, Color color, String label})? _checks(
    SpaceRowPrGroup group,
    DesignSystemTokens t,
    AppLocalizations l10n,
  ) {
    final checks = {
      for (final pr in group.prs)
        if (pr.status != PrSidebarStatus.merged &&
            pr.status != PrSidebarStatus.closed)
          pr.checks,
    };
    if (checks.contains(PrChecksStatus.failing)) {
      return (
        icon: AppIcons.xCircle,
        color: t.danger,
        label: l10n.checksFailing,
      );
    }
    if (checks.contains(PrChecksStatus.pending)) {
      return (icon: AppIcons.clock3, color: t.warn, label: l10n.checksRunning);
    }
    if (checks.contains(PrChecksStatus.passing)) {
      return (
        icon: AppIcons.checkCircle,
        color: t.success,
        label: l10n.checksPassing,
      );
    }
    return null;
  }
}
