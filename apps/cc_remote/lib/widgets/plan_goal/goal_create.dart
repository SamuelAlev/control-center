import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Starts via the same /goal or /loop server dispatch as a conversation turn.
/// A hard cost cap is required and displayed before dispatch.
class PhoneGoalCreate extends ConsumerStatefulWidget {
  const PhoneGoalCreate({
    super.key,
    required this.workspaceId,
    this.conversationId,
  });

  final String workspaceId;
  final String? conversationId;

  @override
  ConsumerState<PhoneGoalCreate> createState() => _PhoneGoalCreateState();
}

class _PhoneGoalCreateState extends ConsumerState<PhoneGoalCreate> {
  final _objective = TextEditingController();
  final _budget = TextEditingController();
  String? _spaceId;
  String? _agentId;
  bool _loop = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _objective.dispose();
    _budget.dispose();
    super.dispose();
  }

  int? get _budgetCents {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final format = NumberFormat.decimalPattern(locale);
    var text = _budget.text.trim();
    // Accept the locale's digits/decimal mark and ASCII digits for hardware
    // keyboards; do not accept grouping or silently round a third cent.
    for (var digit = 0; digit < 10; digit++) {
      text = text.replaceAll(format.format(digit), '$digit');
    }
    final separator = format.symbols.DECIMAL_SEP;
    if (separator != '.') text = text.replaceAll(separator, '.');
    if (!RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(text)) return null;
    final pieces = text.split('.');
    final dollars = int.parse(pieces.first);
    final cents = pieces.length == 1
        ? 0
        : int.parse(pieces.last.padRight(2, '0'));
    final total = dollars * 100 + cents;
    return total > 0 ? total : null;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final objective = _objective.text.trim();
    final cents = _budgetCents;
    final space = _spaceId;
    final agentId = _agentId;
    if (objective.isEmpty ||
        cents == null ||
        agentId == null ||
        (widget.conversationId == null && space == null)) {
      setState(() => _error = l10n.mobileGoalCreateInvalid);
      return;
    }
    final confirmed = await confirmOperation(
      context,
      title: l10n.mobileGoalCreate,
      description: l10n.mobileGoalCreateConfirm(planMoney(context, cents)),
      action: l10n.mobileGoalCreate,
    );
    if (!confirmed ||
        !mounted ||
        ref.read(activeWorkspaceIdProvider).value != widget.workspaceId ||
        !(ref.read(workspaceRoleProvider).value?.canWrite ?? false)) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) {
      setState(() => _error = l10n.mobileGoalUnavailable);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final requestedConversation = widget.conversationId;
      final targetSpace = requestedConversation == null
          ? space
          : (await RpcConversationRepository(client).getById(
              workspaceId: widget.workspaceId,
              conversationId: requestedConversation,
            ))?.spaceId;
      if (targetSpace == null || targetSpace.isEmpty) {
        throw StateError(l10n.mobileGoalConversationMissing);
      }
      final conversationId =
          requestedConversation ??
          (await RpcConversationRepository(
            client,
          ).ensure(workspaceId: widget.workspaceId, spaceId: targetSpace)).id;
      if (ref.read(activeWorkspaceIdProvider).value != widget.workspaceId ||
          !(ref.read(workspaceRoleProvider).value?.canWrite ?? false)) {
        return;
      }
      final budget =
          '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
      final runId = await RemoteMessagingDispatch(client).dispatchAgent(
        workspaceId: widget.workspaceId,
        spaceId: targetSpace,
        agentId: agentId,
        prompt: '${_loop ? '/loop' : '/goal'} $objective --budget $budget',
        conversationId: conversationId,
      );
      if (mounted) {
        if (runId == null) {
          setState(() => _error = l10n.mobileGoalStartRefused);
        } else {
          _objective.clear();
          setState(() => _notice = l10n.mobileGoalCreateSent);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final spaces = ref.watch(spacesProvider);
    final items = (spaces.value ?? const <SpaceDto>[])
        .where((s) => s.workspaceId == widget.workspaceId)
        .toList();
    final agents = ref.watch(agentsProvider);
    final eligibleAgents = (agents.value ?? const <AgentDto>[])
        .where(
          (a) =>
              a.workspaceId == widget.workspaceId &&
              a.lifecycleStatus == 'active',
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mobileGoalCreate,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.conversationId == null) ...[
          Text(
            l10n.mobileGoalChooseSpace,
            style: TextStyle(color: t.textSecondary),
          ),
          if (spaces.isLoading) const Center(child: CcSpinner(size: 20)),
          if (spaces.hasError)
            Text(spaces.error.toString(), style: TextStyle(color: t.danger)),
          if (spaces.hasValue && items.isEmpty)
            Text(
              l10n.mobileGoalNoSpaces,
              style: TextStyle(color: t.textSecondary),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final space in items)
                CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.secondary,
                  onPressed: () => setState(() => _spaceId = space.id),
                  child: Text(
                    _spaceId == space.id
                        ? l10n.mobileGoalSelectedSpace(space.name)
                        : space.name,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(
          l10n.mobileGoalChooseAgent,
          style: TextStyle(color: t.textSecondary),
        ),
        if (agents.isLoading) const Center(child: CcSpinner(size: 20)),
        if (agents.hasError)
          Text(agents.error.toString(), style: TextStyle(color: t.danger)),
        if (agents.hasValue && eligibleAgents.isEmpty)
          Text(
            l10n.mobileGoalNoAgents,
            style: TextStyle(color: t.textSecondary),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final agent in eligibleAgents)
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: () => setState(() => _agentId = agent.id),
                child: Text(
                  _agentId == agent.id
                      ? l10n.mobileGoalSelectedAgent(agent.name)
                      : agent.name,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        CcTextArea(
          controller: _objective,
          minLines: 3,
          maxLines: 6,
          enabled: writable && !_busy,
          hintText: l10n.mobileGoalObjectiveHint,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CcButton(
              size: CcButtonSize.lg,
              variant: _loop
                  ? CcButtonVariant.secondary
                  : CcButtonVariant.primary,
              onPressed: () => setState(() => _loop = false),
              child: Text(l10n.mobileGoalGoal),
            ),
            CcButton(
              size: CcButtonSize.lg,
              variant: _loop
                  ? CcButtonVariant.primary
                  : CcButtonVariant.secondary,
              onPressed: () => setState(() => _loop = true),
              child: Text(l10n.mobileGoalLoop),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _budget,
          label: l10n.mobileGoalBudgetUsd,
          hintText: NumberFormat.decimalPatternDigits(
            locale: Localizations.localeOf(context).toLanguageTag(),
            decimalDigits: 2,
          ).format(50),
          enabled: writable && !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        if (_error != null) Text(_error!, style: TextStyle(color: t.danger)),
        if (_notice != null)
          Text(_notice!, style: TextStyle(color: t.textPrimary)),
        CcButton(
          fullWidth: true,
          size: CcButtonSize.lg,
          loading: _busy,
          onPressed: writable && !_busy ? _send : null,
          child: Text(l10n.mobileGoalCreate),
        ),
      ],
    );
  }
}
