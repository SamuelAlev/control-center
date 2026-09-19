import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Palette grouping for a pipeline node type. [triggers] is first so the
/// sidebar pins start-event entries above body types.
enum PipelineNodeCategory {
  /// Start events (manual, schedule, webhook, domain event).
  triggers,

  /// Routers, gates, fan-out, sub-pipelines.
  flow,

  /// PR clone / comment / reviewer steps.
  pr,

  /// Prompt-driven agents and team dispatch.
  agents,

  /// Conversation and space posts.
  messaging,

  /// Shell / script steps.
  code,
}

/// Icon + category for one node type (or a [StepKind] fallback).
///
/// One table is shared by the sidebar, the editor tiles and the quick-insert
/// picker so a type cannot look like "code" in the palette and "flow" on the
/// canvas. Glyphs are Phosphor via [AppIcons] — never `NodeType.iconCodePoint`,
/// which is a stale Material Symbols index.
class PipelineNodeVisual {
  /// Creates a [PipelineNodeVisual].
  const PipelineNodeVisual({required this.icon, required this.category});

  /// Leading glyph for the type.
  final IconData icon;

  /// Palette section this type belongs to.
  final PipelineNodeCategory category;
}

/// Eyebrow style shared by palette section headers and the on-canvas
/// "When this happens" / "Do this" labels — small, tracked, uppercase, mono.
TextStyle pipelineNodeEyebrowStyle(DesignSystemTokens tokens) {
  return CcFonts.code(
    textStyle: TextStyle(
      color: tokens.textTertiary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      height: 1.2,
      decoration: TextDecoration.none,
    ),
  );
}

/// Localized label for a [PipelineNodeCategory].
String pipelineNodeCategoryLabel(
  AppLocalizations l10n,
  PipelineNodeCategory category,
) {
  return switch (category) {
    PipelineNodeCategory.triggers => l10n.nodeCategoryTriggers,
    PipelineNodeCategory.flow => l10n.nodeCategoryFlow,
    PipelineNodeCategory.pr => l10n.nodeCategoryPr,
    PipelineNodeCategory.agents => l10n.nodeCategoryAgents,
    PipelineNodeCategory.messaging => l10n.nodeCategoryMessaging,
    PipelineNodeCategory.code => l10n.nodeCategoryCode,
  };
}

/// Sidebar / ghost-picker payload for a start trigger. Dropping one on the
/// canvas inserts a [PipelineTrigger] whose graph node sits at the drop point.
class TriggerPaletteEntry {
  /// Creates a [TriggerPaletteEntry].
  const TriggerPaletteEntry({
    required this.eventType,
    required this.title,
    required this.description,
    required this.icon,
  });

  /// [PipelineTrigger.eventType] written when this entry is added.
  final String eventType;

  /// Localized row title.
  final String title;

  /// Localized one-line help under [title].
  final String description;

  /// Leading glyph (matches the on-canvas tile).
  final IconData icon;
}

/// Glyph for a trigger [eventType]: start-kind icons, then event-family icons.
IconData iconForTriggerEventType(String eventType) {
  return switch (eventType) {
    PipelineTrigger.manualEventType => AppIcons.play,
    PipelineTrigger.scheduleEventType => AppIcons.clock,
    PipelineTrigger.webhookEventType => AppIcons.plug,
    'PullRequestStatusChanged' => AppIcons.gitPullRequest,
    'PullRequestPublished' => AppIcons.gitPullRequestCreate,
    'PrMerged' => AppIcons.gitMerge,
    'ExternalPrDetected' => AppIcons.gitPullRequestArrow,
    'MessageReceived' => AppIcons.messageSquare,
    'TicketCreated' ||
    'TicketAssigned' ||
    'TicketCompleted' ||
    'TicketFailed' ||
    'TicketCancelled' ||
    'TicketStatusChanged' => AppIcons.ticket,
    'BudgetThresholdCrossed' => AppIcons.dollarSign,
    'RepoAdded' => AppIcons.folderGit2,
    'MeetingRecordingStopped' => AppIcons.mic,
    'SkillUpdated' => AppIcons.sparkles,
    'SpaceDeleted' => AppIcons.trash2,
    _ => AppIcons.zap,
  };
}

