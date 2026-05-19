import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/shared/utils/agent_responder_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent({required String id, required String name, String? reportsTo}) {
  return Agent(
    id: id,
    name: name,
    title: name,
    agentMdPath: '',
    workspaceId: 'ws-1',
    reportsTo: reportsTo,
    skills: AgentSkills([]),
    createdAt: DateTime(2024),
  );
}

final _ceo = _agent(id: 'ceo-id', name: 'ceo');
final _architect = _agent(
  id: 'arch-id',
  name: 'architect',
  reportsTo: 'ceo-id',
);
final _engineer = _agent(id: 'eng-id', name: 'engineer', reportsTo: 'arch-id');

void main() {
  group('AgentResponderResolver.resolveDefault', () {
    test('returns null for empty agents list', () {
      expect(
        AgentResponderResolver.resolveDefault(agents: [], isDm: false),
        isNull,
      );
    });

    group('DM channel', () {
      test('returns the sole agent participant', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_ceo],
          isDm: true,
        );
        expect(result!.id, 'ceo-id');
      });

      test('returns the sole agent regardless of lastAgentSenderId', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_engineer],
          isDm: true,
          lastAgentSenderId: 'ceo-id',
        );
        expect(result!.id, 'eng-id');
      });
    });

    group('group channel', () {
      test('returns last speaker when lastAgentSenderId matches', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_ceo, _architect, _engineer],
          isDm: false,
          lastAgentSenderId: 'arch-id',
        );
        expect(result!.id, 'arch-id');
      });

      test('ignores lastAgentSenderId when agent not in participants', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_ceo, _architect],
          isDm: false,
          lastAgentSenderId: 'out-id',
        );
        expect(result!.id, 'ceo-id');
      });

      test('falls back to top-level agent when no last speaker', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_architect, _engineer, _ceo],
          isDm: false,
        );
        expect(result!.id, 'ceo-id');
      });

      test('falls back to any participant when no top-level agent', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_architect, _engineer],
          isDm: false,
        );
        expect(result!.id, isIn(['arch-id', 'eng-id']));
      });

      test(
        'falls back to any participant when no top-level and no last speaker',
        () {
          final result = AgentResponderResolver.resolveDefault(
            agents: [_architect, _engineer],
            isDm: false,
            lastAgentSenderId: null,
          );
          expect(result!.id, isIn(['arch-id', 'eng-id']));
        },
      );

      test('prefers top-level over any when both present in participants', () {
        final result = AgentResponderResolver.resolveDefault(
          agents: [_engineer, _ceo],
          isDm: false,
        );
        expect(result!.id, 'ceo-id');
      });
    });
  });
}
