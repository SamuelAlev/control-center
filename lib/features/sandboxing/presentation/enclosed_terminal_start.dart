import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The pre-start body of a RESTORED enclosed (`microvm`) terminal tab.
///
/// A host-shell terminal costs a PTY, so it attaches on mount. An enclosed one
/// boots a virtual machine, and a persisted layout can hold several — three
/// tabs booting three VMs at launch, for shells nobody has asked for yet, is
/// the expensive surprise the rig tabs already refuse. So the tab restores with
/// its badge and this affordance; the shell opens on a press.
///
/// Deliberately the same shape as the rig tab's start screen: same icon
/// treatment, same hint-then-button rhythm, so the two read as one behaviour
/// rather than two accidents.
class EnclosedTerminalStart extends StatelessWidget {
  /// Creates an [EnclosedTerminalStart].
  const EnclosedTerminalStart({super.key, required this.onStart});

  /// Opens the shell (and boots the conversation's VM if it is not up).
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.terminal, size: 28, color: t.fgQuaternary),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.enclosedTerminalTitle,
                style: CcTypography.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.enclosedTerminalStartHint,
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
              const SizedBox(height: AppSpacing.lg),
              CcButton(
                onPressed: onStart,
                icon: AppIcons.play,
                child: Text(l10n.enclosedTerminalStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
