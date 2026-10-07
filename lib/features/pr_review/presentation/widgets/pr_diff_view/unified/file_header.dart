import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/outdated_comments.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Fixed height of a file header row in the unified diff. Sizes the Fenwick
/// header slot, so it must match the rendered header's height budget.
const double kFastFileHeaderHeight = 60;

/// The per-file header bar (status dot, path, +/− stats, copy/comment/viewed,
/// collapse toggle). Hosted by the unified diff sliver as a sparse child.
class FastFileHeader extends StatefulWidget {
  /// Creates a file header.
  const FastFileHeader({
    super.key,
    required this.file,
    required this.expanded,
    required this.isViewed,
    required this.onToggleExpanded,
    this.canPreview = false,
    this.isPreview = false,
    this.onTogglePreview,
    this.previewOffLabel,
    this.previewOnLabel,
    this.onToggleViewed,
    this.onAddFileComment,
    this.onOpenInEditor,
    this.outdatedComments = const [],
    this.showTopBorder = true,
  });

  /// The file this header describes.
  final PrFile file;

  /// Whether the file body is expanded.
  final bool expanded;

  /// Whether the file is marked viewed.
  final bool isViewed;

  /// Whether this file offers a diff/preview toggle (Markdown files with
  /// fetchable HEAD content).
  final bool canPreview;

  /// Whether the file body is currently showing the rendered Markdown preview.
  final bool isPreview;

  /// Toggles between the diff and the Markdown preview (null hides the control).
  final VoidCallback? onTogglePreview;

  /// Label for the off (source/diff) segment. Defaults to [AppLocalizations.diff].
  final String? previewOffLabel;

  /// Label for the on (pictures/preview) segment. Defaults to
  /// [AppLocalizations.preview].
  final String? previewOnLabel;

  /// Toggles expand/collapse.
  final VoidCallback onToggleExpanded;

  /// Toggles the viewed state (null hides the control).
  final VoidCallback? onToggleViewed;

  /// Opens a file-level comment composer (null hides the control).
  final VoidCallback? onAddFileComment;

  /// Opens this file in an editable code-server tab (null hides the control).
  final VoidCallback? onOpenInEditor;

  /// Server review comments on this file whose diff line no longer exists.
  /// When non-empty, a collapsed "outdated" group is shown in the header so the
  /// comments are surfaced (not dropped) without anchoring them to a live row.
  final List<PrCodeReviewComment> outdatedComments;

  /// Whether to draw the top hairline. The first file directly under a
  /// bordered toolbar turns this off so the two borders don't stack.
  final bool showTopBorder;

  @override
  State<FastFileHeader> createState() => _FastFileHeaderState();
}

