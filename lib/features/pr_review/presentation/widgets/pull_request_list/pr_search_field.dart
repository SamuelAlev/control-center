import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_search_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The queue's search field: a single text input that doubles as a structured
/// query. Typing `author:@<login>` filters by author — with an inline
/// IntelliSense-style autocomplete sourced from the authors of loaded PRs — and
/// any remaining free text is sent to the search backend. The parsed query
/// lands in [prSearchInputProvider] (debounced) which drives the queue.
class PrSearchField extends ConsumerStatefulWidget {
  /// Creates a [PrSearchField].
  const PrSearchField({super.key, this.width = 320, this.focusNode});

  /// The field's (and dropdown's) width.
  final double width;

  /// An externally-owned focus node, letting an ancestor focus the field
  /// (e.g. the queue's `/` and ⌘F shortcuts). When omitted the field manages
  /// its own node. The owner is responsible for disposing a node it passes in.
  final FocusNode? focusNode;

  @override
  ConsumerState<PrSearchField> createState() => _PrSearchFieldState();
}

class _PrSearchFieldState extends ConsumerState<PrSearchField> {
  static const _debounce = Duration(milliseconds: 300);
  static const _maxSuggestions = 8;

  // The partial `author:` token immediately preceding the caret, if any.
  static final _partialAuthor = RegExp(
    r'author:@?([A-Za-z0-9-]*)$',
    caseSensitive: false,
  );

  final TextEditingController _controller = TextEditingController();
  final LayerLink _link = LayerLink();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;

  Timer? _debounceTimer;
  OverlayEntry? _overlay;
  List<PrUser> _suggestions = const [];
  int _highlighted = 0;
  int _tokenStart = 0;

  @override
  void initState() {
    super.initState();
    // Drives the author-autocomplete navigation. Attached imperatively because
    // the node may be supplied by an ancestor (which can't know about it).
    _focusNode.onKeyEvent = _handleKey;
    // Toggle the `/` affordance as focus comes and goes.
    _focusNode.addListener(_onFocusChanged);
    _controller.text = ref.read(prSearchInputProvider);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focusNode
      ..onKeyEvent = null
      ..removeListener(_onFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ── input → provider ──────────────────────────────────────────────────

  void _onChanged() {
    _refreshSuggestions();
    if (_controller.text.trim().isEmpty) {
      // Clearing (via the × or backspace) takes effect immediately so the
      // queue snaps back to all open PRs without waiting out the debounce.
      _commitNow();
    } else {
      _scheduleCommit();
    }
  }

  void _scheduleCommit() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) {
        ref.read(prSearchInputProvider.notifier).set(_controller.text);
      }
    });
  }

  void _commitNow() {
    _debounceTimer?.cancel();
    ref.read(prSearchInputProvider.notifier).set(_controller.text);
  }

  // ── author autocomplete ───────────────────────────────────────────────

  int get _caret {
    final offset = _controller.selection.baseOffset;
    return (offset >= 0 && offset <= _controller.text.length)
        ? offset
        : _controller.text.length;
  }

  List<PrUser> _loadedAuthors() {
    final state = ref.read(prsByRepoProvider).value;
    if (state == null) {
      return const [];
    }
    return collectAuthors([for (final group in state.repos) ...group.prs]);
  }

  void _refreshSuggestions() {
    final match = _partialAuthor.firstMatch(
      _controller.text.substring(0, _caret),
    );
    if (match == null) {
      _removeOverlay();
      return;
    }
    final fragment = match.group(1)!.toLowerCase();
    final matches = [
      for (final author in _loadedAuthors())
        if (fragment.isEmpty || author.login.toLowerCase().contains(fragment))
          author,
    ];
    if (matches.isEmpty) {
      _removeOverlay();
      return;
    }
    _tokenStart = match.start;
    _suggestions = matches.take(_maxSuggestions).toList();
    _highlighted = 0;
    _showOverlay();
  }

  void _accept(PrUser user) {
    final text = _controller.text;
    final replacement = 'author:@${user.login} ';
    final newText = text.replaceRange(_tokenStart, _caret, replacement);
    _removeOverlay();
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _tokenStart + replacement.length,
      ),
    );
    _commitNow();
    _focusNode.requestFocus();
  }

  void _moveHighlight(int delta) {
    if (_suggestions.isEmpty) {
      return;
    }
    _highlighted =
        (_highlighted + delta + _suggestions.length) % _suggestions.length;
    _overlay?.markNeedsBuild();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_overlay == null || _suggestions.isEmpty || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      _accept(_suggestions[_highlighted]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _removeOverlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── overlay ───────────────────────────────────────────────────────────

  void _showOverlay() {
    if (_overlay == null) {
      _overlay = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Widget _buildOverlay(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _removeOverlay,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: widget.width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.bgPrimary,
                  border: Border.all(color: tokens.borderSecondary),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppShadows.golden,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 288),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const CcDivider(),
                    itemBuilder: (_, i) => _AuthorRow(
                      user: _suggestions[i],
                      highlighted: i == _highlighted,
                      onTap: () => _accept(_suggestions[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: widget.width,
      child: CompositedTransformTarget(
        link: _link,
        child: CcTextField(
          controller: _controller,
          focusNode: _focusNode,
          hintText: l10n.searchPullRequestsHint,
          size: CcTextFieldSize.sm,
          keyboardType: TextInputType.text,
          onSubmitted: (_) {
            _removeOverlay();
            _commitNow();
          },
          prefix: Icon(
            AppIcons.search,
            size: 15,
            color: tokens.muted,
          ),
          suffix: _buildSuffix(),
        ),
      ),
    );
  }

  /// The trailing affordance: a clear (×) button when the field holds a query,
  /// or a quiet `/` shortcut hint when the field is idle (empty and unfocused).
  Widget? _buildSuffix() {
    if (_controller.text.isNotEmpty) {
      return CcIconButton(
        icon: AppIcons.x,
        size: CcButtonSize.sm,
        onPressed: () {
          _controller.clear();
          _focusNode.requestFocus();
        },
      );
    }
    if (!_focusNode.hasFocus) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: IgnorePointer(child: Kbd.symbol(label: '/')),
      );
    }
    return null;
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.user,
    required this.highlighted,
    required this.onTap,
  });

  final PrUser user;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        color: highlighted
            ? tokens.textPrimary.withValues(alpha: 0.10)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            buildAvatar(user, user.login, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                user.login,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
