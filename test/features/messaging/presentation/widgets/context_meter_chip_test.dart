import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_window_usage.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/context_meter_chip.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `flutter_riverpod` does not re-export `Override`; `misc.dart` is its public
// home in riverpod 3.
import 'package:riverpod/misc.dart' show Override;

const _workspaceId = 'ws-1';
const _spaceId = 'sp-1';
const _agentId = 'ag-1';

class _FakeActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

ContextInspection _inspection({required bool withContent}) => ContextInspection(
  workspaceId: _workspaceId,
  spaceId: _spaceId,
  agentId: _agentId,
  agentName: 'Aria',
  mode: 'chat',
  workingDirectory: '/tmp/overlay/aria',
  windowTokens: 256000,
  hasContent: withContent,
  segments: [
    ContextSegment(
      kind: ContextSegmentKind.systemPrompt,
      tokens: 1200,
      chars: 4800,
      parts: [
        ContextPart(
          id: 'base',
          title: 'Base instructions',
          tokens: 1200,
          chars: 4800,
          content: withContent ? 'BASE INSTRUCTIONS BODY' : null,
        ),
      ],
    ),
    const ContextSegment(
      kind: ContextSegmentKind.rules,
      tokens: 600,
      chars: 2400,
    ),
  ],
);

List<Message> _messages() => [
  Message(
    id: 'm-1',
    spaceId: _spaceId,
    conversationId: 'cv-1',
    senderId: 'user-1',
    senderType: SenderType.user,
    content: 'hello there',
    messageType: MessageType.text,
    createdAt: DateTime.utc(2026),
  ),
];

List<Override> _overrides() => [
  activeWorkspaceIdProvider.overrideWith(_FakeActiveWorkspaceId.new),
  conversationContextUsageProvider((
    spaceId: _spaceId,
    agentId: _agentId,
  )).overrideWith(
    (ref) => const ContextWindowUsage(usedTokens: 8000, windowTokens: 256000),
  ),
  contextInspectionProvider((
    spaceId: _spaceId,
    agentId: _agentId,
    includeContent: false,
  )).overrideWith((ref) async => _inspection(withContent: false)),
  contextInspectionProvider((
    spaceId: _spaceId,
    agentId: _agentId,
    includeContent: true,
  )).overrideWith((ref) async => _inspection(withContent: true)),
  spaceMessagesProvider(
    _spaceId,
  ).overrideWith((ref) => Stream.value(_messages())),
];

Widget _wrap(Widget child) => CcTheme(
  data: CcThemeData.light(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // Bounded like the real space header: without the tight row the chip's
    // inner Center expands to fill the whole body and its MouseRegion
    // swallows every pointer in the harness.
    home: Scaffold(
      body: Center(
        child: SizedBox(
          height: 40,
          child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
        ),
      ),
    ),
  ),
);

