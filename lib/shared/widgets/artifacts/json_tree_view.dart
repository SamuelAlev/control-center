import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Renders arbitrary JSON as an indented, readable tree.
///
/// Generalized out of the pipeline step-detail panel, which was the ONLY place
/// in the app that rendered a structured agent output — and did it with a
/// private widget, so `submit_output` payloads were readable in exactly one
/// screen. Artifacts made a shared renderer necessary; the pipelines panel now
/// uses this one.
///
/// Objects and arrays collapse; scalars are typed by color AND by shape (quoted
/// strings, bare numbers, italic `null`) so the tree never depends on color
/// alone to be legible.
class JsonTreeView extends StatelessWidget {
  /// Creates a [JsonTreeView] over an already-decoded [value].
  const JsonTreeView({
    super.key,
    required this.value,
    this.initiallyExpanded = true,
  });

  /// Renders [raw], falling back to preformatted text when it is not JSON.
  static Widget fromRaw(String raw, {bool initiallyExpanded = true}) {
    try {
      return JsonTreeView(
        value: jsonDecode(raw),
        initiallyExpanded: initiallyExpanded,
      );
    } on FormatException {
      return _RawFallback(raw: raw);
    }
  }

  /// The decoded JSON value: a `Map`, `List`, or scalar.
  final Object? value;

  /// Whether container nodes start open.
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) =>
      _Node(value: value, depth: 0, initiallyExpanded: initiallyExpanded);
}

class _Node extends StatefulWidget {
  const _Node({
    required this.value,
    required this.depth,
    required this.initiallyExpanded,
    this.label,
  });

  final Object? value;
  final int depth;
  final bool initiallyExpanded;
  final String? label;

  @override
  State<_Node> createState() => _NodeState();
}

class _NodeState extends State<_Node> {
  late bool _expanded = widget.initiallyExpanded;

  /// Nesting past this depth starts collapsed regardless, so a deeply nested
  /// payload cannot expand into thousands of rows on first paint.
  static const int _autoCollapseDepth = 3;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    final value = widget.value;
    final entries = switch (value) {
      final Map<String, dynamic> m =>
        m.entries
            .map((e) => (label: e.key, value: e.value as Object?))
            .toList(),
      final List<Object?> l => [
        for (var i = 0; i < l.length; i++) (label: '$i', value: l[i]),
      ],
      _ => null,
    };

    if (entries == null) {
      return _ScalarRow(label: widget.label, value: value, tokens: tokens);
    }

    final isList = value is List;
    final summary = isList ? '[${entries.length}]' : '{${entries.length}}';
    final open = _expanded && widget.depth <= _autoCollapseDepth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: '${widget.label ?? (isList ? 'array' : 'object')} $summary',
          child: CcTappable(
            onPressed: () => setState(() => _expanded = !_expanded),
            builder: (context, states) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: open ? 0 : -0.25,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    AppIcons.chevronDown,
                    size: 14,
                    color: tokens.fgQuaternary,
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.label != null)
                  Text(widget.label!, style: _keyStyle(tokens)),
                if (widget.label != null) const SizedBox(width: 6),
                Text(summary, style: _muted(tokens)),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _Node(
                      value: e.value,
                      depth: widget.depth + 1,
                      initiallyExpanded: widget.initiallyExpanded,
                      label: e.label,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScalarRow extends StatelessWidget {
  const _ScalarRow({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String? label;
  final Object? value;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Shape carries the type as much as color does: strings keep their quotes,
    // null is italic, numbers and booleans stay bare.
    final (text, style) = switch (value) {
      null => ('null', _scalar(tokens, italic: true)),
      final String s => ('"$s"', _scalar(tokens)),
      final bool b => ('$b', _scalar(tokens)),
      final num n => ('$n', _scalar(tokens)),
      final other => ('$other', _scalar(tokens)),
    };
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: _keyStyle(tokens)),
            Text(': ', style: _muted(tokens)),
          ],
          Flexible(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _RawFallback extends StatelessWidget {
  const _RawFallback({required this.raw});

  final String raw;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    // No SelectionArea here: it is a Material-layer widget, and callers that
    // want selection wrap a whole surface (cc_markdown owns the app's selection
    // island).
    return Text(raw, style: _scalar(tokens));
  }
}

TextStyle _keyStyle(DesignSystemTokens tokens) => TextStyle(
  fontFamily: CcFonts.codeFamily,
  fontSize: 11.5,
  height: 1.4,
  fontWeight: FontWeight.w600,
  color: tokens.textSecondary,
);

TextStyle _scalar(DesignSystemTokens tokens, {bool italic = false}) =>
    TextStyle(
      fontFamily: CcFonts.codeFamily,
      fontSize: 11.5,
      height: 1.4,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: tokens.textPrimary,
    );

TextStyle _muted(DesignSystemTokens tokens) => TextStyle(
  fontFamily: CcFonts.codeFamily,
  fontSize: 11.5,
  height: 1.4,
  color: tokens.textTertiary,
);
