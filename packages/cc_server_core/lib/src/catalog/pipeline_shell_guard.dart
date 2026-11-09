import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, ValidationException;
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_arming_policy.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_infra/cc_infra.dart' show TimezoneZoneConverter;
import 'package:uuid/uuid.dart';

export 'package:cc_domain/features/pipelines/domain/services/pipeline_arming_policy.dart'
    show pipelineHasShellStep;

/// Whether [template] runs a shell step.
bool hasShellStep(PipelineDefinition? template) =>
    pipelineHasShellStep(template);

bool _isAdmin(RepoOpContext ctx) => ctx.role?.isAdmin ?? false;

/// A trigger fires its pipeline with no RPC behind it, so arming one that
/// runs a shell step — or editing one that does — is an admin decision, the
/// same as authoring the step.
Future<void> requireAdminForShellTriggers(
  RepoOpContext ctx,
  PipelineTemplateRepository templates,
  List<String> templateIds,
) async {
  if (_isAdmin(ctx)) {
    return;
  }
  for (final id in templateIds.toSet()) {
    if (id.isNotEmpty &&
        hasShellStep(await templates.getById(ctx.workspaceId!, id))) {
      throw const AuthException(
        'Only a workspace admin can schedule or arm a pipeline with a shell '
        'step',
      );
    }
  }
}

/// A fresh webhook token: 128 random bits, hex. It is both the inbound route
/// (`/webhooks/<token>`) and the HMAC secret, so only the server mints it.
String mintWebhookToken() => const Uuid().v4().replaceAll('-', '');

/// Turns a client's `pipeline_trigger.insert` / `.update` payload into the row
/// the server will store, enforcing every rule a trigger write is subject to:
///
/// * The template exists in the bound workspace.
/// * A schedule parses (`every:<n>` with `n > 0`, or a satisfiable 5-field
///   cron) and its timezone is a known IANA zone.
/// * Identity is server-owned. On insert the webhook token is minted here (a
///   client-supplied one is ignored, so it can never re-point another
///   workspace's route) and the scheduler fields start empty. On update the
///   event type, template, token and creation time are carried over from the
///   stored row, the scheduler fields are kept, and `nextRunAt` is cleared when
///   the schedule or timezone changed so the scheduler recomputes it.
/// * Authority. A trigger on a template with a shell step is admin-only
///   ([requireAdminForShellTriggers]); arming a trigger — leaving it enabled on
///   an event, schedule or webhook — on a template with a step outside
///   [kMemberArmableBodyKeys] is admin-only, because the run it starts has no
///   requester and acts as the workspace's accountable human.
///
/// [previous] is the stored row for an update, null for an insert.
Future<PipelineTrigger> preparePipelineTriggerWrite(
  RepoOpContext ctx, {
  required PipelineTemplateRepository templates,
  required PipelineTrigger incoming,
  PipelineTrigger? previous,
  String Function() mintToken = mintWebhookToken,
  bool Function(String timezone)? isKnownTimezone,
}) async {
  final workspaceId = ctx.workspaceId!;
  if (previous != null &&
      (incoming.eventType != previous.eventType ||
          incoming.templateId != previous.templateId)) {
    throw const ValidationException(
      "A trigger's event type and pipeline are fixed; delete it and add a new "
      'one instead',
    );
  }
  final template = await templates.getById(workspaceId, incoming.templateId);
  if (template == null) {
    throw const NotFoundException('Pipeline template not found');
  }
  final scheduleError = incoming.scheduleError;
  if (scheduleError != null) {
    throw ValidationException(scheduleError);
  }
  final timezone = incoming.timezone?.trim() ?? '';
  final knownTimezone =
      isKnownTimezone ?? TimezoneZoneConverter.instance.isKnown;
  if (incoming.eventType == PipelineTrigger.scheduleEventType &&
      timezone.isNotEmpty &&
      !knownTimezone(timezone)) {
    throw ValidationException('Unknown timezone "$timezone"');
  }

  await requireAdminForShellTriggers(ctx, templates, [incoming.templateId]);

  final String? token;
  if (previous != null) {
    // Kept as stored; a webhook row that somehow lacks one gets one now.
    final stored = previous.webhookToken;
    token = (stored == null || stored.isEmpty) && previous.isWebhook
        ? mintToken()
        : stored;
  } else {
    token = incoming.eventType == PipelineTrigger.webhookEventType
        ? mintToken()
        : null;
  }
  final scheduleChanged =
      previous != null &&
      ((previous.cronExpression ?? '') != (incoming.cronExpression ?? '') ||
          (previous.timezone ?? '') != timezone);

  final prepared = PipelineTrigger(
    id: incoming.id,
    eventType: incoming.eventType,
    templateId: incoming.templateId,
    workspaceId: workspaceId,
    enabled: incoming.enabled,
    cronExpression: incoming.cronExpression,
    timezone: timezone.isEmpty ? null : timezone,
    nextRunAt: previous == null || scheduleChanged ? null : previous.nextRunAt,
    webhookToken: token,
    eventFilters: incoming.eventFilters,
    match: incoming.match,
    lastFiredAt: previous?.lastFiredAt,
    catchUpPolicy: incoming.catchUpPolicy,
    createdAt: previous?.createdAt ?? DateTime.now(),
  );

  if (!_isAdmin(ctx) &&
      pipelineTriggerIsArmed(prepared) &&
      pipelineArmingRequiresAdmin(template)) {
    // Disarming (or leaving disarmed) is always a member's call; arming, or
    // re-configuring an armed trigger, is not.
    throw const AuthException(
      'Only a workspace admin can enable this trigger: the pipeline dispatches '
      'agents or changes data with no one starting it',
    );
  }
  return prepared;
}

