import 'dart:convert';

import 'package:cc_domain/features/environments/domain/services/environment_definition_draft.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:test/test.dart';

Map<String, dynamic> _draft(Map<String, String> files) =>
    draftEnvironmentDefinition(repoId: 'r', repoName: 'My Shop', files: files);

Map<String, dynamic> _definition(Map<String, String> files) =>
    _draft(files)['definition'] as Map<String, dynamic>;

void main() {
  test('a compose repo drafts one compose component', () {
    final json = _definition({'compose.yaml': 'services: {}'});
    final definition = EnvironmentDefinition.fromJson(json);
    expect(definition.components.single.kind, 'compose');
    expect(definition.naming.project, 'my-shop');
    expect(validateEnvironmentDefinition(definition), isEmpty);
  });

  test('every draft passes the validator', () {
    final samples = <Map<String, String>>[
      {},
      {'Procfile': 'web: rails s\n# comment\nworker: sidekiq\n'},
      {
        'conductor.json': jsonEncode({
          'scripts': {'setup': 'pnpm i', 'run': 'pnpm dev'},
        }),
      },
      {
        'run-pty.json': jsonEncode([
          {
            'title': 'Dev server',
            'command': ['pnpm', 'dev'],
          },
          {
            'title': 'Dev server',
            'command': ['pnpm', 'other'],
          },
        ]),
      },
      {
        'package.json': jsonEncode({
          'scripts': {'dev': 'vite'},
        }),
        'pnpm-lock.yaml': '',
      },
      {'conductor.json': 'not json', 'package.json': '{'},
    ];
    for (final files in samples) {
      final definition = EnvironmentDefinition.fromJson(_definition(files));
      expect(
        validateEnvironmentDefinition(definition),
        isEmpty,
        reason: '$files',
      );
    }
  });

  test('a lockfile becomes a worktree task', () {
    final components =
        _definition({'pnpm-lock.yaml': ''})['components'] as List;
    final task = components.single as Map;
    expect(task['when'], contains('provision'));
    expect(task['onChange'], ['pnpm-lock.yaml']);
  });

  test('host processes come with a port warning', () {
    final draft = _draft({'Procfile': 'web: rails s'});
    expect(draft['notes'], isNotEmpty);
    expect(_draft({'compose.yaml': ''})['notes'], isEmpty);
  });

  test('run-pty wins over a package dev script', () {
    final components =
        _definition({
              'run-pty.json': jsonEncode([
                {
                  'title': 'Queue',
                  'command': ['node', 'q.js'],
                },
              ]),
              'package.json': jsonEncode({
                'scripts': {'dev': 'vite'},
              }),
            })['components']
            as List;
    expect((components.single as Map)['id'], 'queue');
  });
}
