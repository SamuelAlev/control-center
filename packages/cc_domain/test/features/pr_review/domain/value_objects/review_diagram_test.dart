import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:test/test.dart';

/// Coverage for the typed review diagrams (PRD 18 §3): the [ReviewDiagramKind]
/// enum, the [ReviewDiagram.fromJson] discriminator, and each concrete subtype
/// ([SequenceDiagram], [EntityRelationDiagram], [StateMachineDiagram]) with its
/// component value objects, JSON round-trips and mermaid export.
void main() {
  group('ReviewDiagramKind', () {
    test('wireName is the dart enum name', () {
      for (final k in ReviewDiagramKind.values) {
        expect(k.wireName, k.name);
      }
    });

    test('fromName parses each known kind', () {
      for (final k in ReviewDiagramKind.values) {
        expect(ReviewDiagramKind.fromName(k.name), k);
      }
    });

    test('fromName defaults to sequence for a null or unknown name', () {
      expect(ReviewDiagramKind.fromName(null), ReviewDiagramKind.sequence);
      expect(ReviewDiagramKind.fromName('bogus'), ReviewDiagramKind.sequence);
    });
  });

  group('ReviewDiagram.fromJson', () {
    test('dispatches to SequenceDiagram by kind discriminator', () {
      final d = ReviewDiagram.fromJson(const {'kind': 'sequence'});
      expect(d, isA<SequenceDiagram>());
    });

    test('dispatches to EntityRelationDiagram by kind discriminator', () {
      final d = ReviewDiagram.fromJson(const {'kind': 'entityRelation'});
      expect(d, isA<EntityRelationDiagram>());
    });

    test('dispatches to StateMachineDiagram by kind discriminator', () {
      final d = ReviewDiagram.fromJson(const {'kind': 'stateMachine'});
      expect(d, isA<StateMachineDiagram>());
    });

    test('defaults to SequenceDiagram when kind is null or unknown', () {
      expect(ReviewDiagram.fromJson(const {}), isA<SequenceDiagram>());
      expect(
        ReviewDiagram.fromJson(const {'kind': 'bogus'}),
        isA<SequenceDiagram>(),
      );
    });
  });

  group('SequenceMessage', () {
    const base = SequenceMessage(
      from: 'A',
      to: 'B',
      label: 'doThing',
      symbolRef: 'sym1',
      corroborated: true,
    );

    test('construction round-trips every field', () {
      expect(base.from, 'A');
      expect(base.to, 'B');
      expect(base.label, 'doThing');
      expect(base.symbolRef, 'sym1');
      expect(base.corroborated, isTrue);
    });

    test('defaults corroborated to true when omitted', () {
      const m = SequenceMessage(from: 'A', to: 'B', label: 'x');
      expect(m.corroborated, isTrue);
    });

    group('fromJson', () {
      test('round-trips via toJson', () {
        expect(SequenceMessage.fromJson(base.toJson()), base);
      });

      test('omits symbolRef when null', () {
        const noSym = SequenceMessage(from: 'A', to: 'B', label: 'x');
        expect(noSym.toJson().containsKey('symbolRef'), isFalse);
      });

      test('falls back to defaults when keys are missing', () {
        final m = SequenceMessage.fromJson(const {});
        expect(m.from, '');
        expect(m.to, '');
        expect(m.label, '');
        expect(m.symbolRef, isNull);
        expect(m.corroborated, isTrue);
      });
    });

    test('withCorroboration flips the flag and preserves the rest', () {
      final next = base.withCorroboration(value: false);
      expect(next.corroborated, isFalse);
      expect(next.from, base.from);
      expect(next.to, base.to);
      expect(next.label, base.label);
      expect(next.symbolRef, base.symbolRef);
    });

    group('equality', () {
      test('equal by value and hash', () {
        const other = SequenceMessage(
          from: 'A',
          to: 'B',
          label: 'doThing',
          symbolRef: 'sym1',
          corroborated: true,
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when any field differs', () {
        expect(base.withCorroboration(value: false), isNot(base));
        expect(
          const SequenceMessage(from: 'Z', to: 'B', label: 'doThing'),
          isNot(base),
        );
      });

      test('is not equal to an unrelated object', () {
        expect(base, isNot('string'));
      });
    });
  });

  group('SequenceDiagram', () {
    const base = SequenceDiagram(
      title: 'Flow',
      participants: ['A', 'B'],
      messages: [
        SequenceMessage(from: 'A', to: 'B', label: 'call'),
        SequenceMessage(
          from: 'B',
          to: 'A',
          label: 'reply',
          symbolRef: 'sym',
          corroborated: false,
        ),
      ],
    );

    test('kind is sequence', () {
      expect(base.kind, ReviewDiagramKind.sequence);
    });

    test(
      'isFullyCorroborated is true only when every message is corroborated',
      () {
        expect(base.isFullyCorroborated, isFalse);
        const allGood = SequenceDiagram(
          title: 'Flow',
          participants: ['A'],
          messages: [SequenceMessage(from: 'A', to: 'A', label: 'self')],
        );
        expect(allGood.isFullyCorroborated, isTrue);
      },
    );

    group('fromJson', () {
      test('round-trips via toJson', () {
        final json = base.toJson();
        expect(json['kind'], 'sequence');
        expect(json['title'], 'Flow');
        expect(SequenceDiagram.fromJson(json), base);
      });

      test('falls back to defaults when keys are missing', () {
        final d = SequenceDiagram.fromJson(const {});
        expect(d.title, '');
        expect(d.participants, isEmpty);
        expect(d.messages, isEmpty);
      });

      test('drops non-string participants and non-map messages', () {
        final d = SequenceDiagram.fromJson(const {
          'participants': ['A', 1, 'B'],
          'messages': [
            'junk',
            {'from': 'A', 'to': 'B'},
          ],
        });
        expect(d.participants, ['A', 'B']);
        expect(d.messages, hasLength(1));
        expect(d.messages.single.from, 'A');
      });
    });

    test(
      'toMermaid renders participants and corroborated/unverified arrows',
      () {
        final m = base.toMermaid();
        expect(m, startsWith('sequenceDiagram'));
        expect(m, contains('participant A as A'));
        expect(m, contains('participant B as B'));
        // corroborated arrow uses ->>
        expect(m, contains('A->>B: call'));
        // uncorroborated arrow uses -->> with the unverified suffix
        expect(m, contains('B-->>A: reply (unverified)'));
      },
    );

    group('equality', () {
      test('equal by value and hash', () {
        const other = SequenceDiagram(
          title: 'Flow',
          participants: ['A', 'B'],
          messages: [
            SequenceMessage(from: 'A', to: 'B', label: 'call'),
            SequenceMessage(
              from: 'B',
              to: 'A',
              label: 'reply',
              symbolRef: 'sym',
              corroborated: false,
            ),
          ],
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when title, participants or messages differ', () {
        expect(
          const SequenceDiagram(title: 'Other', participants: [], messages: []),
          isNot(base),
        );
        expect(base, isNot('string'));
      });
    });
  });

  group('ErField', () {
    const base = ErField(name: 'id', type: 'uuid', isKey: true);

    test('construction round-trips every field', () {
      expect(base.name, 'id');
      expect(base.type, 'uuid');
      expect(base.isKey, isTrue);
    });

    test('fromJson round-trips via toJson', () {
      final json = base.toJson();
      expect(json['name'], 'id');
      expect(json['type'], 'uuid');
      expect(json['isKey'], isTrue);
      expect(ErField.fromJson(json), base);
    });

    test('omits isKey when false', () {
      const nonKey = ErField(name: 'name', type: 'string');
      expect(nonKey.toJson().containsKey('isKey'), isFalse);
    });

    test('fromJson falls back to defaults', () {
      final f = ErField.fromJson(const {});
      expect(f.name, '');
      expect(f.type, '');
      expect(f.isKey, isFalse);
    });

    test('equality by value and hash', () {
      const same = ErField(name: 'id', type: 'uuid', isKey: true);
      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(const ErField(name: 'id', type: 'uuid')));
      expect(base, isNot('string'));
    });
  });

  group('ErEntity', () {
    const base = ErEntity(
      name: 'Widget',
      fields: [
        ErField(name: 'id', type: 'uuid', isKey: true),
        ErField(name: 'label', type: 'string'),
      ],
    );

    test('fromJson round-trips via toJson', () {
      final json = base.toJson();
      expect(json['name'], 'Widget');
      expect(json['fields'], isA<List>());
      expect(ErEntity.fromJson(json), base);
    });

    test('falls back to an empty name and fields when missing', () {
      final e = ErEntity.fromJson(const {});
      expect(e.name, '');
      expect(e.fields, isEmpty);
    });

    test('drops non-map field entries', () {
      final e = ErEntity.fromJson(const {
        'name': 'Widget',
        'fields': [
          'junk',
          {'name': 'id', 'type': 'uuid'},
        ],
      });
      expect(e.fields, hasLength(1));
      expect(e.fields.single.name, 'id');
    });

    test('equality by value and hash', () {
      expect(base, isNot('string'));
      expect(
        base,
        const ErEntity(
          name: 'Widget',
          fields: [
            ErField(name: 'id', type: 'uuid', isKey: true),
            ErField(name: 'label', type: 'string'),
          ],
        ),
      );
    });
  });

  group('ErRelation', () {
    const base = ErRelation(
      from: 'Widget',
      to: 'Part',
      label: 'has',
      cardinality: '||--o{',
    );

    test('defaults label to empty and cardinality to ||--o{', () {
      const r = ErRelation(from: 'A', to: 'B');
      expect(r.label, '');
      expect(r.cardinality, '||--o{');
    });

    test('fromJson round-trips via toJson', () {
      expect(ErRelation.fromJson(base.toJson()), base);
    });

    test('omits label when empty', () {
      const noLabel = ErRelation(from: 'A', to: 'B');
      expect(noLabel.toJson().containsKey('label'), isFalse);
    });

    test('fromJson falls back to defaults', () {
      final r = ErRelation.fromJson(const {});
      expect(r.from, '');
      expect(r.to, '');
      expect(r.label, '');
      expect(r.cardinality, '||--o{');
    });

    test('equality by value and hash', () {
      expect(
        base,
        const ErRelation(
          from: 'Widget',
          to: 'Part',
          label: 'has',
          cardinality: '||--o{',
        ),
      );
      expect(base, isNot(const ErRelation(from: 'Widget', to: 'Part')));
      expect(base, isNot('string'));
    });
  });

  group('EntityRelationDiagram', () {
    const base = EntityRelationDiagram(
      title: 'Schema',
      entities: [
        ErEntity(
          name: 'Widget',
          fields: [ErField(name: 'id', type: 'uuid', isKey: true)],
        ),
      ],
      relations: [
        ErRelation(from: 'Widget', to: 'Part', label: 'has'),
        ErRelation(from: 'A', to: 'B'), // empty label
      ],
    );

    test('kind is entityRelation', () {
      expect(base.kind, ReviewDiagramKind.entityRelation);
    });

    test('is always fully corroborated', () {
      expect(base.isFullyCorroborated, isTrue);
    });

    group('fromJson', () {
      test('round-trips via toJson', () {
        final json = base.toJson();
        expect(json['kind'], 'entityRelation');
        expect(json['title'], 'Schema');
        expect(EntityRelationDiagram.fromJson(json), base);
      });

      test('falls back to empty title, entities and relations', () {
        final d = EntityRelationDiagram.fromJson(const {});
        expect(d.title, '');
        expect(d.entities, isEmpty);
        expect(d.relations, isEmpty);
      });

      test('drops non-map entity and relation entries', () {
        final d = EntityRelationDiagram.fromJson(const {
          'entities': [
            'junk',
            {'name': 'Widget', 'fields': []},
          ],
          'relations': [
            1,
            {'from': 'A', 'to': 'B'},
          ],
        });
        expect(d.entities, hasLength(1));
        expect(d.relations, hasLength(1));
      });
    });

    test(
      'toMermaid renders relations (with empty-label fallback) and entities',
      () {
        final m = base.toMermaid();
        expect(m, startsWith('erDiagram'));
        // Labeled relation
        expect(m, contains('Widget ||--o{ Part : has'));
        // Empty-label relation falls back to 'relates'
        expect(m, contains('A ||--o{ B : relates'));
        // Entity block with a PK field
        expect(m, contains('Widget {'));
        expect(m, contains('uuid id PK'));
      },
    );

    test('equality by value and hash', () {
      const other = EntityRelationDiagram(
        title: 'Schema',
        entities: [
          ErEntity(
            name: 'Widget',
            fields: [ErField(name: 'id', type: 'uuid', isKey: true)],
          ),
        ],
        relations: [
          ErRelation(from: 'Widget', to: 'Part', label: 'has'),
          ErRelation(from: 'A', to: 'B'),
        ],
      );
      expect(base, other);
      expect(base.hashCode, other.hashCode);
      expect(base, isNot('string'));
    });
  });

  group('StateTransition', () {
    const base = StateTransition(
      from: 'idle',
      to: 'running',
      label: 'start',
      corroborated: true,
    );

    test('defaults label to empty and corroborated to true', () {
      const t = StateTransition(from: 'a', to: 'b');
      expect(t.label, '');
      expect(t.corroborated, isTrue);
    });

    test('fromJson round-trips via toJson', () {
      expect(StateTransition.fromJson(base.toJson()), base);
    });

    test('omits label when empty', () {
      const noLabel = StateTransition(from: 'a', to: 'b');
      expect(noLabel.toJson().containsKey('label'), isFalse);
    });

    test('fromJson falls back to defaults', () {
      final t = StateTransition.fromJson(const {});
      expect(t.from, '');
      expect(t.to, '');
      expect(t.label, '');
      expect(t.corroborated, isTrue);
    });

    test('withCorroboration flips the flag and preserves the rest', () {
      final next = base.withCorroboration(value: false);
      expect(next.corroborated, isFalse);
      expect(next.from, base.from);
      expect(next.to, base.to);
      expect(next.label, base.label);
    });

    test('equality by value and hash', () {
      expect(
        base,
        const StateTransition(
          from: 'idle',
          to: 'running',
          label: 'start',
          corroborated: true,
        ),
      );
      expect(base, isNot(base.withCorroboration(value: false)));
      expect(base, isNot('string'));
    });
  });

  group('StateMachineDiagram', () {
    const base = StateMachineDiagram(
      title: 'Lifecycle',
      states: ['idle', 'running'],
      transitions: [
        StateTransition(from: 'idle', to: 'running', label: 'start'),
        StateTransition(
          from: 'running',
          to: 'idle',
          label: '',
          corroborated: false,
        ),
        StateTransition(
          from: 'running',
          to: 'failed',
          label: 'crash',
          corroborated: false,
        ),
      ],
      initialState: 'idle',
    );

    test('kind is stateMachine', () {
      expect(base.kind, ReviewDiagramKind.stateMachine);
    });

    test(
      'isFullyCorroborated is true only when every transition is corroborated',
      () {
        expect(base.isFullyCorroborated, isFalse);
        const allGood = StateMachineDiagram(
          title: 'X',
          states: ['a'],
          transitions: [StateTransition(from: 'a', to: 'a')],
        );
        expect(allGood.isFullyCorroborated, isTrue);
      },
    );

    group('fromJson', () {
      test('round-trips via toJson', () {
        final json = base.toJson();
        expect(json['kind'], 'stateMachine');
        expect(json['initialState'], 'idle');
        expect(StateMachineDiagram.fromJson(json), base);
      });

      test('omits initialState when null', () {
        const noInitial = StateMachineDiagram(
          title: 'X',
          states: ['a'],
          transitions: [],
        );
        expect(noInitial.toJson().containsKey('initialState'), isFalse);
      });

      test('falls back to defaults when keys are missing', () {
        final d = StateMachineDiagram.fromJson(const {});
        expect(d.title, '');
        expect(d.states, isEmpty);
        expect(d.transitions, isEmpty);
        expect(d.initialState, isNull);
      });

      test('drops non-string states and non-map transitions', () {
        final d = StateMachineDiagram.fromJson(const {
          'states': ['a', 1, 'b'],
          'transitions': [
            'junk',
            {'from': 'a', 'to': 'b'},
          ],
        });
        expect(d.states, ['a', 'b']);
        expect(d.transitions, hasLength(1));
      });
    });

    test('toMermaid renders the initial state and every transition branch', () {
      final m = base.toMermaid();
      expect(m, startsWith('stateDiagram-v2'));
      // Initial state prefix
      expect(m, contains('[*] --> idle'));
      // Labeled corroborated transition
      expect(m, contains('idle --> running : start'));
      // Empty-label uncorroborated transition -> " : unverified"
      expect(m, contains('running --> idle : unverified'));
      // Labeled uncorroborated transition -> "label (unverified)"
      expect(m, contains('running --> failed : crash (unverified)'));
    });

    test(
      'toMermaid omits the initial-state line when initialState is null',
      () {
        const d = StateMachineDiagram(
          title: 'X',
          states: ['a'],
          transitions: [StateTransition(from: 'a', to: 'b', label: 'go')],
        );
        final m = d.toMermaid();
        expect(m.contains('[*]'), isFalse);
        expect(m, contains('a --> b : go'));
      },
    );

    group('equality', () {
      test('equal by value and hash', () {
        const other = StateMachineDiagram(
          title: 'Lifecycle',
          states: ['idle', 'running'],
          transitions: [
            StateTransition(from: 'idle', to: 'running', label: 'start'),
            StateTransition(
              from: 'running',
              to: 'idle',
              label: '',
              corroborated: false,
            ),
            StateTransition(
              from: 'running',
              to: 'failed',
              label: 'crash',
              corroborated: false,
            ),
          ],
          initialState: 'idle',
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when initialState, states or transitions differ', () {
        expect(
          const StateMachineDiagram(
            title: 'Lifecycle',
            states: ['idle', 'running'],
            transitions: [
              StateTransition(from: 'idle', to: 'running', label: 'start'),
              StateTransition(
                from: 'running',
                to: 'idle',
                label: '',
                corroborated: false,
              ),
              StateTransition(
                from: 'running',
                to: 'failed',
                label: 'crash',
                corroborated: false,
              ),
            ],
          ),
          isNot(base),
        );
        expect(base, isNot('string'));
      });
    });
  });

  group('mermaid identifier sanitization (via toMermaid)', () {
    test('replaces non-alphanumeric characters with underscores', () {
      final d = const SequenceDiagram(
        title: 't',
        participants: ['Order Service'],
        messages: [
          SequenceMessage(
            from: 'Order Service',
            to: 'Order Service',
            label: 'x',
          ),
        ],
      ).toMermaid();
      expect(d, contains('participant Order_Service as Order Service'));
      expect(d, contains('Order_Service->>Order_Service: x'));
    });

    test('prefixes a leading digit with n', () {
      final d = const SequenceDiagram(
        title: 't',
        participants: ['1Lane'],
        messages: [],
      ).toMermaid();
      expect(d, contains('participant n1Lane as 1Lane'));
    });

    test('collapses an all-special-character label to underscores', () {
      final d = const SequenceDiagram(
        title: 't',
        participants: ['!!!'],
        messages: [],
      ).toMermaid();
      // '!!!' -> replaceAll produces '___' (non-empty), rendered as-is.
      expect(d, contains('participant ___ as !!!'));
    });

    test('renders an empty participant label as n', () {
      // The only way the mermaidId 'n' fallback fires is an empty string.
      final d = const SequenceDiagram(
        title: 't',
        participants: [''],
        messages: [],
      ).toMermaid();
      // The empty name yields the sanitized id 'n'; the trailing whitespace is
      // stripped from the buffer's final line by trimRight.
      expect(d, contains('participant n'));
    });
  });
}
