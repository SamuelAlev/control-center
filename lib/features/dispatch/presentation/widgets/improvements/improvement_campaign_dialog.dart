import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the paid evaluation a skill change needs before it can be
/// accepted (`improvements.startCampaign`): a corpus, a provider and model,
/// how many times each task runs, and the most it may spend. The dialog says
/// what it costs before anything starts; cancelling sends nothing.
Future<void> showImprovementCampaignDialog(
  BuildContext context,
  ImprovementProposal proposal,
) => showCcDialog<void>(
  context: context,
  builder: (_) => _CampaignDialog(proposal: proposal),
);

class _CampaignDialog extends ConsumerStatefulWidget {
  const _CampaignDialog({required this.proposal});

  final ImprovementProposal proposal;

  @override
  ConsumerState<_CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends ConsumerState<_CampaignDialog> {
  static const int _maxRepetitions = 20;
  static const int _maxDollars = 1000;

  String? _corpusId, _providerId, _modelId;
  final _repetitions = TextEditingController(text: '3');
  final _dollars = TextEditingController(text: '5');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _repetitions.dispose();
    _dollars.dispose();
    super.dispose();
  }

  int? _ranged(TextEditingController c, int max) {
    final v = int.tryParse(c.text.trim());
    return v != null && v >= 1 && v <= max ? v : null;
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final p = widget.proposal;
    try {
      await ref
          .read(improvementInboxRepositoryProvider)
          .startCampaign(
            p.workspaceId,
            p.id,
            corpusId: _corpusId!,
            providerId: _providerId!,
            modelId: _modelId!,
            repetitions: _ranged(_repetitions, _maxRepetitions)!,
            budgetMicros: _ranged(_dollars, _maxDollars)! * 1000000,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = dispatchFailureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final catalog = ref
        .watch(skillCorporaProvider(widget.proposal.workspaceId))
        .value;
    final models = ref.watch(harnessModelsProvider).value ?? const <Never>[];
    final available = catalog?.capabilities.available ?? false;
    final repetitions = _ranged(_repetitions, _maxRepetitions);
    final dollars = _ranged(_dollars, _maxDollars);
    final valid =
        available &&
        _corpusId != null &&
        _providerId != null &&
        _modelId != null &&
        repetitions != null &&
        dollars != null;
    final providers = {for (final m in models) m.providerId}.toList()..sort();
    return CcDialog(
      title: l10n.improvementCampaignTitle,
      maxWidth: 560,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.improvementCandidateStaged),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dollars == null
                ? l10n.improvementCampaignCostUnknown
                : l10n.improvementCampaignCost(
                    repetitions ?? 0,
                    fmtMicros(dollars * 1000000, locale: locale),
                  ),
          ),
          if (catalog != null && !available) ...[
            const SizedBox(height: AppSpacing.sm),
            CcAlert(
              variant: CcAlertVariant.warning,
              title: l10n.improvementCampaignUnavailable,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CcSelect<String>(
            label: l10n.improvementCampaignCorpus,
            hintText: l10n.improvementCampaignCorpus,
            enabled: available,
            value: _corpusId,
            options: [
              for (final c in catalog?.corpora ?? const <Never>[])
                CcSelectOption(value: c.id, label: c.name),
            ],
            onChanged: (v) => setState(() => _corpusId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CcSelect<String>(
                  label: l10n.improvementCampaignProvider,
                  hintText: l10n.improvementCampaignProvider,
                  enabled: available && providers.isNotEmpty,
                  value: _providerId,
                  options: [
                    for (final p in providers)
                      CcSelectOption(value: p, label: p),
                  ],
                  onChanged: (v) => setState(() {
                    _providerId = v;
                    _modelId = null;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CcSelect<String>(
                  label: l10n.improvementCampaignModel,
                  hintText: l10n.improvementCampaignModel,
                  enabled: available && _providerId != null,
                  value: _modelId,
                  options: [
                    for (final m in models)
                      if (m.providerId == _providerId)
                        CcSelectOption(
                          value: m.bareId,
                          label: m.displayName ?? m.bareId,
                        ),
                  ],
                  onChanged: (v) => setState(() => _modelId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (ctrl, label, error) in [
                (
                  _repetitions,
                  l10n.improvementCampaignRepetitions,
                  repetitions == null
                      ? l10n.improvementCampaignRange(_maxRepetitions)
                      : null,
                ),
                (
                  _dollars,
                  l10n.improvementCampaignBudget,
                  dollars == null
                      ? l10n.improvementCampaignRange(_maxDollars)
                      : null,
                ),
              ]) ...[
                Expanded(
                  child: CcTextField(
                    controller: ctrl,
                    label: label,
                    errorText: error,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(variant: CcAlertVariant.danger, title: error),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: valid && !_busy ? _start : null,
          child: Text(l10n.improvementCampaignStart),
        ),
      ],
    );
  }
}
