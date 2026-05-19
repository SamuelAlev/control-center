import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/open_attachment_preview.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_registry.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/attachments/composer_drop_target.dart';
import 'package:control_center/shared/widgets/composer/composer_history.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/demo_file_picker.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_popup.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_trigger.dart';
import 'package:control_center/shared/widgets/composer/voice/voice_button.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Horizontal inset the composer box keeps from the edges of the column it is
/// placed in.
///
/// Exposed so status lines stacked directly above it (space provisioning, the
/// typing indicator) can start their content on the composer's own left border
/// instead of guessing the inset — they used to hug the pane edge, which read as
/// unrelated to the composer below them.
const double composerHorizontalMargin = 12;

/// The composer box's own outer margin.
///
/// Shared with the drop target so the "drop to attach" ring is drawn on the
/// composer's border rather than in the gutter beside it.
const EdgeInsets _composerMargin = EdgeInsets.symmetric(
  horizontal: composerHorizontalMargin,
  vertical: 8,
);

/// A keyboard-first chat composer with multi-source `@` mentions, file
/// attachments and (scaffolded) voice dictation.
///
/// Usage:
/// ```dart
/// Composer(
///   hint: 'Message #general… (@ to mention, / for commands)',
///   sources: [
///     AgentMentionSource(agents),
///     SpaceMentionSource(spaces),
///     FileMentionSource(search: (q) => searchWorkspaceFilesOverRpc(q)),
///     ScratchpadMentionSource(scratchpad: pad, workspaceId: id),
///     SlashCommandSource(commands),
///   ],
///   onSubmit: (submission) async {
///     await sendUseCase.execute(content: submission.text, ...);
///   },
/// )
/// ```
///
/// The composer keeps the text field focused while the mention popup is
/// open — arrow keys/Enter/Tab/Esc are intercepted by [MentionPopup] via
/// [HardwareKeyboard]; typing and left/right cursor keys reach the field
/// normally. This is what made the previous inline-listview implementation
/// feel broken.
class Composer extends ConsumerStatefulWidget {
  /// Creates a new [Composer].
  const Composer({
    super.key,
    required this.sources,
    required this.onSubmit,
    this.hint = 'Type a message…',
    this.enableFilePicker = true,
    this.controller,
    this.maxLines = 6,
    this.minLines = 1,
    this.trailing,
    this.leading,
    this.autofocus = false,
    this.isBusy = false,
    this.onStop,
    this.onPlanToggle,
    this.history,
    this.historyKey,
    this.attachedTop = false,
  });

  /// Pluggable mention sources, queried in order; results are grouped under
  /// each source's section header.
  final List<MentionSource> sources;

  /// Called when the user submits (Enter on empty popup, or send button).
  final Future<void> Function(ComposerSubmission) onSubmit;

  /// Placeholder for the input.
  final String hint;

  /// When true, shows the attachment picker.
  final bool enableFilePicker;

  /// Optional external text controller. The composer creates its own when
  /// this is null.
  final TextEditingController? controller;

  /// Maximum number of lines for the input field.
  final int maxLines;

  /// Minimum number of lines for the input field.
  final int minLines;

  /// Optional widgets rendered in the bottom toolbar, left/right of the
  /// built-in actions (useful for model picker, reasoning chip, etc.).
  final Widget? leading;

  /// Optional widget rendered in the bottom toolbar after the built-in actions.
  final Widget? trailing;

  /// When true, the text field requests focus after the first frame.
  final bool autofocus;

  /// When true, an agent is currently working in this conversation. While busy
  /// and the input is empty, the send button becomes a stop button (calls
  /// [onStop]); once the user types, it reverts to send (the host decides
  /// whether to dispatch or queue the message).
  final bool isBusy;

  /// Called when the user presses the stop button (shown only while [isBusy]
  /// is true and the input is empty). When null, no stop affordance is shown.
  final Future<void> Function()? onStop;

  /// When non-null, Shift+Tab invokes this instead of moving focus (PRD 17 §8
  /// — Cursor-style plan-mode entry). Only the messaging space composer opts
  /// in; other composers keep Shift+Tab as focus traversal.
  ///
  /// The callback flips the *conversation mode*; it deliberately does not
  /// touch the draft. An earlier version inserted a literal `/plan ` prefix,
  /// which did nothing at all: the server layers the prompt into
  /// `<context>…</context>\n\n<text>` before slash parsing, so the prefix
  /// never matched. `spaces.mode` is the single authority every enforcement
  /// layer (tool surface, guard preset, sandbox, prompt) already reads.
  final VoidCallback? onPlanToggle;

