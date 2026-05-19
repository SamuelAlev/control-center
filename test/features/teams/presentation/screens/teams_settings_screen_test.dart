import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/teams/presentation/screens/teams_settings_screen.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Agent _agent(String id, String name) => Agent(
  id: id,
  name: name,
  title: '$name title',
  agentMdPath: '/a/$id.md',
  workspaceId: 'ws-1',
  skills: AgentSkills(const []),
  createdAt: DateTime(2024),
);

Team _team(String id, String name, {String? leaderId}) => Team(
  id: id,
  workspaceId: 'ws-1',
  name: name,
  leaderId: leaderId,
  createdAt: DateTime(2024),
);

/// Mounts [TeamsSettingsScreen] under a GoRouter whose route supplies the
/// `:workspaceId` that `context.currentWorkspaceId` reads, with the teams /
/// agents / members streams overridden.
Widget _wrap({
  required List<Team> teams,
  List<Agent> agents = const [],
  List<TeamMember> members = const [],
}) {
  final router = GoRouter(
    initialLocation: '/workspaces/ws-1/settings/teams',
    routes: [
      GoRoute(
        path: '/workspaces/:workspaceId/settings/teams',
        builder: (_, _) => const TeamsSettingsScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      teamsForWorkspaceProvider.overrideWith((ref, _) => Stream.value(teams)),
      workspaceAgentsProvider.overrideWith((ref, _) => Stream.value(agents)),
      teamMembersProvider.overrideWith((ref, _) => Stream.value(members)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
      builder: (context, child) => CcTheme(
        data: CcThemeData.light(),
        child: CcToastScope(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
}

void main() {
  group('TeamsSettingsScreen', () {
    testWidgets('shows the empty state when there are no teams', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(teams: const []));
      await tester.pumpAndSettle();

      expect(find.text('No teams yet'), findsOneWidget);
      // The add-team action is offered both in the header and the empty state.
      expect(find.text('Add team'), findsWidgets);
    });

    testWidgets('lists teams in the roster', (tester) async {
      await tester.pumpWidget(_wrap(teams: [_team('t1', 'Frontend')]));
      await tester.pumpAndSettle();

      expect(find.text('Frontend'), findsWidgets);
      // Nothing selected yet → the detail pane prompts for a selection.
      expect(find.text('Select a team'), findsWidgets);
    });

    testWidgets('selecting a team reveals its leader with a badge', (
      tester,
    ) async {
      // A tall surface so the detail ListView builds the members card (its last
      // child) instead of leaving it below the fold of a lazy list.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          teams: [_team('t1', 'Frontend', leaderId: 'a1')],
          agents: [_agent('a1', 'Lina')],
          members: [
            TeamMember(
              teamId: 't1',
              agentId: 'a1',
              role: TeamMemberRole.leader,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the team in the roster to open its detail editor.
      await tester.tap(find.text('Frontend').first);
      await tester.pumpAndSettle();

      expect(find.text('Lina'), findsWidgets);
      // The member is marked as the leader.
      expect(find.text('Leader'), findsWidgets);
    });
  });
}
