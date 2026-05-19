import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A profile's PR search field. Mirrors the queue's search field — search-icon
/// prefix, a quiet `/` affordance, clearable — but the profile is already
/// scoped to one author, so this drives a local title/number filter
/// ([userProfileSearchProvider]) rather than a server search, and carries no
/// author autocomplete.
class UserProfileSearchField extends ConsumerStatefulWidget {
  /// Creates a [UserProfileSearchField] for [login].
  const UserProfileSearchField({
    super.key,
    required this.login,
    this.width = 300,
    this.focusNode,
  });

  /// The profile this search belongs to.
  final String login;

  /// The field width.
  final double width;

  /// Externally-owned focus node so the profile's `/` and ⌘F shortcuts can
  /// focus the field. When omitted the field manages its own node; the owner
  /// disposes a node it passes in.
  final FocusNode? focusNode;

  @override
  ConsumerState<UserProfileSearchField> createState() =>
      _UserProfileSearchFieldState();
}

class _UserProfileSearchFieldState
    extends ConsumerState<UserProfileSearchField> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(userProfileSearchProvider(widget.login));
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    // Local filter over an already-loaded set — cheap enough to apply on every
    // keystroke without debouncing.
    ref
        .read(userProfileSearchProvider(widget.login).notifier)
        .set(_controller.text);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: widget.width,
      child: CcTextField(
        controller: _controller,
        focusNode: _focusNode,
        hintText: l10n.profileSearchHint,
        size: CcTextFieldSize.sm,
        keyboardType: TextInputType.text,
        prefix: Icon(
          AppIcons.search,
          size: 15,
          color: tokens.textTertiary,
        ),
        suffix: _buildSuffix(),
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
