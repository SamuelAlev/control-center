import 'package:cc_domain/features/code_graph/domain/ports/code_graph_lookup_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_goto.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_goto_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Name-level code-graph lookup popover for a Cmd/Ctrl+clicked identifier.
class DiffSymbolPopover extends ConsumerStatefulWidget {
  /// Creates a [DiffSymbolPopover].
  const DiffSymbolPopover({
    super.key,
    required this.name,
    required this.workspaceId,
    required this.repoId,
    this.spaceId,
    required this.prFilePaths,
    required this.onJumpToDiff,
    this.onOpenInEditor,
    this.initialResult,
  });

  /// Identifier under the cursor.
  final String name;

  /// Active workspace.
  final String workspaceId;

  /// Linked repo id (null-checked by the caller).
  final String repoId;

  /// PR/space id for the worktree partition, if known.
  final String? spaceId;

  /// Filenames currently in the PR diff (jump-in-diff vs open-in-editor).
  final Set<String> prFilePaths;

  /// Scrolls the diff to this file at the 1-based start line.
  final void Function(String path, int startLine) onJumpToDiff;

  /// Opens a file in the editor, optionally at a 1-based line.
  final void Function(String path, {int? line})? onOpenInEditor;

  /// Pre-fetched lookup, when the Cmd/Ctrl+click path already ran it.
  final CodeGraphLookupResult? initialResult;

  @override
  ConsumerState<DiffSymbolPopover> createState() => _DiffSymbolPopoverState();
}

class _DiffSymbolPopoverState extends ConsumerState<DiffSymbolPopover> {
  late final Future<CodeGraphLookupResult> _lookup;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialResult;
    _lookup = initial != null
        ? Future<CodeGraphLookupResult>.value(initial)
        : ref
              .read(codeGraphLookupProvider)
              .lookup(
                workspaceId: widget.workspaceId,
                repoId: widget.repoId,
                name: widget.name,
                spaceId: widget.spaceId,
              );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t =
        context.designSystem ??
        ((context.ccTheme?.isDark ?? false)
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return DiffGotoPanel(
      child: FutureBuilder<CodeGraphLookupResult>(
        future: _lookup,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Text(
              widget.name,
              style: CcFonts.code(
                family: context.ccTheme?.monoFontFamily,
                textStyle: CcTypography.bodySm.copyWith(color: t.textPrimary),
              ),
            );
          }
          final result = snap.data ?? const CodeGraphLookupResult.empty();
          if (result.definitions.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: CcFonts.code(
                    family: context.ccTheme?.monoFontFamily,
                    textStyle: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.symbolLookupNone,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: CcFonts.code(
                  family: context.ccTheme?.monoFontFamily,
                  textStyle: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ),
              if (result.fromDiff) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.symbolLookupInDiff,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ] else if (result.fromBasePartition) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.symbolLookupFromBase,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              for (final def in result.definitions)
                _CandidateTile(
                  candidate: def,
                  tokens: t,
                  callersLabel: def.callerCount > 0
                      ? l10n.symbolCallersCount(def.callerCount)
                      : null,
                  inDiff: widget.prFilePaths.any(
                    (p) => diffFilePathsMatch(p, def.filePath),
                  ),
                  openInEditorLabel: l10n.openInEditor,
                  implementationsLabel: l10n.symbolImplementations,
                  onSelect: () => _select(def),
                  onSelectImplementor: _select,
                  canOpenEditor: widget.onOpenInEditor != null,
                ),
            ],
          );
        },
      ),
    );
  }

  void _select(CodeGraphLookupCandidate c) {
    if (widget.prFilePaths.any((p) => diffFilePathsMatch(p, c.filePath))) {
      widget.onJumpToDiff(c.filePath, c.startLine);
      return;
    }
    widget.onOpenInEditor?.call(c.filePath, line: c.startLine);
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.tokens,
    required this.callersLabel,
    required this.inDiff,
    required this.openInEditorLabel,
    required this.implementationsLabel,
    required this.onSelect,
    required this.onSelectImplementor,
    required this.canOpenEditor,
  });

  final CodeGraphLookupCandidate candidate;
  final DesignSystemTokens tokens;
  final String? callersLabel;
  final bool inDiff;
  final String openInEditorLabel;
  final String implementationsLabel;
  final VoidCallback onSelect;
  final void Function(CodeGraphLookupCandidate) onSelectImplementor;
  final bool canOpenEditor;

  @override
  Widget build(BuildContext context) {
    final location = '${candidate.filePath}:${candidate.startLine}';
    final subtitle = [
      candidate.kind.label,
      if (candidate.parentName != null && candidate.parentName!.isNotEmpty)
        candidate.parentName,
      location,
      if (callersLabel != null) callersLabel,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: inDiff || canOpenEditor ? onSelect : null,
            child: MouseRegion(
              cursor: inDiff || canOpenEditor
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.qualifiedName.isNotEmpty
                        ? candidate.qualifiedName
                        : candidate.name,
                    style: CcTypography.bodySm.copyWith(
                      color: tokens.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!inDiff && canOpenEditor) ...[
                    const SizedBox(height: 2),
                    Text(
                      openInEditorLabel,
                      style: CcTypography.caption.copyWith(
                        color: tokens.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (candidate.implementors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              implementationsLabel,
              style: CcTypography.label.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final impl in candidate.implementors)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelectImplementor(impl),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      impl.qualifiedName.isNotEmpty
                          ? impl.qualifiedName
                          : impl.name,
                      style: CcTypography.bodySm.copyWith(
                        color: tokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
