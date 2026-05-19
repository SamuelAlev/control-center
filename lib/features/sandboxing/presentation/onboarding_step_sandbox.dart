import 'dart:io';

import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/sandboxing/providers/is_wsl2_provider.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final accept = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.skipSandboxing),
        body: Text(
          l10n.skipSandboxingDialogContent,
          style: TextStyle(fontSize: 13, color: tokens?.textSecondary),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.of(ctx).pop(false),
                  variant: FButtonVariant.outline,
                  child: Text(l10n.keepSandboxing),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.of(ctx).pop(true),
                  variant: FButtonVariant.destructive,
                  child: Text(l10n.skipAcceptRisk),
                ),
              ],
            ),
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
        child: Center(child: FProgress()),
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
              subtitle: _platformDescription(),
              description: available ? null : native?.note,
              installHint: installHint,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                FButton(
                  onPress: widget.onBack,
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
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
                FButton(
                  onPress: available ? _useNative : null,
                  variant: available
                      ? FButtonVariant.primary
                      : FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
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

  String _platformDescription() {
    if (Platform.isMacOS) {
      return AppLocalizations.of(context).onboardingMacosDescription;
    }
    if (Platform.isLinux || ref.read(isWsl2Provider)) {
      return AppLocalizations.of(context).onboardingLinuxDescription;
    }
    return AppLocalizations.of(context).onboardingUnsupportedDescription;
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
          ready ? LucideIcons.shieldCheck : LucideIcons.shield,
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
