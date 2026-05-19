import 'package:cc_domain/features/agents/domain/value_objects/discovered_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveredAgent', () {
    DiscoveredAgent makeAgent({
      String name = 'coder',
      String title = 'Coder',
      List<String> skills = const ['coding', 'review'],
      String agentMdPath = '/path/to/AGENTS.md',
      String? reportsTo,
      String? persona,
    }) =>
        DiscoveredAgent(
          name: name,
          title: title,
          skills: skills,
          agentMdPath: agentMdPath,
          reportsTo: reportsTo,
          persona: persona,
        );

    test('equality when all fields match', timeout: const Timeout.factor(2), () {
      final a = makeAgent();
      final b = makeAgent();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when name differs', timeout: const Timeout.factor(2), () {
      final a = makeAgent(name: 'alpha');
      final b = makeAgent(name: 'beta');
      expect(a, isNot(equals(b)));
    });

    test('inequality when title differs', timeout: const Timeout.factor(2), () {
      final a = makeAgent(title: 'Alpha');
      final b = makeAgent(title: 'Beta');
      expect(a, isNot(equals(b)));
    });

    test('inequality when agentMdPath differs', timeout: const Timeout.factor(2), () {
      final a = makeAgent(agentMdPath: '/a/AGENTS.md');
      final b = makeAgent(agentMdPath: '/b/AGENTS.md');
      expect(a, isNot(equals(b)));
    });

    test('inequality when reportsTo differs', timeout: const Timeout.factor(2), () {
      final a = makeAgent(reportsTo: 'ceo');
      final b = makeAgent(reportsTo: null);
      expect(a, isNot(equals(b)));
    });

    test('inequality when persona differs', timeout: const Timeout.factor(2), () {
      final a = makeAgent(persona: 'friendly');
      final b = makeAgent(persona: null);
      expect(a, isNot(equals(b)));
    });

    test('inequality when skills differ', timeout: const Timeout.factor(2), () {
      final a = makeAgent(skills: ['coding']);
      final b = makeAgent(skills: ['review']);
      expect(a, isNot(equals(b)));
    });

    test('inequality when skills length differs', timeout: const Timeout.factor(2), () {
      final a = makeAgent(skills: ['coding', 'review']);
      final b = makeAgent(skills: ['coding']);
      expect(a, isNot(equals(b)));
    });

    test('equality when skills are in same order', timeout: const Timeout.factor(2), () {
      final a = makeAgent(skills: ['a', 'b']);
      final b = makeAgent(skills: ['a', 'b']);
      expect(a, equals(b));
    });

    test('inequality when skills are in different order', timeout: const Timeout.factor(2), () {
      final a = makeAgent(skills: ['a', 'b']);
      final b = makeAgent(skills: ['b', 'a']);
      expect(a, isNot(equals(b)));
    });

    test('is identical to itself', timeout: const Timeout.factor(2), () {
      final agent = makeAgent();
      expect(identical(agent, agent), isTrue);
      expect(agent == agent, isTrue);
    });

    test('not equal to non-DiscoveredAgent', timeout: const Timeout.factor(2), () {
      final agent = makeAgent();
      expect(agent == Object(), isFalse);
    });

    test('all fields are accessible', timeout: const Timeout.factor(2), () {
      const agent = DiscoveredAgent(
        name: 'reviewer',
        title: 'Code Reviewer',
        skills: ['review', 'security'],
        agentMdPath: '/agents/reviewer.md',
        reportsTo: 'ceo',
        persona: 'Thorough reviewer',
      );
      expect(agent.name, 'reviewer');
      expect(agent.title, 'Code Reviewer');
      expect(agent.skills, ['review', 'security']);
      expect(agent.agentMdPath, '/agents/reviewer.md');
      expect(agent.reportsTo, 'ceo');
      expect(agent.persona, 'Thorough reviewer');
    });
  });
}
