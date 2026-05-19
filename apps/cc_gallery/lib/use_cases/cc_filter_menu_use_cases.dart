import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcFilterMenu] — a funnel-style filter dropdown: a panel of
/// filter categories, each disclosing a searchable checkbox flyout with
/// per-option population counts.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcFilterMenu`. Selections are
/// stateful, so the interactive cases live inside a file-private
/// [_FilterMenuDemo].

const _path = '[Components]/Inputs';

String _prCount(int count) =>
    count == 1 ? '1 pull request' : '$count pull requests';

String _hiddenCount(int hidden) => hidden == 1
    ? '1 option not matching any pull requests'
    : '$hidden options not matching any pull requests';

/// A self-contained selection harness so the flyouts can toggle values live.
class _FilterMenuDemo extends StatefulWidget {
  const _FilterMenuDemo();

  @override
  State<_FilterMenuDemo> createState() => _FilterMenuDemoState();
}

class _FilterMenuDemoState extends State<_FilterMenuDemo> {
  Set<String> _authors = const {};
  Set<String> _repos = const {};
  Set<String> _statuses = const {};

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final activeCount = _authors.length + _repos.length + _statuses.length;

    return CcFilterMenu(
      semanticLabel: 'Filters',
      searchHint: 'Add filter…',
      optionSearchHint: 'Filter…',
      emptySearchLabel: 'No matches',
      categories: [
        CcFilterCategory(
          id: 'status',
          label: 'Status',
          icon: CcIcons.circleDashed,
          selected: _statuses,
          onChanged: (next) => setState(() => _statuses = next),
          hiddenCountLabel: _hiddenCount,
          options: [
            CcFilterOption(
              value: 'draft',
              label: 'Draft',
              icon: CcIcons.gitPullRequestDraft,
              count: 4,
              countLabel: _prCount(4),
            ),
            CcFilterOption(
              value: 'open',
              label: 'Open',
              icon: CcIcons.gitPullRequestArrow,
              count: 11,
              countLabel: _prCount(11),
            ),
            CcFilterOption(
              value: 'approved',
              label: 'Approved',
              icon: CcIcons.gitPullRequestCreateArrow,
              count: 1,
              countLabel: _prCount(1),
            ),
            CcFilterOption(
              value: 'merged',
              label: 'Merged',
              icon: CcIcons.gitMerge,
              count: 3,
              countLabel: _prCount(3),
            ),
            CcFilterOption(
              value: 'closed',
              label: 'Closed',
              icon: CcIcons.gitPullRequestClosed,
              count: 0,
              countLabel: _prCount(0),
            ),
          ],
        ),
        CcFilterCategory(
          id: 'author',
          label: 'Author',
          icon: CcIcons.user,
          selected: _authors,
          onChanged: (next) => setState(() => _authors = next),
          hiddenCountLabel: _hiddenCount,
          options: [
            CcFilterOption(
              value: 'me',
              label: 'Current user',
              icon: CcIcons.user,
              pinned: true,
              count: 3,
              countLabel: _prCount(3),
            ),
            for (final (login, count) in [
              ('alberto', 1),
              ('bojan', 2),
              ('fabian', 1),
              ('noah', 4),
              ('rene', 2),
              ('red', 0),
              ('sotirios', 0),
            ])
              CcFilterOption(
                value: login,
                label: login,
                leading: CcAvatar(size: 20, initials: login[0].toUpperCase()),
                count: count,
                countLabel: _prCount(count),
              ),
          ],
        ),
        CcFilterCategory(
          id: 'repository',
          label: 'Repository',
          icon: CcIcons.gitBranch,
          selected: _repos,
          onChanged: (next) => setState(() => _repos = next),
          hiddenCountLabel: _hiddenCount,
          options: [
            for (final (repo, count) in [
              ('acme/test-web-app', 11),
              ('acme/test-backend', 3),
              ('acme/test', 5),
              ('acme/test-app', 4),
              ('acme/test-cli', 1),
              ('acme/test-tokens', 0),
            ])
              CcFilterOption(
                value: repo,
                label: repo,
                icon: CcIcons.gitBranch,
                count: count,
                countLabel: _prCount(count),
              ),
          ],
        ),
      ],
      target: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CcIcons.listFilter,
                size: 16,
                color: activeCount > 0 ? t.accent : t.textSecondary,
              ),
              if (activeCount > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$activeCount',
                  style: CcTypography.caption.copyWith(color: t.accent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The full flow: a funnel trigger opening the category panel; hover or click
/// a category to disclose its searchable checkbox flyout. Toggling never
/// closes the menu, zero-count options collapse into the footer summary, and
/// the trigger reports the active criteria count.
@widgetbook.UseCase(name: 'Filter menu', type: CcFilterMenu, path: _path)
Widget ccFilterMenuUseCase(BuildContext context) {
  return const Align(
    alignment: Alignment.topLeft,
    child: Padding(padding: EdgeInsets.all(24), child: _FilterMenuDemo()),
  );
}
