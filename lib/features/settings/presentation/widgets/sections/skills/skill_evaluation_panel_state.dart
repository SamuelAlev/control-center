part of 'skill_evaluation_panel.dart';

class _SkillEvaluationPanelState extends ConsumerState<SkillEvaluationPanel> {
  bool _busy = false;
  Object? _error;
  String? _policyCampaignId;
  String get _skillKey => 'workspace:${widget.slug}';
  ({String workspaceId, String? skillKey}) get _scope =>
      (workspaceId: widget.workspaceId, skillKey: _skillKey);

  void _quality(String? id) {
    final route = observabilityRoute(widget.workspaceId);
    context.go(
      '$route?tab=quality${id == null ? '' : '&campaign=${Uri.encodeQueryComponent(id)}'}',
    );
  }

  Future<void> _start(List<SkillCampaignView> history) async {
    final result = await showSkillEvaluationDialog(
      context,
      workspaceId: widget.workspaceId,
      skillSlug: widget.slug,
      currentHash: widget.currentHash,
      availableSkills: widget.availableSkills,
      history: history,
    );
    if (mounted && result != null) {
      _quality(result.id);
    }
  }

  Future<void> _policy(
    SkillCampaignPolicyView? policy,
    SkillCampaignView? template,
  ) async {
    if (_busy) {
      return;
    }
    final enabled = policy?.enabled != true;
    if (enabled && template == null) {
      return;
    }
    final config = enabled
        ? <String, dynamic>{
            'skillSlug': widget.slug,
            'corpusId': template!.corpusId,
            'adapter': template.adapter,
            'providerId': template.providerId,
            'modelId': template.modelId,
            'comparison': template.comparison.name,
            'repetitions': template.repetitions,
            'budgetMicros': template.budgetMicros,
            if (template.baselineHash != null)
              'baselineHash': template.baselineHash,
            if (template.configuration['ambientSkillSlugs'] is List)
              'ambientSkillSlugs': template.configuration['ambientSkillSlugs'],
          }
        : policy!.configuration;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(skillCampaignClientProvider)
          .setSkillPolicy(
            workspaceId: widget.workspaceId,
            skillKey: _skillKey,
            enabled: enabled,
            configuration: config,
          );
      ref.invalidate(
        skillCampaignPolicyProvider((
          workspaceId: widget.workspaceId,
          skillKey: _skillKey,
        )),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final readOnly = ref.watch(isDemoServerProvider);
    final history = ref.watch(skillCampaignsProvider(_scope));
    final policy = ref.watch(
      skillCampaignPolicyProvider((
        workspaceId: widget.workspaceId,
        skillKey: _skillKey,
      )),
    );
    final hashKnown = widget.currentHash.isNotEmpty;
    final campaigns = [...?history.value]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final current = hashKnown
        ? campaigns.where((c) => c.skillHash == widget.currentHash).toList()
        : const <SkillCampaignView>[];
    final latest = current.firstOrNull;
    final template =
        current.where((c) => c.id == _policyCampaignId).firstOrNull ?? latest;
    // Sits under the heading, beside the Start button it often explains.
    final reason = widget.dirty
        ? l.skillEvalUnsaved
        : !hashKnown || !history.hasValue
        ? null
        : latest == null
        ? l.skillEvalNotEvaluated
        : latest.staleReason;
    final policyView = policy.value;
    final policyOn = policyView?.enabled == true;
    final canToggle =
        !readOnly &&
        !widget.dirty &&
        !policy.isLoading &&
        !policy.hasError &&
        !_busy &&
        (policyOn || template != null);

    final actions = _EvaluationActions(
      readOnly: readOnly,
      onOpenQuality: () => _quality(latest?.id),
      onStart: readOnly || widget.dirty || !hashKnown || history.hasError
          ? null
          : () => _start(campaigns),
    );
    final toggle = SettingsToggle(
      title: l.skillEvalUpdatesToggle,
      description: l.skillEvalPolicyNote,
      value: policyOn,
      onChanged: canToggle ? (_) => _policy(policyView, template) : null,
      trailing: _busy ? const CcSpinner(size: 14) : null,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Two buttons beside the heading leave it no room on a phone.
          final stacked = constraints.maxWidth < kSettingsFieldInlineBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsGroup(
                showRule: true,
                title: l.skillEvalTitle,
                description: reason,
                trailing: stacked ? null : actions,
                children: [
                  if (!hashKnown)
                    CcAlert(
                      title: l.skillEvalHashUnavailable,
                      variant: CcAlertVariant.warning,
                    ),
                  if (history.hasError)
                    CcAlert(
                      title: skillCampaignError(l, history.error!),
                      variant: CcAlertVariant.danger,
                    ),
                  if (history.isLoading && !history.hasValue)
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CcSpinner(size: 16),
                    )
                  else if (hashKnown && campaigns.isNotEmpty)
                    _EvidenceSummary(latest: latest),
                  if (hashKnown)
                    SettingsField(
                      label: l.skillEvalHashLabel,
                      child: SettingsCopyField(
                        value: widget.currentHash,
                        maxLines: 2,
                      ),
                    ),
                  if (stacked) actions,
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsGroup(
                showRule: true,
                gap: AppSpacing.md,
                children: [
                  // The chosen configuration only applies at the moment the
                  // policy turns on; while it is on, the policy keeps its own.
                  if (!policyOn && current.isNotEmpty)
                    SettingsField(
                      label: l.skillEvalPolicyTemplate,
                      child: CcSelect<String>(
                        semanticLabel: l.skillEvalPolicyTemplate,
                        value: template?.id,
                        options: [
                          for (final c in current)
                            CcSelectOption(
                              value: c.id,
                              label:
                                  '${c.corpusId} · ${c.modelId} · ${_evidenceStatus(l, c)}',
                            ),
                        ],
                        onChanged: (id) =>
                            setState(() => _policyCampaignId = id),
                      ),
                    ),
                  if (readOnly)
                    CcTooltip(message: l.demoReadOnlySave, child: toggle)
                  else
                    toggle,
                  if (history.hasValue && template == null && !policyOn)
                    _PolicyHint(text: l.skillEvalPolicyNeedsCampaign),
                  if (policy.hasError)
                    CcAlert(
                      title: skillCampaignError(l, policy.error!),
                      variant: CcAlertVariant.danger,
                    ),
                  if (_error != null)
                    CcAlert(
                      title: skillCampaignError(l, _error!),
                      variant: CcAlertVariant.danger,
                    ),
                ],
              ),
              if (campaigns.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _RevisionHistory(campaigns: campaigns, onOpen: _quality),
              ],
            ],
          );
        },
      ),
    );
  }
}
