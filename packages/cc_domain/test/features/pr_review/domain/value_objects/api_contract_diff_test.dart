import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:test/test.dart';

/// Coverage for the swagger-style API-contract diff value objects (PRD 18 §5):
/// the [ApiChangeKind], [ApiChangeSeverity], [ApiChangeDecision] enums, the
/// [ApiContractChange] value object and the [ApiContractDiff] aggregate.
void main() {
  group('ApiChangeKind', () {
    test('wireName is the dart enum name', () {
      for (final k in ApiChangeKind.values) {
        expect(k.wireName, k.name);
      }
    });

    test('fromName parses each known kind', () {
      for (final k in ApiChangeKind.values) {
        expect(ApiChangeKind.fromName(k.name), k);
      }
    });

    test(
      'fromName defaults to endpointModified for a null or unknown name',
      () {
        expect(ApiChangeKind.fromName(null), ApiChangeKind.endpointModified);
        expect(
          ApiChangeKind.fromName('totally-bogus'),
          ApiChangeKind.endpointModified,
        );
      },
    );
  });

  group('ApiChangeSeverity', () {
    test('wireName is the dart enum name', () {
      for (final s in ApiChangeSeverity.values) {
        expect(s.wireName, s.name);
      }
    });

    test('fromName parses each known severity', () {
      for (final s in ApiChangeSeverity.values) {
        expect(ApiChangeSeverity.fromName(s.name), s);
      }
    });

    test('fromName defaults to info for a null or unknown name', () {
      expect(ApiChangeSeverity.fromName(null), ApiChangeSeverity.info);
      expect(ApiChangeSeverity.fromName('bogus'), ApiChangeSeverity.info);
    });
  });

  group('ApiChangeDecision', () {
    test('wireName is the dart enum name', () {
      for (final d in ApiChangeDecision.values) {
        expect(d.wireName, d.name);
      }
    });

    test('fromName parses each known decision', () {
      for (final d in ApiChangeDecision.values) {
        expect(ApiChangeDecision.fromName(d.name), d);
      }
    });

    test('fromName defaults to pending for a null or unknown name', () {
      expect(ApiChangeDecision.fromName(null), ApiChangeDecision.pending);
      expect(ApiChangeDecision.fromName('bogus'), ApiChangeDecision.pending);
    });
  });

  group('ApiContractChange', () {
    const base = ApiContractChange(
      id: 'c1',
      kind: ApiChangeKind.endpointRemoved,
      severity: ApiChangeSeverity.breaking,
      path: '/widgets',
      method: 'DELETE',
      detail: 'gone',
      decision: ApiChangeDecision.pending,
    );

    test('construction round-trips every field', () {
      expect(base.id, 'c1');
      expect(base.kind, ApiChangeKind.endpointRemoved);
      expect(base.severity, ApiChangeSeverity.breaking);
      expect(base.path, '/widgets');
      expect(base.method, 'DELETE');
      expect(base.detail, 'gone');
      expect(base.decision, ApiChangeDecision.pending);
    });

    test('isBreaking mirrors the breaking severity', () {
      expect(base.isBreaking, isTrue);
      const soft = ApiContractChange(
        id: 'c2',
        kind: ApiChangeKind.paramAdded,
        severity: ApiChangeSeverity.nonBreaking,
        path: '/widgets',
      );
      expect(soft.isBreaking, isFalse);
    });

    test('blocksGate is true when rejected regardless of severity', () {
      const rejected = ApiContractChange(
        id: 'c',
        kind: ApiChangeKind.schemaAdded,
        severity: ApiChangeSeverity.nonBreaking,
        path: 'Widget',
        decision: ApiChangeDecision.rejected,
      );
      expect(rejected.blocksGate, isTrue);
    });

    test('blocksGate is true when breaking and pending', () {
      expect(base.blocksGate, isTrue);
    });

    test('blocksGate is false when breaking but approved', () {
      const approved = ApiContractChange(
        id: 'c',
        kind: ApiChangeKind.endpointRemoved,
        severity: ApiChangeSeverity.breaking,
        path: '/widgets',
        decision: ApiChangeDecision.approved,
      );
      expect(approved.blocksGate, isFalse);
    });

    test('blocksGate is false when non-breaking and pending', () {
      const softPending = ApiContractChange(
        id: 'c',
        kind: ApiChangeKind.paramAdded,
        severity: ApiChangeSeverity.nonBreaking,
        path: '/widgets',
      );
      expect(softPending.blocksGate, isFalse);
    });

    group('fromJson', () {
      test('round-trips via toJson', () {
        final json = base.toJson();
        expect(json['id'], 'c1');
        expect(json['kind'], 'endpointRemoved');
        expect(json['severity'], 'breaking');
        expect(json['path'], '/widgets');
        expect(json['method'], 'DELETE');
        expect(json['detail'], 'gone');
        expect(json['decision'], 'pending');

        expect(ApiContractChange.fromJson(json), base);
      });

      test('omits method when null and detail when empty', () {
        const bare = ApiContractChange(
          id: 'x',
          kind: ApiChangeKind.schemaModified,
          severity: ApiChangeSeverity.info,
          path: 'Widget',
        );
        final json = bare.toJson();
        expect(json.containsKey('method'), isFalse);
        expect(json.containsKey('detail'), isFalse);
      });

      test('falls back to defaults when keys are missing', () {
        final r = ApiContractChange.fromJson(const {});
        expect(r.id, '');
        expect(r.kind, ApiChangeKind.endpointModified);
        expect(r.severity, ApiChangeSeverity.info);
        expect(r.path, '');
        expect(r.method, isNull);
        expect(r.detail, '');
        expect(r.decision, ApiChangeDecision.pending);
      });

      test('preserves an unknown enum string as the fromName default', () {
        final r = ApiContractChange.fromJson(const {
          'id': 'x',
          'kind': 'who-knows',
          'severity': 'who-knows',
          'decision': 'who-knows',
          'path': '/x',
        });
        expect(r.kind, ApiChangeKind.endpointModified);
        expect(r.severity, ApiChangeSeverity.info);
        expect(r.decision, ApiChangeDecision.pending);
      });
    });

    group('withDecision', () {
      test('returns a copy with the new decision only', () {
        final next = base.withDecision(ApiChangeDecision.approved);
        expect(next.decision, ApiChangeDecision.approved);
        // Every other field preserved.
        expect(next.id, base.id);
        expect(next.kind, base.kind);
        expect(next.severity, base.severity);
        expect(next.path, base.path);
        expect(next.method, base.method);
        expect(next.detail, base.detail);
      });
    });

    group('equality', () {
      test('equal by value and hash', () {
        const other = ApiContractChange(
          id: 'c1',
          kind: ApiChangeKind.endpointRemoved,
          severity: ApiChangeSeverity.breaking,
          path: '/widgets',
          method: 'DELETE',
          detail: 'gone',
          decision: ApiChangeDecision.pending,
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when any field differs', () {
        expect(base.withDecision(ApiChangeDecision.approved), isNot(base));
        const otherId = ApiContractChange(
          id: 'other',
          kind: ApiChangeKind.endpointRemoved,
          severity: ApiChangeSeverity.breaking,
          path: '/widgets',
          method: 'DELETE',
          detail: 'gone',
          decision: ApiChangeDecision.pending,
        );
        expect(otherId, isNot(base));
      });

      test('is not equal to an unrelated object', () {
        expect(base, isNot('string'));
      });
    });
  });

  group('ApiContractDiff', () {
    const base = ApiContractDiff(
      id: 'd1',
      workspaceId: 'ws',
      repoId: 'repo',
      prNodeId: 'pr',
      specPath: 'openapi.yaml',
      changes: [
        ApiContractChange(
          id: 'c1',
          kind: ApiChangeKind.endpointRemoved,
          severity: ApiChangeSeverity.breaking,
          path: '/widgets',
          decision: ApiChangeDecision.pending,
        ),
        ApiContractChange(
          id: 'c2',
          kind: ApiChangeKind.paramAdded,
          severity: ApiChangeSeverity.nonBreaking,
          path: '/widgets',
          decision: ApiChangeDecision.pending,
        ),
      ],
      headSha: 'abc',
      derived: false,
    );

    test('construction round-trips every field', () {
      expect(base.id, 'd1');
      expect(base.workspaceId, 'ws');
      expect(base.repoId, 'repo');
      expect(base.prNodeId, 'pr');
      expect(base.specPath, 'openapi.yaml');
      expect(base.changes, hasLength(2));
      expect(base.headSha, 'abc');
      expect(base.derived, isFalse);
    });

    test('hasBreaking and breakingCount count breaking changes', () {
      expect(base.hasBreaking, isTrue);
      expect(base.breakingCount, 1);
    });

    test('blocksGate reflects the worst pending breaking change', () {
      expect(base.blocksGate, isTrue);
    });

    test('blocksGate is true when a change is rejected', () {
      final rejected = base.withChangeDecision(
        'c2',
        ApiChangeDecision.rejected,
      );
      expect(rejected.blocksGate, isTrue);
    });

    test('blocksGate is false once every breaking change is approved', () {
      final approved = base.withChangeDecision(
        'c1',
        ApiChangeDecision.approved,
      );
      expect(approved.blocksGate, isFalse);
    });

    test('blocksGate is always false for a derived contract', () {
      const derived = ApiContractDiff(
        id: 'd1',
        workspaceId: 'ws',
        repoId: 'repo',
        prNodeId: 'pr',
        specPath: 'handlers.dart',
        changes: [
          ApiContractChange(
            id: 'c1',
            kind: ApiChangeKind.endpointRemoved,
            severity: ApiChangeSeverity.breaking,
            path: '/widgets',
            decision: ApiChangeDecision.rejected,
          ),
        ],
        derived: true,
      );
      expect(derived.hasBreaking, isTrue);
      expect(derived.blocksGate, isFalse);
    });

    test('hasBreaking is false when no changes break', () {
      const safe = ApiContractDiff(
        id: 'd',
        workspaceId: 'ws',
        repoId: 'repo',
        prNodeId: 'pr',
        specPath: 'openapi.yaml',
        changes: [
          ApiContractChange(
            id: 'c',
            kind: ApiChangeKind.paramAdded,
            severity: ApiChangeSeverity.nonBreaking,
            path: '/widgets',
          ),
        ],
      );
      expect(safe.hasBreaking, isFalse);
      expect(safe.breakingCount, 0);
      expect(safe.blocksGate, isFalse);
    });

    group('fromJson', () {
      test('round-trips via toJson', () {
        final json = base.toJson();
        expect(json['id'], 'd1');
        expect(json['workspaceId'], 'ws');
        expect(json['repoId'], 'repo');
        expect(json['prNodeId'], 'pr');
        expect(json['specPath'], 'openapi.yaml');
        expect(json['changes'], isA<List>());
        expect(json['headSha'], 'abc');
        expect(json['derived'], isFalse);

        expect(ApiContractDiff.fromJson(json), base);
      });

      test('omits headSha when null', () {
        const bare = ApiContractDiff(
          id: 'd',
          workspaceId: 'ws',
          repoId: 'repo',
          prNodeId: 'pr',
          specPath: 'openapi.yaml',
          changes: [],
        );
        expect(bare.toJson().containsKey('headSha'), isFalse);
      });

      test('falls back to defaults when keys are missing', () {
        final r = ApiContractDiff.fromJson(const {});
        expect(r.id, '');
        expect(r.workspaceId, '');
        expect(r.repoId, '');
        expect(r.prNodeId, '');
        expect(r.specPath, '');
        expect(r.changes, isEmpty);
        expect(r.headSha, isNull);
        expect(r.derived, isFalse);
      });

      test('ignores non-map change entries', () {
        final r = ApiContractDiff.fromJson(const {
          'changes': ['junk', 1],
        });
        expect(r.changes, isEmpty);
      });
    });

    group('withChangeDecision', () {
      test('replaces only the matching change decision', () {
        final next = base.withChangeDecision('c1', ApiChangeDecision.rejected);
        expect(next.changes[0].decision, ApiChangeDecision.rejected);
        expect(next.changes[1].decision, ApiChangeDecision.pending);
        // All other diff fields preserved.
        expect(next.id, base.id);
        expect(next.workspaceId, base.workspaceId);
        expect(next.repoId, base.repoId);
        expect(next.prNodeId, base.prNodeId);
        expect(next.specPath, base.specPath);
        expect(next.headSha, base.headSha);
        expect(next.derived, base.derived);
      });

      test('leaves the diff unchanged when no id matches', () {
        final next = base.withChangeDecision('zzz', ApiChangeDecision.approved);
        expect(
          next.changes.map((c) => c.decision).toList(),
          everyElement(ApiChangeDecision.pending),
        );
      });
    });

    group('equality', () {
      test('equal by value and hash', () {
        const other = ApiContractDiff(
          id: 'd1',
          workspaceId: 'ws',
          repoId: 'repo',
          prNodeId: 'pr',
          specPath: 'openapi.yaml',
          changes: [
            ApiContractChange(
              id: 'c1',
              kind: ApiChangeKind.endpointRemoved,
              severity: ApiChangeSeverity.breaking,
              path: '/widgets',
              decision: ApiChangeDecision.pending,
            ),
            ApiContractChange(
              id: 'c2',
              kind: ApiChangeKind.paramAdded,
              severity: ApiChangeSeverity.nonBreaking,
              path: '/widgets',
              decision: ApiChangeDecision.pending,
            ),
          ],
          headSha: 'abc',
          derived: false,
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when any field differs', () {
        expect(
          const ApiContractDiff(
            id: 'd1',
            workspaceId: 'ws',
            repoId: 'repo',
            prNodeId: 'pr',
            specPath: 'openapi.yaml',
            changes: [],
            headSha: 'abc',
            derived: false,
          ),
          isNot(base),
        );
        expect(
          const ApiContractDiff(
            id: 'd1',
            workspaceId: 'ws',
            repoId: 'repo',
            prNodeId: 'pr',
            specPath: 'openapi.yaml',
            changes: [
              ApiContractChange(
                id: 'c1',
                kind: ApiChangeKind.endpointRemoved,
                severity: ApiChangeSeverity.breaking,
                path: '/widgets',
                decision: ApiChangeDecision.pending,
              ),
              ApiContractChange(
                id: 'c2',
                kind: ApiChangeKind.paramAdded,
                severity: ApiChangeSeverity.nonBreaking,
                path: '/widgets',
                decision: ApiChangeDecision.pending,
              ),
            ],
            headSha: 'abc',
            derived: true,
          ),
          isNot(base),
        );
      });

      test('is not equal to an unrelated object', () {
        expect(base, isNot('string'));
      });
    });
  });
}
