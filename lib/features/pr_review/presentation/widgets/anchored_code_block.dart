import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AnchoredCodeBlock extends StatefulWidget {
  const AnchoredCodeBlock({
    super.key,
    required this.filePath,
    required this.lineNumber,
    required this.fetchFileContent,
    this.lineEnd,
    this.prNumber,
  });

  final String filePath;
  final int lineNumber;
  final int? lineEnd;
  final Future<String> Function(String path) fetchFileContent;
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
              child: Center(child: FCircularProgress()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final lines = snapshot.data!;
        final startLine =
            (widget.lineNumber - 3).clamp(0, lines.length - 1);
        final anchorEnd = widget.lineEnd ?? widget.lineNumber;
        final endLine = (anchorEnd + 3).clamp(0, lines.length);

        final visible = lines.sublist(startLine, endLine);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.bgSecondary,
              borderRadius: BorderRadius.circular(6),
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
                    isAnchored: (startLine + i + 1) >= widget.lineNumber &&
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

class CodeLineRow extends StatelessWidget {
  const CodeLineRow({
    super.key,
    required this.lineNumber,
    required this.code,
    required this.isAnchored,
  });

  final int lineNumber;
  final String code;
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
                fontFamily: 'monospace',
                fontSize: 10,
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
                fontFamily: 'monospace',
                fontSize: 11,
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
