import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_type_visuals.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('triggerPaletteEntries', () {
    test('lists every known domain event as its own searchable row', () {
      final entries = triggerPaletteEntries(l10n);
      final types = [for (final e in entries) e.eventType];

      expect(types.take(3), [
        PipelineTrigger.manualEventType,
        PipelineTrigger.scheduleEventType,
        PipelineTrigger.webhookEventType,
      ]);
      expect(types, containsAll(EventPayloadMapper.knownEventTypes));
      expect(
        types.toSet(),
        hasLength(3 + EventPayloadMapper.knownEventTypes.length),
      );
      expect(
        entries.where((e) => e.title == l10n.pipelineOnEvent),
        isEmpty,
        reason: 'the generic On event card is replaced by per-event rows',
      );
    });

    test('domain event rows have a human description, not the type name', () {
      final entries = triggerPaletteEntries(l10n);
      for (final type in EventPayloadMapper.knownEventTypes) {
        final entry = entries.firstWhere((e) => e.eventType == type);
        expect(
          entry.description,
          isNot(type),
          reason: '$type must not use the raw type name as its description',
        );
        expect(entry.description, isNotEmpty);
        expect(
          entry.description,
          isNot(entry.title),
          reason: '$type description must add information beyond the title',
        );
      }
    });

    test('filter matches title, type name, and PascalCase split', () {
      final entries = triggerPaletteEntries(l10n);

      expect(
        filterTriggerEntries(entries, 'merged').map((e) => e.eventType),
        contains('PrMerged'),
      );
      expect(
        filterTriggerEntries(entries, 'PrMerged').map((e) => e.eventType),
        ['PrMerged'],
      );
      expect(
        filterTriggerEntries(
          entries,
          'pull request',
        ).map((e) => e.eventType).toSet(),
        containsAll({
          'PullRequestPublished',
          'PullRequestStatusChanged',
        }),
      );
      expect(
        filterTriggerEntries(entries, 'ticket').map((e) => e.eventType).toSet(),
        containsAll({
          'TicketCreated',
          'TicketAssigned',
          'TicketCompleted',
          'TicketFailed',
          'TicketCancelled',
          'TicketStatusChanged',
        }),
      );
      expect(
        filterTriggerEntries(entries, 'webhook').map((e) => e.eventType),
        [PipelineTrigger.webhookEventType],
      );
    });
  });
}
