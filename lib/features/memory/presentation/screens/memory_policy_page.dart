import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_details.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_record_links.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_record_page.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One policy: its rule rendered, its details, and the facts it came from.
class MemoryPolicyPage extends ConsumerStatefulWidget {
  /// Creates a [MemoryPolicyPage].
  const MemoryPolicyPage({
    super.key,
    required this.workspaceId,
    required this.policyId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The policy.
  final String policyId;

  @override
  ConsumerState<MemoryPolicyPage> createState() => _MemoryPolicyPageState();
}

class _MemoryPolicyPageState extends ConsumerState<MemoryPolicyPage> {
  final _rule = TextEditingController();
  final _domain = TextEditingController();
  final _ruleFocus = FocusNode();
  AgentRole? _role;
  bool _editing = false;
  bool _saving = false;
  bool _left = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rule.addListener(_onEdited);
    _domain.addListener(_onEdited);
  }

  @override
  void dispose() {
    _rule.dispose();
    _domain.dispose();
    _ruleFocus.dispose();
    super.dispose();
  }

  void _onEdited() => setState(() {});

  bool _dirty(MemoryPolicy policy) =>
      _editing &&
      (_rule.text != policy.rule ||
          _domain.text != policy.domain ||
          _role != policy.requiredRole);

  bool get _complete =>
      _rule.text.trim().isNotEmpty && _domain.text.trim().isNotEmpty;

  void _startEditing(MemoryPolicy policy) => setState(() {
    _rule.text = policy.rule;
    _domain.text = policy.domain;
    _role = policy.requiredRole;
    _error = null;
    _editing = true;
  });

  void _stopEditing() => setState(() {
    _editing = false;
    _error = null;
  });

  /// Once only. A delete both returns here and takes the record out from under
  /// the page, and each would step back: the second a page too far.
  void _leave() {
    if (_left) {
      return;
    }
    _left = true;
    leaveMemoryRecord(ref, widget.workspaceId);
  }

  Future<void> _back(MemoryPolicy policy) async {
    if (await mayDiscardMemoryEdits(context, dirty: _dirty(policy)) &&
        mounted) {
      _leave();
    }
  }

  Future<void> _cancel(MemoryPolicy policy) async {
    if (await mayDiscardMemoryEdits(context, dirty: _dirty(policy)) &&
        mounted) {
      _stopEditing();
    }
  }

  Future<void> _delete(MemoryPolicy policy) async {
    if (await deleteMemoryPolicy(context, ref, policy) && mounted) {
      _leave();
    }
  }

  Future<void> _save(MemoryPolicy policy, AppLocalizations l10n) async {
    final toasts = CcToastScope.maybeOf(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await runMemorySave(
      () => ref
          .read(memoryPolicyRepositoryProvider)
          .upsert(
            policy.copyWith(
              rule: _rule.text.trim(),
              domain: _domain.text.trim(),
              requiredRole: _role,
              // `null` means "keep" to copyWith, so "all roles" has to say so.
              clearRequiredRole: _role == null,
              updatedAt: DateTime.now(),
            ),
          ),
      onError: (message) => _error = message,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _editing = _editing && !saved;
    });
    if (saved) {
      toasts?.show(l10n.saved, variant: CcToastVariant.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final policiesAsync = ref.watch(memoryPoliciesProvider(widget.workspaceId));
    final policies = policiesAsync.value ?? const <MemoryPolicy>[];
    final policy = policies.firstWhereOrNull(
      (policy) => policy.id == widget.policyId,
    );
    if (policy == null) {
      if (policiesAsync.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _leave();
          }
        });
      }
      return const Center(child: CcSpinner());
    }

    final facts =
        ref.watch(memoryFactsProvider(widget.workspaceId)).value ??
        const <MemoryFact>[];
    final sources = [
      for (final id in policy.sourceFactIds)
        ?facts.firstWhereOrNull((fact) => fact.id == id),
    ];
    return MemoryRecordPage(
      title: l10n.policy,
      editing: _editing,
      onBack: memoryAction(() => _back(policy)),
      onEdit: () => _startEditing(policy),
      onCancelEdit: memoryAction(() => _cancel(policy)),
      onDelete: memoryAction(() => _delete(policy)),
      body: _editing
          ? _form(l10n, policies)
          : SectionCard(
              label: l10n.ruleLabel,
              child: StyledMarkdownBody(data: policy.rule),
            ),
      details: MemoryPolicyDetails(policy: policy),
      links: [
        if (sources.isNotEmpty)
          MemoryFactLinks(label: l10n.memorySourceFacts, facts: sources),
      ],
      saveBar: _editing
          ? SettingsSaveBar(
              dirty: _dirty(policy),
              busy: _saving,
              saveEnabled: _complete,
              error: _error,
              onSave: memoryAction(() => _save(policy, l10n)),
              onDiscard: _stopEditing,
            )
          : null,
    );
  }

  Widget _form(AppLocalizations l10n, List<MemoryPolicy> policies) {
    return SectionCard(
      label: l10n.editPolicy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MemoryDomainField(
            controller: _domain,
            domains: policies.map((policy) => policy.domain),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsField(
            label: l10n.requiredRoleOptional,
            child: CcSelect<AgentRole?>(
              value: _role,
              semanticLabel: l10n.requiredRoleOptional,
              options: [
                CcSelectOption<AgentRole?>(
                  value: null,
                  label: l10n.noneAllRoles,
                ),
                for (final role in AgentRole.values)
                  CcSelectOption<AgentRole?>(value: role, label: role.label),
              ],
              onChanged: (role) => setState(() => _role = role),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsField(
            label: l10n.ruleLabel,
            layout: SettingsFieldLayout.stacked,
            child: MemoryMarkdownField(
              controller: _rule,
              focusNode: _ruleFocus,
              hint: l10n.ruleHint,
            ),
          ),
        ],
      ),
    );
  }
}
