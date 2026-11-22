part of 'agent_transcript.dart';

extension _ScriptRows on _AgentTranscriptState {
  /// The expanded body of a `repl` call: its status, the script (folded
  /// until asked for), the calls it made and its output.
  List<Widget> _scriptDetail(
    DesignSystemTokens t,
    ToolSegment s,
    int index,
    List<(int, ToolSegment)> calls,
  ) {
    final l10n = AppLocalizations.of(context);
    final status = readScriptStatus(s);
    final code = s.inputs?['code'];
    final source = code is String ? code.trimRight() : '';
    final lines = source.isEmpty ? 0 : '\n'.allMatches(source).length + 1;
    final key = '$index#script';
    final showScript = _expanded.contains(key);
    return [
      const SizedBox(height: 8),
      Row(
        children: [
          CcStatusTag(
            label: _scriptStateLabel(l10n, status.state),
            tone: _scriptStateTone(status.state),
          ),
          if (status.detail != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ),
          ],
        ],
      ),
      if (source.isNotEmpty) ...[
        const SizedBox(height: 4),
        Semantics(
          expanded: showScript,
          child: CcTappable(
            onPressed: () => _toggle(key),
            builder: (context, _) => ConstrainedBox(
              // The phone's touch floor: the fold is its own target inside
              // the row.
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Icon(
                    showScript ? AppIcons.chevronDown : AppIcons.chevronRight,
                    size: 12,
                    color: t.fgTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.scriptSourceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.scriptSourceLines(lines),
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showScript) _PhoneScriptSource(source: source),
      ],
      ..._nestedCalls(t, calls, script: s),
      if (status.rest.isNotEmpty) _detail(t, l10n.output, status.rest),
    ];
  }

  /// The calls a script made, each drawn by the same row a direct call
  /// gets; under a [script], laid over its structure ([PhoneScriptCalls]).
  List<Widget> _nestedCalls(
    DesignSystemTokens t,
    List<(int, ToolSegment)> calls, {
    ToolSegment? script,
  }) => [
    PhoneScriptCalls(
      script: script,
      calls: calls,
      // A transcript no longer live has stopped, whatever status the script
      // was left in.
      ended:
          !widget.isLive ||
          script == null ||
          script.status != ToolSegmentStatus.running,
      rowBuilder: (entry) => _tool(t, entry.$2, entry.$1),
    ),
  ];

  void _toggle(String key) => _update(() {
    if (!_expanded.remove(key)) {
      _expanded.add(key);
    }
  });
}

/// A closed script row's summary: how many calls, and any that did not go
/// well (`7 calls · 1 failed`).
String _callSummary(AppLocalizations l10n, NestedCallTally tally) => [
  l10n.scriptCallCount(tally.total),
  if (tally.failed > 0) l10n.scriptCallsFailed(tally.failed),
  if (tally.denied > 0) l10n.scriptCallsDenied(tally.denied),
  if (tally.cancelled > 0) l10n.scriptCallsCancelled(tally.cancelled),
].join(' · ');

String _scriptStateLabel(AppLocalizations l10n, ScriptRunState state) =>
    switch (state) {
      ScriptRunState.running => l10n.scriptStateRunning,
      ScriptRunState.completed => l10n.scriptStateCompleted,
      ScriptRunState.failed => l10n.scriptStateFailed,
      ScriptRunState.timedOut => l10n.scriptStateTimedOut,
      ScriptRunState.cancelled => l10n.scriptStateCancelled,
      ScriptRunState.memoryExceeded => l10n.scriptStateMemoryExceeded,
      ScriptRunState.outputExceeded => l10n.scriptStateOutputExceeded,
      ScriptRunState.sandboxError => l10n.scriptStateSandboxError,
      ScriptRunState.refused => l10n.scriptStateRefused,
    };

CcStatusTone _scriptStateTone(ScriptRunState state) => switch (state) {
  ScriptRunState.running || ScriptRunState.cancelled => CcStatusTone.neutral,
  ScriptRunState.completed => CcStatusTone.positive,
  ScriptRunState.timedOut ||
  ScriptRunState.memoryExceeded ||
  ScriptRunState.outputExceeded ||
  ScriptRunState.refused => CcStatusTone.caution,
  ScriptRunState.failed || ScriptRunState.sandboxError => CcStatusTone.negative,
};

/// A script's source, highlighted as JavaScript through the phone's deferred
/// syntax engine (the one its diffs use). It renders plain until the grammar
/// arrives, and stays plain if it cannot load.
class _PhoneScriptSource extends StatefulWidget {
  const _PhoneScriptSource({required this.source});

  final String source;

  /// The most lines shown; a longer script is cut with a marker.
  static const int maxLines = 400;

  @override
  State<_PhoneScriptSource> createState() => _PhoneScriptSourceState();
}

class _PhoneScriptSourceState extends State<_PhoneScriptSource> {
  List<List<DiffToken>>? _tokens;
  bool? _requestedDark;

  List<String> get _lines =>
      widget.source.split('\n').take(_PhoneScriptSource.maxLines).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_highlight());
  }

  Future<void> _highlight() async {
    final language = diffLanguageForPath('script.js');
    final dark = context.ccTheme?.isDark ?? false;
    if (language == null || dark == _requestedDark) {
      return;
    }
    _requestedDark = dark;
    final lines = _lines;
    final tokens = await highlightDiffRows(
      [
        for (var i = 0; i < lines.length; i++)
          DiffLine(
            kind: DiffLineKind.context,
            content: lines[i],
            oldLine: i + 1,
            newLine: i + 1,
          ),
      ],
      language,
      dark: dark,
    );
    if (mounted && _requestedDark == dark) {
      setState(() => _tokens = tokens);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final lines = _lines;
    final tokens = _tokens;
    final base = CcFonts.code(
      textStyle: TextStyle(fontSize: 11, height: 1.4, color: t.textSecondary),
    );
    final hidden = '\n'.allMatches(widget.source).length + 1 - lines.length;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      // RTL carve-out: a script is JavaScript source — LTR in every locale.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border.all(color: t.borderSecondary),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Text.rich(
                    TextSpan(
                      style: base,
                      children: tokens == null || i >= tokens.length
                          ? [TextSpan(text: lines[i])]
                          : [
                              for (final token in tokens[i])
                                TextSpan(
                                  text: token.text,
                                  style: token.colorValue == null
                                      ? null
                                      : TextStyle(
                                          color: Color(token.colorValue!),
                                        ),
                                ),
                            ],
                    ),
                    softWrap: false,
                  ),
                if (hidden > 0)
                  Text(
                    '… +$hidden',
                    style: base.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
