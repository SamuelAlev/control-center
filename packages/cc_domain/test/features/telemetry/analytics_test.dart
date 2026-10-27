import 'dart:async';

import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsPropertyPolicy', () {
    Map<String, Object> accepted(Map<String, Object> props) =>
        AnalyticsPropertyPolicy.apply(props).accepted;

    test('keeps tokens, numbers, flags and wrapped IDs', () {
      final id = AnalyticsId('ws-1');
      expect(
        accepted({
          'delivery': 'send',
          'model': 'claude-opus-5-5-20260101',
          'app_version': '0.0.11',
          'locale': 'zh_Hant_TW',
          'char_count': 42,
          'cost_usd': 0.25,
          'reconnect': false,
          'workspace_id': id,
          'file_count': 3,
        }),
        {
          'delivery': 'send',
          'model': 'claude-opus-5-5-20260101',
          'app_version': '0.0.11',
          'locale': 'zh_Hant_TW',
          'char_count': 42,
          'cost_usd': 0.25,
          'reconnect': false,
          'workspace_id': id,
          'file_count': 3,
        },
      );
    });

    test('refuses free text, paths, URLs and email addresses', () {
      final result = AnalyticsPropertyPolicy.apply({
        'kind': 'hello world',
        'scope': '/Users/someone/repo',
        'source': 'https://example.com',
        'mode': 'someone@example.com',
      });
      expect(result.accepted, isEmpty);
      expect(result.refused.map((v) => v.key), [
        'kind',
        'scope',
        'source',
        'mode',
      ]);
    });

    test('refuses strings under keys that name personal data', () {
      final result = AnalyticsPropertyPolicy.apply({
        'display_name': 'sam',
        'email': 'x',
        'repo_path': 'repo',
        'branch': 'main',
        'prompt': 'fix',
      });
      expect(result.accepted, isEmpty);
    });

    test('refuses raw IDs, which must arrive as AnalyticsId', () {
      final result = AnalyticsPropertyPolicy.apply({
        'workspace_id': 'ws-1',
        'run_id': 7,
        'scope': '0b6f8f6e-3f7e-4c43-9a2e-2a4b8c1f8d11',
        'kind': 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4',
      });
      expect(result.accepted, isEmpty);
      expect(result.refused, hasLength(4));
    });

    test('refuses non-finite numbers and unsupported types', () {
      final result = AnalyticsPropertyPolicy.apply({
        'ratio': double.nan,
        'items': const ['a'],
      });
      expect(result.accepted, isEmpty);
    });
  });

  group('AnalyticsPseudonymizer', () {
    test('is stable per salt and differs across salts', () {
      final a = AnalyticsPseudonymizer('a' * 32);
      final b = AnalyticsPseudonymizer('b' * 32);
      expect(a.pseudonym('ws-1'), a.pseudonym('ws-1'));
      expect(a.pseudonym('ws-1'), hasLength(20));
      expect(a.pseudonym('ws-1'), isNot(b.pseudonym('ws-1')));
      expect(a.pseudonym('ws-1'), isNot(a.pseudonym('ws-2')));
      expect(a.pseudonym('ws-1'), isNot(contains('ws-1')));
    });
  });

  group('AnalyticsEvent / AnalyticsScreenView', () {
    test('validate names, keys and route templates', () {
      expect(() => AnalyticsEvent('Message Sent'), throwsArgumentError);
      expect(
        () => AnalyticsEvent('message_sent', {'Bad Key': 1}),
        throwsArgumentError,
      );
      expect(
        () => AnalyticsScreenView(path: '/workspaces/ws 1', screen: 'space'),
        throwsArgumentError,
      );
      expect(
        AnalyticsScreenView(
          path: '/workspaces/:workspaceId/spaces/:spaceId',
          screen: 'space',
        ).path,
        '/workspaces/:workspaceId/spaces/:spaceId',
      );
      expect(AnalyticsEvent('x', {'a': null}).properties, isEmpty);
    });

    test('closed-vocabulary helpers never pass user-named values', () {
      expect(AnalyticsEvents.pipelineTriggerKind(null), 'manual');
      expect(
        AnalyticsEvents.pipelineTriggerKind('TicketCreated'),
        'TicketCreated',
      );
      expect(
        AnalyticsEvents.pipelineTriggerKind('webhook:acme-deploy'),
        'webhook',
      );
      expect(AnalyticsEvents.pipelineTriggerKind('?? odd'), 'other');
      expect(
        AnalyticsEvents.meetingProvider('https://us02web.zoom.us/j/1'),
        'zoom',
      );
      expect(AnalyticsEvents.meetingProvider('https://example.com/x'), 'other');
      expect(AnalyticsEvents.meetingProvider(null), 'other');
    });

    test('fromRoute names the screen and keeps only ID/number params', () {
      final view = AnalyticsScreenView.fromRoute(
        '/workspaces/:workspaceId/pull-requests/:prNumber',
        {'workspaceId': 'ws-1', 'prNumber': '42', 'q': 'secret search'},
      );
      expect(view.path, '/workspaces/:workspaceId/pull-requests/:prNumber');
      expect(view.screen, 'workspaces_pull_requests');
      expect(view.properties, {
        'workspace_id': AnalyticsId('ws-1'),
        'pr_number': 42,
      });
      expect(AnalyticsScreenView.fromRoute('/').screen, 'root');
      expect(
        AnalyticsScreenView.fromRoute('/ticket/:id', {'id': 't-1'}).properties,
        {'ticket_id': AnalyticsId('t-1')},
      );
    });

    test('every catalog event passes the policy untouched', () {
      final events = [
        AnalyticsEvents.appOpened(startupMs: 1200),
        AnalyticsEvents.messageSent(
          workspaceId: 'w',
          spaceId: 's',
          conversationId: 'c',
          delivery: AnalyticsEvents.messageDeliverySend,
          charCount: 10,
          attachmentCount: 1,
          agentMentionCount: 1,
          otherMentionCount: 0,
          slashCommand: 'plan',
        ),
        AnalyticsEvents.approvalDecided(
          approved: true,
          remembered: false,
          surface: 'overlay',
          actionClasses: const ['gitPush', 'processSpawn'],
          workspaceId: 'w',
          severity: 'high',
        ),
        AnalyticsEvents.agentRunCompleted(
          agentId: 'a',
          workspaceId: 'w',
          runId: 'r',
          status: 'completed',
          adapter: 'claude_code',
          model: 'claude-opus-5-5',
          durationMs: 1000,
          inputTokens: 10,
          outputTokens: 5,
          costUsd: 0.01,
        ),
        AnalyticsEvents.pipelineRunFinished(
          workspaceId: 'w',
          pipelineRunId: 'p',
          templateId: 'meeting_summary',
          outcome: 'completed',
        ),
        AnalyticsEvents.settingChanged(
          setting: 'privacy.usage_analytics',
          value: 'false',
        ),
        AnalyticsEvents.soundscapeStopped(
          mood: 'focus',
          source: 'user',
          listenedS: 600,
        ),
        AnalyticsEvents.focusModeEnded(
          elapsedS: 3000,
          completed: true,
          plannedMinutes: 50,
        ),
        AnalyticsEvents.dictationEnded(
          outcome: 'completed',
          durationS: 12,
          transcriptChars: 140,
        ),
        AnalyticsEvents.pipelineRunRequested(
          workspaceId: 'w',
          templateId: 't',
          trigger: AnalyticsEvents.pipelineTriggerKind('webhook:acme deploy'),
          dryRun: false,
          started: true,
        ),
        AnalyticsEvents.calendarConnectFinished(
          outcome: 'connected',
          builtinClient: true,
          durationS: 30,
        ),
        AnalyticsEvents.calendarRsvpSent(
          calendarEventId: 'e',
          response: 'accepted',
          previousResponse: 'needsAction',
        ),
        AnalyticsEvents.calendarMeetingJoined(
          provider: AnalyticsEvents.meetingProvider(
            'https://meet.google.com/abc-defg-hij',
          ),
        ),
        AnalyticsEvents.notificationAction(action: 'mark_all_read'),
        AnalyticsEvents.agentCreated(
          workspaceId: 'w',
          agentId: 'a',
          adapter: 'claude_code',
          model: 'claude-opus-5-5',
        ),
        AnalyticsEvents.tabOpened(kind: 'codeServer'),
        AnalyticsEvents.skillAction(action: 'install', skillSlug: 'acme-x'),
        AnalyticsEvents.planDecided(
          decision: 'approved',
          planId: 'p',
          partial: true,
          nodeCount: 3,
        ),
        AnalyticsEvents.goalStarted(
          kind: 'loop',
          workspaceId: 'w',
          spaceId: 's',
          accepted: true,
          budgetCents: 500,
        ),
        AnalyticsEvents.ticketStatusChanged(
          workspaceId: 'w',
          ticketId: 't',
          from: 'open',
          to: 'inProgress',
        ),
        AnalyticsEvents.workspaceMemberChanged(
          workspaceId: 'w',
          memberUserId: 'u',
          change: 'role_changed',
          role: 'admin',
        ),
        AnalyticsEvents.rigClosed(
          workspaceId: 'w',
          rigId: 'r',
          reason: 'idleTimeout',
          reaped: true,
        ),
        AnalyticsEvents.budgetThresholdCrossed(
          scopeType: 'workspace',
          scopeId: 'w',
          spentCents: 900,
          budgetCents: 1000,
          hardStop: false,
        ),
        AnalyticsEvents.pullRequestReviewDecisionChanged(
          workspaceId: 'w',
          repoFullName: 'acme/secret-repo',
          decision: 'CHANGES_REQUESTED',
          reviewersRemaining: 1,
        ),
      ];
      for (final event in events) {
        expect(
          AnalyticsPropertyPolicy.apply(event.properties).refused,
          isEmpty,
          reason: event.name,
        );
      }
    });
  });

  group('Analytics', () {
    late _RecordingSink sink;
    late _RecordingSink devSink;
    late List<String> diagnostics;
    var sinksBuilt = 0;

    final config = TelemetryConfig(
      usageAnalyticsEnabled: true,
      installId: 'install-1',
      pseudonymSalt: 's' * 32,
    );

    Analytics build({bool collectionAllowed = true}) {
      sink = _RecordingSink();
      devSink = _RecordingSink();
      diagnostics = [];
      sinksBuilt = 0;
      return Analytics(
        context: AnalyticsContext(
          appType: AnalyticsAppType.desktop,
          appVersion: '1.2.3',
          appBuild: 'abc1234',
          platform: 'macos',
          launchId: AnalyticsId('launch-1'),
          locale: 'en_US',
          screenWidth: 1440,
          screenHeight: 900,
        ),
        collectionAllowed: collectionAllowed,
        sinkFactory: (_) {
          sinksBuilt++;
          return sink;
        },
        developmentSink: devSink,
        onDiagnostic: diagnostics.add,
        clock: () => DateTime.utc(2026, 10, 27, 12),
      );
    }

    test('buffers until the server decides, then delivers', () {
      final analytics = build()..track(AnalyticsEvents.commandPaletteOpened());
      expect(sink.records, isEmpty);
      analytics.configure(config);
      expect(sink.records.single.name, 'command_palette_opened');
    });

    test('drops buffered records when the server says no', () {
      final analytics = build()
        ..track(AnalyticsEvents.commandPaletteOpened())
        ..configure(
          TelemetryConfig(
            usageAnalyticsEnabled: false,
            installId: 'install-1',
            pseudonymSalt: 's' * 32,
          ),
        )
        ..track(AnalyticsEvents.commandPaletteOpened());
      expect(sinksBuilt, 0);
      expect(sink.records, isEmpty);
      expect(analytics.isCollecting, isFalse);
    });

    test('turning collection off closes the sink without flushing', () {
      build()
        ..configure(config)
        ..configure(
          TelemetryConfig(
            usageAnalyticsEnabled: false,
            installId: 'install-1',
            pseudonymSalt: 's' * 32,
          ),
        );
      expect(sink.closedWithFlush, isFalse);
    });

    test('non-release builds log to the development sink only', () {
      build(collectionAllowed: false)
        ..configure(config)
        ..track(AnalyticsEvents.commandPaletteOpened());
      expect(sinksBuilt, 0);
      expect(sink.records, isEmpty);
      expect(devSink.records.single.name, 'command_palette_opened');
    });

    test(
      'the server can let a debug build send, but never without consent',
      () {
        final analytics = build(collectionAllowed: false)
          ..configure(
            TelemetryConfig(
              usageAnalyticsEnabled: true,
              installId: 'install-1',
              pseudonymSalt: 's' * 32,
              debugBuildsAllowed: true,
            ),
          )
          ..track(AnalyticsEvents.commandPaletteOpened());
        expect(sinksBuilt, 1);
        expect(sink.records.single.name, 'command_palette_opened');
        expect(devSink.records, isEmpty);

        analytics
          ..configure(
            TelemetryConfig(
              usageAnalyticsEnabled: false,
              installId: 'install-1',
              pseudonymSalt: 's' * 32,
              debugBuildsAllowed: true,
            ),
          )
          ..track(AnalyticsEvents.commandPaletteOpened());
        expect(sink.records, hasLength(1));
        expect(sink.closedWithFlush, isFalse);
      },
    );

    test('TelemetryConfig carries the debug override over the wire', () {
      final config = TelemetryConfig(
        usageAnalyticsEnabled: true,
        installId: 'i',
        pseudonymSalt: 's' * 32,
        debugBuildsAllowed: true,
      );
      expect(TelemetryConfig.fromWire(config.toWire()), config);
    });

    test('merges context, pseudonymizes IDs and never sends raw IDs', () {
      final analytics = build()
        ..configure(config)
        ..identify(userId: 'user-raw', deviceId: 'device-raw')
        ..screen(
          AnalyticsScreenView(
            path: '/workspaces/:workspaceId',
            screen: 'workspace',
          ),
        )
        ..track(AnalyticsEvents.workspaceSwitched(workspaceId: 'ws-raw'));
      expect(analytics.isCollecting, isTrue);

      final event = sink.records.last;
      final pseudonymizer = AnalyticsPseudonymizer('s' * 32);
      expect(event.kind, AnalyticsEnvelopeKind.event);
      expect(event.path, '/workspaces/:workspaceId');
      expect(event.screen, '1440x900');
      expect(event.locale, 'en_US');
      expect(event.distinctId, pseudonymizer.pseudonym('device-raw'));
      expect(event.properties['app_type'], 'desktop');
      expect(event.properties['app_version'], '1.2.3');
      expect(event.properties['platform'], 'macos');
      expect(event.properties['event_seq'], 2);
      expect(
        event.properties['workspace_id'],
        pseudonymizer.pseudonym('ws-raw'),
      );
      expect(
        event.properties['install_id'],
        pseudonymizer.pseudonym('install-1'),
      );
      expect(event.properties['user_id'], pseudonymizer.pseudonym('user-raw'));
      final serialized = event.properties.values.join(' ');
      for (final raw in ['ws-raw', 'user-raw', 'device-raw', 'launch-1']) {
        expect(serialized, isNot(contains(raw)));
      }
    });

    test('reports refused properties by key, never by value', () {
      build()
        ..configure(config)
        ..track(AnalyticsEvent('custom_event', {'kind': 'free text here'}));
      expect(sink.records.single.properties.containsKey('kind'), isFalse);
      expect(diagnostics.single, contains('kind'));
      expect(diagnostics.single, isNot(contains('free text')));
    });

    test('bounds the pre-consent buffer', () {
      final analytics = build();
      for (var i = 0; i < analytics.pendingLimit + 10; i++) {
        analytics.track(AnalyticsEvents.commandPaletteOpened());
      }
      analytics.configure(config);
      expect(sink.records, hasLength(analytics.pendingLimit));
      expect(sink.records.first.properties['event_seq'], 11);
    });
  });

  group('ServerTelemetryConfigRepository', () {
    test('mints a stable identity once and defaults to off', () async {
      final settings = _MemorySettings();
      final repo = ServerTelemetryConfigRepository(settings);
      final results = await Future.wait([repo.get(), repo.get()]);
      expect(results[0], results[1]);
      expect(results[0].usageAnalyticsEnabled, isFalse);
      expect(results[0].pseudonymSalt, hasLength(64));
      expect(settings.writes, 2);

      final again = await ServerTelemetryConfigRepository(settings).get();
      expect(again, results[0]);
    });

    test('watch follows the operator switch', () async {
      final settings = _MemorySettings();
      final repo = ServerTelemetryConfigRepository(settings);
      final seen = <bool>[];
      final sub = repo.watch().listen((c) => seen.add(c.usageAnalyticsEnabled));
      await pumpEventQueue();
      await repo.setUsageAnalyticsEnabled(enabled: true);
      await pumpEventQueue();
      await repo.setUsageAnalyticsEnabled(enabled: false);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [false, true, false]);
    });
  });
}

class _RecordingSink implements AnalyticsSink {
  final records = <AnalyticsEnvelope>[];
  bool? closedWithFlush;

  @override
  void record(AnalyticsEnvelope envelope) => records.add(envelope);

  @override
  Future<void> flush() async {}

  @override
  Future<void> close({bool flush = true}) async {
    closedWithFlush = flush;
  }
}

class _MemorySettings implements ServerSettingsRepository {
  final _values = <String, String>{};
  final _changes = StreamController<Map<String, String>>.broadcast();
  int writes = 0;

  @override
  Future<String?> get(String key) async => _values[key];

  @override
  Future<Map<String, String>> getAll() async => Map.of(_values);

  @override
  Stream<Map<String, String>> watchAll() async* {
    yield Map.of(_values);
    yield* _changes.stream;
  }

  @override
  Future<void> set(String key, String? value) async {
    writes++;
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    _changes.add(Map.of(_values));
  }
}
