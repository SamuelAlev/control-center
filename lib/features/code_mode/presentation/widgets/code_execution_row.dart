import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One execution in the list: how it ended, what it was for, who ran it, how
/// many calls it made and how long it took, and when.
///
/// The whole row opens the record; its hover wash and cursor are the
/// affordance. The list's query rides along, so the list under the record
/// keeps its filter.
class CodeExecutionRow extends ConsumerWidget {
  /// Creates the row for [execution].
  const CodeExecutionRow({
    super.key,
    required this.workspaceId,
    required this.execution,
    required this.query,
    this.first = false,
  });

  /// The workspace the execution belongs to.
  final String workspaceId;

  /// The execution.
  final CodeExecution execution;

  /// The list's query parameters, carried to the record's location.
  final Map<String, String> query;

  /// Whether this is the first row (no hairline above it).
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final e = execution;
    final agentName = e.agentId == null
        ? null
        : (ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const [])
              .where((a) => a.id == e.agentId)
              .firstOrNull
              ?.name;
    final counts = e.callCounts;
    final failed = counts.failed + counts.unknownTool + counts.invalidArgs;
    // A running script's counts and duration are set when it ends: its row
    // says only who runs it, beside its tag and start.
    final running = e.status == CodeExecutionStatus.running;
    final meta = [
      ?agentName,
      if (!running) ...[
        l10n.scriptCallCount(counts.total),
        if (failed > 0) l10n.scriptCallsFailed(failed),
        if (counts.denied > 0) l10n.scriptCallsDenied(counts.denied),
        formatScriptDuration(l10n, e.durationMs),
      ],
    ].join(' · ');
    final state = scriptRunStateOf(e.status);
    final title = e.description.trim().isEmpty
        ? l10n.codeExecutionUntitled
        : e.description.trim().split('\n').first;
    final location = Uri(
      path: codeExecutionRoute(workspaceId, e.id),
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: t.borderSecondary)),
      ),
      child: CcTappable(
        onPressed: () => context.go(location),
        semanticLabel: title,
        builder: (context, states) => ColoredBox(
          color: states.contains(WidgetState.hovered)
              ? t.bgPrimaryHover
              : const Color(0x00000000),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 128,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CcStatusTag(
                      label: scriptStateLabel(l10n, state),
                      tone: scriptStateTone(state),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.bodySm.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcTypography.caption.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppTimestamp.relative(
                  e.startedAt,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
