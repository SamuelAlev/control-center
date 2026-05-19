import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Schemes we hand to the webview untouched. Anything else before a colon is
/// treated as a host:port pair, not a scheme ("example.com:8080" must become
/// "https://example.com:8080", not stay scheme-less).
final RegExp _knownSchemePrefix = RegExp(
  r'^(https?|file|ftp|about|data|blob|mailto|chrome):',
  caseSensitive: false,
);

/// Parses raw address-bar input into a navigable [Uri], or `null` when the
/// input cannot resolve to a page URL (empty, no host, not host-shaped).
Uri? parseReaderAddress(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final hasScheme =
      trimmed.contains('://') || _knownSchemePrefix.hasMatch(trimmed);
  final candidate = hasScheme ? trimmed : 'https://$trimmed';
  final Uri uri;
  try {
    uri = Uri.parse(candidate);
  } on FormatException {
    return null;
  }
  final host = uri.host;
  if (host.isEmpty) {
    return null;
  }
  // A single word ("hello") parses to a host but is not a destination —
  // require a dotted name, localhost, or a bracketed IPv6 literal.
  final hostShaped =
      host == 'localhost' || host.contains('.') || host.startsWith('[');
  if (!hostShaped) {
    return null;
  }
  return uri;
}

/// Browser-style address field for the article reader toolbar.
///
/// Shows the live URL of the rendered page and doubles as an omnibox:
/// - Focusing selects the whole address so typing replaces it.
/// - Enter navigates via [onNavigate] (with `https://` defaulted in).
/// - Escape — or blurring after an unsubmitted edit — restores the live URL.
/// - A trailing button copies the address (the field also supports normal
///   text selection while focused).
///
/// While focused, external URL changes (link clicks, back/forward) do not
/// clobber what the user is typing; they land once the field is left.
class ReaderAddressField extends StatefulWidget {
  /// Creates a [ReaderAddressField].
  const ReaderAddressField({
    super.key,
    required this.url,
    required this.onNavigate,
  });

  /// The live URL of the currently rendered page. The field follows it
  /// whenever the user is not editing.
  final String url;

  /// Called with the parsed URI when the user submits an address.
  final ValueChanged<Uri> onNavigate;

  @override
  State<ReaderAddressField> createState() => _ReaderAddressFieldState();
}

class _ReaderAddressFieldState extends State<ReaderAddressField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _invalidFlashTimer;
  Timer? _copiedTimer;
  bool _invalid = false;
  bool _copied = false;

  /// True while a submit-driven unfocus is in flight, so the blur handler
  /// keeps the submitted text instead of reverting it to the page URL. The
  /// live URL lands in [didUpdateWidget] once navigation starts.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.url;
    _focusNode.addListener(_onFocusChanged);
    _focusNode.onKeyEvent = _onKeyEvent;
  }

  @override
  void didUpdateWidget(covariant ReaderAddressField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url && !_focusNode.hasFocus) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _invalidFlashTimer?.cancel();
    _copiedTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) {
      return;
    }
    if (_focusNode.hasFocus) {
      // Browser address-bar behavior: focusing selects the whole address, so
      // typing replaces it while a second click can still place the caret.
      final text = _controller.text;
      if (text.isNotEmpty) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      }
    } else if (_submitting) {
      _submitting = false;
    } else if (_controller.text != widget.url) {
      _controller.text = widget.url;
    }
    _invalidFlashTimer?.cancel();
    _invalid = false;
    setState(() {});
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _focusNode.hasFocus) {
      _controller.text = widget.url;
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _submit() {
    final uri = parseReaderAddress(_controller.text);
    if (uri == null) {
      _invalidFlashTimer?.cancel();
      setState(() => _invalid = true);
      _invalidFlashTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() => _invalid = false);
        }
      });
      return;
    }
    _submitting = true;
    _controller.text = uri.toString();
    widget.onNavigate(uri);
    _focusNode.unfocus();
  }

  Future<void> _copy() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final input = CcInputTokens.resolve(tokens);
    final l10n = AppLocalizations.of(context);
    final focused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        // Always present (transparent at rest) so gaining focus or flashing
        // an error never shifts layout.
        border: Border.all(
          color: _invalid
              ? input.borderError
              : focused
              ? input.borderFocused
              : const Color(0x00000000),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CcTextField(
              controller: _controller,
              focusNode: _focusNode,
              chromeless: true,
              hintText: l10n.addressBarHint,
              textInputAction: TextInputAction.go,
              textStyle: CcTypography.caption.copyWith(
                color: focused ? tokens.textPrimary : tokens.textTertiary,
              ),
              // Keep focus on Enter — _submit decides between navigating
              // (unfocus) and flashing the invalid-address state (stay).
              onEditingComplete: () {},
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 4),
          CcTooltip(
            message: _copied ? l10n.copied : l10n.copyAddress,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _copy,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _copied ? AppIcons.check : AppIcons.copy,
                    size: 14,
                    color: _copied
                        ? tokens.fgSuccessSecondary
                        : tokens.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