bool _isSyntheticTrigger(String eventType) {
  return eventType == PipelineTrigger.manualEventType ||
      eventType == PipelineTrigger.scheduleEventType ||
      eventType == PipelineTrigger.webhookEventType;
}

String _triggerEntryHaystack(TriggerPaletteEntry entry) {
  final split = entry.eventType.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  final domainTokens = _isSyntheticTrigger(entry.eventType)
      ? ''
      : 'event on event domain';
  return '${entry.title} ${entry.description} ${entry.eventType} $split '
          'on ${entry.title} $domainTokens'
      .toLowerCase();
}

/// Start-trigger palette rows: manual, schedule, webhook, then one row per
/// [EventPayloadMapper.knownEventTypes] so search can hit "merged" or
/// `PrMerged` instead of a generic "On event" card.
List<TriggerPaletteEntry> triggerPaletteEntries(AppLocalizations l10n) {
  return [
    for (final eventType in [
      PipelineTrigger.manualEventType,
      PipelineTrigger.scheduleEventType,
      PipelineTrigger.webhookEventType,
      ...EventPayloadMapper.knownEventTypes,
    ])
      TriggerPaletteEntry(
        eventType: eventType,
        title: triggerEventLabel(l10n, eventType),
        description: triggerEventHelp(l10n, eventType),
        icon: iconForTriggerEventType(eventType),
      ),
  ];
}

/// Case-insensitive filter over title, description, event type, and a
/// PascalCase split of the type name (`pull request` → `PullRequestPublished`).
List<TriggerPaletteEntry> filterTriggerEntries(
  List<TriggerPaletteEntry> entries,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return entries;
  }
  return [
    for (final entry in entries)
      if (_triggerEntryHaystack(entry).contains(q)) entry,
  ];
}

/// Visuals for every `defaultNodeTypeLibrary()` id. Unknown ids fall back to
/// a generic flow circle rather than throwing — a user-authored body key
/// still has to render.
const Map<String, PipelineNodeVisual> kPipelineNodeTypeVisuals = {
  'bash.script': PipelineNodeVisual(
    icon: AppIcons.terminal,
    category: PipelineNodeCategory.code,
  ),
  'bash.clonePr': PipelineNodeVisual(
    icon: AppIcons.gitBranch,
    category: PipelineNodeCategory.pr,
  ),
  'messaging.createSpace': PipelineNodeVisual(
    icon: AppIcons.messageSquarePlus,
    category: PipelineNodeCategory.messaging,
  ),
  'prReview.comment': PipelineNodeVisual(
    icon: AppIcons.gitPullRequest,
    category: PipelineNodeCategory.pr,
  ),
  'prompt.reviewer': PipelineNodeVisual(
    icon: AppIcons.sparkles,
    category: PipelineNodeCategory.pr,
  ),
  'prompt.join': PipelineNodeVisual(
    icon: AppIcons.gitMerge,
    category: PipelineNodeCategory.agents,
  ),
  'prompt.custom': PipelineNodeVisual(
    icon: AppIcons.bot,
    category: PipelineNodeCategory.agents,
  ),
  'messaging.postSpace': PipelineNodeVisual(
    icon: AppIcons.messageSquare,
    category: PipelineNodeCategory.messaging,
  ),
  'pipeline.condition': PipelineNodeVisual(
    icon: AppIcons.gitCompareArrows,
    category: PipelineNodeCategory.flow,
  ),
  'condition.fileExists': PipelineNodeVisual(
    icon: AppIcons.fileCode,
    category: PipelineNodeCategory.flow,
  ),
  'condition.anyOf': PipelineNodeVisual(
    icon: AppIcons.gitFork,
    category: PipelineNodeCategory.flow,
  ),
  'condition.allOf': PipelineNodeVisual(
    icon: AppIcons.layers,
    category: PipelineNodeCategory.flow,
  ),
  'team.dispatch': PipelineNodeVisual(
    icon: AppIcons.users,
    category: PipelineNodeCategory.agents,
  ),
  'human.gate': PipelineNodeVisual(
    icon: AppIcons.shieldCheck,
    category: PipelineNodeCategory.flow,
  ),
  'flow.forEach': PipelineNodeVisual(
    icon: AppIcons.repeat,
    category: PipelineNodeCategory.flow,
  ),
  'flow.callPipeline': PipelineNodeVisual(
    icon: AppIcons.workflow,
    category: PipelineNodeCategory.flow,
  ),
  'repos.cleanup': PipelineNodeVisual(
    icon: AppIcons.trash2,
    category: PipelineNodeCategory.flow,
  ),
};

