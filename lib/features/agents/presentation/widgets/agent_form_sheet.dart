import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/agents/domain/usecases/create_agent.dart';
import 'package:control_center/features/agents/domain/usecases/update_agent.dart';
import 'package:control_center/features/agents/providers/agent_form_providers.dart';
import 'package:control_center/features/agents/providers/agent_management_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// Opens the create / edit agent form. Pass [agent] to edit an existing one;
/// omit it to create a new agent in [workspaceId].
Future<void> showAgentFormDialog({
  required BuildContext context,
  required String workspaceId,
  Agent? agent,
}) {
  return showFDialog<void>(
    context: context,
    builder: (ctx, style, animation) => _AgentFormDialog(
      style: style,
      animation: animation,
      workspaceId: workspaceId,
      agent: agent,
    ),
  );
}

class _AgentFormDialog extends ConsumerStatefulWidget {
  const _AgentFormDialog({
    required this.style,
    required this.animation,
    required this.workspaceId,
    this.agent,
  });

  final FDialogStyle style;
  final Animation<double> animation;
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
    final messenger = ScaffoldMessenger.maybeOf(context);
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
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail(e.toString()))),
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

    return FDialog(
      style: widget.style,
      animation: widget.animation,
      title: Text(_isEdit ? l10n.editAgent : l10n.addAgent),
      body: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEdit) ...[
                  FTextFormField(
                    control: FTextFieldControl.managed(controller: _nameCtl),
                    label: Text(l10n.nameLabel),
                    hint: 'e.g. architect',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.nameRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                FTextFormField(
                  control: FTextFieldControl.managed(controller: _titleCtl),
                  label: Text(l10n.titleLabel),
                  hint: 'e.g. Software architect',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.titleRequired
                      : null,
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
                FSelect<String>(
                  items: managerItems,
                  control: FSelectControl<String>.lifted(
                    value: selected,
                    onChange: (v) => setState(
                      () => _reportsToId = (v == null || v == _noManager)
                          ? null
                          : v,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FTextField(
                  control: FTextFieldControl.managed(controller: _skillsCtl),
                  label: Text(l10n.skillsCommaSeparated),
                  hint: 'e.g. architecture, design, review',
                ),
                const SizedBox(height: 12),
                FTextField(
                  control: FTextFieldControl.managed(controller: _personaCtl),
                  label: Text(l10n.personaOptional),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FButton(
          onPress: _submitting ? null : () => Navigator.of(context).pop(),
          variant: FButtonVariant.outline,
          mainAxisSize: MainAxisSize.min,
          child: Text(l10n.cancel),
        ),
        FButton(
          onPress: _submitting ? null : _submit,
          mainAxisSize: MainAxisSize.min,
          child: Text(_isEdit ? l10n.saveChanges : l10n.add),
        ),
      ],
    );
  }
}
