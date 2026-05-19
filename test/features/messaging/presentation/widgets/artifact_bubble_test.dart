import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/artifact_bubble.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Message _artifactMessage() => Message(
  id: 'msg-1',
  spaceId: 'ch',
  conversationId: 'ch',
  senderId: 'agent-1',
  senderType: SenderType.agent,
  content: 'published an artifact',
  messageType: MessageType.artifact,
  metadata: const {'workProductId': 'wp-1'},
  createdAt: DateTime(2026),
);

WorkProduct _artifact() => WorkProduct(
  id: 'wp-1',
  workspaceId: 'ws-1',
  title: 'Migration rollout',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// A document far taller than the bubble's collapsed height — the case that used
/// to overflow.
ArtifactDocument _tallDocument() => ArtifactDocument(
  blocks: [
    for (var i = 0; i < 40; i++)
      ArtifactMarkdownBlock(text: 'Paragraph $i of the rollout write-up.'),
  ],
);

WorkProductRevision _revision(ArtifactDocument document) => WorkProductRevision(
  id: 'rev-1',
  workProductId: 'wp-1',
  workspaceId: 'ws-1',
  revisionNumber: 1,
  content: document.toEnvelopeJsonString(),
  createdAt: DateTime(2026),
);

Future<List<EditorTab>> _pump(
  WidgetTester tester, {
  ArtifactDocument? document,
}) async {
  final opened = <EditorTab>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        artifactProvider(
          'wp-1',
        ).overrideWith((ref) => Stream<WorkProduct?>.value(_artifact())),
        artifactRevisionsProvider(
          'wp-1',
        ).overrideWith((ref) async => [_revision(document ?? _tallDocument())]),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EditorTabOpenerScope(
              opener: EditorTabOpener(opened.add),
              // The feed the bubble really lives in is a vertical scroller, so
              // the card gets unbounded height and an expanded artifact is
              // scrolled to, not squeezed.
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 760,
                  child: ArtifactBubble(message: _artifactMessage()),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('a tall artifact collapses without overflowing', (tester) async {
    await _pump(tester);

    // The regression: the collapsed card capped the blocks' Column with a hard
    // maxHeight, so the flex reported an overflow ("A RenderFlex overflowed by
    // 2031 pixels") even though the clip hid it.
    expect(tester.takeException(), isNull);
    expect(find.text('Migration rollout'), findsOneWidget);
    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('show more expands the card, still without overflowing', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('a short artifact is not padded out to the collapsed height', (
    tester,
  ) async {
    await _pump(
      tester,
      document: const ArtifactDocument(
        blocks: [ArtifactMarkdownBlock(text: 'One line.')],
      ),
    );

    expect(tester.takeException(), isNull);
    // Shrink-wrapped: the whole card (header + body + actions) stays well under
    // the 360px collapse cap.
    expect(tester.getSize(find.byType(ArtifactBubble)).height, lessThan(300));
  });

  testWidgets('opens the artifact in a tab', (tester) async {
    final opened = await _pump(tester);

    await tester.tap(find.byIcon(AppIcons.externalLink));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.kind, MessagingTabKinds.artifact);
    expect(opened.single.dedupKey, 'artifact:wp-1');
    expect(opened.single.args['workspaceId'], 'ws-1');
    expect(opened.single.args['workProductId'], 'wp-1');
    expect(opened.single.label, 'Migration rollout');
  });
}
