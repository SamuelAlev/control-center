import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/outdated_comments.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Material(
      color: tokens.bgPrimary,
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
                    const SizedBox(width: 4),
                    CcIconButton(
                      icon: _copied ? AppIcons.check : AppIcons.copy,
                      size: CcButtonSize.sm,
                      color: _copied
                          ? const Color(0xFF2DA44E)
                          : tokens.textTertiary,
                      tooltip: _copied ? 'Copied!' : 'Copy path',
                      onPressed: _handleCopy,
                    ),
                  ],
                ),
              ),
              if (widget.canPreview && widget.onTogglePreview != null) ...[
                const SizedBox(width: 8),
                SegmentedToggle<bool>(
                  value: widget.isPreview,
                  onChanged: (_) => widget.onTogglePreview!.call(),
                  segments: [
                    (value: false, label: AppLocalizations.of(context).diff),
                    (value: true, label: AppLocalizations.of(context).preview),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '+${widget.file.additions}',
                style: const TextStyle(
                  color: Color(0xFF2DA44E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '−${widget.file.deletions}',
                style: const TextStyle(
                  color: Color(0xFFCF222E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
                  tooltip: AppLocalizations.of(context).commentOnThisFile,
                  onPressed: widget.onAddFileComment,
                ),
              ],
              if (widget.onOpenInEditor != null) ...[
                const SizedBox(width: 8),
                CcIconButton(
                  icon: AppIcons.fileCode,
                  size: CcButtonSize.sm,
                  color: tokens.textTertiary,
                  tooltip: AppLocalizations.of(context).openInEditor,
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
                      ? 'Mark as not viewed'
                      : 'Mark as viewed',
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
                tooltip: widget.expanded
                    ? AppLocalizations.of(context).collapse
                    : AppLocalizations.of(context).expand,
                onPressed: widget.onToggleExpanded,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
