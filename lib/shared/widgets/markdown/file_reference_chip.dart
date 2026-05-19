// `@[file:<name>]` in a SENT message, rendered the way the composer rendered
// it while the message was still being typed.
//
// **Why a parser plugin.** The token is ordinary text in the stored message —
// that is the whole design of a reference (see `composer/file_reference.dart`)
// — so by the time a transcript draws it, it is just characters in a
// paragraph. Rewriting it to inline code before parsing was the previous
// answer, and it cost the two things that make a reference a reference: the
// accent that says "this is a file", and the click that opens it. An inline
// plugin claims the characters at parse time instead, so the chip is a real
// node with its own builder and the surrounding sentence still wraps around it.
//
// **Why the name, not the raw token.** The composer paints the whole
// `@[file:…]` because the person is editing those characters and the caret has
// to land between them. Nobody edits a sent message's text, and bracket syntax
// in a transcript reads as markup that leaked. So the chip carries the name and
// the accent carries the meaning.
//
// A reference whose attachment is not on the message resolves to nothing —
// somebody typed the token by hand, or it predates the metadata. It renders as
// plain words rather than as an accent chip, for the same reason the composer
// leaves an unresolved reference unpainted: an affordance that opens nothing is
// worse than no affordance.
library;

import 'dart:async';

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/attachments/open_attachment_preview.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AST node type of a parsed file reference. The key its builder registers
/// under, so the two cannot drift.
const String kFileRefNodeType = 'file_ref';

/// One `@[file:<name>]` reference, parsed out of a message body.
final class CcFileRefInline extends CcCustomInline {
  /// Creates a [CcFileRefInline] for [name].
  const CcFileRefInline(this.name);

  /// The display name between the braces — the identity the message's
  /// attachments are keyed by.
  final String name;

  @override
  String get nodeType => kFileRefNodeType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CcFileRefInline && name == other.name;

  @override
  int get hashCode => Object.hash(nodeType, name);
}

/// Claims `@[file:<name>]` at parse time.
///
/// Dispatched on `@`, so it costs nothing on text that has none, and it falls
/// through on any other `@…` — an email address, an agent mention, a version
/// pin — because the pattern is bracket-delimited and anchored at the index.
final class FileRefInlinePlugin extends CcInlinePlugin {
  /// Creates a [FileRefInlinePlugin].
  const FileRefInlinePlugin();

  @override
  String get id => 'cc_file_ref';

  @override
  String get triggerCharacters => '@';

  @override
  bool canParse(String text, int index) => text.startsWith('@[file:', index);

  @override
  CcInlineParseResult? parse(String text, int startIndex) {
    final match = fileRefPattern.matchAsPrefix(text, startIndex);
    if (match == null) {
      return null;
    }
    return CcInlineParseResult(
      CcFileRefInline(match.group(1)!),
      match.end - startIndex,
    );
  }
}

/// Draws a parsed reference as the composer's pill: accent on a soft accent
/// wash, clickable when the message actually carried the file.
final class FileRefChipBuilder extends CcNodeBuilder {
  /// Creates a [FileRefChipBuilder].
  const FileRefChipBuilder();

  /// The chip reads as part of the sentence, so it sits on the paragraph's
  /// baseline rather than floating on the line box's vertical centre.
  @override
  PlaceholderAlignment get placeholderAlignment =>
      PlaceholderAlignment.baseline;

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      _FileRefChip(
        name: (node as CcFileRefInline).name,
        textStyle: style.paragraph ?? const TextStyle(),
      );
}

/// Resolves a reference name to the attachment behind it, for every chip drawn
/// beneath it.
///
/// An [InheritedWidget] rather than a builder argument because the resolution
/// is per MESSAGE while the builder is a process-global const: the registry is
/// shared by every transcript on screen, and only the bubble knows which
/// attachments its own message carried.
class FileRefScope extends InheritedWidget {
  /// Creates a [FileRefScope] over [attachments], keyed by reference name.
  const FileRefScope({
    super.key,
    required this.attachments,
    required super.child,
  });

  /// Reference name → the attachment it points at.
  final Map<String, ComposerAttachment> attachments;

  /// The attachment [name] refers to in the nearest enclosing scope, or null
  /// when there is no scope or the message carried no such file.
  static ComposerAttachment? attachmentOf(BuildContext context, String name) =>
      context
          .dependOnInheritedWidgetOfExactType<FileRefScope>()
          ?.attachments[name];

  /// Compared field by field, not by map equality: [ComposerAttachment] has no
  /// value semantics, so the bubble's freshly-built map would look different on
  /// every frame and notify every chip under it. What a chip actually renders
  /// from is the identity and the URL its bytes resolve to.
  @override
  bool updateShouldNotify(FileRefScope oldWidget) {
    final previous = oldWidget.attachments;
    if (previous.length != attachments.length) {
      return true;
    }
    for (final entry in attachments.entries) {
      final was = previous[entry.key];
      if (was == null ||
          was.id != entry.value.id ||
          was.remoteUrl != entry.value.remoteUrl) {
        return true;
      }
    }
    return false;
  }
}

class _FileRefChip extends ConsumerWidget {
  const _FileRefChip({required this.name, required this.textStyle});

  final String name;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final attachment = FileRefScope.attachmentOf(context, name);
    if (attachment == null) {
      return Text(
        name,
        style: textStyle.copyWith(decoration: TextDecoration.none),
      );
    }
    final chip = Container(
      padding: kInlineCodeChipPadding,
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(kInlineCodeChipRadius),
      ),
      child: Text(
        name,
        style: textStyle.copyWith(
          color: tokens.accent,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // The same gesture as the attachment card above it and as the
        // composer's own pill: one thing to click, one place it opens.
        onTap: () =>
            unawaited(openAttachmentPreview(context, ref, attachment)),
        child: Semantics(button: true, label: name, child: chip),
      ),
    );
  }
}
