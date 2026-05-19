import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dialog for creating or editing a memory policy.
class PolicyEditDialog extends StatefulWidget {
  /// Creates a [PolicyEditDialog] for creating a new policy or editing [policy].
  const PolicyEditDialog({super.key, this.policy, this.existingDomains = const []});

  /// The policy to edit, or `null` when creating a new policy.
  final MemoryPolicy? policy;
  /// Existing domain names to suggest in the autocomplete field.
  final List<String> existingDomains;

  @override
  State<PolicyEditDialog> createState() => _PolicyEditDialogState();
}

class _PolicyEditDialogState extends State<PolicyEditDialog> {
  late final TextEditingController _ruleController;
  late final TextEditingController _domainController;
  AgentRole? _requiredRole;

  @override
  void initState() {
    super.initState();
    _ruleController = TextEditingController(text: widget.policy?.rule ?? '');
    _domainController = TextEditingController(text: widget.policy?.domain ?? '');
    _requiredRole = widget.policy?.requiredRole;
  }

  @override
  void dispose() {
    _ruleController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.policy != null;
    final l10n = AppLocalizations.of(context);

    return CcDialog(
      maxWidth: 560,
      title: isEditing ? l10n.editPolicy : l10n.newPolicy,
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: widget.policy?.domain ?? ''),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return widget.existingDomains;
                  }
                  return widget.existingDomains.where(
                    (d) => d.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                  );
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _domainController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(labelText: l10n.domainLabel),
                    onSubmitted: (_) => onFieldSubmitted(),
                  );
                },
                onSelected: (selection) {
                  _domainController.text = selection;
                },
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ruleLabel),
                  const SizedBox(height: 6),
                  CcTextArea(
                    controller: _ruleController,
                    hintText: l10n.ruleHint,
                    maxLines: 8,
                    minLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AgentRole?>(
                initialValue: _requiredRole,
                decoration: InputDecoration(labelText: l10n.requiredRoleOptional),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.noneAllRoles),
                  ),
                  for (final r in AgentRole.values)
                    DropdownMenuItem(
                      value: r,
                      child: Text(r.label),
                    ),
                ],
                onChanged: (v) => setState(() => _requiredRole = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () {
            final rule = _ruleController.text.trim();
            final domain = _domainController.text.trim();
            if (rule.isEmpty || domain.isEmpty) {
              return;
            }

            final now = DateTime.now();
            final result = widget.policy?.copyWith(
                  domain: domain,
                  rule: rule,
                  requiredRole: _requiredRole,
                  updatedAt: now,
                ) ??
                MemoryPolicy(
                  id: '',
                  workspaceId: '',
                  domain: domain,
                  rule: rule,
                  requiredRole: _requiredRole,
                  createdAt: now,
                  updatedAt: now,
                );
            Navigator.of(context).pop(result);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
