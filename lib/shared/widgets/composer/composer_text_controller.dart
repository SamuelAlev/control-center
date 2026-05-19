import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:flutter/widgets.dart';

/// The composer's text controller, which paints `@[file:…]` references as
/// pills.
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

  /// Whether the composer still holds an attachment for a reference name.
  ///
  /// Null treats every well-formed reference as resolved — the right default
  /// for a composer that tracks no attachments.
  bool Function(String name)? isResolved;

  /// Tokens are painted in this color family; supplied by the host so the
  /// controller stays free of a `BuildContext` lookup on every keystroke.
  DesignSystemTokens? tokens;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Hand the composing region back to the base implementation. An IME
    // marks its in-flight text with an underline computed from
    // `value.composing`, and re-slicing the string underneath it drops that
    // cue mid-word for anyone typing Japanese, Korean, or an accent on macOS.
    // A reference is fully typed by the time it exists, so nothing is lost.
    if (withComposing &&
        !value.composing.isCollapsed &&
        value.isComposingRangeValid) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final source = text;
    final matches = findFileRefs(source);
    if (matches.isEmpty) {
      return TextSpan(style: style, text: source);
    }
    final ds = tokens ?? context.designSystem ?? DesignSystemTokens.light();
    final resolvedStyle = (style ?? const TextStyle()).copyWith(
      color: ds.accent,
      backgroundColor: ds.accentSoft,
      fontWeight: FontWeight.w500,
    );
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (!(isResolved?.call(match.name) ?? true)) {
        continue;
      }
      if (match.start > cursor) {
        children.add(TextSpan(text: source.substring(cursor, match.start)));
      }
      children.add(TextSpan(text: match.token, style: resolvedStyle));
      cursor = match.end;
    }
    if (cursor < source.length) {
      children.add(TextSpan(text: source.substring(cursor)));
    }
    return TextSpan(style: style, children: children);
  }
}
