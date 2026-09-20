import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Contents of the browser shield flyout.
class RigBrowserPermissionFlyoutBody extends StatelessWidget {
  /// Creates a [RigBrowserPermissionFlyoutBody].
  const RigBrowserPermissionFlyoutBody({
    super.key,
    required this.rig,
    required this.permissions,
    required this.networkRestarting,
    required this.onAllowAllHosts,
    required this.onRespond,
  });

  /// The live browser rig (network state lives here).
  final RigView rig;

  /// Site permissions asked this session, newest last.
  final List<BrowserPermissionEntry> permissions;

  /// Whether the unrestricted replacement is being started.
  final bool networkRestarting;

  /// Closes the flyout then opens the allow-all-hosts confirm.
  final VoidCallback onAllowAllHosts;

  /// Answers a pending site permission.
  final void Function(String requestId, {required bool allow}) onRespond;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pending = [
      for (final e in permissions)
        if (e.decision == BrowserPermissionDecision.pending) e,
    ];
    final decided = [
      for (final e in permissions.reversed)
        if (e.decision != BrowserPermissionDecision.pending) e,
    ];

    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.rigBrowserPermissionsTitle.toUpperCase(),
              style: CcTypography.caption.copyWith(
                color: t.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _AllowAllRow(
            unrestricted: rig.networkIsUnrestricted,
            restarting: networkRestarting,
            onPressed: networkRestarting ? null : onAllowAllHosts,
          ),
          const CcDivider(),
          if (permissions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                l10n.rigBrowserPermissionEmpty,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                children: [
                  for (final e in pending)
                    _PendingRow(entry: e, onRespond: onRespond),
                  for (final e in decided) _DecidedRow(entry: e),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AllowAllRow extends StatelessWidget {
  const _AllowAllRow({
    required this.unrestricted,
    required this.restarting,
    required this.onPressed,
  });

  final bool unrestricted;
  final bool restarting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: unrestricted
          ? l10n.rigNetworkUnrestricted
          : l10n.rigNetworkAllowAllHosts,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              unrestricted ? AppIcons.shieldOff : AppIcons.shield,
              size: 16,
              color: unrestricted ? t.fgWarningPrimary : t.fgSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                unrestricted
                    ? l10n.rigNetworkUnrestricted
                    : l10n.rigNetworkAllowAllHosts,
                style: CcTypography.body.copyWith(color: t.textPrimary),
              ),
            ),
            if (restarting) const CcSpinner(size: 14),
          ],
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.entry, required this.onRespond});

  final BrowserPermissionEntry entry;
  final void Function(String requestId, {required bool allow}) onRespond;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final label = browserPermissionKindLabel(l10n, entry.kind);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                browserPermissionKindIcon(entry.kind),
                size: 16,
                color: t.fgSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.rigBrowserPermissionPrompt(entry.originLabel, label),
                  style: CcTypography.body.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const SizedBox(width: 24),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.success,
                onPressed: () => onRespond(entry.id, allow: true),
                child: Text(l10n.allow),
              ),
              const SizedBox(width: AppSpacing.xs),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                onPressed: () => onRespond(entry.id, allow: false),
                child: Text(l10n.rigBrowserPermissionBlock),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecidedRow extends StatelessWidget {
  const _DecidedRow({required this.entry});

  final BrowserPermissionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final granted = entry.decision == BrowserPermissionDecision.granted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            browserPermissionKindIcon(entry.kind),
            size: 16,
            color: t.fgSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${entry.originLabel} · ${browserPermissionKindLabel(l10n, entry.kind)}',
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
          CcStatusTag(
            label: granted ? l10n.allowed : l10n.blocked,
            tone: granted ? CcStatusTone.positive : CcStatusTone.neutral,
          ),
        ],
      ),
    );
  }
}

/// Icon for a site permission kind.
IconData browserPermissionKindIcon(BrowserPermissionKind kind) =>
    switch (kind) {
      BrowserPermissionKind.camera => AppIcons.video,
      BrowserPermissionKind.microphone => AppIcons.mic,
      BrowserPermissionKind.notifications => AppIcons.bell,
      BrowserPermissionKind.geolocation => AppIcons.mapPin,
      BrowserPermissionKind.persistentStorage => AppIcons.folder,
      BrowserPermissionKind.clipboard => AppIcons.clipboard,
      BrowserPermissionKind.displayCapture => AppIcons.monitor,
      BrowserPermissionKind.midi => AppIcons.radio,
    };

/// Localized label for a site permission kind.
String browserPermissionKindLabel(
  AppLocalizations l10n,
  BrowserPermissionKind kind,
) => switch (kind) {
  BrowserPermissionKind.camera => l10n.rigBrowserPermissionCamera,
  BrowserPermissionKind.microphone => l10n.rigBrowserPermissionMicrophone,
  BrowserPermissionKind.notifications => l10n.rigBrowserPermissionNotifications,
  BrowserPermissionKind.geolocation => l10n.rigBrowserPermissionGeolocation,
  BrowserPermissionKind.persistentStorage =>
    l10n.rigBrowserPermissionPersistentStorage,
  BrowserPermissionKind.clipboard => l10n.rigBrowserPermissionClipboard,
  BrowserPermissionKind.displayCapture =>
    l10n.rigBrowserPermissionDisplayCapture,
  BrowserPermissionKind.midi => l10n.rigBrowserPermissionMidi,
};
