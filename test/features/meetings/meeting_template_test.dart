import 'dart:async';

import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_template.dart';
import 'package:control_center/features/meetings/providers/meeting_template_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeetingTemplate model', () {
    test(
      'built-ins start with the no-op default and are all flagged builtIn',
      () {
        expect(MeetingTemplate.builtIns.first.id, MeetingTemplate.defaultId);
        expect(MeetingTemplate.builtIns.first.instructions, isEmpty);
        expect(MeetingTemplate.builtIns.every((t) => t.builtIn), isTrue);
        // Ids are unique.
        final ids = MeetingTemplate.builtIns.map((t) => t.id).toSet();
        expect(ids.length, MeetingTemplate.builtIns.length);
      },
    );

    test('copyWith preserves id and builtIn, overrides name/instructions', () {
      const t = MeetingTemplate(
        id: 'x',
        name: 'Old',
        instructions: 'old',
        builtIn: true,
      );
      final c = t.copyWith(name: 'New', instructions: 'new');
      expect(c.id, 'x');
      expect(c.name, 'New');
      expect(c.instructions, 'new');
      expect(c.builtIn, isTrue);
    });

    test('equality and hashCode are value-based', () {
      const a = MeetingTemplate(id: 'a', name: 'A', instructions: 'i');
      const b = MeetingTemplate(id: 'a', name: 'A', instructions: 'i');
      const c = MeetingTemplate(id: 'a', name: 'A', instructions: 'j');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('fromJson rejects missing/empty id or name', () {
      expect(MeetingTemplate.fromJson({'name': 'n'}), isNull);
      expect(MeetingTemplate.fromJson({'id': '', 'name': 'n'}), isNull);
      expect(MeetingTemplate.fromJson({'id': 'i'}), isNull);
      expect(MeetingTemplate.fromJson({'id': 'i', 'name': ''}), isNull);
    });

    test(
      'fromJson defaults instructions to empty when absent or wrong type',
      () {
        expect(
          MeetingTemplate.fromJson({'id': 'i', 'name': 'n'})!.instructions,
          isEmpty,
        );
        expect(
          MeetingTemplate.fromJson({
            'id': 'i',
            'name': 'n',
            'instructions': 42,
          })!.instructions,
          isEmpty,
        );
      },
    );

    test('encode/decode round-trips custom templates', () {
      const custom = [
        MeetingTemplate(id: 'c1', name: 'One', instructions: 'do one'),
        MeetingTemplate(id: 'c2', name: 'Two', instructions: ''),
      ];
      final decoded = MeetingTemplate.decodeCustom(
        MeetingTemplate.encodeCustom(custom),
      );
      expect(decoded, custom);
    });

    test('decodeCustom tolerates garbage', () {
      expect(MeetingTemplate.decodeCustom(null), isEmpty);
      expect(MeetingTemplate.decodeCustom(''), isEmpty);
      expect(MeetingTemplate.decodeCustom('not json'), isEmpty);
      expect(MeetingTemplate.decodeCustom('{"not":"a list"}'), isEmpty);
      // A list with one valid + one invalid entry keeps only the valid one.
      expect(
        MeetingTemplate.decodeCustom(
          '[{"id":"ok","name":"OK"},{"name":"no id"}]',
        ).map((t) => t.id),
        ['ok'],
      );
    });
  });

  group('MeetingTemplatesNotifier', () {
    late _FakeWorkspaceSettingsRepository repo;

    Future<ProviderContainer> container(Map<String, String> seed) async {
      repo = _FakeWorkspaceSettingsRepository(seed);
      return ProviderContainer(
        overrides: [
          workspaceSettingsRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdProvider.overrideWith(
            () => _FixedActiveWorkspaceNotifier('ws-1'),
          ),
        ],
      );
    }

    /// Lets the settings watch stream deliver its first (seeded) event and the
    /// dependent notifiers rebuild — several event-loop turns, because a plain
    /// provider container has no frame pump to flush them.
    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('exposes built-ins when no custom templates are stored', () async {
      final c = await container({});
      addTearDown(c.dispose);
      await pump();
      expect(c.read(meetingTemplatesProvider), MeetingTemplate.builtIns);
    });

    test('loads workspace custom templates after the built-ins', () async {
      final c = await container({
        meetingTemplatesSettingKey: MeetingTemplate.encodeCustom(const [
          MeetingTemplate(id: 'c1', name: 'Custom', instructions: 'x'),
        ]),
      });
      addTearDown(c.dispose);
      // Hold a listener so the settings-stream → notifier chain stays built
      // while the seeded event is delivered.
      final sub = c.listen(meetingTemplatesProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();
      final all = c.read(meetingTemplatesProvider);
      expect(all.length, MeetingTemplate.builtIns.length + 1);
      expect(all.last.id, 'c1');
      expect(all.last.builtIn, isFalse);
    });

    test(
      'upsert adds then updates a custom template and persists it',
      () async {
        final c = await container({});
        addTearDown(c.dispose);
        final notifier = c.read(meetingTemplatesProvider.notifier);

        await notifier.upsert(
          const MeetingTemplate(id: 'c1', name: 'First', instructions: 'a'),
        );
        expect(c.read(meetingTemplatesProvider).last.name, 'First');

        await notifier.upsert(
          const MeetingTemplate(id: 'c1', name: 'Renamed', instructions: 'b'),
        );
        final all = c.read(meetingTemplatesProvider);
        // Still only one custom row, now updated.
        expect(all.length, MeetingTemplate.builtIns.length + 1);
        expect(all.last.name, 'Renamed');

        // Persisted to the workspace settings store.
        expect(
          await repo.get('ws-1', meetingTemplatesSettingKey),
          MeetingTemplate.encodeCustom(const [
            MeetingTemplate(id: 'c1', name: 'Renamed', instructions: 'b'),
          ]),
        );
      },
    );

    test('upsert ignores built-in templates', () async {
      final c = await container({});
      addTearDown(c.dispose);
      await c
          .read(meetingTemplatesProvider.notifier)
          .upsert(MeetingTemplate.builtIns.first.copyWith(name: 'Hacked'));
      expect(c.read(meetingTemplatesProvider), MeetingTemplate.builtIns);
    });

    test('remove deletes a custom template', () async {
      final c = await container({});
      addTearDown(c.dispose);
      final notifier = c.read(meetingTemplatesProvider.notifier);
      await notifier.upsert(
        const MeetingTemplate(id: 'c1', name: 'Doomed', instructions: ''),
      );
      await notifier.remove('c1');
      expect(c.read(meetingTemplatesProvider), MeetingTemplate.builtIns);
    });
  });

  group('selected/active meeting template', () {
    late _FakeWorkspaceSettingsRepository repo;

    Future<ProviderContainer> container(Map<String, String> seed) async {
      repo = _FakeWorkspaceSettingsRepository(seed);
      return ProviderContainer(
        overrides: [
          workspaceSettingsRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdProvider.overrideWith(
            () => _FixedActiveWorkspaceNotifier('ws-1'),
          ),
        ],
      );
    }

    /// Lets the settings watch stream deliver its first (seeded) event and the
    /// dependent notifiers rebuild — several event-loop turns, because a plain
    /// provider container has no frame pump to flush them.
    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('defaults to the no-op default template', () async {
      final c = await container({});
      addTearDown(c.dispose);
      await pump();
      expect(
        c.read(selectedMeetingTemplateProvider),
        MeetingTemplate.defaultId,
      );
      expect(
        c.read(activeMeetingTemplateProvider).id,
        MeetingTemplate.defaultId,
      );
    });

    test(
      'select persists to the workspace and resolves the active template',
      () async {
        final c = await container({});
        addTearDown(c.dispose);
        await c
            .read(selectedMeetingTemplateProvider.notifier)
            .select('one_on_one');
        expect(c.read(activeMeetingTemplateProvider).id, 'one_on_one');
        expect(
          await repo.get('ws-1', activeMeetingTemplateSettingKey),
          'one_on_one',
        );
      },
    );

    test(
      'active falls back to default when the selected id is unknown',
      () async {
        final c = await container({
          activeMeetingTemplateSettingKey: 'deleted_custom',
        });
        addTearDown(c.dispose);
        final sub = c.listen(selectedMeetingTemplateProvider, (_, _) {});
        addTearDown(sub.close);
        await pump();
        expect(c.read(selectedMeetingTemplateProvider), 'deleted_custom');
        expect(
          c.read(activeMeetingTemplateProvider).id,
          MeetingTemplate.defaultId,
        );
      },
    );
  });
}

/// In-memory [WorkspaceSettingsRepository]: `set` mutates the map and echoes it
/// on the watch stream, mimicking the server's authoritative store.
class _FakeWorkspaceSettingsRepository implements WorkspaceSettingsRepository {
  _FakeWorkspaceSettingsRepository([Map<String, String>? seed])
    : _settings = Map.of(seed ?? const {}),
      _updates = StreamController<Map<String, String>>.broadcast();

  final Map<String, String> _settings;
  final StreamController<Map<String, String>> _updates;

  @override
  Future<String?> get(String workspaceId, String key) async => _settings[key];

  @override
  Future<Map<String, String>> getAll(String workspaceId) async =>
      Map.of(_settings);

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) async* {
    yield Map.of(_settings);
    yield* _updates.stream.map(Map.of);
  }

  @override
  Future<void> set(String workspaceId, String key, String? value) async {
    if (value == null) {
      _settings.remove(key);
    } else {
      _settings[key] = value;
    }
    _updates.add(Map.of(_settings));
  }
}

/// Pins the active workspace for a provider container.
class _FixedActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _FixedActiveWorkspaceNotifier(this._id);

  final String? _id;

  @override
  String? build() => _id;
}
