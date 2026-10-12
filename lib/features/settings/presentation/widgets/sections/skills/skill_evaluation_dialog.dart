import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_model_fields.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Opens an explicit, budgeted paid evaluation; cancelling submits nothing.
Future<SkillCampaignView?> showSkillEvaluationDialog(
  BuildContext context, {
  required String workspaceId,
  required String skillSlug,
  required String currentHash,
  required List<String> availableSkills,
  required List<SkillCampaignView> history,
}) => showCcDialog<SkillCampaignView>(
  context: context,
  builder: (_) => _StartDialog(
    workspaceId: workspaceId,
    skillSlug: skillSlug,
    currentHash: currentHash,
    availableSkills: availableSkills,
    history: history,
  ),
);

class _StartDialog extends ConsumerStatefulWidget {
  const _StartDialog({
    required this.workspaceId,
    required this.skillSlug,
    required this.currentHash,
    required this.availableSkills,
    required this.history,
  });
  final String workspaceId, skillSlug, currentHash;
  final List<String> availableSkills;
  final List<SkillCampaignView> history;
  @override
  ConsumerState<_StartDialog> createState() => _StartDialogState();
}

class _StartDialogState extends ConsumerState<_StartDialog> {
  String? _corpusId, _modelId, _providerId, _baselineHash;
  String _adapter = 'builtin';
  SkillCampaignComparison _comparison = SkillCampaignComparison.absent;
  final _repeats = TextEditingController(text: '3');
  final _budget = TextEditingController();
  final Set<String> _ambient = {};
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _repeats.dispose();
    _budget.dispose();
    super.dispose();
  }

  bool get _valid {
    final repeats = int.tryParse(_repeats.text.trim());
    final cents = int.tryParse(_budget.text.trim());
    return _corpusId != null &&
        _modelId != null &&
        _providerId != null &&
        repeats != null &&
        repeats > 0 &&
        repeats <= 20 &&
        cents != null &&
        cents > 0 &&
        cents <= 100000 &&
        (_comparison != SkillCampaignComparison.previous ||
            _baselineHash != null) &&
        (_comparison != SkillCampaignComparison.composition ||
            _ambient.isNotEmpty);
  }

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(skillCampaignClientProvider)
          .startSkillCampaign(
            workspaceId: widget.workspaceId,
            skillSlug: widget.skillSlug,
            corpusId: _corpusId!,
            adapter: _adapter,
            providerId: _providerId!,
            modelId: _modelId!,
            comparison: _comparison,
            repetitions: int.parse(_repeats.text.trim()),
            budgetMicros: int.parse(_budget.text.trim()) * 10000,
            baselineHash: _comparison == SkillCampaignComparison.previous
                ? _baselineHash
                : null,
            ambientSkillSlugs:
                _comparison == SkillCampaignComparison.composition
                ? (_ambient.toList()..sort())
                : null,
          );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final catalog = ref.watch(skillCorporaProvider(widget.workspaceId));
    final corpora = catalog.asData?.value;
    final available =
        corpora?.capabilities.available == true &&
        corpora!.capabilities.backends.contains(_adapter);
    final previous = <String>{
      for (final c in widget.history)
        if (c.skillHash.isNotEmpty && c.skillHash != widget.currentHash)
          c.skillHash,
      for (final c in widget.history)
        if (c.baselineHash != null && c.baselineHash != widget.currentHash)
          c.baselineHash!,
    }.toList()..sort();
    return CcDialog(
      title: l.skillEvalStartTitle,
      maxWidth: 560,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 540),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _adapter == 'claude-cli' ||
                        (corpora?.capabilities.usageBudgetProviders.contains(
                              _providerId,
                            ) ??
                            false)
                    ? l.skillEvalUsageBudgetNote
                    : l.skillEvalBudgetNote,
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (catalog.hasError) Text(skillCampaignError(l, catalog.error!)),
              if (corpora != null && !corpora.capabilities.available)
                Text(
                  l.skillEvalUnavailable(
                    corpora.capabilities.reason ?? l.skillEvalUnknown,
                  ),
                ),
              if (corpora != null)
                CcSelect<String>(
                  label: l.skillEvalCorpus,
                  hintText: l.skillEvalCorpus,
                  enabled: available && corpora.corpora.isNotEmpty,
                  value: _corpusId,
                  options: [
                    for (final c in corpora.corpora)
                      CcSelectOption(
                        value: c.id,
                        label: '${c.name} · ${number.format(c.taskCount)}',
                      ),
                  ],
                  onChanged: (v) => setState(() => _corpusId = v),
                ),
              const SizedBox(height: AppSpacing.md),
              SkillEvaluationModelFields(
                adapter: _adapter,
                providerId: _providerId,
                modelId: _modelId,
                capabilities: corpora?.capabilities,
                onChanged: (selection) => setState(() {
                  _adapter = selection.adapter;
                  _providerId = selection.providerId;
                  _modelId = selection.modelId;
                  _error = null;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              CcSelect<SkillCampaignComparison>(
                label: l.skillEvalComparison,
                value: _comparison,
                options: [
                  CcSelectOption(
                    value: SkillCampaignComparison.absent,
                    label: l.skillEvalAbsent,
                  ),
                  CcSelectOption(
                    value: SkillCampaignComparison.previous,
                    label: l.skillEvalPrevious,
                  ),
                  CcSelectOption(
                    value: SkillCampaignComparison.forced,
                    label: l.skillEvalForced,
                  ),
                  CcSelectOption(
                    value: SkillCampaignComparison.composition,
                    label: l.skillEvalComposition,
                  ),
                ],
                onChanged: (v) => setState(() => _comparison = v),
              ),
              if (_comparison == SkillCampaignComparison.previous) ...[
                const SizedBox(height: AppSpacing.md),
                if (previous.isEmpty) Text(l.skillEvalNoPrevious),
                CcSelect<String>(
                  label: l.skillEvalBaseline,
                  hintText: l.skillEvalBaseline,
                  enabled: previous.isNotEmpty,
                  value: _baselineHash,
                  options: [
                    for (final hash in previous)
                      CcSelectOption(value: hash, label: hash),
                  ],
                  onChanged: (v) => setState(() => _baselineHash = v),
                ),
              ],
              if (_comparison == SkillCampaignComparison.composition) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.skillEvalAmbient,
                  style: CcTypography.label.copyWith(color: t.textPrimary),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final slug in widget.availableSkills)
                      if (slug != widget.skillSlug)
                        CcChip(
                          label: slug,
                          selected: _ambient.contains(slug),
                          onPressed: () => setState(
                            () => _ambient.contains(slug)
                                ? _ambient.remove(slug)
                                : _ambient.add(slug),
                          ),
                        ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              CcTextField(
                controller: _repeats,
                label: l.skillEvalRepetitions,
                hintText: l.skillEvalRepetitions,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              CcTextField(
                controller: _budget,
                label: l.skillEvalBudgetCents,
                hintText: l.skillEvalBudgetCents,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  skillCampaignError(l, _error!),
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        CcButton(
          onPressed: available && _valid && !_busy ? _submit : null,
          loading: _busy,
          child: Text(l.skillEvalStart),
        ),
      ],
    );
  }
}