  /// Previously sent texts, oldest first, offered for terminal-style recall:
  /// ArrowUp walks backwards through them, ArrowDown forwards, and stepping
  /// past the newest restores the draft being composed before the first
  /// ArrowUp. Null (or empty) disables the feature — ArrowUp/ArrowDown keep
  /// their plain caret meaning.
  ///
  /// The list is read live at keypress time, never copied into state, so a
  /// host whose history updates mid-browse (a message landing in the
  /// conversation) is seen without any sync.
  final List<String>? history;

  /// What the entries in [history] belong to (typically the conversation id).
  /// When it changes between builds the browsing position resets, so an index
  /// picked in one conversation can never surface a prompt from another.
  final String? historyKey;

  /// When true, the box drops its top margin so whatever is stacked directly
  /// above it sits ON its top border instead of floating over a gap.
  ///
  /// The steering strip is the one caller: a queued card is the message the
  /// composer is about to send, so the two read as one surface — the card's
  /// box has no bottom border and this box's top border is the hairline
  /// between them. Off by default; a composer with nothing above it keeps its
  /// full margin.
  final bool attachedTop;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  late TextEditingController _controller;
  late FocusNode _focus;
  final OverlayPortalController _popupCtrl = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final List<ComposerAttachment> _attachments = [];
  // Structured `#` entity mentions (ticket/pr/meeting) captured when the user
  // picks them from the popup, so their payload survives — the regex re-parse
  // on submit can't recover the entity id. Pruned on submit to those whose
  // inserted token still appears in the text.
  final List<({ResolvedMention mention, String token})> _picked = [];

  MentionQuery? _activeQuery;
  bool _sending = false;
  bool _composerFocused = false;
  bool _isEmpty = true;

  // Terminal-style prompt recall (see [Composer.history]); the browsing
  // state machine lives in [ComposerHistory], fed at keypress time.
  final ComposerHistory _history = ComposerHistory();

