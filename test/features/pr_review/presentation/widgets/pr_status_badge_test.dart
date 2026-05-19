import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PR state is surfaced by TWO widgets with a deliberate split:
///
///   * [PrStatusBadge] — a tinted capsule carrying the label ALONE. No leading
///     icon and no uppercasing: the tint reports the state and the label names
///     it, so it reads as a tag beside its siblings.
///   * [PrStatusIcon] — the compact icon form shown left of a PR title, with the
///     label in a tooltip.
///
/// Both resolve through `prStatusIconData`, so the precedence rules
/// (draft > merged > closed > open) are asserted once per widget.
PullRequest _pr({
  bool isDraft = false,
  String state = 'open',
  DateTime? mergedAt,
}) {
  return PullRequest(
    id: 1,
    number: 1,
    title: 'Test PR',
    body: '',
    state: PrStateExtension.fromString(state),
    isDraft: isDraft,
    author: null,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    repoFullName: 'owner/repo',
    htmlUrl: '',
    mergedAt: mergedAt,
  );
}

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('PrStatusBadge — label-only tag', () {
    // Sentence case, straight from l10n: the badge deliberately does not
    // uppercase (see the widget doc).
    for (final (name, pr, label) in <(String, PullRequest, String)>[
      ('open', _pr(), 'Open'),
      ('draft', _pr(isDraft: true), 'Draft'),
      ('merged', _pr(mergedAt: DateTime(2024, 1, 1)), 'Merged'),
      ('closed', _pr(state: 'closed'), 'Closed'),
    ]) {
      testWidgets('displays the $name label', (tester) async {
        await tester.pumpWidget(_host(PrStatusBadge(pr: pr)));
        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('carries no icon — that is PrStatusIcon\'s job', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PrStatusBadge(pr: _pr())));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('draft takes priority over merged', (tester) async {
      final pr = _pr(isDraft: true, mergedAt: DateTime(2024, 1, 1));
      await tester.pumpWidget(_host(PrStatusBadge(pr: pr)));
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Merged'), findsNothing);
    });

    testWidgets('merged takes priority over open', (tester) async {
      final pr = _pr(mergedAt: DateTime(2024, 1, 1));
      await tester.pumpWidget(_host(PrStatusBadge(pr: pr)));
      expect(find.text('Merged'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('renders without crashing for a minimal PR', (tester) async {
      final pr = PullRequest(
        id: 1,
        number: 1,
        title: 'Minimal',
        body: '',
        state: PrState.open,
        isDraft: false,
        author: null,
        createdAt: null,
        updatedAt: null,
        repoFullName: 'o/r',
        htmlUrl: '',
      );
      await tester.pumpWidget(_host(PrStatusBadge(pr: pr)));
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('PrStatusIcon — icon form', () {
    // Icons come from AppIcons (the app's own IconData table), NOT
    // the icon font package — lib/ must not import that package (see
    // the icon-package ratchet in lib_boundary_test.dart), so assert against the same
    // constants the widget uses rather than re-deriving codepoints.
    for (final (name, pr, icon) in <(String, PullRequest, IconData)>[
      ('open', _pr(), AppIcons.gitPullRequest),
      ('draft', _pr(isDraft: true), AppIcons.gitPullRequestDraft),
      ('merged', _pr(mergedAt: DateTime(2024, 1, 1)), AppIcons.gitMerge),
      ('closed', _pr(state: 'closed'), AppIcons.gitPullRequestClosed),
    ]) {
      testWidgets('shows the $name icon', (tester) async {
        await tester.pumpWidget(_host(PrStatusIcon(pr: pr)));
        expect(find.byIcon(icon), findsOneWidget);
      });
    }

    testWidgets('closed never shows the merge icon', (tester) async {
      await tester.pumpWidget(_host(PrStatusIcon(pr: _pr(state: 'closed'))));
      expect(find.byIcon(AppIcons.gitMerge), findsNothing);
    });

    testWidgets('draft icon takes priority over merged', (tester) async {
      final pr = _pr(isDraft: true, mergedAt: DateTime(2024, 1, 1));
      await tester.pumpWidget(_host(PrStatusIcon(pr: pr)));
      expect(find.byIcon(AppIcons.gitPullRequestDraft), findsOneWidget);
      expect(find.byIcon(AppIcons.gitMerge), findsNothing);
    });

    testWidgets('honours the size argument', (tester) async {
      await tester.pumpWidget(_host(PrStatusIcon(pr: _pr(), size: 24)));
      final icon = tester.widget<Icon>(find.byIcon(AppIcons.gitPullRequest));
      expect(icon.size, 24);
    });
  });
}
