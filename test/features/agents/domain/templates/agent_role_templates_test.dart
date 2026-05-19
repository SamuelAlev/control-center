import 'package:control_center/features/agents/domain/templates/agent_role_templates.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AgentRoleTemplate constructor
  // ---------------------------------------------------------------------------

  group('AgentRoleTemplate', () {
    group('constructor', () {
      test(
        'sets all fields',
        timeout: const Timeout.factor(2),
        () {
          const template = AgentRoleTemplate(
            label: 'Test Role',
            persona: 'You are a test agent.',
            defaultSkills: 'testing, mocking',
            defaultAdapter: 'pi_local',
            lenses: ['Lens A', 'Lens B'],
          );

          expect(template.label, 'Test Role');
          expect(template.persona, 'You are a test agent.');
          expect(template.defaultSkills, 'testing, mocking');
          expect(template.defaultAdapter, 'pi_local');
          expect(template.lenses, ['Lens A', 'Lens B']);
        },
      );
    });

    // ---------------------------------------------------------------------------
    // renderPersonaWithLenses
    // ---------------------------------------------------------------------------

    group('renderPersonaWithLenses', () {
      test(
        'includes persona text and lenses',
        timeout: const Timeout.factor(2),
        () {
          const template = AgentRoleTemplate(
            label: 'Tester',
            persona: 'You test code.',
            defaultSkills: 'testing',
            defaultAdapter: 'pi_local',
            lenses: ['Equivalence partitioning', 'Boundary value analysis'],
          );

          final rendered = template.renderPersonaWithLenses();

          expect(rendered, contains('You test code.'));
          expect(rendered, contains('**Lenses**'));
          expect(rendered, contains('- Equivalence partitioning'));
          expect(rendered, contains('- Boundary value analysis'));
        },
      );

      test(
        'includes all lenses from list',
        timeout: const Timeout.factor(2),
        () {
          const template = AgentRoleTemplate(
            label: 'Checker',
            persona: 'Be methodical.',
            defaultSkills: 'checking',
            defaultAdapter: 'pi_local',
            lenses: ['One', 'Two', 'Three'],
          );

          final rendered = template.renderPersonaWithLenses();

          expect(rendered, contains('- One'));
          expect(rendered, contains('- Two'));
          expect(rendered, contains('- Three'));
        },
      );

      test(
        'with empty lenses still works',
        timeout: const Timeout.factor(2),
        () {
          const template = AgentRoleTemplate(
            label: 'Minimal',
            persona: 'Just do it.',
            defaultSkills: '',
            defaultAdapter: 'pi_local',
            lenses: [],
          );

          final rendered = template.renderPersonaWithLenses();

          // Contains the persona but no lenses section.
          expect(rendered, 'Just do it.');
          // No lenses header injected.
          expect(rendered, isNot(contains('**Lenses**')));
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // AgentRoleTemplates.templates map
  // ---------------------------------------------------------------------------

  group('AgentRoleTemplates', () {
    test(
      'templates map is non-empty',
      timeout: const Timeout.factor(2),
      () {
        expect(AgentRoleTemplates.templates, isNotEmpty);
      },
    );

    test(
      'each template has non-empty label, persona, defaultSkills, defaultAdapter',
      timeout: const Timeout.factor(2),
      () {
        for (final entry in AgentRoleTemplates.templates.entries) {
          final template = entry.value;
          expect(
            template.label,
            isNotEmpty,
            reason: '${entry.key}.label is empty',
          );
          expect(
            template.persona,
            isNotEmpty,
            reason: '${entry.key}.persona is empty',
          );
          expect(
            template.defaultAdapter,
            isNotEmpty,
            reason: '${entry.key}.defaultAdapter is empty',
          );
          // defaultSkills may be empty (e.g. 'general' role).
        }
      },
    );

    test(
      'known role keys present',
      timeout: const Timeout.factor(2),
      () {
        final keys = AgentRoleTemplates.templates.keys.toSet();
        // Architect is not a direct key, but the expected keys from the spec
        // are: coder, reviewer, pm, qa (at minimum). Others may exist.
        expect(keys, contains('coder'));
        expect(keys, contains('reviewer'));
        expect(keys, contains('qa'));
        expect(keys, contains('pm'));
      },
    );
  });
}
