import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/identity/providers/account_profile_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/username_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first onboarding step: the username and display name the person is
/// known by, prefilled with what the server derived for them.
///
/// It cannot be passed with a name the rule or the server refuses. A name
/// someone takes between the check and the save is refused by the save and
/// shown here the same way.
class OnboardingYouStep extends ConsumerWidget {
  /// Creates the step.
  const OnboardingYouStep({super.key, required this.onContinue});

  /// Advances once the name is saved.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return switch (ref.watch(accountProfileProvider)) {
      AsyncValue(:final value?) => _YouForm(
        key: ValueKey(value.id),
        user: value,
        onContinue: onContinue,
      ),
      AsyncError(:final error) => OnboardingStepLayout(
        content: Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(AppIcons.triangleAlert, size: 14, color: t.fgErrorPrimary),
            Text(
              storageRefusalMessage(l10n, error) ??
                  l10n.accountLoadFailed(
                    error is RemoteRpcException ? error.message : '$error',
                  ),
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            ),
          ],
        ),
        footer: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => ref.invalidate(accountProfileProvider),
            child: Text(l10n.retry),
          ),
        ),
      ),
      _ => const Center(child: CcSpinner()),
    };
  }
}

class _YouForm extends ConsumerStatefulWidget {
  const _YouForm({super.key, required this.user, required this.onContinue});

  final UserDto user;
  final VoidCallback onContinue;

  @override
  ConsumerState<_YouForm> createState() => _YouFormState();
}

class _YouFormState extends ConsumerState<_YouForm> {
  late final _handle = TextEditingController(text: widget.user.handle);
  late final _displayName = TextEditingController(
    text: widget.user.displayName,
  );
  late final _availability = UsernameAvailability(
    check: ref.read(usernameCheckProvider),
    current: widget.user.handle,
  );
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayName.addListener(_changed);
    _availability.addListener(_changed);
  }

  @override
  void dispose() {
    _handle.dispose();
    _displayName.dispose();
    _availability.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _canContinue =>
      !_busy &&
      !_availability.status.blocksSave &&
      _displayName.text.trim().isNotEmpty;

  Future<void> _continue() async {
    if (!_canContinue) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final handle = Username.normalizeInput(_handle.text);
    final displayName = _displayName.text.trim();
    final user = widget.user;
    if (handle == user.handle && displayName == user.displayName) {
      return widget.onContinue();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(accountProfileProvider.notifier)
          .save(
            handle: handle == user.handle ? null : handle,
            displayName: displayName == user.displayName ? null : displayName,
          );
      if (mounted) {
        widget.onContinue();
      }
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
    final error = _error;
    return OnboardingStepLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          UsernameField(
            controller: _handle,
            availability: _availability,
            enabled: !_busy,
            autofocus: true,
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsField(
            label: l10n.displayNameLabel,
            layout: SettingsFieldLayout.stacked,
            hint: l10n.accountDisplayNameHint,
            error: _displayName.text.trim().isEmpty
                ? l10n.accountDisplayNameRequired
                : null,
            child: CcTextField(
              controller: _displayName,
              enabled: !_busy,
              onSubmitted: (_) => _continue(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            ),
          ],
        ],
      ),
      footer: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: CcButton(
          loading: _busy,
          onPressed: _canContinue ? _continue : null,
          child: Text(l10n.continueLabel),
        ),
      ),
    );
  }
}
