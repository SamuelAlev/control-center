import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/presentation/widgets/presence_avatar_chip.dart';
import 'package:control_center/features/presence/presentation/widgets/whos_here_strip.dart';
import 'package:control_center/features/presence/presentation/widgets/workspace_presence_rail.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';

class _QuietPresence extends MyPresenceNotifier {
  @override
  MyPresenceState build() => const MyPresenceState();
}

ParticipantPresence _presence(
  Principal principal,
  String name, {
  String? spaceId,
  String? typingSpaceId,
}) => ParticipantPresence(
  principal: principal,
  displayName: name,
  availability: PresenceAvailability.online,
  locus: spaceId == null ? null : SpaceLocus(spaceId: spaceId),
  typingInSpaceId: typingSpaceId,
);

Future<ProviderContainer> _pumpPresence(
  WidgetTester tester,
  List<ParticipantPresence> roster, {
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceIdOverride(),
      currentUserIdProvider.overrideWithValue('me'),
      presenceRosterProvider(
        kTestWorkspaceId,
      ).overrideWith((ref) => Stream.value(roster)),
      myPresenceProvider.overrideWith(_QuietPresence.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testWrap(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkspacePresenceRail(),
            WhosHereStrip(spaceId: 'space-1'),
          ],
        ),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _chipsIn(Type surface) => find.descendant(
  of: find.byType(surface),
  matching: find.byType(PresenceAvatarChip),
);

List<String> _namesIn(WidgetTester tester, Type surface) => tester
    .widgetList<PresenceAvatarChip>(_chipsIn(surface))
    .map((chip) => chip.participant.displayName)
    .toList();

void main() {
  testWidgets('agents do not activate solo-mode following chrome', (
    tester,
  ) async {
    await _pumpPresence(tester, [
      _presence(const UserPrincipal('me'), 'Me', spaceId: 'space-1'),
      _presence(const AgentPrincipal('agent-1'), 'Agent', spaceId: 'space-1'),
    ]);

    expect(find.byType(CcAvatar), findsNothing);
    expect(find.byType(CcIconButton), findsNothing);
    expect(find.byType(PresenceAvatarChip), findsNothing);
  });

  for (final direction in TextDirection.values) {
    testWidgets('only other users can be followed in ${direction.name}', (
      tester,
    ) async {
      final container = await _pumpPresence(tester, [
        _presence(const UserPrincipal('me'), 'Me', spaceId: 'space-1'),
        _presence(const AgentPrincipal('agent-1'), 'Agent', spaceId: 'space-1'),
        _presence(const UserPrincipal('alice'), 'Alice', spaceId: 'space-1'),
        _presence(const UserPrincipal('bob'), 'Bob', spaceId: 'space-2'),
        _presence(
          const UserPrincipal('charlie'),
          'Charlie',
          typingSpaceId: 'space-1',
        ),
      ], textDirection: direction);

      expect(_namesIn(tester, WorkspacePresenceRail), [
        'Alice',
        'Bob',
        'Charlie',
      ]);
      expect(_namesIn(tester, WhosHereStrip), ['Alice', 'Charlie']);

      final alice = _chipsIn(WorkspacePresenceRail).first;
      await tester.tap(alice);
      await tester.pump();
      expect(
        container.read(followedPrincipalProvider),
        const UserPrincipal('alice'),
      );

      await tester.tap(_chipsIn(WhosHereStrip).last);
      await tester.pump();
      expect(
        container.read(followedPrincipalProvider),
        const UserPrincipal('charlie'),
      );

      await tester.tap(_chipsIn(WhosHereStrip).last);
      await tester.pump();
      expect(container.read(followedPrincipalProvider), isNull);
    });
  }

  testWidgets('agents neither occupy avatar slots nor inflate overflow', (
    tester,
  ) async {
    await _pumpPresence(tester, [
      for (var i = 0; i < 8; i++)
        _presence(AgentPrincipal('agent-$i'), 'Agent $i'),
      for (var i = 0; i < 6; i++)
        _presence(UserPrincipal('user-$i'), 'User $i'),
    ]);

    expect(_namesIn(tester, WorkspacePresenceRail), [
      'User 0',
      'User 1',
      'User 2',
      'User 3',
      'User 4',
    ]);
    expect(find.text('+1'), findsOneWidget);
  });
}
