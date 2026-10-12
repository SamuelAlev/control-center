import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selects an explicit executor and only that executor's model vocabulary.
class SkillEvaluationModelFields extends ConsumerWidget {
  /// Renders server-reported adapter availability and its model choices.
  const SkillEvaluationModelFields({
    required this.adapter,
    required this.providerId,
    required this.modelId,
    required this.capabilities,
    required this.onChanged,
    super.key,
  });

  /// Explicit campaign executor, independent of the provider identity.
  final String adapter;

  /// Selected provider; native Claude uses `anthropic`.
  final String? providerId;

  /// Native model identifier, without the harness provider qualifier.
  final String? modelId;

  /// Server admission capabilities, including unavailable-adapter reasons.
  final SkillCampaignCapabilities? capabilities;

  /// Emits a coherent selection, clearing model identity on adapter changes.
  final ValueChanged<({String adapter, String? providerId, String? modelId})>
  onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final native = adapter == 'claude-cli';
    final available = capabilities?.available == true;
    final enabled = available && capabilities!.backends.contains(adapter);
    final harness = native ? null : ref.watch(harnessModelsProvider);
    final claude = native
        ? ref.watch(adapterModelsProvider('claude-code'))
        : null;
    final models = harness?.asData?.value;
    final nativeModels = claude?.asData?.value;
    final error = harness?.error ?? claude?.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcSelect<String>(
          label: l.adapter,
          value: adapter,
          enabled: available,
          options: [
            CcSelectOption(value: 'builtin', label: l.guardrailAdapterHarness),
            CcSelectOption(
              value: 'claude-cli',
              label: l.guardrailAdapterClaudeCli,
            ),
          ],
          onChanged: (value) => onChanged((
            adapter: value,
            providerId: value == 'claude-cli' ? 'anthropic' : null,
            modelId: null,
          )),
        ),
        if (available && !enabled) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.skillEvalUnavailable(
              capabilities!.unavailableBackends[adapter] ?? l.skillEvalUnknown,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (error != null) Text(skillCampaignError(l, error)),
        if (models?.isEmpty == true || nativeModels?.isEmpty == true)
          Text(l.skillEvalNoModels),
        if (native) ...[
          Text('${l.claudeAccountsTitle}: ${l.claudeAccountDefault}'),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!native && models != null) ...[
          CcSelect<String>(
            label: l.skillEvalProvider(''),
            hintText: l.skillEvalProvider(''),
            value: providerId,
            enabled: enabled && models.isNotEmpty,
            options: [
              for (final id in {for (final model in models) model.providerId})
                CcSelectOption(value: id, label: id),
            ],
            onChanged: (value) =>
                onChanged((adapter: adapter, providerId: value, modelId: null)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        CcSelect<String>(
          label: l.skillEvalModel,
          hintText: l.skillEvalModel,
          enabled: enabled && providerId != null,
          value: modelId,
          options: [
            if (nativeModels != null)
              for (final model in nativeModels)
                if (model.id.startsWith('claude-'))
                  CcSelectOption(value: model.id, label: model.name),
            if (models != null)
              for (final model in models)
                if (model.providerId == providerId)
                  CcSelectOption(
                    value: model.bareId,
                    label: model.displayName ?? model.bareId,
                  ),
          ],
          onChanged: (value) => onChanged((
            adapter: adapter,
            providerId: providerId,
            modelId: value,
          )),
        ),
      ],
    );
  }
}
