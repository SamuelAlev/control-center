import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/context_usage_flyout.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the explorer's detail pane renders: the whole context, one whole
/// segment, or a single part.
class _ExplorerSelection {
  const _ExplorerSelection.everything() : kind = null, partId = null;

  const _ExplorerSelection.segment(this.kind) : partId = null;

  const _ExplorerSelection.part(this.kind, this.partId);

  /// The selected segment; null selects EVERYTHING.
  final ContextSegmentKind? kind;

  /// The selected part within [kind]; null selects the whole segment.
  final String? partId;
}

/// The full context explorer: a master-detail surface over one agent's
/// context window. The left rail lists every segment and part with its token
/// cost; the right pane renders the selected part's verbatim content.
///
/// Fetches the inspection WITH content (`includeContent: true`) and composes
/// the conversation segment from the live messages — the same merge the
/// flyout's summary uses, so the numbers agree.
class ContextExplorerPane extends ConsumerStatefulWidget {
  /// Creates a [ContextExplorerPane].
  const ContextExplorerPane({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.agentId,
  });

  /// The workspace the inspected agent belongs to (carried so the host can
  /// guard a restored tab against a workspace switch).
  final String workspaceId;

  /// The space whose context to explore.
  final String spaceId;

  /// The agent whose context window this is.
  final String agentId;

  @override
  ConsumerState<ContextExplorerPane> createState() =>
      _ContextExplorerPaneState();
}

class _ContextExplorerPaneState extends ConsumerState<ContextExplorerPane> {
  _ExplorerSelection? _selection;

  /// Rail sections whose part lists are minimized. Collapsing never changes
  /// the selection — a collapsed segment still opens in the detail pane when
  /// its header is tapped.
  final Set<ContextSegmentKind> _collapsed = {};

  void _toggleCollapsed(ContextSegmentKind kind) => setState(
    () => _collapsed.contains(kind)
        ? _collapsed.remove(kind)
        : _collapsed.add(kind),
  );

