import 'dart:async';

import 'package:control_center/core/infrastructure/speech/speech_transcriber.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_strip.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_popup.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_trigger.dart';
import 'package:control_center/shared/widgets/composer/voice/voice_button.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

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
///     FileMentionSource(search: dartFileSearch, roots: repoPaths),
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
class Composer extends StatefulWidget {
  /// Creates a new [Composer].
  const Composer({
    super.key,
    required this.sources,
    required this.onSubmit,
    this.hint = 'Type a message…',
    this.transcriber,
    this.enableFilePicker = true,
    this.controller,
    this.maxLines = 6,
    this.minLines = 1,
    this.trailing,
    this.leading,
    this.autofocus = false,
    this.isBusy = false,
    this.onStop,
  });

  /// Pluggable mention sources, queried in order; results are grouped under
  /// each source's section header.
  final List<MentionSource> sources;

  /// Called when the user submits (Enter on empty popup, or send button).
  final Future<void> Function(ComposerSubmission) onSubmit;

  /// Placeholder for the input.
  final String hint;

  /// Optional speech transcriber. If null, the mic button is disabled.
  final SpeechTranscriber? transcriber;

  /// When true, shows the paperclip attachment picker.
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

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late TextEditingController _controller;
  late FocusNode _focus;
  final OverlayPortalController _popupCtrl = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final List<ComposerAttachment> _attachments = [];

  MentionQuery? _activeQuery;
  bool _sending = false;
  bool _composerFocused = false;
  bool _isEmpty = true;

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
    final text = _controller.text;
    final mentions = _extractResolvedMentions(text);
    final submission = ComposerSubmission(
      text: text,
      mentions: mentions,
      attachments: List.unmodifiable(_attachments),
    );
    if (submission.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    // Clear immediately so the user sees instant feedback and the
    // TextField cannot re-insert a newline during the async gap.
    _controller.clear();
    _attachments.clear();
    try {
      await widget.onSubmit(submission);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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
    final theme = context.theme;
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _composerFocused
                ? theme.colors.primary
                : theme.colors.border,
            width: 1,
          ),
          boxShadow: [
            // A calm focus cue: a soft, low-alpha bloom rather than a loud
            // glow, so the composer stays composed when active.
            if (_composerFocused)
              BoxShadow(
                color: theme.colors.primary.withValues(alpha: 0.12),
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
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    textInputAction: TextInputAction.send,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                    ),
                    cursorColor: theme.colors.primary,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      isDense: true,
                      // Inner border off — the outer Container provides the
                      // border. Focus is tracked via FocusNode listener and
                      // shown as an outline glow (no layout shift).
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
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
                transcriber: widget.transcriber,
                onTranscript: (t) {
                  if (t.text.trim().isEmpty) {
                    return;
                  }
                  final text = _controller.text;
                  final sep = text.isEmpty || text.endsWith(' ') ? '' : ' ';
                  _controller.value = TextEditingValue(
                    text: '$text$sep${t.text}',
                    selection: TextSelection.collapsed(
                      offset: text.length + sep.length + t.text.length,
                    ),
                  );
                },
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
    required this.transcriber,
    required this.onTranscript,
  });

  final Widget? leading;
  final Widget? trailing;
  final bool sending;
  final bool showStop;
  final Future<void> Function()? onStop;
  final bool enableFilePicker;
  final VoidCallback onPickFiles;
  final VoidCallback onSubmit;
  final SpeechTranscriber? transcriber;
  final void Function(TranscriptionResult) onTranscript;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: [
        ?leading,
        const Spacer(),
        if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
        if (enableFilePicker)
          FTooltip(
            tipBuilder: (_, _) =>
                Text(AppLocalizations.of(context).attachFiles),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: onPickFiles,
              child: Icon(
                LucideIcons.plus,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        VoiceButton(transcriber: transcriber, onTranscript: onTranscript),
        const SizedBox(width: 6),
        if (showStop)
          FTooltip(
            tipBuilder: (_, _) =>
                Text(AppLocalizations.of(context).stopAgent),
            child: FButton(
              variant: FButtonVariant.destructive,
              onPress: onStop,
              mainAxisSize: MainAxisSize.min,
              child: const Icon(LucideIcons.square, size: 14),
            ),
          )
        else
          FButton(
            onPress: sending ? null : onSubmit,
            mainAxisSize: MainAxisSize.min,
            child: sending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: FCircularProgress(),
                  )
                : const Icon(LucideIcons.arrowUp, size: 16),
          ),
      ],
    );
  }
}
