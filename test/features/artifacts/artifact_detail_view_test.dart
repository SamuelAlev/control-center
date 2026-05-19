import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WorkProduct _artifact() => WorkProduct(
  id: 'wp-1',
  workspaceId: 'ws-1',
  title: 'Migration rollout',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WorkProductRevision _revision(int number, String text) => WorkProductRevision(
  id: 'rev-$number',
  workProductId: 'wp-1',
  workspaceId: 'ws-1',
  revisionNumber: number,
  content: ArtifactDocument(
    blocks: [ArtifactMarkdownBlock(text: text)],
  ).toEnvelopeJsonString(),
  createdAt: DateTime(2026, 1, number),
);

Future<void> _pump(
  WidgetTester tester, {
  WorkProduct? artifact,
  List<WorkProductRevision> revisions = const [],
  bool ownsScroll = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        artifactProvider(
          'wp-1',
        ).overrideWith((ref) => Stream<WorkProduct?>.value(artifact)),
        artifactRevisionsProvider(
          'wp-1',
        ).overrideWith((ref) async => revisions),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ownsScroll
                ? const ArtifactDetailView(workProductId: 'wp-1')
                // The PR review tab's host shape: the view shrink-wraps into
                // one outer scroll it does not own.
                : const CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: ArtifactDetailView(
                          workProductId: 'wp-1',
                          ownsScroll: false,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the head revision under the artifact title', (
    tester,
  ) async {
    await _pump(
      tester,
      artifact: _artifact(),
      revisions: [_revision(1, 'First cut'), _revision(2, 'Second cut')],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Migration rollout'), findsOneWidget);
    // The head is the LAST entry — the same convention the bubble and the
    // sidebar card use.
    expect(find.textContaining('Second cut'), findsOneWidget);
    expect(find.textContaining('First cut'), findsNothing);
    // Two revisions ⇒ the picker is offered.
    expect(find.text('Revision'), findsOneWidget);
  });

  testWidgets('a single revision hides the picker', (tester) async {
    await _pump(
      tester,
      artifact: _artifact(),
      revisions: [_revision(1, 'Only cut')],
    );

    expect(find.textContaining('Only cut'), findsOneWidget);
    expect(find.text('Revision'), findsNothing);
  });

  testWidgets('an older revision can be selected', (tester) async {
    await _pump(
      tester,
      artifact: _artifact(),
      revisions: [_revision(1, 'First cut'), _revision(2, 'Second cut')],
    );

    await tester.tap(find.widgetWithText(CcButton, '1'));
    await tester.pumpAndSettle();

    expect(find.textContaining('First cut'), findsOneWidget);
    // Off the head, restoring it as a new head becomes available.
    expect(find.text('Restore this revision'), findsOneWidget);
  });

  testWidgets('a missing artifact says so instead of rendering a hole', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Artifact unavailable'), findsOneWidget);
  });

  testWidgets('inside a sliver it shrink-wraps instead of crashing the flex', (
    tester,
  ) async {
    // Regression: the PR review tab embeds the view in a SliverToBoxAdapter
    // (unbounded height) — an Expanded body cannot survive that.
    await _pump(
      tester,
      artifact: _artifact(),
      revisions: [_revision(1, 'First cut'), _revision(2, 'Second cut')],
      ownsScroll: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Migration rollout'), findsOneWidget);
    expect(find.textContaining('Second cut'), findsOneWidget);
    expect(find.text('Revision'), findsOneWidget);
  });
}
