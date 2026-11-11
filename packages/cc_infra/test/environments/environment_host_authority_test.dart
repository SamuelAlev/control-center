import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';
import 'helpers/environment_service_harness.dart';

/// A definition that runs anything on the server host runs it as the
/// server's OS user, so only the server owner saves or approves one. A
/// workspace admin may still save one that runs entirely in a rig. Decided on
/// the validated definition, never on what the caller or the stored row says.
void main() {
  late ServiceHarness h;

  setUp(() {
    h = ServiceHarness(tempDir(addTearDown).path);
    addTearDown(() => h.service.stopListening());
  });

  final ownerOnly = throwsA(isA<ServerOwnerRequiredException>());

  Map<String, dynamic> rig([List<Map<String, dynamic>>? components]) =>
      definitionJson(
        components ?? [composeJson()],
        extra: {'placement': 'rig'},
      );

  Map<String, dynamic> host() => definitionJson([composeJson()]);

  Future<EnvironmentDefinitionRecord> save(
    Map<String, dynamic> definition, {
    required bool owner,
    String? id,
  }) => h.service.saveDefinition(
    workspaceId: 'ws-a',
    definitionId: id,
    definition: definition,
    by: principal,
    byServerOwner: owner,
  );

  group('saveDefinition', () {
    test(
      'an admin cannot save a host definition, and nothing is written',
      () async {
        await expectLater(save(host(), owner: false), ownerOnly);
        expect(h.definitions.records, isEmpty);
      },
    );

    test('an admin saves a definition that runs entirely in a rig', () async {
      final record = await save(rig(), owner: false);
      expect(h.definitions.records.keys, [record.id]);
    });

    test('the owner saves either', () async {
      await save(host(), owner: true);
      await save(rig(), owner: true);
      expect(h.definitions.records, hasLength(2));
    });

    test('in a rig, a check that runs a command or a worktree task still runs '
        'on the host', () async {
      final check = definitionJson(
        [composeJson()],
        extra: {
          'placement': 'rig',
          'checks': [
            {
              'id': 'tool',
              'command': ['tool', '--version'],
            },
          ],
        },
      );
      await expectLater(save(check, owner: false), ownerOnly);
      for (final trigger in ['provision', 'archive']) {
        await expectLater(
          save(
            rig([
              composeJson(),
              taskJson('t', [trigger]),
            ]),
            owner: false,
          ),
          ownerOnly,
          reason: trigger,
        );
      }
      expect(h.definitions.records, isEmpty);
      // A task that only runs with the environment stays in the rig.
      await save(
        rig([
          composeJson(),
          taskJson('t', ['start']),
        ]),
        owner: false,
      );
    });

    test('editing a stored host definition is the owner\'s, even keeping it '
        'on the host', () async {
      final stored = await save(host(), owner: true);
      final before = h.definitions.records[stored.id];
      await expectLater(save(host(), owner: false, id: stored.id), ownerOnly);
      expect(h.definitions.records[stored.id], before);
    });

    test('an admin cannot move a rig definition to the host', () async {
      final stored = await save(rig(), owner: false);
      final before = h.definitions.records[stored.id];
      await expectLater(save(host(), owner: false, id: stored.id), ownerOnly);
      expect(h.definitions.records[stored.id], before);
    });

    test('a linked definition is judged on its file', () async {
      h.git['show'] = ok(jsonEncode(host()));
      h.git['rev-parse'] = ok('blob1\n');
      await expectLater(
        save({
          'source': {'repoId': 'repo-app', 'path': 'env.json'},
        }, owner: false),
        ownerOnly,
      );
      expect(h.definitions.records, isEmpty);
    });
  });

  group('approveSource', () {
    Future<EnvironmentDefinitionRecord> approve(
      Map<String, dynamic> file, {
      required bool owner,
      Map<String, dynamic>? overrides,
    }) {
      h.git['show'] = ok(jsonEncode(file));
      h.git['rev-parse'] = ok('blob1\n');
      return h.service.approveSource(
        workspaceId: 'ws-a',
        repoId: 'repo-app',
        path: 'env.json',
        overrides: overrides,
        by: principal,
        byServerOwner: owner,
      );
    }

    test(
      'an admin cannot approve a host file, and nothing is written',
      () async {
        await expectLater(approve(host(), owner: false), ownerOnly);
        expect(h.definitions.records, isEmpty);
      },
    );

    test('an admin approves a rig file', () async {
      final record = await approve(rig(), owner: false);
      expect(record.approvedBlobHash, 'blob1');
    });

    test('the owner approves a host file', () async {
      final record = await approve(host(), owner: true);
      expect(record.approvedBlobHash, 'blob1');
    });

    test('overrides that bring it to the host are judged too', () async {
      await expectLater(
        approve(
          rig(),
          owner: false,
          overrides: {
            'checks': [
              {
                'id': 'tool',
                'command': ['tool', '--version'],
              },
            ],
          },
        ),
        ownerOnly,
      );
      expect(h.definitions.records, isEmpty);
    });
  });
}
