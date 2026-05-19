import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/agents/agent_discovery_service.dart';
import 'package:cc_infra/src/util/agents_md_parser.dart';
import 'package:test/test.dart';

class _FakeFs implements WorkspaceFilesystemPort {
  List<String> slugs = const [];
  // Per-slug path; defaults to /ws/<slug>/AGENTS.md
  String pathFor(String slug) => '/ws/$slug/AGENTS.md';

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async => slugs;

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      pathFor(agentSlug);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A parser that returns a programmed result per path, or throws to simulate
/// a malformed file.
class _FakeParser implements AgentsMdParser {
  _FakeParser(this._byPath);

  final Map<String, AgentMdParseResult> _byPath;
  final List<String> calls = [];

  @override
  AgentMdParseResult parseAgentFile(String path) {
    calls.add(path);
    final result = _byPath[path];
    if (result == null) {
      throw FormatException('malformed: $path');
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgentMdParseResult _result({
  required String path,
  required String name,
  String title = 'T',
  List<String> skills = const [],
  String? reportsTo,
  String persona = '',
}) => AgentMdParseResult(
  name: name,
  title: title,
  reportsTo: reportsTo,
  skills: skills,
  personaMarkdown: persona,
  agentMdPath: path,
);

void main() {
  group('AgentDiscoveryService.findImportable', () {
    test('returns parsed agents not already registered', () async {
      final fs = _FakeFs()..slugs = ['alpha', 'beta'];
      final parser = _FakeParser({
        '/ws/alpha/AGENTS.md': _result(
          path: '/ws/alpha/AGENTS.md',
          name: 'Alpha',
          title: 'Engineer',
        ),
        '/ws/beta/AGENTS.md': _result(
          path: '/ws/beta/AGENTS.md',
          name: 'Beta',
          skills: const ['codex'],
          reportsTo: 'ceo',
          persona: 'Calm and thorough.',
        ),
      });
      final svc = AgentDiscoveryService(filesystem: fs, parser: parser);

      final found = await svc.findImportable(
        workspaceId: 'ws',
        existingNamesLower: const {},
      );

      expect(found, hasLength(2));
      expect(found[0].name, 'Alpha');
      expect(found[0].title, 'Engineer');
      expect(found[1].name, 'Beta');
      expect(found[1].skills, ['codex']);
      expect(found[1].reportsTo, 'ceo');
      expect(found[1].persona, 'Calm and thorough.');
    });

    test(
      'excludes agents already in existingNamesLower (case-insensitive)',
      () async {
        final fs = _FakeFs()..slugs = ['alpha', 'beta'];
        final parser = _FakeParser({
          '/ws/alpha/AGENTS.md': _result(
            path: '/ws/alpha/AGENTS.md',
            name: 'Alpha',
          ),
          '/ws/beta/AGENTS.md': _result(
            path: '/ws/beta/AGENTS.md',
            name: 'Beta',
          ),
        });
        final svc = AgentDiscoveryService(filesystem: fs, parser: parser);

        final found = await svc.findImportable(
          workspaceId: 'ws',
          existingNamesLower: const {'alpha'},
        );

        expect(found.map((a) => a.name).toList(), ['Beta']);
      },
    );

    test('de-duplicates within the scan by lower-cased name', () async {
      final fs = _FakeFs()..slugs = ['a', 'b'];
      final parser = _FakeParser({
        '/ws/a/AGENTS.md': _result(path: '/ws/a/AGENTS.md', name: 'Delta'),
        '/ws/b/AGENTS.md': _result(path: '/ws/b/AGENTS.md', name: 'DELTA'),
      });
      final svc = AgentDiscoveryService(filesystem: fs, parser: parser);

      final found = await svc.findImportable(
        workspaceId: 'ws',
        existingNamesLower: const {},
      );

      expect(found, hasLength(1));
      expect(found.single.name, 'Delta');
    });

    test('skips malformed files silently', () async {
      final fs = _FakeFs()..slugs = ['good', 'bad'];
      final parser = _FakeParser({
        '/ws/good/AGENTS.md': _result(path: '/ws/good/AGENTS.md', name: 'Good'),
        // bad: not in the map → parseAgentFile throws.
      });
      final svc = AgentDiscoveryService(filesystem: fs, parser: parser);

      final found = await svc.findImportable(
        workspaceId: 'ws',
        existingNamesLower: const {},
      );

      expect(found, hasLength(1));
      expect(found.single.name, 'Good');
    });

    test(
      'empty persona markdown yields a null persona on the result',
      () async {
        final fs = _FakeFs()..slugs = ['x'];
        final parser = _FakeParser({
          '/ws/x/AGENTS.md': _result(
            path: '/ws/x/AGENTS.md',
            name: 'X',
            persona: '',
          ),
        });
        final svc = AgentDiscoveryService(filesystem: fs, parser: parser);

        final found = await svc.findImportable(
          workspaceId: 'ws',
          existingNamesLower: const {},
        );

        expect(found.single.persona, isNull);
      },
    );

    test('no slugs → empty result', () async {
      final fs = _FakeFs()..slugs = const [];
      final parser = _FakeParser({});
      final svc = AgentDiscoveryService(filesystem: fs, parser: parser);

      final found = await svc.findImportable(
        workspaceId: 'ws',
        existingNamesLower: const {},
      );

      expect(found, isEmpty);
    });
  });
}
