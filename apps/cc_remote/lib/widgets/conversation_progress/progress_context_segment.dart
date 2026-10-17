import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProgressContextSegment extends ConsumerWidget {
  const ProgressContextSegment({
    required this.scope,
    required this.agentId,
    required this.segment,
    required this.formatter,
    required this.open,
    required this.onToggle,
    super.key,
  });

  final ProgressScope scope;
  final String agentId;
  final ContextSegment segment;
  final NumberFormat formatter;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final segment = this.segment;
    final label = switch (segment.kind) {
      ContextSegmentKind.systemPrompt => l.progressContextSystem,
      ContextSegmentKind.rules => l.progressContextRules,
      ContextSegmentKind.skills => l.progressContextSkills,
      ContextSegmentKind.toolDefinitions => l.progressContextTools,
      ContextSegmentKind.mcpTools => l.progressContextMcp,
      ContextSegmentKind.deferredTools => l.progressContextDeferred,
      ContextSegmentKind.subagents => l.progressContextSubagents,
      ContextSegmentKind.runner => l.progressContextRunner,
      ContextSegmentKind.memory => l.progressContextMemory,
      ContextSegmentKind.conversation => l.progressContextHistory,
    };
    final args = (scope: scope, agentId: agentId, includeContent: true);
    final details = open ? ref.watch(progressInspectionProvider(args)) : null;
    final expanded = details?.value?.segmentFor(segment.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: onToggle,
          child: Text(
            l.progressContextSegment(label, formatter.format(segment.tokens)),
          ),
        ),
        if (open) ...[
          if (details?.hasError == true)
            progressError(
              l,
              details!.error!,
              () => ref.invalidate(progressInspectionProvider(args)),
            )
          else if (details?.isLoading == true)
            const CcSpinner(size: 18)
          else if (expanded != null)
            for (final part in expanded.parts)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.progressContextPart(
                        part.title,
                        formatter.format(part.tokens),
                      ),
                      style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                    ),
                    if (part.subtitle != null)
                      Text(
                        part.subtitle!,
                        style: CcTypography.caption.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    if (part.content != null)
                      SelectableRegion(
                        selectionControls: emptyTextSelectionControls,
                        child: Text(
                          part.content!,
                          style: CcTypography.bodySm.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}