  // Voice-dictation pending span (PRD 25 §2). While a session is live, the
  // dictated text occupies a tracked range [_dictationBase, _dictationBase +
  // _dictationLength) that is replaced ATOMICALLY on each partial — never a
  // whole-field re-parse. Null base = no live dictation.
  int? _dictationBase;
  int _dictationLength = 0;
  // True only while force-finalizing on send, so a late partial forwarded by
  // the VoiceButton during the stop/drain can't re-open a committed span.
  bool _dictationFinalizing = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ComposerTextController();
    _bindRefStyling();
    _isEmpty = _controller.text.trim().isEmpty;
    _focus = FocusNode();
    _focus.addListener(_onFocusChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focus.requestFocus();
        }
      });
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant Composer old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      _controller.removeListener(_onControllerChanged);
      if (old.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? ComposerTextController();
      _bindRefStyling();
      _controller.addListener(_onControllerChanged);
    }
    // A new scope means the indices name different prompts: drop the browsing
    // position rather than clamping it against a list it was never picked
    // from. The recalled text itself stays in the field — the draft is the
    // user's property, wherever it came from.
    if (widget.historyKey != old.historyKey) {
      _history.reset();
    }
  }

  /// Teaches the controller which `@[file:…]` names this composer can actually
  /// resolve, so a hand-typed one stays plain text.
  ///
  /// A caller may pass a plain [TextEditingController] (the composer works
  /// perfectly well with one); it simply gets no pill styling.
  void _bindRefStyling() {
    final controller = _controller;
    if (controller is ComposerTextController) {
      controller.isResolved = (name) =>
          _attachments.any((a) => a.refName == name);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final text = _controller.text;
    final caret = _controller.selection.baseOffset;
    final query = detectMentionQuery(text, caret);
    final isEmpty = text.trim().isEmpty;
    // Drop structured picks whose inserted token has been edited out, so a
    // deleted `#`-reference is never re-emitted on submit.
    if (_picked.isNotEmpty) {
      _picked.removeWhere((p) => !_tokenSurvives(text, p.token));
    }
    final droppedRefs = _pruneDeletedRefs(text);
    if (query != _activeQuery || isEmpty != _isEmpty || droppedRefs) {
      setState(() {
        _activeQuery = query;
        _isEmpty = isEmpty;
      });
    }
    if (query != null && !_popupCtrl.isShowing) {
      _popupCtrl.show();
    } else if (query == null && _popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    _maybeOpenTappedRef(text);
  }

  /// Removes attachments whose inline reference has been edited out of the
  /// text, and reports whether anything went.
  ///
  /// Deleting `@[file:diagram.png]` is how you un-attach something you
  /// referenced in a sentence — the token IS the attachment's presence in the
  /// message, so leaving the file on the submission after the words are gone
  /// would send a file the person removed. Attachments with no reference (a
  /// scratchpad, or a caller that inserts no token) are never pruned.
  bool _pruneDeletedRefs(String text) {
    if (_attachments.isEmpty) {
      return false;
    }
    final before = _attachments.length;
    _attachments.removeWhere((a) {
      final name = a.refName;
      return name != null && !fileRefSurvives(text, fileRefToken(name));
    });
    return _attachments.length != before;
  }

  // A click INSIDE a reference opens its preview. Detected from the caret
  // landing there rather than from a gesture, because the caret is what the
  // field's own tap handler moves and there is no public seam for hit-testing
  // a character range from outside a `RenderEditable`. The pointer flag is
  // what separates a click from an arrow key walking through the same token —
  // without it, cursoring past a reference would open a tab.
  bool _pointerTapPending = false;

  void _onPointerUp(PointerUpEvent event) {
    _pointerTapPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pointerTapPending = false;
    });
  }

  void _maybeOpenTappedRef(String text) {
    if (!_pointerTapPending) {
      return;
    }
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      return;
    }
    final offset = selection.baseOffset;
    for (final match in findFileRefs(text)) {
      if (!match.containsOffset(offset)) {
        continue;
      }
      final attachment = _attachmentForRef(match.name);
      if (attachment == null) {
        return;
      }
      _pointerTapPending = false;
      unawaited(openAttachmentPreview(context, ref, attachment));
      return;
    }
  }

  ComposerAttachment? _attachmentForRef(String name) {
    for (final attachment in _attachments) {
      if (attachment.refName == name) {
        return attachment;
      }
    }
    return null;
  }

  /// Adds [incoming] to the composer and writes one inline reference per item
  /// at the caret.
  ///
  /// Both halves happen together on purpose: the chip says the file is coming
  /// along, and the reference says WHERE in the sentence it belongs. Attaching
  /// three screenshots and writing "the second one is wrong" is a message
  /// nobody can act on; "⟦shot-2.png⟧ is wrong" is.
  ///
  /// De-duplicated by id, so dropping the same file twice is one attachment —
  /// unlike a pasted picture, which carries a fresh id each time because two
  /// pastes of one screenshot are two deliberate acts.
  void _attach(List<ComposerAttachment> incoming) {
    if (incoming.isEmpty) {
      return;
    }
    final taken = {
      for (final a in _attachments)
        if (a.refName != null) a.refName!,
    };
    final added = <ComposerAttachment>[];
    final tokens = <String>[];
    for (final attachment in incoming) {
      if (_attachments.any((a) => a.id == attachment.id)) {
        continue;
      }
      final refName = uniqueFileRefName(
        attachment.path ?? attachment.label,
        taken,
      );
      taken.add(refName);
      final resolved = attachment.copyWith(
        refName: refName,
        // A desktop drop usually reports no type at all, so infer it from the
        // name before anything downstream has to guess twice.
        mimeType: attachment.mimeType ?? mediaTypeForFileName(attachment.label),
      );
      added.add(resolved);
      tokens.add(fileRefToken(refName));
    }
    if (added.isEmpty) {
      return;
    }
    _attachments.addAll(added);
    ref.read(attachmentRegistryProvider.notifier).register(added);
    _insertAtCaret(tokens.join(' '));
    setState(() {});
  }

  /// Splices [snippet] in at the caret, space-separated from its neighbours.
  ///
  /// One edit for the whole insertion (not one per file): each
  /// `TextEditingValue` write is an undo step, and a four-file drop should be
  /// one press of ⌘Z, not four.
  void _insertAtCaret(String snippet) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length)
        : text.length;
    final end = selection.isValid
        ? selection.end.clamp(start, text.length)
        : text.length;
    final needsLeadingSpace =
        start > 0 && !_isWhitespace(text.codeUnitAt(start - 1));
    final insertion = '${needsLeadingSpace ? ' ' : ''}$snippet ';
    _controller.value = TextEditingValue(
      text: text.substring(0, start) + insertion + text.substring(end),
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
  }

  /// Accepts everything a drop produced.
  Future<void> _handleDrop(ComposerDrop drop) async {
    final text = drop.text;
    // Text-only drops (a selection dragged out of a browser or an editor) are
    // inserted verbatim — a drop is a paste with a destination.
    if (drop.attachments.isEmpty && text != null && text.isNotEmpty) {
      _insertAtCaret(text.trim());
      return;
    }
    _attach(drop.attachments);
  }

  void _onFocusChanged() {
    if (_composerFocused != _focus.hasFocus) {
      setState(() => _composerFocused = _focus.hasFocus);
    }
  }

  void _selectSuggestion(MentionSuggestion suggestion) {
    final q = _activeQuery;
    if (q == null) {
      return;
    }
    // A picked FILE becomes the same `@[file:…]` reference a drop or the `[+]`
    // picker produces, rather than the raw relative path the source proposes.
    // One vocabulary for "this file, here in the sentence": the three ways of
    // naming a file used to insert three different things, and only one of
    // them was clickable.
    final path = suggestion.payload?['path'] as String?;
    final isDirectory = suggestion.payload?['isDirectory'] as bool? ?? false;
    final isFileRef = suggestion.kind == 'file' && path != null && !isDirectory;
    if (isFileRef) {
      _replaceQuery(q, '');
      setState(() => _activeQuery = null);
      if (_popupCtrl.isShowing) {
        _popupCtrl.hide();
      }
      final name = p.basename(path);
      _attach([
        ComposerAttachment(
          id: 'file:$path',
          kind: 'file',
          label: name,
          path: path,
          mimeType: mediaTypeForFileName(name),
          payload: suggestion.payload,
        ),
      ]);
      return;
    }
    final text = _controller.text;
    final before = text.substring(0, q.start);
    final after = text.substring(q.end);
    final newText = '$before${suggestion.replacement}$after';
    final cursor = (before + suggestion.replacement).length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
    setState(() => _activeQuery = null);
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    // A DIRECTORY falls through with the plain-path insertion above: it is a
    // place to look, not a file to preview or upload.
    if (suggestion.kind == 'scratchpad') {
      final scratchpadId = suggestion.payload?['scratchpadId'] as String?;
      if (scratchpadId != null) {
        _attachments.add(
          ComposerAttachment(
            id: 'scratchpad:$scratchpadId',
            kind: 'scratchpad',
            label: 'notes',
            payload: suggestion.payload,
          ),
        );
        setState(() {});
      }
    } else if (suggestion.kind == 'ticket' ||
        suggestion.kind == 'pr' ||
        suggestion.kind == 'meeting') {
      // `#` entity references: keep the structured pick so its payload (the
      // real entity id) reaches the submission; the inline token alone can't be
      // resolved back to an id.
      _picked.add((
        mention: ResolvedMention(
          kind: suggestion.kind,
          label: suggestion.label,
          start: q.start,
          end: cursor,
          payload: suggestion.payload,
        ),
        token: suggestion.replacement.trim(),
      ));
    }
  }

  /// Replaces the live mention query (`@part`) with [replacement], leaving the
  /// caret just after it.
  void _replaceQuery(MentionQuery query, String replacement) {
    final text = _controller.text;
    final start = query.start.clamp(0, text.length);
    final end = query.end.clamp(start, text.length);
    _controller.value = TextEditingValue(
      text: text.substring(0, start) + replacement + text.substring(end),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _dismissPopup() {
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    setState(() => _activeQuery = null);
  }

  /// Reads the host clipboard and, when it holds an image, attaches it.
  ///
  /// Runs alongside the field's own text paste rather than replacing it: a
  /// clipboard can hold both (copying from a browser often yields an image AND
  /// its alt text), and the useful outcome is the picture plus whatever text
  /// the field pasted on its own.
  Future<void> _tryPasteImage() async {
    final snapshot = await readHostClipboard();
    final bytes = snapshot.imageBytes;
    if (bytes == null || bytes.isEmpty || !mounted) {
      return;
    }
    final mimeType = snapshot.imageMediaType ?? 'image/png';
    final extension = mimeType.split('/').last;
    _attach([
      ComposerAttachment(
        // Content-independent id: two pastes of the same picture are two
        // deliberate attachments, and de-duplicating them would silently
        // swallow the second keystroke.
        id: 'paste:${DateTime.now().microsecondsSinceEpoch}',
        kind: 'image',
        label: 'pasted.$extension',
        bytes: bytes,
        mimeType: mimeType,
        sizeBytes: bytes.length,
      ),
    ]);
  }

  Future<void> _pickFiles() async {
    // The demo has no real files to offer and writes nothing to the host:
    // a mock picker hands back the demo world's fictional documents, and the
    // send path records them by name without ever moving bytes.
    if (ref.read(isDemoServerProvider)) {
      final picked = await showDemoFilePicker(context);
      if (picked.isEmpty || !mounted) {
        return;
      }
      _attach([
        for (final file in picked)
          ComposerAttachment(
            id: 'demo:${file.name}',
            kind: file.imageBytes != null ? 'image' : 'file',
            label: file.name,
            bytes: file.imageBytes,
            mimeType: file.mimeType,
            sizeBytes: file.sizeBytes,
          ),
      ]);
      return;
    }
    final files = await openFiles();
    if (files.isEmpty) {
      return;
    }
    // Bytes are read only for pictures, and only so they can be uploaded with
    // the message. Everything else travels as a path the agent opens itself —
    // reading a video into memory to put a chip on a toolbar would be absurd.
    final attachments = <ComposerAttachment>[];
    for (final file in files) {
      final name = p.basename(file.path);
      final mimeType = file.mimeType ?? mediaTypeForFileName(name);
      final isImage = (mimeType ?? '').startsWith('image/');
      final bytes = isImage ? await file.readAsBytes() : null;
      if (bytes != null && bytes.length > kMaxDroppedImageBytes) {
        // Over the ceiling the blob store enforces anyway: attach it as a
        // path rather than carrying bytes that would be refused on send.
        attachments.add(
          ComposerAttachment(
            id: 'file:${file.path}',
            kind: 'file',
            label: name,
            path: file.path,
            mimeType: mimeType,
            sizeBytes: bytes.length,
          ),
        );
        continue;
      }
      attachments.add(
        ComposerAttachment(
          id: 'file:${file.path}',
          kind: isImage ? 'image' : 'file',
          label: name,
          path: file.path,
          bytes: bytes,
          mimeType: mimeType,
          sizeBytes: bytes?.length,
        ),
      );
    }
    if (mounted) {
      _attach(attachments);
    }
  }

  /// Removes an attachment from the chip strip, taking its inline reference
  /// with it.
  ///
  /// Both directions are wired (deleting the token drops the attachment, in
  /// [_pruneDeletedRefs]) because they are one fact stated twice: leaving an
  /// orphan `@[file:…]` behind would read as an attachment that is still
  /// coming along.
  void _removeAttachment(ComposerAttachment a) {
    _attachments.removeWhere((x) => x.id == a.id);
    ref.read(attachmentRegistryProvider.notifier).unregister(a.id);
    final refName = a.refName;
    if (refName != null) {
      _removeToken(fileRefToken(refName));
    }
    setState(() {});
  }

  /// Deletes [token] from the draft, plus one adjacent space so removing a
  /// reference mid-sentence does not leave a double gap behind.
  void _removeToken(String token) {
    final text = _controller.text;
    final at = text.indexOf(token);
    if (at < 0) {
      return;
    }
    var end = at + token.length;
    if (end < text.length && _isWhitespace(text.codeUnitAt(end))) {
      end++;
    }
    final caret = _controller.selection.baseOffset;
    final next = text.substring(0, at) + text.substring(end);
    final removed = end - at;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: (caret > end ? caret - removed : at).clamp(0, next.length),
      ),
    );
  }

  Future<void> _submit() async {
    if (_sending) {
      return;
    }
    // Nothing to send and no live dictation to flush → no-op (so a stray Enter
    // on an empty composer doesn't flash the spinner).
    if (_dictationBase == null &&
        _controller.text.trim().isEmpty &&
        _attachments.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      // If a dictation session is live, force best-effort finalization: stop
      // the session, take the last (fully-drained) text and splice it into the
      // pending span — never drop the span, never submit styled-pending markup.
      if (_dictationBase != null) {
        _dictationFinalizing = true;
        final finalText = await ref
            .read(dictationControllerProvider.notifier)
            .stopAndDrain();
        _spliceDictation(finalText);
        _resetDictationSpan();
      }
      final text = _controller.text;
      final mentions = <ResolvedMention>[
        ..._extractResolvedMentions(text),
        // Structured `#` entity picks, kept only if their inserted token still
        // survives in the text (so deleting the token drops the reference).
        for (final p in _picked)
          if (_tokenSurvives(text, p.token)) p.mention,
      ];
      final submission = ComposerSubmission(
        text: text,
        mentions: mentions,
        attachments: List.unmodifiable(_attachments),
      );
      if (submission.isEmpty) {
        return;
      }
      // Clear immediately so the user sees instant feedback and the
      // TextField cannot re-insert a newline during the async gap.
      _controller.clear();
      _attachments.clear();
      _picked.clear();
      _resetDictationSpan();
      // A sent prompt is history now, not a browsing position: the next ↑
      // starts from the newest entry again.
      _history.reset();
      await widget.onSubmit(submission);
    } finally {
      _dictationFinalizing = false;
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// Applies a dictation [text] update from the mic button as an ATOMIC
  /// pending-span replacement — the whole span is spliced in one edit, never a
  /// whole-field re-parse. [isFinal] commits the span (clears the tracking).
  /// Dropped while force-finalizing on send, so a late partial can't re-open a
  /// committed span.
  void _applyDictationPartial(String text, {required bool isFinal}) {
    if (_dictationFinalizing) {
      return;
    }
    _spliceDictation(text);
    if (isFinal) {
      _resetDictationSpan();
    }
  }

  /// Replaces the tracked dictation span with [text] (separated from preceding
  /// text by a single space when needed), anchoring at the caret on first use.
  void _spliceDictation(String text) {
    final full = _controller.text;
    if (_dictationBase == null) {
      final sel = _controller.selection;
      final caret = sel.isValid ? sel.baseOffset : full.length;
      _dictationBase = caret.clamp(0, full.length);
      _dictationLength = 0;
    }
    final base = _dictationBase!.clamp(0, full.length);
    final end = (base + _dictationLength).clamp(base, full.length);
    final trimmed = text.trim();
    final needsSep =
        trimmed.isNotEmpty &&
        base > 0 &&
        !_isWhitespace(full.codeUnitAt(base - 1));
    final content = trimmed.isEmpty ? '' : (needsSep ? ' $trimmed' : trimmed);
    final newText = full.substring(0, base) + content + full.substring(end);
    _dictationBase = base;
    _dictationLength = content.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: base + content.length),
    );
  }

  void _resetDictationSpan() {
    _dictationBase = null;
    _dictationLength = 0;
  }

  static bool _isWhitespace(int codeUnit) =>
      codeUnit == 0x20 || // space
      codeUnit == 0x09 || // tab
      codeUnit == 0x0A || // LF
      codeUnit == 0x0D; // CR

  // A picked entity reference survives only while its inserted token is still
  // present as a whole, whitespace-delimited word. A raw substring test would
  // let `#42` linger inside a later `#420`, persisting a reference the user
  // removed.
  static bool _tokenSurvives(String text, String token) {
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word == token) {
        return true;
      }
    }
    return false;
  }

  /// Re-parse the text to surface structural mentions to the caller. Mentions
  /// are detected by trigger char + boundary; we don't store separate spans
  /// because edits would invalidate them.
  List<ResolvedMention> _extractResolvedMentions(String text) {
    final mentions = <ResolvedMention>[];
    final re = RegExp(r'(?<=^|\s)([@#/])(\w[\w\-./]*)');
    for (final m in re.allMatches(text)) {
      final trigger = m.group(1)!;
      final label = m.group(2)!;
      final kind = switch (trigger) {
        '@' => 'agent', // best-effort; file/scratchpad are also '@'
        '#' => 'space',
        '/' => 'slash',
        _ => 'unknown',
      };
      mentions.add(
        ResolvedMention(kind: kind, label: label, start: m.start, end: m.end),
      );
    }
    return mentions;
  }

  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    // Esc closes the popup if open; abandons a history recall, restoring the
    // parked draft; otherwise blurs the field.
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_popupCtrl.isShowing) {
        _dismissPopup();
        return KeyEventResult.handled;
      }
      final draft = _history.isBrowsing ? _history.abandon() : null;
      if (draft != null) {
        _showHistoryEntry(draft);
        return KeyEventResult.handled;
      }
      node.unfocus();
      return KeyEventResult.handled;
    }
    // Cmd/Ctrl+V with an IMAGE on the clipboard becomes an attachment rather
    // than a paste. Flutter's own paste only knows plain text, so without this
    // a screenshot on the clipboard pastes as nothing at all — the keystroke
    // looks broken. Text pastes are deliberately left to the field: this
    // returns `ignored` unless an image is actually found, so the normal path
    // is untouched (and stays synchronous, which the async read here is not).
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed)) {
      unawaited(_tryPasteImage());
      return KeyEventResult.ignored;
    }
    // Shift+Tab toggles plan mode (PRD 17 §8) on opted-in composers. Handled
    // before traversal so focus stays put. The draft is left alone — the
    // callback flips the conversation's mode.
    final planToggle = widget.onPlanToggle;
    if (planToggle != null &&
        event.logicalKey == LogicalKeyboardKey.tab &&
        HardwareKeyboard.instance.isShiftPressed &&
        !_popupCtrl.isShowing) {
      planToggle();
      return KeyEventResult.handled;
    }
    // Terminal-style ↑/↓ recall through the host-supplied history. Consuming
    // the key here is what keeps the caret from also moving: the framework's
    // default arrow→caret shortcuts live on DefaultTextEditingShortcuts at the
    // app root, which only sees an event every focus ancestor (this wrapper
    // among them) declined.
    final historyResult = _onHistoryKey(event.logicalKey);
    if (historyResult != KeyEventResult.ignored) {
      return historyResult;
    }
    // Shift+Enter inserts a newline when the popup is closed.
    // Plain Enter sends the message.
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        if (!_popupCtrl.isShowing) {
          final text = _controller.text;
          final sel = _controller.selection;
          final newText =
              '${text.substring(0, sel.start)}\n${text.substring(sel.end)}';
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: sel.start + 1),
          );
        }
        return KeyEventResult.handled;
      }
      if (!_popupCtrl.isShowing) {
        _submit();
        return KeyEventResult.handled;
      }
    }
    // When the popup is open, the global handler in MentionPopup eats
    // arrow/Enter/Tab — we just stay out of its way here.
    return KeyEventResult.ignored;
  }

  /// Handles ↑/↓ for terminal-style recall through the host-supplied
  /// history; returns [KeyEventResult.ignored] when the key belongs to the
  /// field. Consuming the key here is what keeps the caret from also moving:
  /// the framework's default arrow→caret shortcuts live on
  /// `DefaultTextEditingShortcuts` at the app root, which only sees an event
  /// every focus ancestor (this wrapper among them) declined.
  KeyEventResult _onHistoryKey(LogicalKeyboardKey key) {
    final history = widget.history;
    if (history == null ||
        history.isEmpty ||
        _popupCtrl.isShowing ||
        // A live dictation span is tracked by offsets into the current text;
        // swapping the whole field out from under it would corrupt the span.
        _dictationBase != null) {
      return KeyEventResult.ignored;
    }
    final isUp = key == LogicalKeyboardKey.arrowUp;
    final isDown = key == LogicalKeyboardKey.arrowDown;
    if (!isUp && !isDown) {
      return KeyEventResult.ignored;
    }
    // Modifier chords keep their text-editing meaning (Shift+↑ selects,
    // Alt/Cmd+↑ jumps to the document start) — recall is the bare key only.
    final kb = HardwareKeyboard.instance;
    if (kb.isShiftPressed ||
        kb.isAltPressed ||
        kb.isControlPressed ||
        kb.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final entry = isUp
        ? _history.up(
            history,
            text: _controller.text,
            selection: _controller.selection,
          )
        : _history.down(history);
    if (entry == null) {
      return KeyEventResult.ignored;
    }
    _showHistoryEntry(entry);
    return KeyEventResult.handled;
  }

  /// Shows one recalled entry, caret at the end — a recalled prompt is
  /// something you edit from the tip, the same as having just typed it.
  void _showHistoryEntry(String entry) {
    _controller.value = TextEditingValue(
      text: entry,
      selection: TextSelection.collapsed(offset: entry.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final controller = _controller;
    if (controller is ComposerTextController) {
      // Refreshed here rather than watched: the pill color has to follow a
      // theme switch, and reading tokens inside `buildTextSpan` would cost a
      // `dependOnInheritedWidget` lookup on every keystroke instead.
      controller.tokens = ds;
    }
    // Attached: the top margin belongs to whatever is stacked above (the
    // steering strip draws right down onto this box's top border).
    final margin = widget.attachedTop
        ? _composerMargin.copyWith(top: 0)
        : _composerMargin;
    return OverlayPortal(
      controller: _popupCtrl,
      overlayChildBuilder: (overlayContext) {
        final query = _activeQuery;
        if (query == null) {
          return const SizedBox.shrink();
        }
        // Position the popup so its bottom-left meets the composer's top-left,
        // i.e. floats just above the input. Wrapping in Positioned(width:…)
        // keeps the follower's bounding box tight to the popup so the
        // bottom-left anchor lines up with the popup's actual edge — not the
        // overlay's edge — which is what was previously breaking placement.
        return Positioned(
          width: 380,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, -6),
            followerAnchor: Alignment.bottomLeft,
            targetAnchor: Alignment.topLeft,
            child: MentionPopup(
              query: query,
              sources: widget.sources,
              onSelect: _selectSuggestion,
              onDismiss: _dismissPopup,
            ),
          ),
        );
      },
      child: ComposerDropTarget(
        onDrop: _handleDrop,
        // The same value the box below uses as its margin, handed over
        // rather than copied, so the drop ring cannot drift off the border.
        insets: margin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: margin,
          decoration: BoxDecoration(
            color: ds.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(
              // The accent is the focus color everywhere else (it is what
              // `CcInputTokens.borderFocused` resolves to), so the composer —
              // the most-focused surface in the app — uses it too rather than
              // going ink-black on its own.
              color: _composerFocused ? ds.accent : ds.borderSecondary,
              width: 1,
            ),
            boxShadow: [
              // A calm focus cue: a soft, low-alpha bloom rather than a loud
              // glow, so the composer stays composed when active.
              if (_composerFocused)
                BoxShadow(
                  color: ds.accent.withValues(alpha: 0.12),
                  blurRadius: 5,
                ),
              ...AppShadows.soft,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AttachmentStrip(
                      attachments: _attachments,
                      onRemove: _removeAttachment,
                      onOpen: (a) =>
                          unawaited(openAttachmentPreview(context, ref, a)),
                    ),
                  ),
                CompositedTransformTarget(
                  link: _link,
                  child: Focus(
                    onKeyEvent: _onFieldKey,
                    // Notes that the next caret move came from a POINTER, which
                    // is what separates clicking a reference from arrowing over
                    // it. Listener, not GestureDetector: this must observe
                    // without entering the arena, where it would compete with
                    // the field's own tap-to-place-caret recognizer.
                    child: Listener(
                      onPointerUp: _onPointerUp,
                      child: CcTextField(
                        controller: _controller,
                        focusNode: _focus,
                        maxLines: widget.maxLines,
                        minLines: widget.minLines,
                        textInputAction: TextInputAction.send,
                        textStyle: CcTypography.body.copyWith(
                          color: ds.textPrimary,
                        ),
                        onSubmitted: (_) => _submit(),
                        hintText: widget.hint,
                        chromeless: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _Toolbar(
                  leading: widget.leading,
                  trailing: widget.trailing,
                  sending: _sending,
                  showStop: widget.isBusy && _isEmpty && widget.onStop != null,
                  onStop: widget.onStop,
                  enableFilePicker: widget.enableFilePicker,
                  onPickFiles: _pickFiles,
                  onSubmit: _submit,
                  composerFocused: _composerFocused,
                  onDictationPartial: _applyDictationPartial,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.leading,
    required this.trailing,
    required this.sending,
    required this.showStop,
    required this.onStop,
    required this.enableFilePicker,
    required this.onPickFiles,
    required this.onSubmit,
    required this.composerFocused,
    required this.onDictationPartial,
  });

  final Widget? leading;
  final Widget? trailing;
  final bool sending;
  final bool showStop;
  final Future<void> Function()? onStop;
  final bool enableFilePicker;
  final VoidCallback onPickFiles;
  final VoidCallback onSubmit;
  final bool composerFocused;
  final void Function(String text, {required bool isFinal}) onDictationPartial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ?leading,
        const Spacer(),
        if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
        if (enableFilePicker)
          CcIconButton(
            icon: AppIcons.plus,
            onPressed: onPickFiles,
            // Names the drag-and-drop affordance too. A drop target that only
            // announces itself once a drag is already in flight is one nobody
            // discovers on a quiet screen.
            tooltip: AppLocalizations.of(context).attachFilesOrDrop,
          ),
        VoiceButton(
          onPartial: onDictationPartial,
          composerFocused: composerFocused,
        ),
        const SizedBox(width: 6),
        if (showStop)
          CcTooltip(
            message: AppLocalizations.of(context).stopAgent,
            child: CcButton(
              variant: CcButtonVariant.destructive,
              onPressed: onStop,
              child: const Icon(AppIcons.square, size: 14),
            ),
          )
        else
          CcButton(
            onPressed: sending ? null : onSubmit,
            child: sending
                ? const CcSpinner(size: 14)
                : const Icon(AppIcons.arrowUp, size: 16),
          ),
      ],
    );
  }
}
