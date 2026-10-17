import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_content.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressGoal extends ConsumerStatefulWidget {
  const ProgressGoal({
    required this.scope,
    required this.canWrite,
    required this.mutate,
    required this.onError,
    super.key,
  });

  final ProgressScope scope;
  final bool canWrite;
  final ProgressMutation mutate;
  final ValueChanged<String> onError;

  @override
  ConsumerState<ProgressGoal> createState() => _ProgressGoalState();
}

class _ProgressGoalState extends ConsumerState<ProgressGoal> {
  final _goal = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final goal = ref.watch(progressGoalProvider(scope));
    if (goal.hasError) {
      return progressError(
        l,
        goal.error!,
        () => ref.invalidate(progressGoalProvider(scope)),
      );
    }
    if (goal.isLoading) return const CcSpinner(size: 18);
    if (_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CcTextField(
            controller: _goal,
            label: l.progressGoal,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CcButton(
                size: CcButtonSize.lg,
                onPressed: widget.canWrite
                    ? () async {
                        final value = _goal.text.trim();
                        if (value.isEmpty) {
                          widget.onError(l.progressGoalRequired);
                          return;
                        }
                        final saved = await widget.mutate(
                          (repo) => repo.setGoal(
                            scope.workspaceId,
                            scope.conversationId,
                            value,
                          ),
                        );
                        if (mounted && saved) setState(() => _editing = false);
                      }
                    : null,
                child: Text(l.save),
              ),
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: () => setState(() => _editing = false),
                child: Text(l.cancel),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.value?.title ?? l.progressNoGoal,
          style: CcTypography.body.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 8),
        if (widget.canWrite)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: () {
                  _goal.text = goal.value?.title ?? '';
                  setState(() => _editing = true);
                },
                child: Text(
                  goal.value == null ? l.progressSetGoal : l.progressEditGoal,
                ),
              ),
              if (goal.value != null)
                CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.secondary,
                  onPressed: () => widget.mutate(
                    (repo) =>
                        repo.clearGoal(scope.workspaceId, scope.conversationId),
                  ),
                  child: Text(l.progressClearGoal),
                ),
            ],
          ),
      ],
    );
  }
}
