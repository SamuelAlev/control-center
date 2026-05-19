// The three non-running states of a rig tab: not started, coming up, and
// cannot run here.
//
// Split out of `rig_tab_pane.dart` so the pane is the state machine and these
// are the pictures it chooses between.
library;

import 'package:cc_data/cc_data.dart' show RigBackendView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pre-start state: what this will do, and one button that does it.
class RigStart extends ConsumerWidget {
  /// Creates a [RigStart].
  const RigStart({
    super.key,
    required this.surface,
    required this.starting,
    required this.error,
    required this.onStart,
  });

  /// Which machine this tab would open.
  final String surface;

  /// Whether the open call is in flight.
  final bool starting;

  /// The last failure, when there was one.
  final String? error;

  /// Opens the machine.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(rigCapabilitiesProvider);

    return capabilities.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => RigNotice(text: l10n.failedWithError('$e')),
      data: (backends) {
        final hosting = _backendFor(backends, surface);
        if (hosting == null) {
          // Hiding beats disabling, but a TAB the user opened deliberately
          // needs to say why it is empty — and what would fix it.
          return RigUnavailable(backends: backends, surface: surface);
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  RigTabSurfaces.iconFor(surface),
                  size: 28,
                  color: t.fgQuaternary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  RigTabSurfaces.labelFor(l10n, surface),
                  style: CcTypography.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.rigStartHint,
                  textAlign: TextAlign.center,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                if (!hosting.enforcedEgress) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.rigEgressNotEnforced,
                    textAlign: TextAlign.center,
                    style: CcTypography.caption.copyWith(color: t.warn),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CcButton(
                  loading: starting,
                  onPressed: onStart,
                  icon: AppIcons.play,
                  child: Text(l10n.rigStartMachine),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: CcTypography.caption.copyWith(color: t.danger),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static RigBackendView? _backendFor(
    List<RigBackendView> backends,
    String surface,
  ) {
    for (final backend in backends) {
      if (backend.available && backend.surfaces.contains(surface)) {
        return backend;
      }
    }
    return null;
  }
}

/// Why this surface cannot run here, with the fix if there is one.
class RigUnavailable extends StatelessWidget {
  /// Creates a [RigUnavailable].
  const RigUnavailable({
    super.key,
    required this.backends,
    required this.surface,
  });

  /// What this host reported it can boot.
  final List<RigBackendView> backends;

  /// The surface the tab asked for.
  final String surface;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    // The most useful thing to show is the backend that came closest: one that
    // needs installing beats "unavailable" with no next step.
    RigBackendView? best;
    for (final backend in backends) {
      if (backend.installHint != null || backend.missingImages.isNotEmpty) {
        best = backend;
        break;
      }
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.triangleAlert, size: 24, color: t.fgQuaternary),
              const SizedBox(height: AppSpacing.md),
              Text(
                backends.isEmpty
                    ? l10n.rigsUnsupportedServer
                    : best?.note ?? l10n.rigSurfaceUnavailable,
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
              if (best?.installHint != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  best!.installHint!,
                  textAlign: TextAlign.center,
                  style: CcTypography.caption.copyWith(color: t.accent),
                ),
              ],
              if ((best?.missingImages ?? const []).isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.rigImagesMissing(best!.missingImages.length),
                  textAlign: TextAlign.center,
                  style: CcTypography.caption.copyWith(color: t.warn),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A centred line of explanation where a machine would otherwise be.
class RigNotice extends StatelessWidget {
  /// Creates a [RigNotice].
  const RigNotice({super.key, required this.text});

  /// What to say.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ),
    );
  }
}

/// The booting state: which stage the machine is in, as the server reports it.
class RigProgress extends StatelessWidget {
  /// Creates a [RigProgress].
  const RigProgress({super.key, required this.surface, required this.detail});

  /// Which machine is coming up.
  final String surface;

  /// The server's own description of the current boot step.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CcSpinner(),
            const SizedBox(height: AppSpacing.md),
            Text(
              // NOT `'\${label} — \${l10n.rigPhaseStarting.toLowerCase()}'`:
              // `toLowerCase` is locale-independent in Dart, so Turkish
              // "İ" becomes "i̇" and Azeri behaves the same way. The two
              // localized strings are concatenated as they were written.
              '${RigTabSurfaces.labelFor(l10n, surface)} — '
              '${l10n.rigPhaseStarting}',
              style: CcTypography.body.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
