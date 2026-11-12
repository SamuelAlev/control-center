import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/account_profile_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/username_field.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_avatar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editable account row: username, display name, email and avatar.
///
/// Saves as a unit. The server leaves a blank field unchanged rather than
/// clearing it, so a field that had a value cannot be emptied here: the form
/// says so instead of pretending the save removed it.
class AccountProfileForm extends ConsumerStatefulWidget {
  /// Creates the form for [user].
  const AccountProfileForm({super.key, required this.user});

  /// The account row as last loaded.
  final UserDto user;

  @override
  ConsumerState<AccountProfileForm> createState() => _AccountProfileFormState();
}

class _AccountProfileFormState extends ConsumerState<AccountProfileForm> {
  late UserDto _saved = widget.user;
  late final _handle = TextEditingController(text: _saved.handle);
  late final _displayName = TextEditingController(text: _saved.displayName);
  late final _email = TextEditingController(text: _saved.email ?? '');
  late final _avatar = TextEditingController(text: _saved.avatarRef ?? '');
  late final _availability = UsernameAvailability(
    check: ref.read(usernameCheckProvider),
    current: _saved.handle,
  );
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_handle, _displayName, _email, _avatar]) {
      c.addListener(_changed);
    }
    _availability.addListener(_changed);
  }

  @override
  void dispose() {
    for (final c in [_handle, _displayName, _email, _avatar]) {
      c.dispose();
    }
    _availability.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  String get _newHandle => Username.normalizeInput(_handle.text);

  bool get _dirty =>
      _newHandle != _saved.handle ||
      _displayName.text.trim() != _saved.displayName ||
      _email.text.trim() != (_saved.email ?? '') ||
      _avatar.text.trim() != (_saved.avatarRef ?? '');

  String? _displayNameError(AppLocalizations l10n) =>
      _displayName.text.trim().isEmpty ? l10n.accountDisplayNameRequired : null;

  /// Whether the address in the field is one only this person vouches for:
  /// the saved one the identity provider or server owner never confirmed, or
  /// a new one, which nobody has confirmed yet. Single sign-on matches only a
  /// confirmed address.
  bool get _emailUnconfirmed {
    final typed = _email.text.trim();
    return typed.isNotEmpty &&
        (typed != (_saved.email ?? '') || !_saved.emailVerified);
  }

  String? _emailError(AppLocalizations l10n) =>
      _email.text.trim().isEmpty && (_saved.email ?? '').isNotEmpty
      ? l10n.accountFieldCannotBeCleared
      : null;

  String? _avatarError(AppLocalizations l10n) {
    final value = _avatar.text.trim();
    if (value.isEmpty) {
      return (_saved.avatarRef ?? '').isNotEmpty
          ? l10n.accountFieldCannotBeCleared
          : null;
    }
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? null
        : l10n.accountAvatarInvalid;
  }

  bool _valid(AppLocalizations l10n) =>
      !_availability.status.blocksSave &&
      _displayNameError(l10n) == null &&
      _emailError(l10n) == null &&
      _avatarError(l10n) == null;

  void _discard() {
    _handle.text = _saved.handle;
    _displayName.text = _saved.displayName;
    _email.text = _saved.email ?? '';
    _avatar.text = _saved.avatarRef ?? '';
    _availability.saved(_saved.handle);
    setState(() => _error = null);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    String? changed(String value, String? saved) =>
        value.trim() == (saved ?? '') ? null : value.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(accountProfileProvider.notifier)
          .save(
            handle: _newHandle == _saved.handle ? null : _newHandle,
            displayName: changed(_displayName.text, _saved.displayName),
            email: changed(_email.text, _saved.email),
            avatarRef: changed(_avatar.text, _saved.avatarRef),
          );
      if (!mounted) {
        return;
      }
      _saved = user;
      _discard();
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.profileSaved, variant: CcToastVariant.success);
    } on UsernameRefusedException catch (refusal) {
      _availability.refused(refusal.reason);
    } on Object catch (error) {
      _error = failureMessage(l10n, error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final preview = _avatarError(l10n) == null && _avatar.text.trim() != ''
        ? _avatar.text.trim()
        : _saved.avatarRef;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MemberAvatar(
              name: _displayName.text.trim().isEmpty
                  ? _saved.displayName
                  : _displayName.text.trim(),
              user: _saved,
              imageUrl: preview,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _saved.displayName,
                    style: CcTypography.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '@${_saved.handle}',
                    // RTL carve-out: a username reads left to right.
                    textDirection: TextDirection.ltr,
                    style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        UsernameField(
          controller: _handle,
          availability: _availability,
          enabled: !_busy,
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsField(
          label: l10n.displayNameLabel,
          layout: SettingsFieldLayout.stacked,
          hint: l10n.accountDisplayNameHint,
          error: _displayNameError(l10n),
          child: CcTextField(controller: _displayName, enabled: !_busy),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsField(
          label: l10n.emailLabel,
          layout: SettingsFieldLayout.stacked,
          optional: true,
          error: _emailError(l10n),
          hint: _emailUnconfirmed ? l10n.accountEmailUnconfirmedHint : null,
          child: CcTextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsField(
          label: l10n.accountAvatarLabel,
          layout: SettingsFieldLayout.stacked,
          optional: true,
          hint: l10n.accountAvatarHint,
          error: _avatarError(l10n),
          // RTL carve-out: a URL reads left to right.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CcTextField(
              controller: _avatar,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              hintText: 'https://',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsSaveBar(
          dirty: _dirty,
          busy: _busy,
          error: _error,
          saveEnabled: _valid(l10n),
          onSave: _save,
          onDiscard: _discard,
        ),
      ],
    );
  }
}