/// Turns a client's `pipeline_template.upsert` payload into the definition the
/// server will store.
///
/// * `isBuiltIn` is the server's: only the seeder writes `true`. A client save
///   of a built-in clears it — the seeder then leaves the user's copy alone and
///   the repository validates and versions it — except for a save that changes
///   nothing but `isEnabled`, which is a toggle, not an edit.
/// * A shell step is operator code on this host: creating one, or editing a
///   pipeline that already has one, needs an admin.
/// * Putting a step a member could not arm behind a trigger that is already
///   armed needs an admin too, or editing the template would bypass the gate
///   [preparePipelineTriggerWrite] puts on arming.
Future<PipelineDefinition> preparePipelineTemplateWrite(
  RepoOpContext ctx, {
  required PipelineTemplateRepository templates,
  required PipelineTriggerConfigRepository triggers,
  required PipelineDefinition incoming,
}) async {
  final workspaceId = ctx.workspaceId!;
  final stored = await templates.getById(workspaceId, incoming.templateId);
  final toggleOnly =
      stored != null &&
      stored.isBuiltIn &&
      incoming.copyWith(isBuiltIn: true, isEnabled: stored.isEnabled) ==
          stored;
  final definition = incoming.copyWith(isBuiltIn: toggleOnly);
  if (_isAdmin(ctx)) {
    return definition;
  }
  if (hasShellStep(definition) || hasShellStep(stored)) {
    throw const AuthException(
      'Only a workspace admin can create or edit a pipeline with a shell step',
    );
  }
  if (pipelineArmingRequiresAdmin(definition) &&
      !pipelineArmingRequiresAdmin(stored)) {
    final armed = (await triggers.forWorkspace(workspaceId)).any(
      (t) => t.templateId == definition.templateId && pipelineTriggerIsArmed(t),
    );
    if (armed) {
      throw const AuthException(
        'Only a workspace admin can add this step while the pipeline has an '
        'enabled event, schedule or webhook trigger',
      );
    }
  }
  return definition;
}
