import 'package:cc_infra/src/detection/claude_code_model_catalog.dart';
import 'package:cc_infra/src/detection/claude_code_model_probe.dart';
import 'package:test/test.dart';

/// Answers like the installed CLI would, and counts how often it is asked.
class _FakeProbe extends ClaudeCodeModelProbe {
  _FakeProbe(this.answer);

  ClaudeCodeProbeResult Function(bool listCatalog, List<String> extraIds)
  answer;
  final calls = <({bool listCatalog, List<String> extraIds})>[];

  @override
  Future<ClaudeCodeProbeResult> probe({
    required String binaryPath,
    String? configDir,
    bool listCatalog = true,
    List<String> extraIds = const [],
  }) async {
    calls.add((listCatalog: listCatalog, extraIds: extraIds));
    return answer(listCatalog, extraIds);
  }
}

const _all = ['low', 'medium', 'high', 'xhigh', 'max'];

/// What 2.1.316 answers for a first-party subscription.
ClaudeCodeProbeResult _cli(bool listCatalog, List<String> extraIds) =>
    ClaudeCodeProbeResult(
      models: listCatalog
          ? const [
              ClaudeCodeProbedModel(
                value: 'default',
                resolvedModel: 'claude-opus-5-5',
                displayName: 'Default (recommended)',
                effortLevels: _all,
                contextWindow: 1000000,
              ),
              ClaudeCodeProbedModel(
                value: 'opus',
                resolvedModel: 'claude-opus-5-5',
                displayName: 'Opus 5.5',
                effortLevels: _all,
                contextWindow: 1000000,
              ),
              ClaudeCodeProbedModel(
                value: 'sonnet',
                resolvedModel: 'claude-sonnet-5-5',
                displayName: 'Sonnet 5.5',
                effortLevels: _all,
                contextWindow: 1000000,
              ),
              ClaudeCodeProbedModel(
                value: 'claude-haiku-4-5-20251001',
                resolvedModel: 'claude-haiku-4-5-20251001',
                displayName: 'Haiku 4.5',
                contextWindow: 200000,
              ),
              ClaudeCodeProbedModel(
                value: 'claude-opus-4-6',
                resolvedModel: 'claude-opus-4-6',
                displayName: 'Opus 4.6',
                effortLevels: ['low', 'medium', 'high', 'max'],
                contextWindow: 200000,
              ),
              ClaudeCodeProbedModel(
                value: 'claude-opus-5',
                displayName: 'Opus 5',
                contextWindow: 1000000,
                disabled: true,
              ),
            ]
          : const [],
      defaultWindow: 1000000,
      extras: {
        for (final id in extraIds)
          if (id == 'opusplan')
            id: const ClaudeCodeProbedModel(
              value: 'opusplan',
              resolvedModel: 'claude-sonnet-5-5',
              contextWindow: 1000000,
            )
          else if (id == 'claude-opus-4-6[1m]')
            id: const ClaudeCodeProbedModel(
              value: 'claude-opus-4-6[1m]',
              resolvedModel: 'claude-opus-4-6[1m]',
              contextWindow: 1000000,
            ),
        // `best` and anything else: refused.
      },
    );

