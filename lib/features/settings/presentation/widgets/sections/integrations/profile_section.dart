import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's profile: display name, email and the git author
/// identity stamped on commits made on their behalf.
class ProfileSection extends ConsumerWidget {
  /// Creates a [ProfileSection].
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final identityAsync = ref.watch(currentIdentityProvider);

    return SectionCard(
      label: l10n.profileSectionLabel,
      subtitle: Text(l10n.profileSectionDescription),
      child: identityAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Text(
          l10n.failedWithError('$e'),
          style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
        ),
        // Key by user id so a different signed-in user re-seeds the fields,
        // while refreshes of the same user keep any in-progress edits.
        data: (me) => _ProfileForm(key: ValueKey(me.user.id), user: me.user),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({super.key, required this.user});

  final UserDto user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _displayName = TextEditingController(
    text: widget.user.displayName,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email ?? '',
  );
  late final TextEditingController _gitAuthorName = TextEditingController(
    text: widget.user.gitAuthorName ?? '',
  );
  late final TextEditingController _gitAuthorEmail = TextEditingController(
    text: widget.user.gitAuthorEmail ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _gitAuthorName.dispose();
    _gitAuthorEmail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(identityRepositoryProvider)
          .updateProfile(
            displayName: _displayName.text.trim(),
            email: _email.text.trim(),
            gitAuthorName: _gitAuthorName.text.trim(),
            gitAuthorEmail: _gitAuthorEmail.text.trim(),
          );
      ref.invalidate(currentIdentityProvider);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      CcToastScope.of(
        context,
      ).show(l10n.profileSaved, variant: CcToastVariant.success);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      CcToastScope.of(
        context,
      ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CcTextField(
                controller: _displayName,
                label: l10n.displayNameLabel,
                enabled: !_busy,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CcTextField(
                controller: _email,
                label: l10n.emailLabel,
                enabled: !_busy,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CcTextField(
                controller: _gitAuthorName,
                label: l10n.gitAuthorNameLabel,
                enabled: !_busy,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CcTextField(
                controller: _gitAuthorEmail,
                label: l10n.gitAuthorEmailLabel,
                enabled: !_busy,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: CcButton(
            loading: _busy,
            onPressed: _busy ? null : _save,
            child: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