Future<void> _pumpChip(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: _wrap(
        const ContextMeterChip(spaceId: _spaceId, agentId: _agentId),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders the compact meter with the fill bar', (tester) async {
    await _pumpChip(tester);

    // 1800 persistent (server) + 3 conversation ('hello there', 11 chars).
    expect(find.text('2k / 256k'), findsOneWidget);
    // The flyout stays closed until tapped.
    expect(find.text('Context usage'), findsNothing);
  });

  testWidgets('tap opens the flyout with the breakdown and See more opens the '
      'explorer', (tester) async {
    await _pumpChip(tester);

    await tester.tap(find.text('2k / 256k'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Header, summary and the per-category rows — the server categories and
    // the client-composed conversation row are all present.
    expect(find.text('Context usage'), findsOneWidget);
    expect(find.text('System prompt'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('See more'), findsOneWidget);

    await tester.tap(find.text('See more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // No editor-layout host in this harness → the modal fallback hosts the
    // explorer pane.
    expect(find.text('Context · Aria'), findsOneWidget);
    expect(find.text('Everything'), findsOneWidget);
    expect(find.text('Base instructions'), findsOneWidget);
    expect(find.text('Select a part to inspect its content'), findsOneWidget);

    // Selecting a part renders its verbatim content.
    await tester.tap(find.text('Base instructions'));
    await tester.pump();
    expect(find.text('BASE INSTRUCTIONS BODY'), findsOneWidget);

    // The rail's sections are accordions: the twistie minimizes a section's
    // parts… (two sections have parts: System prompt and Conversation).
    expect(find.byIcon(AppIcons.chevronDown), findsNWidgets(2));
    await tester.tap(find.byIcon(AppIcons.chevronDown).first);
    await tester.pump();
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    expect(find.text('Base instructions'), findsNothing);

    // …while the header stays a pure selection action: tapping it does NOT
    // re-expand, and the detail pane still shows the section's content.
    await tester.tap(find.text('System prompt'));
    await tester.pump();
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    expect(find.textContaining('BASE INSTRUCTIONS BODY'), findsOneWidget);

    // Toggling again restores the part rows.
    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pump();
    expect(find.text('Base instructions'), findsOneWidget);
  });

  testWidgets(
    'hover lights a square wash and it stays lit while the flyout is open',
    (tester) async {
      await _pumpChip(tester);
      final tokens = DesignSystemTokens.light();
      final idle = tokens.bgSecondaryHover.withValues(alpha: 0);

      Color? labelColor() =>
          tester.widget<Text>(find.text('2k / 256k')).style?.color;

      BoxDecoration deco() {
        final container = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('2k / 256k'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return container.decoration! as BoxDecoration;
      }

      expect(labelColor(), tokens.textTertiary);
      expect(deco().color, idle);
      expect(deco().borderRadius, isNull);

      // Drive EVERYTHING with one mouse pointer, like a real desktop user:
      // tester.tap() dispatches a synthetic TOUCH pointer whose hover exit is
      // swallowed when the overlay teardown removes the device mid-gesture.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      Future<void> mouseTap(Finder target) async {
        await mouse.down(tester.getCenter(target));
        await tester.pump();
        await mouse.up();
        await tester.pump();
      }

      await mouse.moveTo(tester.getCenter(find.text('2k / 256k')));
      await tester.pump();
      expect(labelColor(), tokens.textSecondary);
      expect(deco().color, tokens.bgSecondaryHover);
      expect(deco().borderRadius, isNull);

      // Click to open the flyout, then move the pointer away: the wash stays
      // lit for as long as the popover is open.
      await mouseTap(find.text('2k / 256k'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Context usage'), findsOneWidget);
      await mouse.moveTo(const Offset(4, 4));
      await tester.pump();
      expect(labelColor(), tokens.textSecondary);
      expect(deco().color, tokens.bgSecondaryHover);

      // Click the chip again to close. Let the overlay teardown finish
      // BEFORE moving the pointer — moving in the same frame as the
      // removal races the MouseTracker's annotation update and the exit
      // can be swallowed.
      await mouseTap(find.text('2k / 256k'));
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.moveTo(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Context usage'), findsNothing);
      expect(labelColor(), tokens.textTertiary);
      expect(deco().color, idle);
    },
  );

  testWidgets('names the agent when the space holds more than one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides(),
          agentDetailProvider(_agentId).overrideWith(
            (ref) async => Agent(
              id: _agentId,
              name: 'Aria',
              title: 'Architect',
              agentMdPath: '/tmp/aria.md',
              workspaceId: _workspaceId,
              skills: AgentSkills([]),
              createdAt: DateTime.utc(2026),
            ),
          ),
        ],
        child: _wrap(
          const ContextMeterChip(
            spaceId: _spaceId,
            agentId: _agentId,
            showAgent: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The meter follows whoever is working, so the numbers carry an avatar and
    // an accessible name — otherwise a swap reads as one window shrinking.
    expect(find.byType(AgentAvatar), findsOneWidget);
    expect(find.text('2k / 256k'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: find.text('2k / 256k'),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .properties
          .label,
      'Context usage · Aria',
    );

    // …and the flyout it opens says whose breakdown it is.
    await tester.tap(find.text('2k / 256k'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Context usage · Aria'), findsOneWidget);
  });

  testWidgets('stays hidden when usage is unknown', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_FakeActiveWorkspaceId.new),
          conversationContextUsageProvider((
            spaceId: _spaceId,
            agentId: _agentId,
          )).overrideWith((ref) => ContextWindowUsage.unknown),
          // An empty conversation and an inspection with no known window:
          // nothing to measure, so the chip hides.
          spaceMessagesProvider(
            _spaceId,
          ).overrideWith((ref) => Stream.value(const <Message>[])),
          contextInspectionProvider((
            spaceId: _spaceId,
            agentId: _agentId,
            includeContent: false,
          )).overrideWith(
            (ref) async => const ContextInspection(
              workspaceId: _workspaceId,
              spaceId: _spaceId,
              agentId: _agentId,
              agentName: 'Aria',
              mode: 'chat',
              windowTokens: 0,
              hasContent: false,
              segments: [],
            ),
          ),
        ],
        child: _wrap(
          const ContextMeterChip(spaceId: _spaceId, agentId: _agentId),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ContextMeterChip), findsOneWidget);
    expect(find.byType(CcPopover), findsNothing);
  });
}
