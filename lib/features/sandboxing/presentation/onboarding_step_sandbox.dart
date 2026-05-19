import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/providers/privacy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding step that turns the OS-level native sandbox on (or opts the
/// user out explicitly). Sits between workspace creation and the voice-model
/// download.
class OnboardingStepSandbox extends ConsumerStatefulWidget {
  /// Creates an [OnboardingStepSandbox].
  const OnboardingStepSandbox({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// Callback for the back button.
  final VoidCallback onBack;

  /// Callback fired once the user has either set up the sandbox or
  /// explicitly opted out.
  final VoidCallback onContinue;

  @override
  ConsumerState<OnboardingStepSandbox> createState() =>
      _OnboardingStepSandboxState();
}

class _OnboardingStepSandboxState extends ConsumerState<OnboardingStepSandbox> {
  Future<void> _useNative() async {
    await ref
        .read(sandboxPreferencesProvider)
        .setBackend(SandboxBackend.native);
    widget.onContinue();
  }

  Future<void> _confirmSkip() async {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final accept = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.skipSandboxing,
        content: Text(
          l10n.skipSandboxingDialogContent,
          style: TextStyle(fontSize: 13, color: tokens?.textSecondary),
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.keepSandboxing),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.skipAcceptRisk),
          ),
        ],
      ),
    );
    if (accept != true) {
      return;
    }
    await ref.read(sandboxPreferencesProvider).setEnabled(false);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final detection = ref.watch(sandboxDetectionProvider);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);

    return detection.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CcProgressBar()),
      ),
      error: (e, _) => Text(
        l10n.detectionFailed('$e'),
        style: TextStyle(
          fontSize: 13,
          color: tokens?.textErrorPrimary,
        ),
      ),
      data: (result) {
        final native = result.capabilities[SandboxBackend.native];
        final available = native?.available == true;
        final installHint = available ? null : native?.installHint;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusRow(
              ready: available,
              title: available
                  ? l10n.nativeSandboxAvailable(result.platform)
                  : l10n.nativeSandboxNeedsInstall,
              subtitle: _platformDescription(result.platform),
              description: available ? null : native?.note,
              installHint: installHint,
            ),
            const SizedBox(height: 20),
            Divider(
              height: 1,
              thickness: 1,
              color: tokens?.borderSoft ??
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
            const _DiagnosticsConsentRow(),
            const SizedBox(height: 24),
            Row(
              children: [
                CcButton(
                  onPressed: widget.onBack,
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.back),
                ),
                const Spacer(),
                if (available)
                  TextButton(
                    onPressed: _confirmSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: tokens?.textErrorPrimary,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: Text(l10n.skipSandboxing),
                  ),
                if (available)
                  const SizedBox(width: 12),
                CcButton(
                  onPressed: available ? _useNative : null,
                  variant: available
                      ? CcButtonVariant.primary
                      : CcButtonVariant.secondary,
                  child: Text(
                    available ? l10n.useSandbox : l10n.installRequired,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Describes the native sandbox on the detected HOST platform. Branches on
  /// the detection result's platform string (the local machine on desktop, the
  /// connected cc_server over RPC on a thin/web client) rather than `dart:io`
  /// `Platform`, which throws on web. WSL2 reports as Linux, so it folds in.
  String _platformDescription(String platform) {
    final l10n = AppLocalizations.of(context);
    final p = platform.toLowerCase();
    if (p.contains('mac') || p.contains('darwin')) {
      return l10n.onboardingMacosDescription;
    }
    if (p.contains('linux') || p.contains('wsl')) {
      return l10n.onboardingLinuxDescription;
    }
    return l10n.onboardingUnsupportedDescription;
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.ready,
    required this.title,
    required this.subtitle,
    this.description,
    this.installHint,
  });

  final bool ready;
  final String title;
  final String subtitle;
  final String? description;
  final String? installHint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ready ? AppIcons.shieldCheck : AppIcons.shield,
          size: 20,
          color: ready ? tokens?.fgBrandPrimary : tokens?.fgTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: tokens?.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: tokens?.textTertiary,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: tokens?.textTertiary,
                  ),
                ),
              ],
              if (installHint != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  installHint!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontFamily: 'monospace',
                    color: tokens?.textBrandPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Diagnostics opt-out surfaced on the sandbox/security onboarding step.
///
/// Defaults to enabled; toggling it writes the same preference used by
/// Settings → Privacy (via [errorReportingEnabledProvider]) and only affects
/// release builds, where crash/error diagnostics would otherwise be sent.
class _DiagnosticsConsentRow extends ConsumerWidget {
  const _DiagnosticsConsentRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(errorReportingEnabledProvider);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          AppIcons.activity,
          size: 20,
          color: enabled ? tokens?.fgBrandPrimary : tokens?.fgTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingDiagnosticsTitle,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: tokens?.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.onboardingDiagnosticsSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: tokens?.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CcSwitch(
          value: enabled,
          onChanged: (v) =>
              ref.read(errorReportingEnabledProvider.notifier).setEnabled(value: v),
        ),
      ],
    );
  }
}
