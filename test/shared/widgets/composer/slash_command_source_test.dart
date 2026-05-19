import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/slash_command_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MentionQuery q(String partial) => MentionQuery(
    trigger: MentionTrigger.slash,
    partial: partial,
    start: 0,
    end: partial.length + 1,
  );

  final source = SlashCommandSource(const [
    SlashCommand(name: 'plan', description: 'Plan the work'),
    // A skill sharing a BUILTIN's name — the case the namespace exists for.
    SlashCommand(name: 'skill:plan', description: 'Workspace planning skill'),
    SlashCommand(name: 'skill:testing', description: 'Workspace testing skill'),
    SlashCommand(
      name: 'skill:web-app:testing',
      description: 'Front-end testing conventions',
      badge: 'web-app',
    ),
    SlashCommand(
      name: 'skill:api:migrations',
      description: 'Write a migration',
      badge: 'api',
    ),
  ]);

  test('a repo skill carries its repo as the badge', () {
    final hit = source
        .suggestSync(q('web-app'))
        .firstWhere((s) => s.label == '/skill:web-app:testing');
    expect(hit.badge, 'web-app');
    expect(hit.replacement, '/skill:web-app:testing ');
  });

  test('a builtin has no badge', () {
    final hit = source
        .suggestSync(q('plan'))
        .firstWhere((s) => s.label == '/plan');
    expect(hit.badge, isNull);
  });

  test('a skill and a builtin of the same name both stay reachable', () {
    final labels = source.suggestSync(q('plan')).map((s) => s.label).toList();
    expect(labels, containsAll(['/plan', '/skill:plan']));
  });

  test('typing the bare skill name finds the namespaced entry', () {
    // Otherwise the namespace that keeps skills out of the builtin vocabulary
    // would also hide them behind a prefix you have to know first.
    final labels = source.suggestSync(q('migrations')).map((s) => s.label);
    expect(labels, contains('/skill:api:migrations'));
  });

  test('a bare name matches both the workspace and repo variants', () {
    final labels = source.suggestSync(q('testing')).map((s) => s.label).toList();
    expect(labels, contains('/skill:testing'));
    expect(labels, contains('/skill:web-app:testing'));
  });

  test('typing the namespace narrows to skills only', () {
    final labels = source.suggestSync(q('skill:')).map((s) => s.label).toList();
    expect(labels, isNot(contains('/plan')));
    expect(labels, contains('/skill:plan'));
    expect(labels, contains('/skill:api:migrations'));
  });

  test('typing the repo prefix narrows to that repo', () {
    final labels = source.suggestSync(q('api:')).map((s) => s.label).toList();
    expect(labels, ['/skill:api:migrations']);
  });

  test('a non-slash trigger yields nothing', () {
    expect(
      source.suggestSync(
        const MentionQuery(
          trigger: MentionTrigger.at,
          partial: 'testing',
          start: 0,
          end: 8,
        ),
      ),
      isEmpty,
    );
  });
}
