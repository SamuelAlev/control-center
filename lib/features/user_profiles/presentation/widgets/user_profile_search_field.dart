import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: widget.width,
      child: FTextField(
        control: FTextFieldControl.managed(controller: _controller),
        focusNode: _focusNode,
        hint: l10n.profileSearchHint,
        size: FTextFieldSizeVariant.sm,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        clearable: (value) => value.text.isNotEmpty,
        prefixBuilder: (context, style, variants) => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(
            LucideIcons.search,
            size: 15,
            color: colors.mutedForeground,
          ),
        ),
        // A quiet `/` affordance, mirroring the shortcut that focuses the
        // field. Hidden once the field is focused or holds a query — the ×
        // clear button takes the slot instead.
        suffixBuilder: (context, style, variants) {
          if (_focusNode.hasFocus || _controller.text.isNotEmpty) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.only(right: 8),
            child: IgnorePointer(child: Kbd.symbol(label: '/')),
          );
        },
      ),
    );
  }
}