  void _refresh() {
    ref.invalidate(
      contextInspectionProvider((
        spaceId: widget.spaceId,
        agentId: widget.agentId,
        includeContent: true,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // A restored layout must never render another workspace's breakdown.
    if (ref.watch(activeWorkspaceIdProvider) != widget.workspaceId) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(
      contextInspectionProvider((
        spaceId: widget.spaceId,
        agentId: widget.agentId,
        includeContent: true,
      )),
    );
    final inspection = async.value;
    final messages =
        ref.watch(spaceMessagesProvider(widget.spaceId)).value ??
        const <Message>[];
    final conversation = buildConversationContextSegment(
      messages,
      inspection?.agentName,
    );
    final fallbackWindow = ref
        .watch(
          conversationContextUsageProvider((
            spaceId: widget.spaceId,
            agentId: widget.agentId,
          )),
        )
        .windowTokens;
    final breakdown = composeContextBreakdown(
      inspection,
      conversation,
      fallbackWindow,
      isLoading: async.isLoading && inspection == null,
      hasError: async.hasError && inspection == null,
    );

    if (breakdown.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.contextExplorerUnavailable,
              style: CcTypography.body.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: _refresh,
              child: Text(l10n.contextRetry),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          breakdown: breakdown,
          onRefresh: _refresh,
          isRefreshing: async.isLoading,
        ),
        Container(height: 1, color: tokens.borderPrimary),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 280,
                color: tokens.bgSecondary,
                child: _Rail(
                  breakdown: breakdown,
                  selection: _selection,
                  collapsedKinds: _collapsed,
                  onToggleCollapse: _toggleCollapsed,
                  onSelect: (selection) =>
                      setState(() => _selection = selection),
                ),
              ),
              Container(width: 1, color: tokens.borderPrimary),
              Expanded(
                child: _Detail(breakdown: breakdown, selection: _selection),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.breakdown,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final ContextBreakdown breakdown;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final agentName = breakdown.inspection?.agentName ?? '';
    final workingDirectory = breakdown.inspection?.workingDirectory;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  agentName.isEmpty
                      ? l10n.contextExplorerTitle
                      : '${l10n.contextExplorerTitle} · $agentName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.title.copyWith(color: tokens.textPrimary),
                ),
              ),
              CcIconButton(
                icon: AppIcons.refreshCw,
                size: CcButtonSize.sm,
                loading: isRefreshing,
                semanticLabel: l10n.contextRetry,
                onPressed: onRefresh,
              ),
            ],
          ),
          if (workingDirectory != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              workingDirectory,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ContextStackedBar(segments: breakdown.segments, height: 8),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(breakdown.fraction * 100).round()}% '
                '${l10n.contextUsageFull}',
                style: CcTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              Text(
                '~${formatContextTokenCount(breakdown.totalTokens)} / '
                '${formatContextTokenCount(breakdown.windowTokens)} '
                '${l10n.contextUsageTokens}',
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.breakdown,
    required this.selection,
    required this.collapsedKinds,
    required this.onToggleCollapse,
    required this.onSelect,
  });

  final ContextBreakdown breakdown;
  final _ExplorerSelection? selection;

  /// Segments whose part rows are minimized (accordion).
  final Set<ContextSegmentKind> collapsedKinds;

  /// Toggles one segment's collapse state.
  final ValueChanged<ContextSegmentKind> onToggleCollapse;

  final ValueChanged<_ExplorerSelection?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final sel = selection;

    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      children: [
        _RailRow(
          label: l10n.contextExplorerEverything,
          tokens: breakdown.totalTokens,
          selected: sel != null && sel.kind == null,
          onTap: () => onSelect(const _ExplorerSelection.everything()),
        ),
        for (final segment in breakdown.segments) ...[
          _RailRow(
            label: contextSegmentLabel(l10n, segment.kind),
            tokens: segment.tokens,
            color: contextSegmentColor(tokens, segment.kind),
            selected: sel?.kind == segment.kind && sel?.partId == null,
            onTap: () => onSelect(_ExplorerSelection.segment(segment.kind)),
            // The twistie exists only where there is something to hide.
            collapsed: segment.parts.isEmpty
                ? null
                : collapsedKinds.contains(segment.kind),
            onToggleCollapse: () => onToggleCollapse(segment.kind),
          ),
          if (!collapsedKinds.contains(segment.kind))
            for (final part in segment.parts)
              _RailRow(
                label: part.title,
                subtitle: part.subtitle,
                tokens: part.tokens,
                indent: true,
                selected: sel?.kind == segment.kind && sel?.partId == part.id,
                onTap: () =>
                    onSelect(_ExplorerSelection.part(segment.kind, part.id)),
              ),
        ],
        if (breakdown.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Center(child: CcSpinner(size: 12)),
          ),
      ],
    );
  }
}

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.label,
    required this.tokens,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.color,
    this.indent = false,
    this.collapsed,
    this.onToggleCollapse,
  });

  final String label;
  final String? subtitle;
  final int tokens;
  final Color? color;
  final bool indent;
  final bool selected;
  final VoidCallback onTap;

  /// Collapse state when the row can act as an accordion header; null hides
  /// the twistie (leaf rows and segments with no parts).
  final bool? collapsed;

  /// Twistie tap — toggles collapse WITHOUT touching the selection, so the
  /// header row stays a pure "open in the detail pane" action.
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(
            // Aligned under the header labels: sm + twistie (16) + gap (xs).
            left: indent ? 28 : AppSpacing.sm,
            right: AppSpacing.sm,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? t.bgTertiary : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (collapsed case final collapsed?) ...[
                CcTappable(
                  onPressed: onToggleCollapse,
                  semanticLabel: collapsed ? l10n.expand : l10n.collapse,
                  builder:
                      (context, states) => Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          collapsed
                              ? AppIcons.chevronRight
                              : AppIcons.chevronDown,
                          size: 12,
                          color:
                              states.contains(WidgetState.hovered)
                                  ? t.textSecondary
                                  : t.textTertiary,
                        ),
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (color != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  subtitle == null ? label : '$label · $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(
                    color: selected ? t.textPrimary : t.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatContextTokenCount(tokens),
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: t.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.breakdown, required this.selection});

  final ContextBreakdown breakdown;
  final _ExplorerSelection? selection;

  /// The verbatim text for [selection], or null when nothing is selected.
  String? _content(AppLocalizations l10n) {
    final selection = this.selection;
    if (selection == null) {
      return null;
    }
    final buffer = StringBuffer();
    if (selection.kind == null) {
      // Everything: every non-empty segment under a `## <label>` header, its
      // parts separated by `── <title> ──` rules.
      for (final segment in breakdown.segments) {
        final parts = _partTexts(segment);
        if (parts.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.write('\n\n');
        }
        buffer.write('## ${contextSegmentLabel(l10n, segment.kind)}\n\n');
        buffer.write(parts.join('\n\n'));
      }
    } else {
      final segment = breakdown.segments
          .where((s) => s.kind == selection.kind)
          .firstOrNull;
      if (segment == null) {
        return null;
      }
      final partId = selection.partId;
      if (partId == null) {
        buffer.write(_partTexts(segment).join('\n\n'));
      } else {
        final part = segment.parts.where((p) => p.id == partId).firstOrNull;
        if (part == null) {
          return null;
        }
        buffer.write(part.content ?? '');
      }
    }
    final text = buffer.toString();
    return text.isEmpty ? null : text;
  }

  /// Each part's text headed by a `── <title> ──` rule.
  List<String> _partTexts(ContextSegment segment) => [
    for (final part in segment.parts)
      if (part.content case final content?) '── ${part.title} ──\n\n$content',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final content = _content(l10n);

    if (content == null) {
      return Center(
        child: Text(
          l10n.contextExplorerSelectPart,
          style: CcTypography.body.copyWith(color: tokens.textTertiary),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Align(
        alignment: Alignment.topLeft,
        child: SelectableRegion(
          selectionControls: _NoHandleSelectionControls(),
          child: Text(
            content,
            style: CcFonts.code(
              textStyle: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selection controls for the explorer's detail pane — desktop-first, like
/// `CcTextArea`: no drag handles and no toolbar (this package never imports
/// Material); click-drag and keyboard selection plus copy still work.
class _NoHandleSelectionControls extends TextSelectionControls {
  _NoHandleSelectionControls();

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => const SizedBox.shrink();

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      Offset.zero;

  @override
  Size getHandleSize(double textLineHeight) => Size.zero;

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) => const SizedBox.shrink();
}
