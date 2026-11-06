import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/composer/composer_markdown.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:flutter/widgets.dart';

/// The composer's text controller, which paints `@[file:…]` references as
/// pills and the draft's Markdown as it will read (see
/// [scanComposerMarkdown]).
///
/// Styling only — the characters are untouched, so the caret, selection, undo
/// and the platform's input connection all see exactly the text the user typed.
/// See `file_reference.dart` for why this is not a `WidgetSpan`.
///
/// A reference is painted as "resolved" only while [isResolved] says the
/// composer still holds an attachment for it. Someone who types `@[file:x]` by
/// hand, or who edits a real token into a name that no longer matches, sees
/// plain text — which is the truth: nothing is attached, and nothing will be
/// spliced in on submit.
class ComposerTextController extends TextEditingController {
  /// Creates a [ComposerTextController].
  ComposerTextController({super.text, this.isResolved});

  /// Creates a controller for a Markdown field outside the composer, such as
  /// an agent's system prompt.
  ///
  /// Such a field holds no attachments, so a `@[file:…]` in it stays plain
  /// text. With a null [isResolved] it would paint as an attached file.
  ComposerTextController.markdownOnly({super.text})
    : isResolved = _noAttachments;

  static bool _noAttachments(String name) => false;

  /// Whether the composer still holds an attachment for a reference name.
  ///
  /// Null treats every well-formed reference as resolved — the right default
  /// for a composer that tracks no attachments.
  bool Function(String name)? isResolved;

  /// Tokens are painted in this color family; supplied by the host so the
  /// controller stays free of a `BuildContext` lookup on every keystroke.
  DesignSystemTokens? tokens;

  /// True for the duration of [replaceAll].
  ///
  /// The composer reads this from inside the controller listener, which runs
  /// synchronously during the assignment, and skips pruning attachments and
  /// entity picks. A temporary swap — loading a message in to edit, then
  /// putting the draft back — must not treat the missing tokens as deletions.
  bool preservingAttachments = false;

  /// Replaces the whole document and puts the caret at the end.
  ///
  /// Sets [preservingAttachments] around the assignment so a composer listening
  /// to this controller keeps attachments and structured mentions that belong
  /// to the text being swapped out.
  void replaceAll(String text) {
    preservingAttachments = true;
    try {
      value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } finally {
      preservingAttachments = false;
    }
  }

  // The scan depends only on the text, and `buildTextSpan` runs on every
  // build — caret blinks and focus changes included — so the last result is
  // kept rather than re-scanned for an unchanged draft.
  String? _scannedText;
  Uint16List _scannedFlags = Uint16List(0);
  List<FileRefMatch> _scannedRefs = const [];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    if (!identical(source, _scannedText) && source != _scannedText) {
      _scannedRefs = findFileRefs(source);
      _scannedFlags = scanComposerMarkdown(
        source,
        opaque: [for (final m in _scannedRefs) (start: m.start, end: m.end)],
      );
      _scannedText = source;
    }
    final refs = _scannedRefs;
    var flags = _scannedFlags;

    // An IME marks its in-flight text with an underline computed from
    // `value.composing`. Dropping it mid-word would cost anyone typing
    // Japanese, Korean, or an accent on macOS the cue, so the composing range
    // is folded into the same per-character pass rather than handed back to
    // the base implementation, which would also drop the Markdown styling for
    // the length of every composition.
    if (withComposing &&
        !value.composing.isCollapsed &&
        value.isComposingRangeValid) {
      flags = Uint16List.fromList(flags);
      for (var i = value.composing.start; i < value.composing.end; i++) {
        flags[i] |= _composingFlag;
      }
    }

    if (refs.isEmpty && !flags.any((f) => f != 0)) {
      return TextSpan(style: style, text: source);
    }

    final ds = tokens ?? context.designSystem ?? DesignSystemTokens.light();
    final base = style ?? const TextStyle();
    final pill = TextStyle(
      color: ds.accent,
      backgroundColor: ds.accentSoft,
      fontWeight: FontWeight.w500,
    );

    // Each character's run key: its flags, or a pill marker inside a resolved
    // reference. Run boundaries also fall on every reference edge, so an
    // unresolved one still stands as its own (plain) run.
    final resolvedRefs = [
      for (final ref in refs) isResolved?.call(ref.name) ?? true,
    ];
    final children = <InlineSpan>[];
    var refIndex = 0;
    var runStart = 0;
    int? runKey;
    TextStyle? runStyle;

    void flush(int end) {
      if (end > runStart) {
        children.add(
          TextSpan(text: source.substring(runStart, end), style: runStyle),
        );
      }
      runStart = end;
    }

    for (var i = 0; i < source.length; i++) {
      while (refIndex < refs.length && refs[refIndex].end <= i) {
        refIndex++;
      }
      final ref = refIndex < refs.length ? refs[refIndex] : null;
      final inRef = ref != null && i >= ref.start;
      final resolved = inRef && resolvedRefs[refIndex];
      final atRefEdge =
          (ref != null && i == ref.start) ||
          (refIndex > 0 && refs[refIndex - 1].end == i);
      final key = resolved ? _pillKey | (flags[i] & _composingFlag) : flags[i];
      if (runKey == null) {
        runKey = key;
        runStyle = _styleFor(key, ds, base, pill);
      } else if (key != runKey || atRefEdge) {
        flush(i);
        runKey = key;
        runStyle = _styleFor(key, ds, base, pill);
      }
    }
    flush(source.length);
    return TextSpan(style: style, children: children);
  }

  static const int _pillKey = 1 << 14;
  static const int _composingFlag = 1 << 15;

  static TextStyle? _styleFor(
    int key,
    DesignSystemTokens ds,
    TextStyle base,
    TextStyle pill,
  ) {
    if (key == 0) {
      return null;
    }
    final composing = key & _composingFlag != 0;
    if (key & _pillKey != 0) {
      return composing
          ? pill.copyWith(decoration: TextDecoration.underline)
          : pill;
    }
    var style = const TextStyle();
    final decorations = <TextDecoration>[];
    if (key & (ComposerMarkdownFlag.code | ComposerMarkdownFlag.block) != 0) {
      // One step down the type ramp (14 → 13, the mono size DESIGN.md sets
      // for machine values) so Fira Code's wider glyphs sit level with the
      // Manrope around them.
      style = CcFonts.code(
        textStyle: TextStyle(fontSize: (base.fontSize ?? 14) - 1),
      );
    }
    if (key & ComposerMarkdownFlag.code != 0) {
      style = style.copyWith(backgroundColor: ds.hoverStrong);
    }
    if (key & (ComposerMarkdownFlag.bold | ComposerMarkdownFlag.heading) != 0) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }
    if (key & ComposerMarkdownFlag.italic != 0) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (key & ComposerMarkdownFlag.quote != 0) {
      style = style.copyWith(color: ds.textSecondary);
    }
    if (key & ComposerMarkdownFlag.strike != 0) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (key & ComposerMarkdownFlag.link != 0) {
      decorations.add(TextDecoration.underline);
    }
    if (composing) {
      decorations.add(TextDecoration.underline);
    }
    // Last, so a delimiter inside bold or a quote still reads as scaffolding.
    if (key & ComposerMarkdownFlag.marker != 0) {
      style = style.copyWith(color: ds.textPlaceholder);
    }
    if (decorations.isNotEmpty) {
      style = style.copyWith(decoration: TextDecoration.combine(decorations));
    }
    return style;
  }
}
