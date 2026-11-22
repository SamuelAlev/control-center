import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether a held wake is the Resume a server stop left for a person's run.
bool isRecoveryWake(WakeView wake) =>
    wake.state == WakeState.held &&
    (wake.stateReason == 'server_stopped' ||
        wake.stateReason == 'server_restarted');

/// Runs one wake action and keeps its failure for the card. Every action
/// names the wake's workspace; nothing runs outside the active workspace or
/// without the member role.
mixin WakeActionState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  Object? failure;
  String? skipKind;

  String get wakeWorkspaceId;

  Future<void> wakeAct(
    Future<Object?> Function(ConversationWakesRepository repo) action,
  ) async {
    final repo = ref.read(phoneWakesRepositoryProvider);
    final allowed =
        ref.read(activeWorkspaceIdProvider).value == wakeWorkspaceId &&
        (ref.read(workspaceRoleProvider).value?.canWrite ?? false);
    if (busy || !allowed || repo == null) return;
    setState(() {
      busy = true;
      failure = null;
      skipKind = null;
    });
    try {
      final result = await action(repo);
      if (!mounted) return;
      setState(
        () => skipKind = switch (result) {
          WakeSkipped(:final kind) || WakeWaiting(:final kind) => kind,
          _ => null,
        },
      );
    } catch (e) {
      if (mounted) setState(() => failure = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// The failure or the reason a Deliver now did not deliver, if any.
  Widget? wakeOutcome(AppLocalizations l) {
    if (failure != null) return WorkFailureLine(error: failure!);
    final kind = skipKind;
    if (kind == null) return null;
    return WorkKindLine(sentence: wakeKindSentence(l, kind), kind: kind);
  }
}

/// One pending or held wake: what raised it and for which agent, when it is
/// due or that it is held and why, its expiry and attempt, and Cancel,
/// Deliver now (pending) or Resume (held), the last two only when the server
/// says this viewer may (`canRelease`). A recovery wake after a server stop
/// reads as such, with Resume and Dismiss.
class WakeCard extends ConsumerStatefulWidget {
  const WakeCard({super.key, required this.wake, required this.agentName});

  final WakeView wake;
  final String? Function(String agentId) agentName;

  @override
  ConsumerState<WakeCard> createState() => _WakeCardState();
}

class _WakeCardState extends ConsumerState<WakeCard>
    with WakeActionState<WakeCard> {
  @override
  String get wakeWorkspaceId => widget.wake.workspaceId;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final w = widget.wake;
    ref.watch(activeWorkspaceIdProvider);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final held = w.state == WakeState.held;
    final recovery = isRecoveryWake(w);
    final source = w.sourceAgentId == null
        ? null
        : widget.agentName(w.sourceAgentId!);
    final agent = widget.agentName(w.agentId);
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    final reasonText = wakeKindSentence(l, w.stateReason);
    final due = !w.notBefore.isAfter(DateTime.now().toUtc())
        ? l.wakeDueNow
        : l.wakeDue(workTime(context, w.notBefore));
    Widget button(String label, VoidCallback onPressed, CcButtonVariant v) =>
        CcButton(
          size: CcButtonSize.lg,
          variant: v,
          onPressed: busy ? null : onPressed,
          child: Text(label),
        );
    final outcome = wakeOutcome(l);
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  wakeOriginLabel(l, w.reason, agentName: source),
                  style: CcTypography.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CcBadge(
                label: held ? l.wakeHeld : due,
                variant: held ? CcBadgeVariant.warning : CcBadgeVariant.neutral,
              ),
            ],
          ),
          if (agent != null) Text(l.wakeFor(agent), style: caption),
          if (recovery) ...[
            const SizedBox(height: 6),
            Text(
              l.wakeRecovery,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ] else if (w.stateReason != null) ...[
            const SizedBox(height: 6),
            WorkKindLine(sentence: reasonText, kind: w.stateReason!),
          ],
          Wrap(
            spacing: 10,
            children: [
              if (w.expiresAt != null)
                Text(
                  l.wakeExpires(workTime(context, w.expiresAt!)),
                  style: caption,
                ),
              if (w.attempt > 1) Text(l.wakeAttempt(w.attempt), style: caption),
            ],
          ),
          if (held && !w.canRelease && writable)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.wakeResumeOnlyTheirs, style: caption),
            ),
          if (writable) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (held && w.canRelease)
                  button(
                    l.wakeResume,
                    () =>
                        wakeAct((r) => r.release(w.workspaceId, wakeId: w.id)),
                    CcButtonVariant.primary,
                  ),
                if (!held && w.canRelease)
                  button(
                    l.wakeDeliverNow,
                    () => wakeAct((r) => r.deliverNow(w.workspaceId, w.id)),
                    CcButtonVariant.secondary,
                  ),
                button(
                  recovery ? l.wakeDismiss : l.wakeCancel,
                  () => wakeAct((r) => r.cancel(w.workspaceId, w.id)),
                  CcButtonVariant.ghost,
                ),
              ],
            ),
          ],
          if (outcome != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: outcome),
        ],
      ),
    );
  }
}
