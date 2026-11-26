import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/code_mode/providers/code_mode_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_record_link.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [ScriptRecordLinkBuilder] for `repl` rows shown inside one
/// conversation or one run of [workspaceId].
///
/// Every finished row gets the link at once; nothing is looked up until it
/// is pressed (see [CodeExecutionCallRecordLink]). Without a run or a
/// conversation there is nowhere to look, so no link.
ScriptRecordLinkBuilder codeExecutionRecordLinkBuilder({
  required String workspaceId,
  String? conversationId,
  String? runId,
}) => (context, call) {
  if ((runId == null || runId.isEmpty) &&
      (conversationId == null || conversationId.isEmpty)) {
    return null;
  }
  return CodeExecutionCallRecordLink(
    callKey: (
      workspaceId: workspaceId,
      runId: runId == null || runId.isEmpty ? null : runId,
      conversationId: conversationId,
      toolCallId: call.toolCallId,
      startedAt: call.startedAt,
    ),
  );
};

/// "Open record" on a finished `repl` row.
///
/// Pressing it asks the server once for the record of this call (see
/// [findCodeExecutionForCall]) and opens it. When none is found, or the
/// question fails, it opens the executions list scoped to the same run or
/// conversation instead, so the press always lands somewhere useful.
class CodeExecutionCallRecordLink extends ConsumerStatefulWidget {
  /// Creates the link for the call [callKey] names.
  const CodeExecutionCallRecordLink({super.key, required this.callKey});

  /// The call, and where to look for its record.
  final CodeExecutionCallKey callKey;

  @override
  ConsumerState<CodeExecutionCallRecordLink> createState() =>
      _CodeExecutionCallRecordLinkState();
}

class _CodeExecutionCallRecordLinkState
    extends ConsumerState<CodeExecutionCallRecordLink> {
  bool _resolving = false;

  Future<void> _open() async {
    final key = widget.callKey;
    final router = ref.read(routerProvider);
    final repo = ref.read(codeModeRepositoryProvider);
    setState(() => _resolving = true);
    String? id;
    try {
      id = await findCodeExecutionForCall(repo.listExecutions, key);
    } on Object {
      // The list says why it cannot be read, if it cannot.
      id = null;
    }
    if (!mounted) {
      return;
    }
    setState(() => _resolving = false);
    router.go(
      id == null
          ? codeExecutionsRoute(
              key.workspaceId,
              runId: key.runId,
              conversationId: key.runId == null ? key.conversationId : null,
            )
          : codeExecutionRoute(key.workspaceId, id),
    );
  }

  @override
  Widget build(BuildContext context) =>
      CodeExecutionRecordLinkText(onPressed: _resolving ? null : _open);
}

/// "Open record" beside the line that says an approval or a question came
/// from a script, shown only when the record [executionId] resolves.
///
/// The record is written when the host admits the script, so it resolves
/// while the script waits on the answer. A Python `eval` cell has no record
/// and its origin no id, so its line never builds this link.
class CodeExecutionOriginRecordLink extends ConsumerWidget {
  /// Creates the link for [executionId] of [workspaceId].
  const CodeExecutionOriginRecordLink({
    super.key,
    required this.executionId,
    this.workspaceId,
  });

  /// The workspace the request belongs to, or null for the active one.
  final String? workspaceId;

  /// The execution the request's origin names.
  final String executionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId =
        this.workspaceId ?? ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final key = (workspaceId: workspaceId, executionId: executionId);
    final resolves =
        ref.watch(codeExecutionResolvesProvider(key)).value ?? false;
    if (!resolves) {
      return const SizedBox.shrink();
    }
    return CodeExecutionRecordLinkText(
      // Through the router rather than the context: the floating approval
      // deck sits above the navigator.
      onPressed: () => ref
          .read(routerProvider)
          .go(codeExecutionRoute(workspaceId, executionId)),
    );
  }
}

/// The quiet link text both record links use: caption size, secondary ink,
/// a record glyph, so it sits beside status text without competing with it.
class CodeExecutionRecordLinkText extends StatelessWidget {
  /// Creates the link.
  const CodeExecutionRecordLinkText({super.key, required this.onPressed});

  /// Opens the record; null while the link is finding it.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      color: t.textSecondary,
      decoration: TextDecoration.none,
    );
    // Opens the record page: a link, named by its own text.
    return CcTappable(
      onPressed: onPressed,
      semanticButton: false,
      builder: (context, states) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.scrollText, size: 12, color: t.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          CcLinkText(l10n.codeExecutionOpenRecord, style: style),
        ],
      ),
    );
  }
}
