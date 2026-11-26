import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_fences.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A list item's line: its indent, then a bullet or an ordered marker.
final RegExp _listMarker = RegExp(r'^([ \t]*)([-*+]|\d+[.)])(?:[ \t]|$)');

/// Indents (Tab) or outdents (Shift+Tab) the lines the selection touches,
/// keeping the indentation the text already uses: a tab where the block is
/// tab-indented, otherwise spaces in the block's own step.
///
/// The key is the editor's only where indentation means something, so Tab
/// keeps moving focus everywhere else:
///
/// - inside a fenced code block: a bare caret inserts one step at the caret,
///   a selection indents its lines;
/// - on a list item: the item nests under (or climbs out of) the item above;
/// - with a selection spanning several lines.
///
/// Returns null when the key is not the editor's — a caret in prose, or an
/// outdent with nothing to remove — so the caller lets it through.
TextEditingValue? indentMarkdownLines(
  TextEditingValue value, {
  required bool outdent,
}) {
  final selection = value.selection;
  final text = value.text;
  if (!selection.isValid ||
      (value.composing.isValid && !value.composing.isCollapsed)) {
    return null;
  }
  final start = selection.start.clamp(0, text.length);
  final end = selection.end.clamp(start, text.length);
  final collapsed = start == end;
  final firstLineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  // A selection that ends at a line's start does not take that line with it.
  final lastOffset = !collapsed && text[end - 1] == '\n' ? end - 1 : end;
  final newline = text.indexOf('\n', lastOffset);
  final lastLineEnd = newline == -1 ? text.length : newline;
  final lines = text.substring(firstLineStart, lastLineEnd).split('\n');

  final fence = markdownFenceBodyAt(text, start);
  final firstMarker = fence == null
      ? _listMarker.firstMatch(
          lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => ''),
        )
      : null;
  if (fence == null && lines.length == 1 && firstMarker == null) {
    return null;
  }
  final style = _detectIndent(
    fence == null ? text : text.substring(fence.start, fence.end),
  );

  if (!outdent && collapsed && fence != null) {
    final column = start - firstLineStart;
    final insert = style.tabs
        ? '\t'
        : ' ' * (style.width - column % style.width);
    return TextEditingValue(
      text: text.replaceRange(start, start, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
  }

  final width = firstMarker == null || firstMarker.group(1)!.contains('\t')
      ? style.width
      : _listStep(text, firstLineStart, firstMarker, outdent: outdent);

  final buffer = StringBuffer(text.substring(0, firstLineStart));
  var newStart = start;
  var newEnd = end;
  var changed = false;
  var lineStart = firstLineStart;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (i > 0) {
      buffer.write('\n');
    }
    if (outdent) {
      final removed = line.startsWith('\t')
          ? 1
          : math.min(_leadingSpaces(line), width);
      buffer.write(line.substring(removed));
      if (removed > 0) {
        changed = true;
        newStart -= (start - lineStart).clamp(0, removed);
        newEnd -= (end - lineStart).clamp(0, removed);
      }
    } else if (line.trim().isEmpty && lines.length > 1) {
      buffer.write(line);
    } else {
      final added = style.tabs || line.startsWith('\t') ? '\t' : ' ' * width;
      buffer
        ..write(added)
        ..write(line);
      changed = true;
      // The selection's start stays on the line's first column, so the new
      // indent is inside it; a bare caret moves with its text.
      if (start > lineStart || (collapsed && start == lineStart)) {
        newStart += added.length;
      }
      if (end >= lineStart) {
        newEnd += added.length;
      }
    }
    lineStart += line.length + 1;
  }
  if (!changed) {
    return null;
  }
  buffer.write(text.substring(lastLineEnd));
  final reversed = selection.baseOffset > selection.extentOffset;
  return TextEditingValue(
    text: buffer.toString(),
    selection: TextSelection(
      baseOffset: reversed ? newEnd : newStart,
      extentOffset: reversed ? newStart : newEnd,
    ),
  );
}

int _leadingSpaces(String line) {
  var count = 0;
  while (count < line.length && line.codeUnitAt(count) == 0x20) {
    count++;
  }
  return count;
}

/// The indentation [scope] already uses: tabs when more of its lines start
/// with one than with a space, and the step its space-indented lines share
/// (two when they share none, or nothing is indented yet).
({bool tabs, int width}) _detectIndent(String scope) {
  var tabLines = 0;
  var spaceLines = 0;
  var step = 0;
  for (final line in scope.split('\n')) {
    if (line.startsWith('\t')) {
      tabLines++;
      continue;
    }
    final spaces = _leadingSpaces(line);
    if (spaces == 0 || spaces == line.length) {
      continue;
    }
    spaceLines++;
    step = step.gcd(spaces);
  }
  return (
    tabs: tabLines > spaceLines,
    width: step >= 2 && step <= 8 ? step : 2,
  );
}

