import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
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
/// Exposed so status lines stacked directly above it (channel provisioning, the
/// typing indicator) can start their content on the composer's own left border
/// instead of guessing the inset — they used to hug the pane edge, which read as
/// unrelated to the composer below them.
const double composerHorizontalMargin = 12;

/// A keyboard-first chat composer with multi-source `@` mentions, file
/// attachments, and (scaffolded) voice dictation.
///
/// Usage:
/// ```dart
/// Composer(
///   hint: 'Message #general… (@ to mention, / for commands)',
///   sources: [
///     AgentMentionSource(agents),
///     ChannelMentionSource(channels),
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
  /// — Cursor-style plan-mode entry). Only the messaging channel composer opts
  /// in; other composers keep Shift+Tab as focus traversal.
  ///
  /// The callback flips the *conversation mode*; it deliberately does not
  /// touch the draft. An earlier version inserted a literal `/plan ` prefix,
  /// which did nothing at all: the server layers the prompt into
  /// `<context>…</context>\n\n<text>` before slash parsing, so the prefix
  /// never matched. `channels.mode` is the single authority every enforcement
  /// layer (tool surface, guard preset, sandbox, prompt) already reads.
  final VoidCallback? onPlanToggle;

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
    _controller = widget.controller ?? TextEditingController();
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
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onControllerChanged);
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
    final caret = _controller.selection.baseOffset;
    final query = detectMentionQuery(_controller.text, caret);
    final isEmpty = _controller.text.trim().isEmpty;
    // Drop structured picks whose inserted token has been edited out, so a
    // deleted `#`-reference is never re-emitted on submit.
    if (_picked.isNotEmpty) {
      _picked.removeWhere((p) => !_tokenSurvives(_controller.text, p.token));
    }
    if (query != _activeQuery || isEmpty != _isEmpty) {
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
    // Files inserted as @ mentions also surface as attachments so the host
    // app can ship the bytes without re-parsing the text.
    if (suggestion.kind == 'file') {
      final path = suggestion.payload?['path'] as String?;
      final isDir = suggestion.payload?['isDirectory'] as bool? ?? false;
      if (path != null && !isDir) {
        _attachments.add(
          ComposerAttachment(
            id: 'file:$path',
            kind: 'file',
            label: p.basename(path),
            path: path,
          ),
        );
        setState(() {});
      }
    } else if (suggestion.kind == 'scratchpad') {
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

  void _dismissPopup() {
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    setState(() => _activeQuery = null);
  }

  Future<void> _pickFiles() async {
    final files = await openFiles();
    if (files.isEmpty) {
      return;
    }
    for (final f in files) {
      _attachments.add(
        ComposerAttachment(
          id: 'file:${f.path}',
          kind: 'file',
          label: p.basename(f.path),
          path: f.path,
          mimeType: f.mimeType,
        ),
      );
    }
    setState(() {});
  }

  void _removeAttachment(ComposerAttachment a) {
    setState(() {
      _attachments.removeWhere((x) => x.id == a.id);
    });
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
      // the session, take the last (fully-drained) text, and splice it into the
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
        '#' => 'channel',
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
    // Esc closes the popup if open; otherwise blurs the field.
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_popupCtrl.isShowing) {
        _dismissPopup();
        return KeyEventResult.handled;
      }
      node.unfocus();
      return KeyEventResult.handled;
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

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(
          horizontal: composerHorizontalMargin,
          vertical: 8,
        ),
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
                  ),
                ),
              CompositedTransformTarget(
                link: _link,
                child: Focus(
                  onKeyEvent: _onFieldKey,
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
            tooltip: AppLocalizations.of(context).attachFiles,
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
