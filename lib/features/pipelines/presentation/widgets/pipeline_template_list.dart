import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The workspace's pipeline templates.
class PipelineTemplateList extends StatelessWidget {
  /// Creates a [PipelineTemplateList].
  const PipelineTemplateList({super.key, required this.templates});

  /// What the server holds.
  final AsyncValue<List<PipelineDefinition>> templates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A reload keeps the rows on screen instead of flashing the spinner.
    final shown = !templates.hasError && templates.hasValue
        ? AsyncValue<List<PipelineDefinition>>.data(templates.requireValue)
        : templates;
    return shown.when(
      loading: () => const Center(child: CcSpinner()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: CcAlert(variant: CcAlertVariant.danger, title: '$error'),
      ),
      data: (records) => records.isEmpty
          ? CcEmptyState(
              icon: AppIcons.workflow,
              message: l10n.pipelineTemplatesEmpty,
            )
          : SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: SectionCard(
                label: l10n.pipelineTemplatesTitle,
                count: records.length,
                padding: EdgeInsets.zero,
                headerPadding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  14,
                  AppSpacing.lg,
                  0,
                ),
                child: SettingsGroup(
                  separator: SettingsGroupSeparator.rule,
                  children: [
                    for (final template in records)
                      _TemplateRow(template: template),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Opens the editor on a click. The switch stays in view because it shows
/// state; deleting sits behind hover, and behind a confirmation.
class _TemplateRow extends ConsumerWidget {
  const _TemplateRow({required this.template});

  final PipelineDefinition template;

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(pipelineTemplateRepositoryProvider);
    final full = await repo.getById(template.workspaceId, template.templateId);
    if (full == null) {
      return;
    }
    try {
      // copyWith, not a hand-rebuilt definition: flipping one flag must not
      // drop the template's declared inputs or its concurrency cap.
      await repo.upsert(full.copyWith(isEnabled: value));
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.errorWithDetail('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.pipelineTemplateDeleteConfirmTitle,
        content: Text(l10n.pipelineTemplateDeleteConfirmBody(template.name)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(pipelineTemplateRepositoryProvider)
          .deleteById(template.workspaceId, template.templateId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsEntityRow(
      icon: template.isBuiltIn ? AppIcons.boxes : AppIcons.workflow,
      title: template.name,
      subtitleWidget: _TemplateSummary(template: template),
      statusLabel: template.isBuiltIn
          ? l10n.pipelineTemplateBuiltInBadge
          : null,
      meta: [_TemplateTriggerChips(template: template)],
      onPressed: () => context.go(
        pipelineTemplateEditorRoute(template.workspaceId, template.templateId),
      ),
      hoverTrailing: template.isBuiltIn
          ? null
          : CcIconButton(
              variant: CcButtonVariant.destructive,
              icon: AppIcons.trash2,
              size: CcButtonSize.sm,
              tooltip: l10n.delete,
              onPressed: () => unawaited(_confirmDelete(context, ref)),
            ),
      trailing: CcSwitch(
        value: template.isEnabled,
        semanticLabel: template.name,
        onChanged: (value) => unawaited(_setEnabled(context, ref, value)),
      ),
    );
  }
}

/// The template's id beside what it does.
class _TemplateSummary extends StatelessWidget {
  const _TemplateSummary({required this.template});

  final PipelineDefinition template;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final plain = CcTypography.caption.copyWith(color: ds.textTertiary);
    final description = template.description;
    return Text.rich(
      TextSpan(
        style: plain,
        children: [
          TextSpan(
            text: template.templateId,
            style: CcFonts.code(textStyle: plain),
          ),
          if (description != null) TextSpan(text: ' · $description'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Compact, read-only summary of a template's triggers, shown on each template
/// row so the trigger is visible at a glance. Shows *all* configured triggers
/// — enabled ones filled, disabled ones muted/outlined (with their schedule or
/// match detail) so a configured-but-off trigger (e.g. an opt-in cron) is still
/// discoverable.
class _TemplateTriggerChips extends ConsumerWidget {
  const _TemplateTriggerChips({required this.template});

  final PipelineDefinition template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final triggers =
        ref
            .watch(pipelineTriggersForWorkspaceProvider(template.workspaceId))
            .value
            ?.where((t) => t.templateId == template.templateId)
            .toList() ??
        const [];
    if (triggers.isEmpty) {
      return Text(
        l10n.triggerSummaryNone,
        style: CcTypography.caption.copyWith(color: ds.textTertiary),
      );
    }
    triggers.sort((a, b) {
      if (a.enabled != b.enabled) {
        return a.enabled ? -1 : 1;
      }
      return a.eventType.compareTo(b.eventType);
    });
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final t in triggers)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: t.enabled ? ds.bgSecondary : const Color(0x00000000),
              borderRadius: AppRadii.brSm,
              border: t.enabled ? null : Border.all(color: ds.borderSecondary),
            ),
            child: Text(
              t.enabled
                  ? triggerDetailLabel(l10n, t)
                  : '${triggerDetailLabel(l10n, t)} · ${l10n.triggerDisabledTag}',
              style: CcTypography.caption.copyWith(
                color: t.enabled ? ds.textPrimary : ds.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
