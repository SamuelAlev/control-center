import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show BuiltInBodyKeys;
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/catalog/pipeline_shell_guard.dart';
import 'package:test/test.dart';

/// The server-side rules every `pipeline_trigger.insert` / `.update` and
/// `pipeline_template.upsert` goes through (audit H4, H5, H6 and the schedule
/// / template-existence validation).
void main() {
  RepoOpContext ctx(WorkspaceRole role) => RepoOpContext(
    args: const {},
    workspaceId: 'ws-1',
    deviceId: 'device-1',
    userId: 'user-1',
    role: role,
  );
  final member = ctx(WorkspaceRole.member);
  final admin = ctx(WorkspaceRole.admin);

  PipelineDefinition template(String id, List<String> bodies) =>
      PipelineDefinition(
        templateId: id,
        workspaceId: 'ws-1',
        name: id,
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: BuiltInBodyKeys.trigger,
          ),
          for (final (i, body) in bodies.indexed)
            PipelineStepDefinition(
              id: 's$i',
              kind: StepKind.listen,
              bodyKey: body,
            ),
        ],
      );

  late _Templates templates;
  late _Triggers triggers;
  setUp(() {
    templates = _Templates({
      'inert': template('inert', [BuiltInBodyKeys.humanGate]),
      'agent': template('agent', [BuiltInBodyKeys.promptAgent]),
      'shell': template('shell', [BuiltInBodyKeys.bashScript]),
    });
    triggers = _Triggers();
  });

  PipelineTrigger trigger({
    String id = 't1',
    String templateId = 'inert',
    String eventType = 'TicketAssigned',
    bool enabled = true,
    String? cron,
    String? timezone,
    String? token,
    String workspaceId = 'ws-1',
  }) => PipelineTrigger(
    id: id,
    eventType: eventType,
    templateId: templateId,
    workspaceId: workspaceId,
    enabled: enabled,
    cronExpression: cron,
    timezone: timezone,
    webhookToken: token,
  );

  Future<PipelineTrigger> write(
    RepoOpContext c,
    PipelineTrigger incoming, {
    PipelineTrigger? previous,
  }) => preparePipelineTriggerWrite(
    c,
    templates: templates,
    incoming: incoming,
    previous: previous,
    mintToken: () => 'minted',
    isKnownTimezone: (tz) => tz == 'Europe/Berlin',
  );

  group('webhook tokens are server-minted (H4)', () {
    test('a client token is ignored on insert', () async {
      final out = await write(
        member,
        trigger(eventType: PipelineTrigger.webhookEventType, token: 'victim'),
      );
      expect(out.webhookToken, 'minted');
    });

    test('an update keeps the stored token, not the client one', () async {
      final stored = trigger(
        eventType: PipelineTrigger.webhookEventType,
        token: 'stored',
      );
      final out = await write(
        member,
        trigger(eventType: PipelineTrigger.webhookEventType, token: 'victim'),
        previous: stored,
      );
      expect(out.webhookToken, 'stored');
    });

    test('a non-webhook trigger gets no token', () async {
      final out = await write(member, trigger(token: 'x'));
      expect(out.webhookToken, isNull);
    });

    test('the workspace comes from the bound context', () async {
      final out = await write(member, trigger(workspaceId: 'ws-2'));
      expect(out.workspaceId, 'ws-1');
    });
  });

  group('arming is admin-gated for privileged pipelines (H5)', () {
    test('a member may arm a trigger on an inert pipeline', () async {
      final out = await write(member, trigger());
      expect(out.enabled, isTrue);
    });

    test('a member may not arm one that dispatches an agent', () async {
      await expectLater(
        write(member, trigger(templateId: 'agent')),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        write(
          member,
          trigger(
            templateId: 'agent',
            eventType: PipelineTrigger.scheduleEventType,
            cron: 'every:60',
          ),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('a member may add it disarmed, or as a manual trigger', () async {
      await write(member, trigger(templateId: 'agent', enabled: false));
      await write(
        member,
        trigger(
          templateId: 'agent',
          eventType: PipelineTrigger.manualEventType,
        ),
      );
    });

    test('a member may disarm an armed trigger', () async {
      final stored = trigger(templateId: 'agent');
      final out = await write(
        member,
        trigger(templateId: 'agent', enabled: false),
        previous: stored,
      );
      expect(out.enabled, isFalse);
    });

    test('an admin may arm it', () async {
      await write(admin, trigger(templateId: 'agent'));
    });

    test('any trigger on a shell pipeline is admin-only', () async {
      await expectLater(
        write(member, trigger(templateId: 'shell', enabled: false)),
        throwsA(isA<AuthException>()),
      );
      await write(admin, trigger(templateId: 'shell'));
    });
  });

  group('validation', () {
    test('the template must exist in the workspace', () async {
      await expectLater(
        write(admin, trigger(templateId: 'missing')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('a schedule must parse', () async {
      for (final cron in ['every:0', 'every:-1', 'nope', '']) {
        await expectLater(
          write(
            admin,
            trigger(eventType: PipelineTrigger.scheduleEventType, cron: cron),
          ),
          throwsA(isA<ValidationException>()),
          reason: cron,
        );
      }
    });

    test('a schedule timezone must be a known zone', () async {
      await expectLater(
        write(
          admin,
          trigger(
            eventType: PipelineTrigger.scheduleEventType,
            cron: '0 9 * * *',
            timezone: 'Mars/Base',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      final ok = await write(
        admin,
        trigger(
          eventType: PipelineTrigger.scheduleEventType,
          cron: '0 9 * * *',
          timezone: 'Europe/Berlin',
        ),
      );
      expect(ok.timezone, 'Europe/Berlin');
    });

    test('an update cannot change event type or template', () async {
      final stored = trigger();
      await expectLater(
        write(admin, trigger(templateId: 'agent'), previous: stored),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        write(admin, trigger(eventType: 'PrMerged'), previous: stored),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a schedule edit clears nextRunAt so it is recomputed', () async {
      final stored = trigger(
        eventType: PipelineTrigger.scheduleEventType,
        cron: '0 9 * * *',
      ).copyWith(nextRunAt: DateTime.utc(2026, 7, 1, 9));
      final same = await write(
        admin,
        trigger(
          eventType: PipelineTrigger.scheduleEventType,
          cron: '0 9 * * *',
        ),
        previous: stored,
      );
      expect(same.nextRunAt, stored.nextRunAt);
      final changed = await write(
        admin,
        trigger(
          eventType: PipelineTrigger.scheduleEventType,
          cron: '0 10 * * *',
        ),
        previous: stored,
      );
      expect(changed.nextRunAt, isNull);
    });
  });

  group('template writes', () {
    Future<PipelineDefinition> upsert(
      RepoOpContext c,
      PipelineDefinition incoming,
    ) => preparePipelineTemplateWrite(
      c,
      templates: templates,
      triggers: triggers,
      incoming: incoming,
    );

    test('a client cannot mark a template built-in (H6)', () async {
      final out = await upsert(
        member,
        template('new', [BuiltInBodyKeys.humanGate]).copyWith(isBuiltIn: true),
      );
      expect(out.isBuiltIn, isFalse);
    });

    test('editing a built-in clears the flag; toggling keeps it', () async {
      final builtIn = template('inert', [
        BuiltInBodyKeys.humanGate,
      ]).copyWith(isBuiltIn: true);
      templates.rows['inert'] = builtIn;

      final toggled = await upsert(member, builtIn.copyWith(isEnabled: false));
      expect(toggled.isBuiltIn, isTrue);
      expect(toggled.isEnabled, isFalse);

      final edited = await upsert(member, builtIn.copyWith(name: 'Mine'));
      expect(edited.isBuiltIn, isFalse);
    });

    test('a member cannot add or edit a shell step', () async {
      await expectLater(
        upsert(member, template('new', [BuiltInBodyKeys.bashScript])),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        upsert(member, templates.rows['shell']!.copyWith(name: 'x')),
        throwsA(isA<AuthException>()),
      );
      await upsert(admin, template('new', [BuiltInBodyKeys.bashScript]));
    });

    test(
      'a member cannot slip a privileged step behind an armed trigger',
      () async {
        triggers.rows.add(trigger());
        await expectLater(
          upsert(member, template('inert', [BuiltInBodyKeys.promptAgent])),
          throwsA(isA<AuthException>()),
        );
        triggers.rows
          ..clear()
          ..add(trigger(enabled: false));
        await upsert(member, template('inert', [BuiltInBodyKeys.promptAgent]));
      },
    );
  });
}

class _Templates implements PipelineTemplateRepository {
  _Templates(this.rows);
  final Map<String, PipelineDefinition> rows;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => workspaceId == 'ws-1' ? rows[templateId] : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Triggers implements PipelineTriggerConfigRepository {
  final List<PipelineTrigger> rows = [];

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async =>
      rows.where((t) => t.workspaceId == workspaceId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
