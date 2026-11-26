import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_record_link.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The quiet line on an approval card or a question form that a script
/// raised: it says so, and offers the way back to the script's row.
///
/// A person deciding on a call a script made should be able to read the
/// script that is waiting on the answer; the row holds it, with every call
/// the script made so far. A `repl` script's durable record exists from the
/// moment it was admitted, so the line offers it beside the row; a Python
/// `eval` cell has none, and its origin names no execution.
class ScriptOriginLine extends StatelessWidget {
  /// Creates the line. [onShow] null drops the link to the row; [origin]
  /// null drops the link to the record.
  const ScriptOriginLine({
    super.key,
    this.onShow,
    this.origin,
    this.workspaceId,
  });

  /// Brings the script's transcript row into view.
  final VoidCallback? onShow;

  /// Which script raised the request: its record is offered when the origin
  /// names one and it resolves (a Python `eval` cell names none).
  final ScriptCallOrigin? origin;

  /// The request's workspace, or null for the active one.
  final String? workspaceId;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      color: t.textTertiary,
      decoration: TextDecoration.none,
    );
    final show = onShow;
    return Row(
      children: [
        Icon(AppIcons.code, size: 12, color: t.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(l10n.scriptOriginLine, style: style)),
        if (show != null) ...[
          const SizedBox(width: AppSpacing.sm),
          // Scrolls to the call: a link, named by its own text.
          CcTappable(
            onPressed: show,
            semanticButton: false,
            builder: (context, states) => CcLinkText(
              l10n.scriptOriginShow,
              style: style.copyWith(color: t.textSecondary),
            ),
          ),
        ],
        // A Python `eval` cell is not a recorded execution: no record link.
        if (origin?.executionId case final executionId?) ...[
          const SizedBox(width: AppSpacing.sm),
          CodeExecutionOriginRecordLink(
            workspaceId: workspaceId,
            executionId: executionId,
          ),
        ],
      ],
    );
  }
}

/// Brings the transcript row of the call [toolCallId] into view.
///
/// The conversation's feed does the scrolling when it is on screen. With
/// [navigate] the app first opens that conversation, for a request answered
/// from somewhere else (the floating approval deck).
void showScriptCall(
  WidgetRef ref, {
  required String spaceId,
  required String? conversationId,
  required String toolCallId,
  String? workspaceId,
  bool navigate = false,
}) {
  if (navigate && spaceId.isNotEmpty) {
    final ws = workspaceId ?? ref.read(activeWorkspaceIdProvider);
    if (ws != null) {
      ref
          .read(routerProvider)
          .go(
            spaceRoute(
              ws,
              spaceId,
              tab: conversationId == null || conversationId.isEmpty
                  ? null
                  : conversationTabKey(conversationId),
            ),
          );
    }
  }
  ref.read(pendingFocusToolCallProvider.notifier).set((
    spaceId: spaceId,
    conversationId: conversationId,
    toolCallId: toolCallId,
  ));
}