class _FastFileHeaderState extends State<FastFileHeader> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.file.filename));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final dotColor = switch (widget.file.status) {
      PrFileStatus.added => const Color(0xFF2DA44E),
      PrFileStatus.removed => const Color(0xFFCF222E),
      _ => const Color(0xFF1F75FE),
    };
    final l10n = AppLocalizations.of(context);
    return Material(
      color: tokens.bgPrimary,
      // One announcement for the row: the full path (the visible one may be
      // truncated from the start), what changed, and whether it is viewed. A
      // heading, so the screen reader's headings rotor walks file by file;
      // the expanded state says what Enter/Space on the row will do.
      child: Semantics(
        container: true,
        header: true,
        button: true,
        expanded: widget.expanded,
        label: fileHeaderSemanticsLabel(
          l10n,
          widget.file,
          isViewed: widget.isViewed,
        ),
        child: InkWell(
          onTap: widget.onToggleExpanded,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: widget.showTopBorder
                    ? BorderSide(color: tokens.borderSecondary)
                    : BorderSide.none,
                bottom: BorderSide(color: tokens.borderSecondary),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ExcludeSemantics(
                          child: FileHeaderPath(
                            filename: widget.file.filename,
                            previousFilename: widget.file.previousFilename,
                            status: widget.file.status,
                            style: CcTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                            mutedColor: tokens.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      CcIconButton(
                        icon: _copied ? AppIcons.check : AppIcons.copy,
                        size: CcButtonSize.sm,
                        color: _copied
                            ? const Color(0xFF2DA44E)
                            : tokens.textTertiary,
                        tooltip: _copied ? l10n.copied : l10n.copyPath,
                        onPressed: _handleCopy,
                      ),
                    ],
                  ),
                ),
                if (widget.canPreview && widget.onTogglePreview != null) ...[
                  const SizedBox(width: 8),
                  CcSegmentedToggle<bool>(
                    value: widget.isPreview,
                    onChanged: (_) => widget.onTogglePreview!.call(),
                    segments: [
                      CcSegment(
                        value: false,
                        label:
                            widget.previewOffLabel ??
                            AppLocalizations.of(context).diff,
                      ),
                      CcSegment(
                        value: true,
                        label:
                            widget.previewOnLabel ??
                            AppLocalizations.of(context).preview,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                // The row label already says these in words.
                ExcludeSemantics(
                  child: Text(
                    '+${widget.file.additions}',
                    style: const TextStyle(
                      color: Color(0xFF2DA44E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ExcludeSemantics(
                  child: Text(
                    '−${widget.file.deletions}',
                    style: const TextStyle(
                      color: Color(0xFFCF222E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (widget.outdatedComments.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutdatedCommentsGroup(comments: widget.outdatedComments),
                ],
                if (widget.onAddFileComment != null) ...[
                  const SizedBox(width: 8),
                  CcIconButton(
                    icon: AppIcons.messageSquarePlus,
                    size: CcButtonSize.sm,
                    color: tokens.textTertiary,
                    tooltip: l10n.commentOnThisFile,
                    onPressed: widget.onAddFileComment,
                  ),
                ],
                if (widget.onOpenInEditor != null) ...[
                  const SizedBox(width: 8),
                  CcIconButton(
                    icon: AppIcons.fileCode,
                    size: CcButtonSize.sm,
                    color: tokens.textTertiary,
                    tooltip: l10n.openInEditor,
                    onPressed: widget.onOpenInEditor,
                  ),
                ],
                if (widget.onToggleViewed != null) ...[
                  const SizedBox(width: 8),
                  CcIconButton(
                    icon: widget.isViewed
                        ? AppIcons.checkCircle2
                        : AppIcons.circle,
                    size: CcButtonSize.sm,
                    color: widget.isViewed
                        ? const Color(0xFF1F75FE)
                        : tokens.textTertiary,
                    tooltip: widget.isViewed
                        ? l10n.diffMarkFileNotViewed
                        : l10n.diffMarkFileViewed,
                    onPressed: widget.onToggleViewed,
                  ),
                ],
                const SizedBox(width: 2),
                CcIconButton(
                  icon: widget.expanded
                      ? AppIcons.chevronUp
                      : AppIcons.chevronDown,
                  size: CcButtonSize.sm,
                  color: tokens.textTertiary,
                  tooltip: widget.expanded ? l10n.collapse : l10n.expand,
                  onPressed: widget.onToggleExpanded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen-reader label for a file: its full path (with the old path on a
/// rename), status, line counts and viewed state.
String fileHeaderSemanticsLabel(
  AppLocalizations l10n,
  PrFile file, {
  required bool isViewed,
}) {
  final previous = file.previousFilename;
  final renamed =
      file.status == PrFileStatus.renamed &&
      previous != null &&
      previous.isNotEmpty &&
      previous != file.filename;
  final status = switch (file.status) {
    PrFileStatus.added => l10n.added,
    PrFileStatus.removed => l10n.removed,
    PrFileStatus.renamed when renamed => l10n.diffFileRenamedFrom(previous),
    PrFileStatus.renamed => l10n.renamed,
    PrFileStatus.modified || PrFileStatus.unchanged => l10n.modified,
  };
  final additions = l10n.diffAdditionsCount(file.additions);
  final deletions = l10n.diffDeletionsCount(file.deletions);
  return isViewed
      ? l10n.diffFileSemanticsViewed(
          file.filename,
          status,
          additions,
          deletions,
        )
      : l10n.diffFileSemantics(file.filename, status, additions, deletions);
}

/// Renders a file path with a rename arrow when the file was moved/renamed.
class FileHeaderPath extends StatelessWidget {
  /// Creates a file-header path label.
  const FileHeaderPath({
    super.key,
    required this.filename,
    required this.previousFilename,
    required this.status,
    required this.style,
    required this.mutedColor,
  });

  /// Current path.
  final String filename;

  /// Previous path (for renames).
  final String? previousFilename;

  /// File status.
  final PrFileStatus status;

  /// Path text style.
  final TextStyle? style;

  /// Muted colour for the rename arrow / old path.
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final renamed =
        status == PrFileStatus.renamed &&
        previousFilename != null &&
        previousFilename!.isNotEmpty &&
        previousFilename != filename;
    if (!renamed) {
      return LeftTruncatedText(text: filename, style: style);
    }
    final oldStyle = style?.copyWith(
      color: mutedColor,
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: LeftTruncatedText(text: previousFilename!, style: oldStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(AppIcons.arrowRight, size: 12, color: mutedColor),
        ),
        Flexible(
          child: LeftTruncatedText(text: filename, style: style),
        ),
      ],
    );
  }
}

/// Single-line text that truncates from the LEFT (keeping the filename tail
/// visible) when it overflows.
class LeftTruncatedText extends StatelessWidget {
  /// Creates a left-truncated text.
  const LeftTruncatedText({super.key, required this.text, required this.style});

  static const String _ellipsis = '…';

  /// Full text.
  final String text;

  /// Text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0 || text.isEmpty) {
          return Text(text, style: style, maxLines: 1, softWrap: false);
        }
        final direction = Directionality.of(context);
        double widthOf(String s) {
          final tp = TextPainter(
            text: TextSpan(text: s, style: style),
            textDirection: direction,
            maxLines: 1,
          )..layout();
          return tp.size.width;
        }

        if (widthOf(text) <= maxW) {
          return Text(text, style: style, maxLines: 1, softWrap: false);
        }

        var lo = 1;
        var hi = text.length;
        var best = text.length;
        while (lo <= hi) {
          final mid = (lo + hi) ~/ 2;
          final probe = '$_ellipsis${text.substring(mid)}';
          if (widthOf(probe) <= maxW) {
            best = mid;
            hi = mid - 1;
          } else {
            lo = mid + 1;
          }
        }
        final display = '$_ellipsis${text.substring(best)}';
        return Text(display, style: style, maxLines: 1, softWrap: false);
      },
    );
  }
}
