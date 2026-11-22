part of 'transcript_segment_row.dart';

// The collapsed header's trailing facts (diff stats, script calls, duration)
// and the list of calls a script made.

extension _TranscriptSegmentRowTrailing on _TranscriptSegmentRowState {
  List<Widget> _trailing(
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    DesignSystemTokens t,
  ) {
    final out = <Widget>[];
    final small = CcTypography.caption.copyWith(
      color: tokens.textQuaternary,
      fontSize: 10,
    );
    if (seg is ToolSegment) {
      final stats = toolDiffStats(seg, whenReady: _onDeferredDiff);
      if (stats != null && (stats.adds > 0 || stats.dels > 0)) {
        out.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Text.rich(
              // A base style on the root span matters: an unstyled child
              // (e.g. a bare ' ' spacer) would inherit the ambient
              // DefaultTextStyle, inflate the line box and lift the stats
              // off the shared baseline with the duration beside it.
              TextSpan(
                style: CcTypography.caption.copyWith(fontSize: 10),
                children: [
                  TextSpan(
                    text: '+${stats.adds}',
                    style: CcTypography.caption.copyWith(
                      color: tokens.textSuccessPrimary,
                      fontSize: 10,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '−${stats.dels}',
                    style: CcTypography.caption.copyWith(
                      color: tokens.textErrorPrimary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    final calls = widget.nestedCalls;
    if (calls.isNotEmpty) {
      // What a closed script row has to say without being opened: how many
      // calls it made and which did not go well.
      out.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: Text(
            nestedCallSummary(
              AppLocalizations.of(context),
              NestedCallTally.of(calls),
            ),
            style: small.copyWith(color: tokens.textTertiary),
          ),
        ),
      );
    }
    if (seg.durationMs != null) {
      out.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: Text(
            _formatDuration(Duration(milliseconds: seg.durationMs!)),
            style: small,
          ),
        ),
      );
    }
    return out;
  }

  /// [_nestedList] for a call that ran a script or made calls, else null.
  Widget? _nestedListOf(ToolSegment seg) =>
      widget.nestedCalls.isEmpty && !isReplTool(seg.toolName)
      ? null
      : _nestedList(seg);

  /// The calls the script made over its structure, each made call drawn by
  /// this same row. Built for a `repl` row before its first call too: what
  /// it is about to do is listed as queued.
  Widget _nestedList(ToolSegment script) => NestedToolCalls(
    script: script,
    calls: widget.nestedCalls,
    // A row no longer live has stopped, whatever status it was left in.
    ended: !widget.pending || script.status != ToolSegmentStatus.running,
    codeFont: widget.codeFont,
    itemBuilder: (context, call) => TranscriptSegmentRow(
      segment: call,
      codeFont: widget.codeFont,
      nested: true,
      // A call spins only while its script is live; once the script has
      // stopped, a call it left running is shown as it was recorded.
      pending: widget.pending && call.status == ToolSegmentStatus.running,
    ),
  );
}
