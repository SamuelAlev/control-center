import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';

/// One trigger's verdict in a [TriggerPreview].
class TriggerPreviewItem {
  /// Creates a [TriggerPreviewItem].
  const TriggerPreviewItem({
    required this.triggerId,
    required this.templateId,
    required this.templateName,
    required this.willEnqueue,
    required this.reason,
    required this.handoffSupported,
  });

  /// The trigger this verdict is for.
  final String triggerId;

  /// The template the trigger would start.
  final String templateId;

  /// Human-readable template name (or the id when no definition is found).
  final String templateName;

  /// Whether this trigger would enqueue a run for the previewed event.
  final bool willEnqueue;

  /// Why it would / would not enqueue.
  final String reason;

  /// Whether the resulting run hands off to an agent or human (it contains a
  /// dispatch / approval / fan-out node) rather than running purely
  /// deterministically.
  final bool handoffSupported;
}

/// The result of a dry-run trigger preview.
class TriggerPreview {
  /// Creates a [TriggerPreview].
  const TriggerPreview({required this.eventType, required this.items});

  /// The event type that was previewed.
  final String eventType;

  /// Per-trigger verdicts.
  final List<TriggerPreviewItem> items;

  /// How many runs would actually start.
  int get willEnqueueCount => items.where((i) => i.willEnqueue).length;

  /// The items that would enqueue.
  List<TriggerPreviewItem> get enqueuing =>
      items.where((i) => i.willEnqueue).toList();
}

/// Read-only "which runs would start" dry-run for a hypothetical event.
///
/// This is the single `willEnqueueRun` predicate every entry point (create /
/// single-assign / single-status / batch) consults — so a preview and the real
/// dispatch agree on exactly which triggers fire.
class TriggerPreviewService {
  /// Creates a [TriggerPreviewService].
  const TriggerPreviewService();

  /// Body keys whose presence in a template means a run "hands off" to an agent
  /// or human rather than running purely deterministically.
  static const Set<String> _handoffBodyKeys = {
    'conversation.promptAgent',
    'team.dispatch',
    'human.gate',
    'flow.forEach',
    'flow.callPipeline',
  };

  /// The core predicate: would [trigger] enqueue a run for [eventType] given
  /// the candidate [payload]? Returns `(will, reason)`.
  (bool, String) willEnqueueRun(
    PipelineTrigger trigger,
    String eventType,
    Map<String, dynamic> payload,
  ) {
    if (trigger.eventType != eventType) {
      return (false, 'trigger listens for a different event');
    }
    if (!trigger.enabled) {
      return (false, 'trigger is disabled');
    }
    if (!trigger.matches(payload)) {
      return (false, 'event payload does not satisfy the trigger filter');
    }
    return (true, 'would enqueue a run');
  }

  /// Previews every workspace trigger against a candidate event.
  TriggerPreview preview({
    required String eventType,
    required Map<String, dynamic> payload,
    required List<PipelineTrigger> triggers,
    required List<PipelineDefinition> templates,
  }) {
    final byId = {for (final t in templates) t.templateId: t};
    final items = <TriggerPreviewItem>[];
    for (final trigger in triggers) {
      if (trigger.eventType != eventType) {
        continue;
      }
      final (will, reason) = willEnqueueRun(trigger, eventType, payload);
      final def = byId[trigger.templateId];
      items.add(
        TriggerPreviewItem(
          triggerId: trigger.id,
          templateId: trigger.templateId,
          templateName: def?.name ?? trigger.templateId,
          willEnqueue: will,
          reason: reason,
          handoffSupported: def != null && _handsOff(def),
        ),
      );
    }
    return TriggerPreview(eventType: eventType, items: items);
  }

  bool _handsOff(PipelineDefinition def) =>
      def.steps.any((s) => _handoffBodyKeys.contains(s.bodyKey));
}
