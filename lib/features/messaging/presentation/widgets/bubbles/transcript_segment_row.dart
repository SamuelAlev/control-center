import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_links.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/nested_tool_calls.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'transcript_segment_row_text.dart';
part 'transcript_segment_row_trailing.dart';
part 'transcript_status_dot.dart';

/// One row in the transcript process timeline: a reasoning span, tool call,
/// error, or sandbox violation. Collapsed by default; tools and long prose
/// expand to a rich body (code, diff, terminal, or JSON).
///
/// A call that ran a script lists the calls the script made inside its body,
/// each drawn by this same row, so a nested edit shows the diff a direct one
/// does.
class TranscriptSegmentRow extends ConsumerStatefulWidget {
  /// Creates a [TranscriptSegmentRow].
  const TranscriptSegmentRow({
    super.key,
    required this.segment,
    required this.codeFont,
    this.pending = false,
    this.nestedCalls = const [],
    this.nested = false,
  });

  /// The segment to render.
  final TranscriptSegment segment;

  /// Mono font for rich code/diff bodies.
  final String codeFont;

  /// Whether this is the live, currently-running tail segment.
  final bool pending;

  /// The calls a script made from this call, in the order it made them.
  final List<ToolSegment> nestedCalls;

  /// Whether this row is one of those calls, inside its script's row. A
  /// script can make hundreds, so they start closed whatever their kind.
  final bool nested;

  @override
  ConsumerState<TranscriptSegmentRow> createState() =>
      _TranscriptSegmentRowState();
}

class _TranscriptSegmentRowState extends ConsumerState<TranscriptSegmentRow> {
  bool? _userOpen;

  /// A heavy edit's `+N −N` badge is filled in after the diff leaves the
  /// frame. Keyed by the tool inputs: a live output stream rebuilds this
  /// header on every chunk, and the edit text is not what those chunks change.
  String? _watchedDiffKey;

  bool get _open => _userOpen ?? _defaultOpen;

  void _onDeferredDiff(Future<void> done) {
    final seg = widget.segment;
    final key = seg is ToolSegment
        ? '${seg.toolCallId}:${identityHashCode(seg.inputs)}'
        : '';
    if (_watchedDiffKey == key) {
      return;
    }
    _watchedDiffKey = key;
    done.whenComplete(() {
      if (!mounted || _watchedDiffKey != key) {
        return;
      }
      setState(() {});
    });
  }

  bool get _defaultOpen {
    final seg = widget.segment;
    if (widget.nested) {
      return false;
    }
    if (seg is ErrorSegment || seg is ViolationSegment) {
      return true;
    }
    if (seg is ToolSegment && seg.status == ToolSegmentStatus.error) {
      return true;
    }
    // Reads and file changes show their results inline until the user closes them.
    if (seg is ToolSegment && toolBodyOpensByDefault(seg)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final seg = widget.segment;
    final canExpand = _hasExpandable(seg) || widget.nestedCalls.isNotEmpty;
    // The blob URL is signed per workspace, and `shared/` may not reach into
    // a feature to find out which one — so it is read here and passed down.
    // Watched in this build, not the lazily built body below.
    final workspaceId = canExpand && seg is ToolSegment
        ? ref.watch(activeWorkspaceIdProvider)
        : null;

    final summaryRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(_icon(seg), size: 14, color: _iconColor(seg, tokens)),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            _summaryText(seg, tokens, t),
            // An error's headline IS the message; clipping it to one line hid
            // the part that says what to do.
            maxLines: seg is ErrorSegment || seg is ViolationSegment ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ..._trailing(seg, tokens, t),
        const SizedBox(width: 4),
        _StatusDot(segment: seg, pending: widget.pending, tokens: tokens),
      ],
    );