void main() {
  late _FakeProbe probe;
  late DateTime now;
  String? binary;

  ClaudeCodeModelCatalog catalog() => ClaudeCodeModelCatalog(
    probe: probe,
    resolveBinary: (_) async => binary,
    now: () => now,
  );

  setUp(() {
    probe = _FakeProbe(_cli);
    now = DateTime(2026, 11, 3);
    binary = '/nonexistent/claude';
  });

  group('models', () {
    test('names follow the app convention, not the CLI labels', () async {
      final models = await catalog().models();
      final names = {for (final m in models) m.id: m.name};

      expect(names['opus'], 'Opus (latest)');
      expect(names['sonnet'], 'Sonnet (latest)');
      expect(names['opusplan'], 'Opus in plan mode, else Sonnet');
      expect(names['claude-opus-5-5'], 'Claude Opus 5.5');
      expect(names['claude-opus-4-6'], 'Claude Opus 4.6');
      expect(
        names['claude-haiku-4-5-20251001'],
        'Claude Haiku 4.5 (2025-10-01)',
      );
    });

    test('aliases, then modes, then model ids — the one each alias runs '
        'included', () async {
      final ids = [for (final m in await catalog().models()) m.id];

      expect(ids, [
        'opus',
        'sonnet',
        'opusplan',
        'claude-opus-5-5',
        'claude-sonnet-5-5',
        'claude-haiku-4-5-20251001',
        'claude-opus-4-6',
      ]);
    });

    test('default, disabled and refused rows are not offered', () async {
      final ids = {for (final m in await catalog().models()) m.id};

      expect(ids, isNot(contains('default')));
      expect(ids, isNot(contains('claude-opus-5')));
      expect(ids, isNot(contains('best')));
    });

    test('windows and levels are the CLI\'s', () async {
      final byId = {for (final m in await catalog().models()) m.id: m};

      expect(byId['opus']!.contextWindow, 1000000);
      expect(byId['claude-opus-5-5']!.contextWindow, 1000000);
      expect(byId['claude-opus-4-6']!.contextWindow, 200000);
      expect(byId['claude-opus-4-6']!.thinkingLevels!.map((l) => l.id), [
        'low',
        'medium',
        'high',
        'max',
      ]);
      expect(byId['opus']!.thinkingLevels!.last.label, 'Max');
      expect(byId['opus']!.defaultThinkingLevel, 'medium');
      // No `--effort` on Haiku 4.5: no levels, not invented ones.
      expect(byId['claude-haiku-4-5-20251001']!.thinkingLevels, isNull);
      // A mode borrows the levels of the model it runs as.
      expect(byId['opusplan']!.thinkingLevels, hasLength(5));
    });

    test('an unreadable CLI offers the family aliases only', () async {
      probe.answer = (_, _) => throw StateError('not logged in');

      final models = await catalog().models();

      expect(
        [for (final m in models) m.id],
        ['opus', 'sonnet', 'haiku', 'fable'],
      );
      expect(models.every((m) => m.contextWindow == null), isTrue);
    });

    test('no claude binary offers the family aliases only', () async {
      binary = null;

      expect(await catalog().models(), ClaudeCodeModelCatalog.fallback);
      expect(probe.calls, isEmpty);
    });
  });

  group('caching', () {
    test('one read serves concurrent callers and repeat calls', () async {
      final c = catalog();
      await Future.wait([c.models(), c.models(), c.contextWindowOf('opus')]);
      await c.models();

      expect(probe.calls, hasLength(1));
    });

    test('an expired read is served while the CLI is re-read', () async {
      final c = catalog();
      final first = await c.models();
      now = now.add(const Duration(hours: 2));
      probe.answer = (_, _) => throw StateError('refresh failed');

      // Served at once from the old read; the refresh runs behind it.
      expect(await c.models(), same(first));
      await Future<void>.delayed(Duration.zero);
      expect(probe.calls, hasLength(2));
      // A failed refresh keeps the read it was replacing.
      expect(await c.models(), same(first));
      expect(probe.calls, hasLength(2));
    });

    test('a failed read is retried only after a pause', () async {
      probe.answer = (_, _) => throw StateError('boom');
      final c = catalog();
      await c.models();
      await c.models();
      expect(probe.calls, hasLength(1));

      probe.answer = _cli;
      now = now.add(const Duration(minutes: 1));
      expect(await c.models(), hasLength(greaterThan(4)));
      expect(probe.calls, hasLength(2));
    });
  });

  group('contextWindowOf', () {
    test('reads listed ids, aliases and the ids they resolve to', () async {
      final c = catalog();

      expect(await c.contextWindowOf('opus'), 1000000);
      expect(await c.contextWindowOf('claude-opus-4-6'), 200000);
      expect(await c.contextWindowOf('claude-sonnet-5-5'), 1000000);
      expect(await c.contextWindowOf('opusplan'), 1000000);
      expect(probe.calls, hasLength(1));
    });

    test('no model is the CLI default model', () async {
      expect(await catalog().contextWindowOf(null), 1000000);
    });

    test('an unlisted id is asked about once', () async {
      final c = catalog();

      expect(await c.contextWindowOf('claude-opus-4-6[1m]'), 1000000);
      expect(await c.contextWindowOf('claude-opus-4-6[1m]'), 1000000);
      expect(probe.calls.last.listCatalog, isFalse);
      expect(probe.calls.last.extraIds, ['claude-opus-4-6[1m]']);
      expect(probe.calls, hasLength(2));
    });

    test('an id the CLI refuses has no window', () async {
      expect(await catalog().contextWindowOf('claude-nope'), isNull);
    });

    test('an unreadable CLI has no window, never a guessed one', () async {
      probe.answer = (_, _) => throw StateError('boom');

      expect(await catalog().contextWindowOf('opus'), isNull);
    });
  });

  group('nameOf', () {
    test('covers ids the CLI may add later', () {
      expect(ClaudeCodeModelCatalog.nameOf('fable'), 'Fable (latest)');
      expect(ClaudeCodeModelCatalog.nameOf('opus[1m]'), 'Opus (1M context)');
      expect(
        ClaudeCodeModelCatalog.nameOf('claude-opus-9-1'),
        'Claude Opus 9.1',
      );
      expect(
        ClaudeCodeModelCatalog.nameOf('claude-sonnet-4-6[1m]', 'Sonnet 4.6'),
        'Claude Sonnet 4.6 (1M context)',
      );
      // The CLI's own qualifier is replaced, never doubled.
      expect(
        ClaudeCodeModelCatalog.nameOf(
          'claude-sonnet-4-6[1m]',
          'Sonnet 4.6 (1M context)',
        ),
        'Claude Sonnet 4.6 (1M context)',
      );
      expect(
        ClaudeCodeModelCatalog.nameOf('claude-3-5-haiku-20241022'),
        'Claude Haiku 3.5 (2024-10-22)',
      );
    });
  });
}
