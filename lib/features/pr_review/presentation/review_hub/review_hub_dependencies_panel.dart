import 'package:cc_domain/features/pr_review/domain/services/lockfile_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// How many rows of one group (added / removed / changed) are listed before
/// the remainder is collapsed. A lockfile regeneration routinely moves
/// thousands of packages, which would otherwise build thousands of rows for a
/// reviewer who stopped reading at the first screen.
const int _kGroupRowCap = 25;

/// Every lockfile this PR touched, and what moved inside it — the "did this
/// change pull in a new dependency, or jump a major version?" view.
class ReviewHubDependenciesPanel extends StatelessWidget {
  /// Creates a [ReviewHubDependenciesPanel].
  const ReviewHubDependenciesPanel({super.key, required this.diffs});

  /// One entry per changed lockfile. A monorepo routinely changes several.
  final List<PrDependencyDiff> diffs;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final changed = diffs.where((d) => !d.isEmpty).toList();
    if (changed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.reviewHubDepsNone,
            style: TextStyle(color: ds.textTertiary, fontSize: 13),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < changed.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 14),
            const CcDivider(),
            const SizedBox(height: 14),
          ],
          _lockfile(ds, l10n, changed[i]),
        ],
      ],
    );
  }

  Widget _lockfile(
    DesignSystemTokens ds,
    AppLocalizations l10n,
    PrDependencyDiff entry,
  ) {
    final diff = entry.diff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.box, size: 12, color: ds.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.filePath,
                style: CcFonts.code(
                  textStyle: TextStyle(
                    color: ds.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _chip(
              ds,
              entry.ecosystem.wireName,
              color: ds.accent,
              background: ds.accentSoft,
            ),
          ],
        ),
        // A hand-rolled parser's output is labelled rather than presented as
        // precise: "we could not fully guarantee this" is a different claim
        // from "this is what changed".
        if (diff.bestEffort) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.info, size: 11, color: ds.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reviewHubDepsBestEffort,
                  style: TextStyle(color: ds.textTertiary, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
        if (diff.added.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader(ds, l10n.reviewHubDepsAdded),
          const SizedBox(height: 6),
          ..._capped(
            entry,
            l10n,
            ds,
            diff.added.entries
                .map(
                  (e) => _versionRow(
                    ds,
                    e.key,
                    e.value,
                    icon: AppIcons.plus,
                    iconColor: ds.success,
                  ),
                )
                .toList(),
          ),
        ],
        if (diff.removed.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader(ds, l10n.reviewHubDepsRemoved),
          const SizedBox(height: 6),
          ..._capped(
            entry,
            l10n,
            ds,
            diff.removed.entries
                .map(
                  (e) => _versionRow(
                    ds,
                    e.key,
                    e.value,
                    icon: AppIcons.minus,
                    iconColor: ds.danger,
                  ),
                )
                .toList(),
          ),
        ],
        if (diff.upgraded.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader(ds, l10n.reviewHubDepsUpgraded),
          const SizedBox(height: 6),
          ..._capped(
            entry,
            l10n,
            ds,
            diff.upgraded.map((u) => _upgradeRow(ds, l10n, u)).toList(),
          ),
        ],
      ],
    );
  }

  /// Trims [rows] to [_kGroupRowCap] and appends a subdued count of what was
  /// left out, so a truncated list never passes for a complete one.
  List<Widget> _capped(
    PrDependencyDiff entry,
    AppLocalizations l10n,
    DesignSystemTokens ds,
    List<Widget> rows,
  ) {
    if (rows.length <= _kGroupRowCap) {
      return rows;
    }
    final hidden = rows.length - _kGroupRowCap;
    return [
      ...rows.take(_kGroupRowCap),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n.reviewHubImpactMore(hidden, entry.filePath),
          style: TextStyle(color: ds.textTertiary, fontSize: 11),
        ),
      ),
    ];
  }

  Widget _sectionHeader(DesignSystemTokens ds, String label) => Text(
    label,
    style: TextStyle(
      color: ds.textTertiary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _versionRow(
    DesignSystemTokens ds,
    String name,
    String version, {
    required IconData icon,
    required Color iconColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 11, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: CcFonts.code(
              textStyle: TextStyle(color: ds.textPrimary, fontSize: 11),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          version,
          style: CcFonts.code(
            textStyle: TextStyle(color: ds.textSecondary, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Widget _upgradeRow(
    DesignSystemTokens ds,
    AppLocalizations l10n,
    DependencyUpgrade upgrade,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(AppIcons.arrowRight, size: 11, color: ds.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            upgrade.name,
            style: CcFonts.code(
              textStyle: TextStyle(color: ds.textPrimary, fontSize: 11),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${upgrade.from} → ${upgrade.to}',
          style: CcFonts.code(
            textStyle: TextStyle(color: ds.textSecondary, fontSize: 11),
          ),
        ),
        if (upgrade.majorBump) ...[
          const SizedBox(width: 6),
          _chip(
            ds,
            l10n.reviewHubDepsMajorBump,
            color: ds.warn,
            background: ds.warnSoft,
            icon: AppIcons.alertTriangle,
          ),
        ],
      ],
    ),
  );

  Widget _chip(
    DesignSystemTokens ds,
    String label, {
    required Color color,
    required Color background,
    IconData? icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
