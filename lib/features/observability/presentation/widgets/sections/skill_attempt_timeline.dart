import 'dart:ui' as ui;

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A single selected attempt stays legible on phones and in RTL chrome.
class SkillAttemptTimeline extends ConsumerWidget {
  /// Loads the selected campaign attempt and renders its bounded evidence.
  const SkillAttemptTimeline({
    required this.workspaceId,
    required this.campaignId,
    required this.attemptId,
    this.refreshEpoch = 0,
    super.key,
  });

  /// Workspace whose membership authorizes the evidence read.
  final String workspaceId;

  /// Campaign containing the selected attempt.
  final String campaignId;

  /// Attempt whose tool, skill-loading and verification events are shown.
  final String attemptId;

  /// Incremented by a manual refresh to fetch an in-progress attempt again.
  final int refreshEpoch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final attempt = ref.watch(
      _attemptProvider((
        workspaceId: workspaceId,
        campaignId: campaignId,
        attemptId: attemptId,
        refreshEpoch: refreshEpoch,
      )),
    );
    return attempt.when(
      loading: () => const CcSpinner(),
      error: (error, _) => Text(skillCampaignError(l, error)),
      data: (record) {
        final evidence = record.evidence;
        final events = _rows(evidence['skillEvents'])
          ..sort(
            (a, b) => ((a['atEpochMs'] as num?)?.toInt() ?? 0).compareTo(
              (b['atEpochMs'] as num?)?.toInt() ?? 0,
            ),
          );
        final tools = _rows(evidence['toolEvents']);
        final verifiers = _rows(evidence['verification']);
        final date = DateFormat.Hms(Localizations.localeOf(context).toString());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.skillEvalAttempt(
                record.taskId,
                record.armId,
                record.repetition + 1,
              ),
              style: CcTypography.label.copyWith(color: t.textPrimary),
            ),
            Text(
              evidence['verifiedSuccess'] == true
                  ? l.skillEvalVerified
                  : evidence['completed'] == true
                  ? l.skillEvalNotVerified
                  : l.skillEvalIncomplete,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
            if (evidence['error'] != null)
              Text(l.skillEvalUnavailable('${evidence['error']}')),
            if (events.isEmpty)
              Text(
                l.skillEvalLoadUnobserved,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            for (final event in events)
              _TimelineRow(
                title: _eventLabel(l, event['kind']?.toString()),
                detail:
                    '${event['origin'] ?? l.skillEvalUnknown} · '
                    '${event['observed'] == true ? l.skillEvalObserved : l.skillEvalInferred}'
                    '${event['path'] == null ? '' : ' · ${event['path']}'}',
                time: event['atEpochMs'] is num
                    ? date.format(
                        DateTime.fromMillisecondsSinceEpoch(
                          (event['atEpochMs'] as num).toInt(),
                        ),
                      )
                    : null,
              ),
            if (events.isNotEmpty)
              Text(
                l.skillBehaviorRoutingNote,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            if (tools.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.skillEvalTools,
                style: CcTypography.label.copyWith(color: t.textPrimary),
              ),
              for (final tool in tools)
                _TimelineRow(
                  title: '${tool['name'] ?? l.skillEvalUnknown}',
                  detail:
                      '${tool['target'] ?? ''} · ${tool['isError'] == true ? l.skillEvalToolError : l.skillEvalObserved}',
                ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.skillEvalVerifiers,
              style: CcTypography.label.copyWith(color: t.textPrimary),
            ),
            if (verifiers.isEmpty) Text(l.skillEvalNoVerifiers),
            for (final result in verifiers)
              _TimelineRow(
                title:
                    '${result['verifierId'] ?? l.skillEvalUnknown} · '
                    '${result['passed'] == true ? l.skillEvalVerified : l.skillEvalNotVerified}',
                detail:
                    '${result['provenance'] ?? l.skillEvalUnknown}'
                    '${result['skippedReason'] == null ? '' : ' · ${result['skippedReason']}'}'
                    '${result['detail'] == null ? '' : ' · ${result['detail']}'}',
              ),
            if (evidence['transcriptRef'] != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  l.skillEvalArtifactRef('${evidence['transcriptRef']}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
              ),
          ],
        );
      },
    );
  }
}

final _attemptProvider = FutureProvider.autoDispose
    .family<
      SkillAttemptView,
      ({
        String workspaceId,
        String campaignId,
        String attemptId,
        int refreshEpoch,
      })
    >((ref, scope) {
      ref.watch(
        skillCampaignProvider((
          workspaceId: scope.workspaceId,
          campaignId: scope.campaignId,
        )).select(
          (value) => (
            value.asData?.value?.completedAttempts,
            value.asData?.value?.status,
          ),
        ),
      );
      return ref
          .watch(skillCampaignClientProvider)
          .getAttempt(scope.workspaceId, scope.campaignId, scope.attemptId);
    });

List<Map<String, dynamic>> _rows(Object? raw) => [
  for (final row in raw is List ? raw : const [])
    if (row is Map) row.cast<String, dynamic>(),
];

String _eventLabel(AppLocalizations l, String? kind) => switch (kind) {
  'available' => l.skillEvalAvailableEvent,
  'forced' => l.skillEvalForcedEvent,
  'body_load' => l.skillEvalBodyLoad,
  'reference_load' => l.skillEvalReferenceLoad,
  'script_execution' => l.skillEvalScriptExecution,
  _ => l.skillEvalUnknown,
};

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.title, required this.detail, this.time});
  final String title, detail;
  final String? time;
  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          // RTL carve-out: log timestamps retain their left-to-right time order.
          if (time != null)
            Text(
              time!,
              textDirection: ui.TextDirection.ltr,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
