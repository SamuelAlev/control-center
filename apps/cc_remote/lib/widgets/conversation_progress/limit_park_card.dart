import 'package:cc_domain/cc_domain.dart' show MessageDto;
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/wake_card.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A person's run parked at a provider's usage limit, read from the system
/// row the park posted (`kind: limit_park`). Once the park's wake settled,
/// the server stamps the row with how it ended ([LimitPark.rowOutcomeKey]),
/// when ([LimitPark.rowSettledAtKey]) and, for a skip, why
/// ([LimitPark.rowSkipKindKey]); the client never infers it.
typedef LimitParkRow = ({
  String wakeId,
  String? provider,
  DateTime? resumesAt,
  String? outcome,
  DateTime? settledAt,
  String? skipKind,
});

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

/// Reads one park row's metadata, or null when it is not a park row.
LimitParkRow? limitParkRowOf(MessageDto message) {
  final meta = message.metadata;
  if (meta is! Map || meta['kind'] != LimitPark.rowKind) return null;
  final wakeId = _text(meta['wakeId']);
  if (wakeId == null) return null;
  final provider = _text(meta['provider']);
  final resumes = _text(meta['resumesAt']);
  final settled = _text(meta[LimitPark.rowSettledAtKey]);
  return (
    wakeId: wakeId,
    provider: provider == null ? null : inertText(provider, singleLine: true),
    resumesAt: resumes == null ? null : DateTime.tryParse(resumes),
    outcome: _text(meta[LimitPark.rowOutcomeKey]),
    settledAt: settled == null ? null : DateTime.tryParse(settled),
    skipKind: _text(meta[LimitPark.rowSkipKindKey]),
  );
}

/// The park rows in [messages], newest first, one per wake.
List<LimitParkRow> limitParkRows(List<MessageDto> messages) {
  final seen = <String>{};
  final rows = <LimitParkRow>[];
  for (final m in messages.reversed) {
    final row = limitParkRowOf(m);
    if (row == null || !seen.add(row.wakeId)) continue;
    rows.add(row);
  }
  return rows;
}

/// What came of a settled park, from the row's stamped outcome: the
/// sentence and, for a skip, the skip kind. No outcome yet (the stamp has
/// not arrived) reads "no longer waiting".
String limitParkOutcomeSentence(
  AppLocalizations l,
  LimitParkRow row,
  String provider,
) => switch (row.outcome) {
  LimitPark.outcomeResumed => l.limitParkResumed(provider),
  LimitPark.outcomeCancelled => l.limitParkCancelled(provider),
  LimitPark.outcomeExpired => l.limitParkExpired(provider),
  LimitPark.outcomeSkipped => l.limitParkSkipped(provider),
  _ => l.limitParkGone(provider),
};

/// The settled park: what came of it, when, and why a skip happened.
class LimitParkSettled extends StatelessWidget {
  const LimitParkSettled({super.key, required this.row});

  final LimitParkRow row;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final settledAt = row.settledAt;
    final skipKind = row.outcome == LimitPark.outcomeSkipped
        ? row.skipKind
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Icon(
            row.outcome == LimitPark.outcomeResumed
                ? AppIcons.circleCheck
                : AppIcons.circleSlash,
            size: 16,
            color: t.textTertiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                limitParkOutcomeSentence(
                  l,
                  row,
                  row.provider ?? l.limitParkProviderUnknown,
                ),
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              ),
              if (skipKind != null)
                WorkKindLine(
                  sentence: wakeKindSentence(l, skipKind),
                  kind: skipKind,
                ),
              if (settledAt != null)
                Text(
                  workTime(context, settledAt),
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Paused at the provider's usage limit. Resumes at 14:30." with Resume now
/// (only for the person whose run it is: `canRelease`) and Cancel while the
/// held wake lives; once it settled, what came of it, without actions.
class LimitParkCard extends ConsumerStatefulWidget {
  const LimitParkCard({super.key, required this.row, required this.wake});

  final LimitParkRow row;

  /// The live held wake, or null once it settled.
  final WakeView? wake;

  @override
  ConsumerState<LimitParkCard> createState() => _LimitParkCardState();
}

class _LimitParkCardState extends ConsumerState<LimitParkCard>
    with WakeActionState<LimitParkCard> {
  @override
  String get wakeWorkspaceId => widget.wake?.workspaceId ?? '';

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final wake = widget.wake;
    final provider = widget.row.provider;
    if (wake == null || widget.row.outcome != null) {
      return CcCard(child: LimitParkSettled(row: widget.row));
    }
    final time = workTime(context, widget.row.resumesAt ?? wake.notBefore);
    ref.watch(activeWorkspaceIdProvider);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final outcome = wakeOutcome(l);
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Icon(AppIcons.clock, size: 16, color: t.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider == null
                      ? l.limitParkTitleUnnamed(time)
                      : l.limitParkTitle(provider, time),
                  style: CcTypography.body.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
          if (!wake.canRelease && writable)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 4),
              child: Text(
                l.wakeResumeOnlyTheirs,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ),
          if (writable) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (wake.canRelease)
                  CcButton(
                    size: CcButtonSize.lg,
                    onPressed: busy
                        ? null
                        : () => wakeAct(
                            (r) => r.release(wake.workspaceId, wakeId: wake.id),
                          ),
                    child: Text(l.limitParkResumeNow),
                  ),
                CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.ghost,
                  onPressed: busy
                      ? null
                      : () =>
                            wakeAct((r) => r.cancel(wake.workspaceId, wake.id)),
                  child: Text(l.limitParkCancel),
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
