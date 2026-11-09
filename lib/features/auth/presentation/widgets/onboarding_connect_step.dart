import 'dart:async';

import 'package:cc_data/cc_data.dart' show ConnectModeSetting;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_mode_options.dart';
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First-run choice of whose provider apps this server signs people in
/// with: Control Center's (hosted Connect), the operator's own, or a custom
/// Connect server.
///
/// Server owner only — the flow never plans it for anyone else. Nothing is
/// preselected: each option changes who holds a piece of the trust, so the
/// operator picks one on purpose. A mode the environment pins
/// (`CC_CONNECT_URL`) is shown, locked, and Continue just moves on.
class OnboardingConnectStep extends ConsumerStatefulWidget {
  /// Creates the step.
  const OnboardingConnectStep({super.key, required this.onContinue});

  /// Advances once a mode is saved.
  final VoidCallback onContinue;

  @override
  ConsumerState<OnboardingConnectStep> createState() =>
      _OnboardingConnectStepState();
}

class _OnboardingConnectStepState extends ConsumerState<OnboardingConnectStep> {
  final _url = TextEditingController();
  ConnectModeSetting? _selected;
  String? _urlError;
  String? _error;
  bool _saving = false;
  bool _creatingApp = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _continue({required bool locked}) async {
    final l10n = AppLocalizations.of(context);
    final mode = _selected;
    if (locked) {
      widget.onContinue();
      return;
    }
    if (mode == null) {
      return;
    }
    final url = _url.text.trim();
    if (mode == ConnectModeSetting.custom && !isConnectServerUrl(url)) {
      setState(() => _urlError = l10n.connectCustomUrlInvalid);
      return;
    }
    setState(() {
      _urlError = null;
      _error = null;
      _saving = true;
    });
    try {
      await ConnectSettingsActions(
        ref,
      ).configure(mode, url: mode == ConnectModeSetting.custom ? url : null);
      if (mounted) {
        widget.onContinue();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = l10n.failedWithError('$e'));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _createGitHubApp() async {
    final l10n = AppLocalizations.of(context);
    final open = ref.read(externalUrlOpenerProvider);
    setState(() => _creatingApp = true);
    try {
      final url = await beginGitHubAppManifest(ref);
      if (!open(url) && mounted) {
        setState(() => _error = l10n.couldNotOpenBrowser);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = l10n.failedWithError('$e'));
      }
    } finally {
      if (mounted) {
        setState(() => _creatingApp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(connectStatusProvider).value;
    final locked = status?.locked ?? false;
    final selected = locked ? status?.mode : _selected;
    final error = _error;
    return OnboardingStepLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locked) ...[
            CcAlert(title: l10n.connectLocked, variant: CcAlertVariant.info),
            const SizedBox(height: AppSpacing.md),
          ],
          ConnectModeOptions(
            selected: selected == ConnectModeSetting.unset ? null : selected,
            enabled: !locked && !_saving,
            urlController: _url,
            urlError: _urlError,
            onSelected: (mode) => setState(() {
              _selected = mode;
              _urlError = null;
              _error = null;
            }),
            onUrlSubmitted: (_) => unawaited(_continue(locked: locked)),
          ),
          if (selected == ConnectModeSetting.off) ...[
            const SizedBox(height: AppSpacing.sm),
            CcAlert(
              title: l10n.onboardingConnectOwnNext,
              variant: CcAlertVariant.info,
              action: CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                icon: AppIcons.externalLink,
                loading: _creatingApp,
                onPressed: _creatingApp
                    ? null
                    : () => unawaited(_createGitHubApp()),
                child: Text(l10n.providerAppCreateGitHub),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(title: error, variant: CcAlertVariant.danger),
          ],
        ],
      ),
      footer: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: CcButton(
          loading: _saving,
          onPressed: _saving || (!locked && _selected == null)
              ? null
              : () => unawaited(_continue(locked: locked)),
          child: Text(l10n.continueLabel),
        ),
      ),
    );
  }
}
