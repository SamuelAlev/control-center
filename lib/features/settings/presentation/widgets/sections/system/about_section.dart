import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/server_build_provider.dart';
import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Advanced → About: the build identity of this client and the
/// connected server, plus the desktop "Check for updates" action.
///
/// This is the truth surface of the version-identity work: one CI-stamped
/// const ([BuildInfo]) compiles into both the app and the server it spawns,
/// so a mismatch here is a REAL stale binary (a bundled `cc_server` that
/// predates the app), not a drifted hand-typed string. The updater itself is
/// separate: macOS/Windows prompt through Sparkle/WinSparkle (release notes
/// + explicit confirm), Linux opens the release page.
class AboutSection extends ConsumerWidget {
  /// Creates an [AboutSection].
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final server = ref.watch(serverBuildProvider);
    final older = serverOlderThanClient(server);
    final t = context.designSystem;
    final update = ref.watch(desktopUpdateProvider);

    return SectionCard(
      label: l10n.aboutTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VersionRow(
            label: l10n.aboutAppVersion,
            value: '${BuildInfo.buildVersion} (${BuildInfo.buildGitSha})',
          ),
          _VersionRow(
            label: l10n.aboutServerVersion,
            value: server?.version == null
                ? l10n.aboutServerUnknown
                : '${server!.version} (${server.gitSha ?? '—'})',
          ),
          if (server?.catalogVersion != null)
            _VersionRow(
              label: l10n.aboutRpcCatalog,
              value: 'v${server!.catalogVersion}',
            ),
          if (older == true) ...[
            const SizedBox(height: 8),
            CcAlert(
              title: l10n.serverStaleTitle,
              description: Text(
                l10n.serverStaleBody(
                  server!.version ?? '?',
                  BuildInfo.buildVersion,
                ),
              ),
              variant: CcAlertVariant.warning,
              icon: AppIcons.alertTriangle,
            ),
          ],
          if (!kIsWeb) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CcButton(
                  onPressed: () =>
                      ref.read(desktopUpdateProvider.notifier).checkNow(),
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.updateCheckButton),
                ),
                if (update.status != DesktopUpdateStatus.idle &&
                    update.status != DesktopUpdateStatus.available) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      switch (update.status) {
                        DesktopUpdateStatus.checking => l10n.updateChecking,
                        DesktopUpdateStatus.upToDate => l10n.updateUpToDate,
                        DesktopUpdateStatus.deferred => l10n.updateDeferredBusy,
                        DesktopUpdateStatus.openedReleasesPage =>
                          l10n.updateOpenedReleasesPage,
                        DesktopUpdateStatus.error =>
                          update.errorMessage ?? l10n.updateCheckFailed,
                        _ => '',
                      },
                      style: CcTypography.bodySm.copyWith(
                        color: t?.textTertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (update.status == DesktopUpdateStatus.available &&
                update.version != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.updateAvailableVersion(update.version!),
                style: CcTypography.bodySm.copyWith(color: t?.textPrimary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: CcTypography.bodySm.copyWith(color: t?.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: CcTypography.body.copyWith(color: t?.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
