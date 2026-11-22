import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_source.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_syntax/syntax_languages.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/features/code_mode/presentation/screens/code_executions_screen.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_call_row.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_header.dart';
import 'package:control_center/features/code_mode/providers/code_executions_list_provider.dart';
import 'package:control_center/features/code_mode/providers/code_mode_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_tree/script_call_tree.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One execution's record: the header, the script, its output and every
/// tool call it made, laid over the script's structure the way the
/// conversation shows them ([ScriptCallTree]).
///
/// Both forms build lazily, so a script that made thousands of calls builds
/// only the rows on screen: the tree line by line
/// ([ScriptCallTreeSliver]), and calls that do not say where in the script
/// they were made (a record from a runner that reported no sites) as a
/// sliver list in call order. A record the reader may not open
/// shows the server's refusal in words, never a blank page.
class CodeExecutionDetailView extends ConsumerWidget {
  /// Creates the view of [executionId] in [workspaceId].
  const CodeExecutionDetailView({
    super.key,
    required this.workspaceId,
    required this.executionId,
    required this.listFilter,
  });

  /// The workspace the record belongs to.
  final String workspaceId;

  /// The record's opaque id, whole.
  final String executionId;

  /// The list under the record, where Back goes when there is no history.
  final CodeExecutionsFilter listFilter;

  void _back(WidgetRef ref) => ref
      .read(navigationHistoryProvider.notifier)
      .backOr(codeExecutionsLocationOf(listFilter));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(
      codeExecutionDetailProvider((
        workspaceId: workspaceId,
        executionId: executionId,
      )),
    );
    if (detail.value case final d?) {
      return _Record(
        workspaceId: workspaceId,
        detail: d,
        onBack: () => _back(ref),
      );
    }
    if (detail.isLoading) {
      return const Center(child: CcSpinner());
    }
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CcEmptyState(
          icon: detail.hasError ? AppIcons.lock : AppIcons.searchX,
          message: detail.hasError
              ? codeExecutionLoadFailure(l10n, detail.error!)
              : l10n.codeExecutionNotFound,
          action: CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.arrowLeft,
            onPressed: () => _back(ref),
            child: Text(l10n.codeExecutionBackToList),
          ),
        ),
      ),
    );
  }
}

class _Record extends ConsumerWidget {
  const _Record({
    required this.workspaceId,
    required this.detail,
    required this.onBack,
  });

  final String workspaceId;
  final CodeExecutionDetail detail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final codeFont = ref.watch(codeFontFamilyProvider);
    final payload = detail.payload;
    final calls = detail.calls;
    // A running script has produced no output yet: the page shows its
    // script and the calls settled so far.
    final running = detail.execution.status == CodeExecutionStatus.running;
    final view = payload == null
        ? null
        : scriptRunViewOrFlat(
            source: payload.source,
            calls: [
              for (final call in calls)
                ScriptRunCall(
                  payload: call,
                  toolName: call.toolName,
                  line: call.site?.line,
                  column: call.site?.column,
                  running: false,
                  failed: _callState(call) != NestedCallState.ok,
                  startMs: call.startOffsetMs,
                  endMs: call.startOffsetMs + call.durationMs,
                ),
            ],
            ended: !running,
          );
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    final heading = CcTypography.bodySm.copyWith(
      color: t.textPrimary,
      fontWeight: FontWeight.w600,
    );
    const gutter = EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xl);
    Widget box(Widget child) => SliverToBoxAdapter(
      child: Padding(padding: gutter, child: child),
    );
    return CustomScrollView(
      slivers: [
        box(
          CodeExecutionHeader(
            workspaceId: workspaceId,
            execution: detail.execution,
            settledCalls: calls.length,
            errorName: payload?.errorName,
            onBack: onBack,
          ),
        ),
        box(const SizedBox(height: AppSpacing.xl)),
        if (payload == null)
          box(Text(l10n.codeExecutionNoPayload, style: caption))
        else ...[
          box(Text(l10n.codeExecutionScript, style: heading)),
          box(const SizedBox(height: AppSpacing.sm)),
          // RTL carve-out: the script is JavaScript source; CodePreview lays
          // its lines and gutter out left to right in every locale.
          box(
            CodePreview(
              code: payload.source,
              codeFont: codeFont,
              tokens: t,
              languageId: shikiLangForPath('script.js'),
              maxHeight: 480,
              maxLines: 5000,
            ),
          ),
          if (!running && payload.output.isNotEmpty)
            box(
              buildLabeledToolBlock(
                context,
                label: l10n.transcriptOutput,
                body: payload.output,
                codeFont: codeFont,
                tokens: t,
              ),
            ),
          if (!running && payload.console.isNotEmpty)
            box(
              buildLabeledToolBlock(
                context,
                label: l10n.codeExecutionConsole,
                body: payload.console,
                codeFont: codeFont,
                tokens: t,
              ),
            ),
          if (detail.execution.outputTruncated)
            box(
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(l10n.codeExecutionOutputTruncated, style: caption),
              ),
            ),
        ],
        box(const SizedBox(height: AppSpacing.xl)),
        box(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.codeExecutionCallsHeading(calls.length),
              style: heading,
            ),
          ),
        ),
        if (view != null && view.counts.total > 0)
          ScriptCallTreeSliver<CodeExecutionCall>(
            view: view,
            scope: 'record:${detail.execution.id}',
            stateOf: _callState,
            keepInSight: (call) =>
                call.gateDecision == NestedCallGateDecision.approved,
            toolOf: (call) => call.toolName,
            // The record's rows name a tool as it is called.
            toolLabel: (tool) => tool,
            itemBuilder: (context, call) => CodeExecutionCallRow(
              key: ValueKey(call.sequence),
              call: call,
              codeFont: codeFont,
            ),
            codeFont: codeFont,
            wrap: (line) => Padding(padding: gutter, child: line),
          )
        else if (calls.isEmpty)
          box(Text(l10n.codeExecutionNoCalls, style: caption))
        else
          SliverPadding(
            padding: gutter,
            sliver: SliverList.builder(
              itemCount: calls.length,
              itemBuilder: (context, i) => CodeExecutionCallRow(
                key: ValueKey(calls[i].sequence),
                call: calls[i],
                codeFont: codeFont,
              ),
            ),
          ),
        box(const SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

/// How a recorded call ended, in the terms the transcript uses. A record
/// holds settled calls only, so none is running.
NestedCallState _callState(CodeExecutionCall call) => switch (call.status) {
  NestedCallStatus.completed => NestedCallState.ok,
  NestedCallStatus.failed ||
  NestedCallStatus.unknownTool ||
  NestedCallStatus.invalidArgs => NestedCallState.failed,
  NestedCallStatus.denied => NestedCallState.denied,
  NestedCallStatus.cancelled ||
  NestedCallStatus.timedOut => NestedCallState.cancelled,
};
