import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/trigger_preview_service.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineDefinition _def(String id, {required bool handsOff}) =>
    PipelineDefinition(
      templateId: id,
      workspaceId: 'ws1',
      name: 'Template $id',
      steps: [
        PipelineStepDefinition(
          id: 'step',
          kind: StepKind.listen,
          bodyKey: handsOff ? 'pipeline.promptAgent' : 'pipeline.bashScript',
        ),
      ],
    );

PipelineTrigger _trigger(
  String id,
  String templateId, {
  String eventType = 'TicketAssigned',
  bool enabled = true,
  Map<String, dynamic> match = const {},
}) => PipelineTrigger(
  id: id,
  eventType: eventType,
  templateId: templateId,
  workspaceId: 'ws1',
  enabled: enabled,
  match: match,
);

void main() {
  const service = TriggerPreviewService();

  test(
    'counts only the enabled, matching triggers as runs that would start',
    () {
      final preview = service.preview(
        eventType: 'TicketAssigned',
        payload: {'workspaceId': 'ws1'},
        triggers: [
          _trigger('a', 'tpl_a'),
          _trigger('b', 'tpl_b'),
          _trigger('c', 'tpl_c', enabled: false), // disabled
          _trigger('d', 'tpl_d', eventType: 'PrMerged'), // different event
        ],
        templates: [
          _def('tpl_a', handsOff: true),
          _def('tpl_b', handsOff: false),
          _def('tpl_c', handsOff: true),
        ],
      );

      expect(preview.willEnqueueCount, 2); // "2 runs would start"
      expect(preview.enqueuing.map((e) => e.templateId), {'tpl_a', 'tpl_b'});
    },
  );

  test('respects the per-trigger payload filter', () {
    final preview = service.preview(
      eventType: 'PullRequestStatusChanged',
      payload: {'status': 'opened'},
      triggers: [
        _trigger(
          'merged-only',
          'cleanup',
          eventType: 'PullRequestStatusChanged',
          match: {
            'status': ['merged', 'closed'],
          },
        ),
      ],
      templates: [_def('cleanup', handsOff: false)],
    );
    expect(preview.willEnqueueCount, 0);
    expect(preview.items.single.reason, contains('filter'));
  });

  test('reports handoff_supported per template', () {
    final preview = service.preview(
      eventType: 'TicketAssigned',
      payload: const {},
      triggers: [_trigger('a', 'tpl_a'), _trigger('b', 'tpl_b')],
      templates: [
        _def('tpl_a', handsOff: true),
        _def('tpl_b', handsOff: false),
      ],
    );
    final byTemplate = {for (final i in preview.items) i.templateId: i};
    expect(byTemplate['tpl_a']!.handoffSupported, isTrue);
    expect(byTemplate['tpl_b']!.handoffSupported, isFalse);
  });
}
