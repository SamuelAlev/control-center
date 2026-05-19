import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:test/test.dart';

final _createdAt = DateTime.utc(2026, 1, 1);
final _updatedAt = DateTime.utc(2026, 1, 2);

OrchestrationProposal _sourceProposal() => const OrchestrationProposal(
  goal: 'Do {{task}}',
  roles: [
    ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
  ],
  subTickets: [ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder')],
  synthesis: SynthesisSpec(
    roleKey: 'coder',
    prompt: 'p',
    outputSchema: {'type': 'object'},
  ),
);

Playbook _playbook({
  String id = 'pb-1',
  String workspaceId = 'ws-1',
  String name = 'My playbook',
  List<PlaybookParam> params = const [],
  int version = 1,
}) => Playbook(
  id: id,
  workspaceId: workspaceId,
  name: name,
  params: params,
  sourceProposal: _sourceProposal(),
  version: version,
  createdAt: _createdAt,
  updatedAt: _updatedAt,
);

void main() {
  group('PlaybookParamType.fromName', () {
    test('parses known names', () {
      expect(PlaybookParamType.fromName('string'), PlaybookParamType.string);
      expect(
        PlaybookParamType.fromName('enumeration'),
        PlaybookParamType.enumeration,
      );
      expect(PlaybookParamType.fromName('repoRef'), PlaybookParamType.repoRef);
      expect(
        PlaybookParamType.fromName('agentRef'),
        PlaybookParamType.agentRef,
      );
    });

    test('defaults to string for unknown/null names', () {
      expect(PlaybookParamType.fromName('bogus'), PlaybookParamType.string);
      expect(PlaybookParamType.fromName(null), PlaybookParamType.string);
    });
  });

  group('PlaybookParam — constructor validation', () {
    test('throws on empty name', () {
      expect(() => PlaybookParam(name: ''), throwsArgumentError);
    });

    test('accepts a well-formed param', () {
      expect(() => PlaybookParam(name: 'x'), returnsNormally);
    });
  });

  group('PlaybookParam JSON round-trip', () {
    test('round-trips all fields', () {
      final param = PlaybookParam(
        name: 'priority',
        type: PlaybookParamType.enumeration,
        description: 'How urgent',
        required: false,
        defaultValue: 'low',
        choices: const ['low', 'high'],
      );
      final restored = PlaybookParam.fromJson(param.toJson());
      expect(restored.name, 'priority');
      expect(restored.type, PlaybookParamType.enumeration);
      expect(restored.description, 'How urgent');
      expect(restored.required, isFalse);
      expect(restored.defaultValue, 'low');
      expect(restored.choices, ['low', 'high']);
    });

    test('required defaults to true when absent from JSON', () {
      final restored = PlaybookParam.fromJson(const {'name': 'x'});
      expect(restored.required, isTrue);
    });

    test('optional fields omitted from JSON when unset', () {
      final param = PlaybookParam(name: 'x');
      final json = param.toJson();
      expect(json.containsKey('default'), isFalse);
      expect(json.containsKey('choices'), isFalse);
    });
  });

  group('Playbook — constructor validation', () {
    test('throws on empty id', () {
      expect(() => _playbook(id: ''), throwsArgumentError);
    });

    test('throws on empty workspaceId', () {
      expect(() => _playbook(workspaceId: ''), throwsArgumentError);
    });

    test('throws on empty name', () {
      expect(() => _playbook(name: ''), throwsArgumentError);
    });

    test('throws when version < 1', () {
      expect(() => _playbook(version: 0), throwsArgumentError);
      expect(() => _playbook(version: -1), throwsArgumentError);
    });

    test('accepts a well-formed playbook', () {
      expect(_playbook, returnsNormally);
    });
  });

  group('Playbook.paramsToJsonString / paramsFromJsonString', () {
    test('round-trips a list of params', () {
      final params = [
        PlaybookParam(name: 'client'),
        PlaybookParam(
          name: 'priority',
          type: PlaybookParamType.enumeration,
          choices: const ['low', 'high'],
        ),
      ];
      final playbook = _playbook(params: params);
      final restored = Playbook.paramsFromJsonString(
        playbook.paramsToJsonString(),
      );
      expect(restored, hasLength(2));
      expect(restored[0].name, 'client');
      expect(restored[1].name, 'priority');
      expect(restored[1].choices, ['low', 'high']);
    });

    test('paramsFromJsonString returns empty for malformed JSON', () {
      expect(Playbook.paramsFromJsonString('not json'), isEmpty);
    });

    test('paramsFromJsonString returns empty for a non-list JSON value', () {
      expect(Playbook.paramsFromJsonString('{"a": 1}'), isEmpty);
    });

    test('paramsFromJsonString returns empty for an empty list', () {
      expect(Playbook.paramsFromJsonString('[]'), isEmpty);
    });
  });

  group('Playbook.copyWith', () {
    test('replaces only the given fields, keeping identity fields', () {
      final playbook = _playbook();
      final edited = playbook.copyWith(name: 'New name', version: 2);
      expect(edited.id, playbook.id);
      expect(edited.workspaceId, playbook.workspaceId);
      expect(edited.name, 'New name');
      expect(edited.version, 2);
      expect(edited.createdAt, playbook.createdAt);
    });
  });

  group('Playbook equality', () {
    test('equal when id/version/updatedAt match', () {
      final a = _playbook(name: 'A');
      final b = _playbook(name: 'B');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when version differs', () {
      final a = _playbook(version: 1);
      final b = _playbook(version: 2);
      expect(a, isNot(b));
    });
  });
}