/// Icon + category for a library [NodeType.id].
PipelineNodeVisual visualForNodeTypeId(String id) {
  return kPipelineNodeTypeVisuals[id] ??
      const PipelineNodeVisual(
        icon: AppIcons.circle,
        category: PipelineNodeCategory.flow,
      );
}

/// Fallback glyph when a step's body key is not in the library (the mandatory
/// trigger node, built-in bodies that have no palette entry).
PipelineNodeVisual visualForStepKind(StepKind kind) {
  return switch (kind) {
    StepKind.trigger => const PipelineNodeVisual(
      icon: AppIcons.zap,
      category: PipelineNodeCategory.flow,
    ),
    StepKind.listen => const PipelineNodeVisual(
      icon: AppIcons.circle,
      category: PipelineNodeCategory.flow,
    ),
    StepKind.join => const PipelineNodeVisual(
      icon: AppIcons.gitMerge,
      category: PipelineNodeCategory.flow,
    ),
    StepKind.router => const PipelineNodeVisual(
      icon: AppIcons.gitFork,
      category: PipelineNodeCategory.flow,
    ),
    StepKind.forEach => const PipelineNodeVisual(
      icon: AppIcons.repeat,
      category: PipelineNodeCategory.flow,
    ),
    StepKind.terminal => const PipelineNodeVisual(
      icon: AppIcons.circleStop,
      category: PipelineNodeCategory.flow,
    ),
  };
}

/// Resolves the palette [NodeType] a step was dropped from.
///
/// Steps do not store the type id. We match `bodyKey` to a type id first
/// (several types use their body key as the id), then to `defaultBodyKey`
/// preferring a matching [StepKind], so a prompt-agent join still lands on
/// `prompt.join` rather than `prompt.custom`.
NodeType? nodeTypeForStep(
  PipelineStepDefinition step,
  NodeTypeLibrary library,
) {
  final byId = library.byId(step.bodyKey);
  if (byId != null) {
    return byId;
  }
  NodeType? kindMatch;
  NodeType? bodyMatch;
  for (final type in library.types) {
    if (type.defaultBodyKey != step.bodyKey) {
      continue;
    }
    bodyMatch ??= type;
    if (type.defaultKind == step.kind) {
      kindMatch = type;
      break;
    }
  }
  return kindMatch ?? bodyMatch;
}

/// Visuals for a rendered step: library type when known, else [StepKind].
PipelineNodeVisual visualForStep(
  PipelineStepDefinition step,
  NodeTypeLibrary library,
) {
  final type = nodeTypeForStep(step, library);
  if (type != null) {
    return visualForNodeTypeId(type.id);
  }
  return visualForStepKind(step.kind);
}

/// Case-insensitive name/description filter used by the sidebar and picker.
List<NodeType> filterNodeTypes(List<NodeType> types, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return types;
  }
  return [
    for (final type in types)
      if (type.displayName.toLowerCase().contains(q) ||
          type.description.toLowerCase().contains(q))
        type,
  ];
}

/// Groups [types] by palette category, preserving [PipelineNodeCategory] order.
List<(PipelineNodeCategory, List<NodeType>)> groupNodeTypes(
  List<NodeType> types,
) {
  final grouped = <PipelineNodeCategory, List<NodeType>>{};
  for (final type in types) {
    grouped
        .putIfAbsent(visualForNodeTypeId(type.id).category, () => [])
        .add(type);
  }
  return [
    for (final category in PipelineNodeCategory.values)
      if (grouped[category] case final list?) (category, list),
  ];
}
