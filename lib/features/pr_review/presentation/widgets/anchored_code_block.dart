import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';

/// Displays a code block anchored to a specific file and line range,
/// fetched asynchronously from a file content provider.
class AnchoredCodeBlock extends StatefulWidget {
  /// Creates an [AnchoredCodeBlock].
  const AnchoredCodeBlock({
    super.key,
    required this.filePath,
    required this.lineNumber,
    required this.fetchFileContent,
    this.lineEnd,
    this.prNumber,
  });

  /// Path of the file to display.
  final String filePath;

  /// Starting line number to anchor to.
  final int lineNumber;

  /// Optional ending line number.
  final int? lineEnd;

  /// Async function that fetches file content given a path.
  final Future<String> Function(String path) fetchFileContent;

  /// Optional PR number for context.
  final int? prNumber;

  @override
  State<AnchoredCodeBlock> createState() => _AnchoredCodeBlockState();
}

class _AnchoredCodeBlockState extends State<AnchoredCodeBlock> {
  Future<List<String>>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget
        .fetchFileContent(widget.filePath)
        .then((content) => content.split('\n'));
  }

  @override
  void didUpdateWidget(covariant AnchoredCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.lineNumber != widget.lineNumber) {
      _future = widget
          .fetchFileContent(widget.filePath)
          .then((content) => content.split('\n'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              child: Center(child: CcSpinner()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final lines = snapshot.data!;
        final startLine = (widget.lineNumber - 3).clamp(0, lines.length - 1);
        final anchorEnd = widget.lineEnd ?? widget.lineNumber;
        final endLine = (anchorEnd + 3).clamp(0, lines.length);

        final visible = lines.sublist(startLine, endLine);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.bgSecondary,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: tokens.borderSecondary),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visible.length; i++)
                  CodeLineRow(
                    lineNumber: startLine + i + 1,
                    code: visible[i],
                    isAnchored:
                        (startLine + i + 1) >= widget.lineNumber &&
                        (startLine + i + 1) <= anchorEnd,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A single row in the anchored code block, showing a line number and code text.
class CodeLineRow extends StatelessWidget {
  /// Creates a [CodeLineRow].
  const CodeLineRow({
    super.key,
    required this.lineNumber,
    required this.code,
    required this.isAnchored,
  });

  /// The 1-based line number.
  final int lineNumber;

  /// The code text for this line.
  final String code;

  /// Whether this line is part of the anchored range.
  final bool isAnchored;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final isDimmed = !isAnchored;
    return Container(
      color: isAnchored
          ? tokens.bgBrandPrimary.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$lineNumber',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFonts.codeFamily,
                fontSize: 11,
                color: tokens.textTertiary.withValues(
                  alpha: isDimmed ? 0.5 : 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.codeFamily,
                fontSize: 12,
                height: 1.5,
                color: tokens.textPrimary.withValues(
                  alpha: isDimmed ? 0.6 : 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
