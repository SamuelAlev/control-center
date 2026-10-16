import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/references/pr_reference_chip.dart';
import 'package:control_center/features/pr_review/providers/pr_reference_preview_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

PullRequest _pr({
  bool isDraft = false,
  PrState state = PrState.open,
  DateTime? mergedAt,
}) => PullRequest(
  id: 1,
  number: 1,
  title: 'Test PR',
  body: '',
  state: state,
  isDraft: isDraft,
  author: null,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  repoFullName: 'owner/repo',
  htmlUrl: '',
  mergedAt: mergedAt,
);

void main() {
  for (final (name, pr, icon, variant) in [
    ('open', _pr(), AppIcons.gitPullRequest, CcBadgeVariant.success),
    (
      'open draft',
      _pr(isDraft: true),
      AppIcons.gitPullRequestDraft,
      CcBadgeVariant.neutral,
    ),
    (
      'closed',
      _pr(state: PrState.closed),
      AppIcons.gitPullRequestClosed,
      CcBadgeVariant.danger,
    ),
    (
      'closed draft',
      _pr(state: PrState.closed, isDraft: true),
      AppIcons.gitPullRequestClosed,
      CcBadgeVariant.danger,
    ),
    (
      'merged without a timestamp',
      _pr(state: PrState.merged),
      AppIcons.gitMerge,
      CcBadgeVariant.brand,
    ),
    (
      'merged with a retained draft flag',
      _pr(state: PrState.merged, isDraft: true),
      AppIcons.gitMerge,
      CcBadgeVariant.brand,
    ),
    (
      'REST closed state with a merge timestamp',
      _pr(state: PrState.closed, mergedAt: DateTime(2024)),
      AppIcons.gitMerge,
      CcBadgeVariant.brand,
    ),
    (
      'merge timestamp with a retained draft flag',
      _pr(isDraft: true, mergedAt: DateTime(2024)),
      AppIcons.gitMerge,
      CcBadgeVariant.brand,
    ),
  ]) {
    testWidgets('$name has matching status, tint and accessible icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          Row(
            children: [
              PrStatusBadge(pr: pr),
              PrStatusIcon(pr: pr),
            ],
          ),
        ),
      );
      final context = tester.element(find.byType(PrStatusBadge));
      final l10n = AppLocalizations.of(context);
      final label = switch (variant) {
        CcBadgeVariant.neutral => l10n.draft,
        CcBadgeVariant.success => l10n.openStatus,
        CcBadgeVariant.danger => l10n.closed,
        _ => l10n.merged,
      };
      expect(find.text(label), findsOneWidget);
      expect(tester.widget<CcBadge>(find.byType(CcBadge)).variant, variant);
      final renderedIcon = tester.widget<Icon>(find.byIcon(icon));
      expect(renderedIcon.semanticLabel, label);
      expect(tester.widget<CcTooltip>(find.byType(CcTooltip)).message, label);
      final tokens = context.designSystem!;
      expect(renderedIcon.color, switch (variant) {
        CcBadgeVariant.neutral => tokens.textTertiary,
        CcBadgeVariant.success => tokens.fgSuccessPrimary,
        CcBadgeVariant.danger => tokens.fgErrorPrimary,
        _ => tokens.fgMergedPrimary,
      });
    });
  }

  for (final (state, isMerged, icon) in [
    ('open', false, AppIcons.gitPullRequestDraft),
    ('closed', false, AppIcons.gitPullRequestClosed),
    ('closed', true, AppIcons.gitMerge),
  ]) {
    testWidgets(
      'reference chip respects $state / merged=$isMerged over draft',
      (tester) async {
        const key = PrReferenceKey(owner: 'owner', repo: 'repo', number: 1);
        await tester.pumpWidget(
          testWrap(
            ProviderScope(
              overrides: [
                prReferencePreviewProvider(key).overrideWith(
                  (ref) async => PrPreview(
                    title: 'Test PR',
                    state: state,
                    isDraft: true,
                    isMerged: isMerged,
                    htmlUrl: '',
                  ),
                ),
              ],
              child: const PrReferenceChip(
                reference: GitHubPrReference(
                  owner: 'owner',
                  repo: 'repo',
                  number: 1,
                ),
                currentOwner: 'owner',
                currentRepo: 'repo',
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(icon), findsOneWidget);
        final context = tester.element(find.byType(PrReferenceChip));
        final l10n = AppLocalizations.of(context);
        final label = isMerged
            ? l10n.merged
            : state == 'closed'
            ? l10n.closed
            : l10n.draft;
        expect(tester.widget<CcTooltip>(find.byType(CcTooltip)).message, label);
      },
    );
  }
}
