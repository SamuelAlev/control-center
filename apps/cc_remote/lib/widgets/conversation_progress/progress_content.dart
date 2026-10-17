import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_remote/conversation_progress_model.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_context.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_goal.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_outputs.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_run.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_todos.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns true only when the mutation completed in the current route scope.
typedef ProgressMutation =
    Future<bool> Function(
      Future<void> Function(RpcTodoRepository repo) operation,
    );

class ProgressContent extends ConsumerStatefulWidget {
  const ProgressContent({
    required this.scope,
    required this.space,
    required this.conversation,
    super.key,
  });

  final ProgressScope scope;
  final SpaceDto space;
  final Conversation conversation;

  @override
  ConsumerState<ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends ConsumerState<ProgressContent> {
  bool _acting = false;
  String? _actionError;
  Timer? _liveClock;

  @override
  void dispose() {
    _liveClock?.cancel();
    super.dispose();
  }

  bool _sameScope(ProgressScope scope) =>
      mounted &&
      widget.scope == scope &&
      ref.read(activeWorkspaceIdProvider).value == scope.workspaceId;

  Future<bool> _mutate(
    Future<void> Function(RpcTodoRepository repo) operation,
  ) async {
    final scope = widget.scope;
    if (_acting ||
        !_sameScope(scope) ||
        ref.read(workspaceRoleProvider).value?.canWrite != true ||
        ref.read(progressConversationProvider(scope)).value == null) {
      return false;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) {
      setState(
        () => _actionError = AppLocalizations.of(context).connectionFailed,
      );
      return false;
    }
    setState(() {
      _acting = true;
      _actionError = null;
    });
    try {
      await operation(RpcTodoRepository(client));
      return _sameScope(scope);
    } catch (error) {
      if (_sameScope(scope)) setState(() => _actionError = error.toString());
      return false;
    } finally {
      if (_sameScope(scope)) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final runs = ref.watch(progressRunsProvider(scope));
    final tokens = ref.watch(progressTokensProvider(scope));
    final agents = ref.watch(agentsProvider);
    final role = ref.watch(workspaceRoleProvider);
    final canWrite =
        role.value?.atLeast(WorkspaceRole.member) == true && !_acting;
    final runList = runs.value ?? const <AgentRunLogDto>[];
    if (runList.any((run) => run.status == 'running')) {
      _liveClock ??= Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _liveClock?.cancel();
      _liveClock = null;
    }
    final agentList = (agents.value ?? const <AgentDto>[])
        .where((agent) => agent.workspaceId == scope.workspaceId)
        .toList();
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 40),
      children: [
        if (_actionError != null) ...[
          CcAlert(
            title: l.progressSaveFailed,
            description: Text(_actionError!),
            variant: CcAlertVariant.danger,
          ),
          const SizedBox(height: 16),
        ],
        if (role.hasError) ...[
          progressError(
            l,
            role.error!,
            () => ref.invalidate(workspaceRoleProvider),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          widget.space.name,
          style: CcTypography.bodySm.copyWith(color: t.textSecondary),
        ),
        Text(
          widget.conversation.title.trim().isEmpty
              ? l.progressConversation
              : widget.conversation.title,
          style: CcTypography.title.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 24),
        progressHeading(t, l.progressGoal),
        ProgressGoal(
          scope: scope,
          canWrite: canWrite,
          mutate: _mutate,
          onError: (message) => setState(() => _actionError = message),
        ),
        const SizedBox(height: 24),
        progressHeading(t, l.progressTodos),
        ProgressTodos(
          scope: scope,
          canWrite: canWrite,
          mutate: _mutate,
          onError: (message) => setState(() => _actionError = message),
        ),
        const SizedBox(height: 28),
        progressHeading(t, l.progressRunTree),
        if (runs.hasError)
          progressError(
            l,
            runs.error!,
            () => ref.invalidate(progressRunsProvider(scope)),
          )
        else if (runs.isLoading)
          const CcSpinner(size: 18)
        else if (runList.isEmpty)
          Text(
            l.progressNoRuns,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          )
        else
          for (final entry in progressRunTree(runList))
            ProgressRun(
              run: entry.$1,
              depth: entry.$2,
              scope: scope,
              agents: agentList,
            ),
        const SizedBox(height: 28),
        progressHeading(t, l.progressContext),
        ProgressContext(
          scope: scope,
          runs: runList,
          agents: agents,
          tokens: tokens,
        ),
        const SizedBox(height: 28),
        progressHeading(t, l.progressOutputs),
        ProgressOutputs(scope: scope, runs: runList),
      ],
    );
  }
}
