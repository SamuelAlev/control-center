import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_fleet_rail.dart';
import 'package:control_center/features/dashboard/providers/fleet_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

Agent _agent({
  required String id,
  required String name,
  required String title,
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/agents/$id.md',
    workspaceId: 'ws-test',
    skills: AgentSkills(<String>[]),
    createdAt: DateTime(2024, 1, 1),
  );
}

FleetAgent _fleetAgent(Agent agent, AgentLiveState state) {
  return FleetAgent(agent: agent, state: state);
}

void main() {
  testWidgets('renders empty fleet message when no agents', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardFleetProvider.overrideWithValue(const <FleetAgent>[]),
        ],
        child: testWrap(const DashboardFleetRail(codeFont: 'Fira Code')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No agents configured'), findsOneWidget);
  });

  testWidgets('renders fleet cards when agents present', (tester) async {
    final alice = _agent(id: 'agent-1', name: 'Alice', title: 'CEO');
    final bob = _agent(id: 'agent-2', name: 'Bob', title: 'Senior Engineer');

    final fleet = <FleetAgent>[
      _fleetAgent(alice, AgentLiveState.idle),
      _fleetAgent(bob, AgentLiveState.idle),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardFleetProvider.overrideWithValue(fleet),
        ],
        child: testWrap(const DashboardFleetRail(codeFont: 'Fira Code')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('renders agent registry link', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardFleetProvider.overrideWithValue(const <FleetAgent>[]),
        ],
        child: testWrap(const DashboardFleetRail(codeFont: 'Fira Code')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Agent registry'), findsOneWidget);
  });
}