/// How far a list item at [lineStart] moves so it lands where markdown reads
/// it as nested: indenting aligns it with the content of the item above,
/// outdenting with the marker of the nearest shallower item. Falls back to the
/// item's own marker width when no such item is above.
int _listStep(
  String text,
  int lineStart,
  RegExpMatch marker, {
  required bool outdent,
}) {
  final current = marker.group(1)!.length;
  final fallback = marker.group(2)!.length + 1;
  var end = lineStart - 1;
  for (var scanned = 0; end > 0 && scanned < 200; scanned++) {
    final start = text.lastIndexOf('\n', end - 1) + 1;
    final above = _listMarker.firstMatch(text.substring(start, end));
    end = start - 1;
    if (above == null) {
      continue;
    }
    final indent = above.group(1)!;
    if (indent.contains('\t')) {
      break;
    }
    if (outdent && indent.length < current) {
      return current - indent.length;
    }
    if (!outdent && indent.length <= current) {
      final content = indent.length + above.group(2)!.length + 1;
      return content > current ? content - current : fallback;
    }
  }
  return fallback;
}

/// Routes Tab and Shift+Tab to [indentMarkdownLines] for one field.
///
/// Escape releases the key: the Tab that follows it moves focus even where it
/// would indent, so the field is never a keyboard trap (WCAG 2.1.2).
///
/// [onFirstCapture] runs the first time this handler takes a Tab, so the host
/// can tell the person how to leave ([announceMarkdownIndentKeys]).
class MarkdownIndentKeyHandler {
  /// Creates a [MarkdownIndentKeyHandler].
  MarkdownIndentKeyHandler({this.onFirstCapture});

  /// Called once, on the first Tab this handler keeps for indentation.
  final VoidCallback? onFirstCapture;

  bool _released = false;
  bool _announced = false;

  static final Set<LogicalKeyboardKey> _modifiers = {
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.capsLock,
  };

  /// Applies the key to [controller]; [KeyEventResult.ignored] when it is not
  /// an indentation key here.
  KeyEventResult handle(TextEditingController controller, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _released = true;
      return KeyEventResult.ignored;
    }
    if (key != LogicalKeyboardKey.tab) {
      if (!_modifiers.contains(key)) {
        _released = false;
      }
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (_released) {
      _released = false;
      return KeyEventResult.ignored;
    }
    final next = indentMarkdownLines(
      controller.value,
      outdent: keyboard.isShiftPressed,
    );
    if (next == null) {
      return KeyEventResult.ignored;
    }
    controller.value = next;
    if (!_announced) {
      _announced = true;
      onFirstCapture?.call();
    }
    return KeyEventResult.handled;
  }
}

bool _hintShown = false;

/// Forgets that the hint was shown, so each test starts like a fresh run.
@visibleForTesting
void resetMarkdownIndentHint() => _hintShown = false;

/// Tells the person that Tab indents here and that Escape, then Tab moves
/// focus on (WCAG 2.1.2 asks that the way out be stated).
///
/// The first capture of a run shows it as a toast, which is a live region, so
/// it is both seen and read out. Later fields only announce it to assistive
/// technology: a toast on every edit would be noise for someone who knows.
void announceMarkdownIndentKeys(BuildContext context) {
  final message = AppLocalizations.of(context).markdownTabIndentHint;
  final toasts = _hintShown ? null : CcToastScope.maybeOf(context);
  if (toasts != null) {
    _hintShown = true;
    toasts.show(message, duration: const Duration(seconds: 8));
    return;
  }
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

/// Gives the markdown field under it Tab / Shift+Tab indentation. Sits above
/// the field, so a key the field itself takes (a suggestion pick) never
/// reaches it.
class MarkdownIndentKeys extends StatefulWidget {
  /// Creates a [MarkdownIndentKeys].
  const MarkdownIndentKeys({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The controller of the field in [child].
  final TextEditingController controller;

  /// The field.
  final Widget child;

  @override
  State<MarkdownIndentKeys> createState() => _MarkdownIndentKeysState();
}

class _MarkdownIndentKeysState extends State<MarkdownIndentKeys> {
  late final MarkdownIndentKeyHandler _keys = MarkdownIndentKeyHandler(
    onFirstCapture: () {
      if (mounted) {
        announceMarkdownIndentKeys(context);
      }
    },
  );

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) => _keys.handle(widget.controller, event),
    child: widget.child,
  );
}
