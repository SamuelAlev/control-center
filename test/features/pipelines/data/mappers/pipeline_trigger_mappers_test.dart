import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/pipeline_trigger_mappers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('triggerToCompanion', () {
    test('converts all fields to companion with Value wrappers', () {
      final now = DateTime(2025, 6, 11);
      final lastFired = DateTime(2025, 6, 10);
      final trigger = PipelineTrigger(
        id: 't-1',
        eventType: 'pr_merged',
        templateId: 'tmpl-1',
        workspaceId: 'ws-1',
        enabled: true,
        cronExpression: 'every:3600',
        match: {'status': 'merged'},
        lastFiredAt: lastFired,
        createdAt: now,
      );

      final companion = triggerToCompanion(trigger);

      expect(companion.id, const Value('t-1'));
      expect(companion.eventType, const Value('pr_merged'));
      expect(companion.templateId, const Value('tmpl-1'));
      expect(companion.workspaceId, const Value('ws-1'));
      expect(companion.enabled, const Value(true));
      expect(companion.cronExpression, const Value('every:3600'));
      expect(companion.matchJson, Value(jsonEncode({'status': 'merged'})));
      expect(companion.lastFiredAt, Value(lastFired));
      expect(companion.createdAt, Value(now));
    });

    test('empty match map serializes correctly', () {
      final trigger = PipelineTrigger(
        id: 't-2',
        eventType: 'push',
        templateId: 'tmpl-2',
        workspaceId: 'ws-1',
        match: const {},
      );

      final companion = triggerToCompanion(trigger);

      expect(companion.matchJson, const Value('{}'));
    });

    test('disabled trigger with null optional fields', () {
      final trigger = PipelineTrigger(
        id: 't-3',
        eventType: 'schedule',
        templateId: 'tmpl-3',
        workspaceId: 'ws-3',
        enabled: false,
      );

      final companion = triggerToCompanion(trigger);

      expect(companion.enabled, const Value(false));
      expect(companion.cronExpression, const Value(null));
      expect(companion.lastFiredAt, const Value(null));
    });
  });

  group('triggerFromRow', () {
    test('parses all fields from row data', () {
      final now = DateTime(2025, 6, 11);
      final lastFired = DateTime(2025, 6, 10);
      final row = PipelineTriggersTableData(
        id: 't-1',
        eventType: 'pr_merged',
        templateId: 'tmpl-1',
        workspaceId: 'ws-1',
        enabled: true,
        cronExpression: 'every:3600',
        matchJson: '{"status":"merged"}',
        lastFiredAt: lastFired,
        createdAt: now,
      );

      final trigger = triggerFromRow(row);

      expect(trigger.id, 't-1');
      expect(trigger.eventType, 'pr_merged');
      expect(trigger.templateId, 'tmpl-1');
      expect(trigger.workspaceId, 'ws-1');
      expect(trigger.enabled, isTrue);
      expect(trigger.cronExpression, 'every:3600');
      expect(trigger.match, {'status': 'merged'});
      expect(trigger.lastFiredAt, lastFired);
      expect(trigger.createdAt, now);
    });

    test('malformed matchJson falls back to empty map', () {
      final row = PipelineTriggersTableData(
        id: 't-2',
        eventType: 'push',
        templateId: 'tmpl-2',
        workspaceId: 'ws-2',
        enabled: false,
        cronExpression: null,
        matchJson: 'not-json',
        lastFiredAt: null,
        createdAt: DateTime(2025, 1, 1),
      );

      final trigger = triggerFromRow(row);

      expect(trigger.match, isEmpty);
    });

    test('matchJson that is not a Map falls back to empty map', () {
      final row = PipelineTriggersTableData(
        id: 't-3',
        eventType: 'push',
        templateId: 'tmpl-3',
        workspaceId: 'ws-3',
        enabled: false,
        cronExpression: null,
        matchJson: '[1, 2, 3]',
        lastFiredAt: null,
        createdAt: DateTime(2025, 1, 1),
      );

      final trigger = triggerFromRow(row);

      expect(trigger.match, isEmpty);
    });
  });

  group('trigger round-trip', () {
    test('domain → companion → rebuilt row → domain preserves equality', () {
      final original = PipelineTrigger(
        id: 't-r1',
        eventType: 'pr_merged',
        templateId: 'tmpl-r1',
        workspaceId: 'ws-r1',
        enabled: true,
        cronExpression: 'every:7200',
        match: {'status': ['merged', 'closed']},
        lastFiredAt: DateTime(2025, 6, 9),
        createdAt: DateTime(2025, 6, 1),
      );

      final companion = triggerToCompanion(original);
      // Simulate Drift: build a row-like object with the companion values
      final roundtripped = triggerFromRow(
        PipelineTriggersTableData(
          id: companion.id.value,
          eventType: companion.eventType.value,
          templateId: companion.templateId.value,
          workspaceId: companion.workspaceId.value,
          enabled: companion.enabled.value,
          cronExpression: companion.cronExpression.value,
          matchJson: companion.matchJson.value,
          lastFiredAt: companion.lastFiredAt.value,
          createdAt: companion.createdAt.value,
        ),
      );

      expect(roundtripped, original);
    });
  });

  group('newTriggerId', () {
    test('generates unique UUIDs', () {
      final ids = List.generate(10, (_) => newTriggerId());
      expect(ids.toSet().length, 10);
    });

    test('generates a valid UUID v4', () {
      final id = newTriggerId();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });
  });
}
