import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:control_center/features/agents/domain/usecases/update_agent.dart';
import 'package:control_center/features/agents/providers/agent_form_providers.dart';
import 'package:control_center/features/agents/providers/agent_management_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the create / edit agent form. Pass [agent] to edit an existing one;
/// omit it to create a new agent in [workspaceId].
Future<void> showAgentFormDialog({
  required BuildContext context,
  required String workspaceId,
  Agent? agent,
}) {
  return showCcDialog<void>(
    context: context,
    builder: (ctx) => _AgentFormDialog(
      workspaceId: workspaceId,
      agent: agent,
    ),
  );
}

class _AgentFormDialog extends ConsumerStatefulWidget {
  const _AgentFormDialog({
    required this.workspaceId,
    this.agent,
  });

  final String workspaceId;
  final Agent? agent;

  @override
  ConsumerState<_AgentFormDialog> createState() => _AgentFormDialogState();
}

class _AgentFormDialogState extends ConsumerState<_AgentFormDialog> {
  static const _noManager = '__none__';

  late final TextEditingController _nameCtl;
  late final TextEditingController _titleCtl;
  late final TextEditingController _skillsCtl;
  late final TextEditingController _personaCtl;
  final _formKey = GlobalKey<FormState>();

  String? _reportsToId;
  bool _submitting = false;

  bool get _isEdit => widget.agent != null;

  @override
  void initState() {
    super.initState();
    final agent = widget.agent;
    _nameCtl = TextEditingController(text: agent?.name ?? '');
    _titleCtl = TextEditingController(text: agent?.title ?? '');
    _skillsCtl = TextEditingController(
      text: agent?.skills.toList().join(', ') ?? '',
    );
    _personaCtl = TextEditingController(text: agent?.persona ?? '');
    _reportsToId = agent?.reportsTo;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _titleCtl.dispose();
    _skillsCtl.dispose();
    _personaCtl.dispose();
    super.dispose();
  }

  List<String> get _skills => _skillsCtl.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    final toaster = CcToastScope.of(context);
    final navigator = Navigator.of(context);
    try {
      if (_isEdit) {
        await ref.read(updateAgentUseCaseProvider).execute(
              UpdateAgentCommand(
                agentId: widget.agent!.id,
                workspaceId: widget.workspaceId,
                title: _titleCtl.text.trim(),
                skills: _skills,
                reportsTo: _reportsToId,
                persona: _personaCtl.text.trim().isEmpty
                    ? null
                    : _personaCtl.text.trim(),
              ),
            );
      } else {
        await ref.read(createAgentUseCaseProvider).execute(
              CreateAgentCommand(
                name: _nameCtl.text.trim(),
                title: _titleCtl.text.trim(),
                workspaceId: widget.workspaceId,
                reportsTo: _reportsToId,
                skills: _skills,
                persona: _personaCtl.text.trim().isEmpty
                    ? null
                    : _personaCtl.text.trim(),
              ),
            );
      }
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
      }
      toaster.show(
        l10n.errorWithDetail(e.toString()),
        variant: CcToastVariant.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final agents =
        ref.watch(workspaceAgentsProvider(widget.workspaceId)).asData?.value ??
            const <Agent>[];
    // Candidate managers: every other agent in the workspace, by name → id.
    final managerItems = <String, String>{
      l10n.reportsToNobody: _noManager,
      for (final a in agents)
        if (a.id != widget.agent?.id) a.name: a.id,
    };
    // Drop a stale selection that no longer resolves to a real agent.
    final selected = _reportsToId != null &&
            managerItems.values.contains(_reportsToId)
        ? _reportsToId!
        : _noManager;

    return CcDialog(
      title: _isEdit ? l10n.editAgent : l10n.addAgent,
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEdit) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.nameLabel),
                      const SizedBox(height: 6),
                      CcTextFormField(
                        controller: _nameCtl,
                        hintText: 'e.g. architect',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.nameRequired
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.titleLabel),
                    const SizedBox(height: 6),
                    CcTextFormField(
                      controller: _titleCtl,
                      hintText: 'e.g. Software architect',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.titleRequired
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.reportsTo,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 4),
                CcSelect<String>(
                  value: selected,
                  options: [
                    for (final e in managerItems.entries)
                      CcSelectOption(value: e.value, label: e.key),
                  ],
                  onChanged: (v) => setState(
                    () => _reportsToId = v == _noManager ? null : v,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.skillsCommaSeparated),
                    const SizedBox(height: 6),
                    CcTextField(
                      controller: _skillsCtl,
                      hintText: 'e.g. architecture, design, review',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.personaOptional),
                    const SizedBox(height: 6),
                    CcTextArea(
                      controller: _personaCtl,
                      maxLines: 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_isEdit ? l10n.saveChanges : l10n.add),
        ),
      ],
    );
  }
}