    final header = canExpand
        ? MergeSemantics(
            child: Semantics(
              expanded: _open,
              child: CcTappable(
                onPressed: () => setState(() => _userOpen = !_open),
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: summaryRow,
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: summaryRow,
          );

    return Container(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: _categoryAccent(seg, tokens), width: 2),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(start: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (canExpand)
            CcCollapsible(
              expanded: _open,
              // A Builder so a closed row never builds (or parses) its body:
              // the collapsible only builds its child while it shows.
              child: Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _detail(context, seg, tokens, workspaceId),
                ),
              ),
            ),
        ],
      ),
    );
  }

  TextSpan _summaryText(
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    DesignSystemTokens t,
  ) {
    final l10n = AppLocalizations.of(context);
    final base = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(color: tokens.textTertiary),
    );
    final mono = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(color: tokens.textPrimary),
    );
    switch (seg) {
      case ToolSegment():
        final p = resolveToolPresentation(seg);
        return TextSpan(
          // Base style on the root so the unstyled '  ' spacer below shares
          // the summary's metrics instead of the ambient DefaultTextStyle.
          style: base,
          children: [
            TextSpan(
              text: p.verb,
              style: mono.copyWith(fontWeight: FontWeight.w600),
            ),
            if (p.subtitle != null) ...[
              const TextSpan(text: '  '),
              TextSpan(text: p.subtitle, style: base),
            ],
          ],
        );
      case ReasoningSegment(:final text):
        return TextSpan(
          text: _firstLine(text) ?? l10n.transcriptThinking,
          style: base,
        );
      case ErrorSegment(:final message):
        return TextSpan(
          text: _firstLine(message) ?? l10n.transcriptErrorLabel,
          style: base.copyWith(color: tokens.textErrorPrimary),
        );
      case ViolationSegment(:final message):
        return TextSpan(
          text: _firstLine(message) ?? l10n.transcriptSandboxBlocked,
          style: base.copyWith(color: tokens.fgWarningPrimary),
        );
      case TextSegment(:final text):
        return TextSpan(text: _firstLine(text) ?? '', style: base);
    }
  }

  Widget _detail(
    BuildContext context,
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    String? workspaceId,
  ) {
    if (seg is ToolSegment) {
      return buildToolBody(
        context,
        seg: seg,
        codeFont: widget.codeFont,
        tokens: tokens,
        workspaceId: workspaceId,
        nestedCalls: _nestedListOf(seg),
      );
    }
    final text = switch (seg) {
      ReasoningSegment(:final text) => text,
      ErrorSegment(:final message) => _afterFirstLine(message) ?? message,
      ViolationSegment(:final message) => _afterFirstLine(message) ?? message,
      TextSegment(:final text) => text,
      ToolSegment() => '',
    };
    return CcMarkdown(
      data: text,
      selectable: true,
      style: appMarkdownStyle(context, compact: true),
      codeBuilder: sharedCodeBuilder(),
      plugins: chatMarkdownPlugins,
      options: chatMarkdownOptions,
      builders: chatMarkdownBuilders,
      imageBuilder: appMarkdownImageBuilder,
      onTapLink: openMarkdownLink,
    );
  }
}

IconData _icon(TranscriptSegment seg) => switch (seg) {
  ReasoningSegment() => AppIcons.brain,
  ToolSegment() => resolveToolPresentation(seg).icon,
  ErrorSegment() => AppIcons.triangleAlert,
  ViolationSegment() => AppIcons.shield,
  TextSegment() => AppIcons.messageSquare,
};

Color _iconColor(TranscriptSegment seg, DesignSystemTokens tokens) =>
    switch (seg) {
      ErrorSegment() => tokens.fgErrorPrimary,
      ViolationSegment() => tokens.fgWarningPrimary,
      // Refused before it ran: a policy outcome, not a tool that broke.
      ToolSegment() when nestedCallStateOf(seg) == NestedCallState.denied =>
        tokens.fgWarningPrimary,
      ToolSegment(:final status) when status == ToolSegmentStatus.error =>
        tokens.fgErrorPrimary,
      ToolSegment() => tokens.textPrimary,
      _ => tokens.textTertiary,
    };

/// Left-rail accent color for a transcript row: tool categories get a distinct
/// token hue (explore/edit/run/delegate/fetch/other); error and violation rows
/// get their status hue; everything else a faint rail. Color is an additional
/// scannability cue only — the icon, verb and status dot always carry the
/// primary signal.
Color _categoryAccent(TranscriptSegment seg, DesignSystemTokens tokens) {
  if (seg is ToolSegment) {
    return switch (resolveToolPresentation(seg).category) {
      ToolCategory.explore => tokens.textTertiary,
      ToolCategory.edit => tokens.fgWarningPrimary,
      ToolCategory.run => tokens.accent,
      ToolCategory.delegate => tokens.fgBrandSecondary,
      ToolCategory.fetch => tokens.textSuccessPrimary,
      ToolCategory.other => tokens.borderSecondary,
    };
  }
  if (seg is ErrorSegment) {
    return tokens.fgErrorPrimary;
  }
  if (seg is ViolationSegment) {
    return tokens.fgWarningPrimary;
  }
  return tokens.borderSecondary;
}

bool _hasExpandable(TranscriptSegment seg) => switch (seg) {
  ToolSegment(
    :final inputs,
    :final outputs,
    :final images,
    :final attachments,
  ) =>
    (inputs != null && inputs.isNotEmpty) ||
        outputs.isNotEmpty ||
        images.isNotEmpty ||
        attachments.isNotEmpty,
  ReasoningSegment(:final text) => text.length > 80,
  // The header already wraps the first line of an error in full; only what
  // follows it is worth an expansion. Expanding a one-line error used to print
  // the same sentence twice.
  ErrorSegment(:final message) => _afterFirstLine(message) != null,
  ViolationSegment(:final message) => _afterFirstLine(message) != null,
  TextSegment(:final text) => text.length > 80,
};
