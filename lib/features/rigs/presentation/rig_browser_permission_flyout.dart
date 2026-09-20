// The browser toolbar's shield: network bypass plus site permissions.
//
// Headless guests cannot show a doorhanger. This flyout is the prompt. The
// first row is still "Allow all hosts" (VM egress). Everything under it is
// what the page asked for, and whether it was allowed or blocked.
library;

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_permission_flyout_body.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Shield trigger + popover listing network bypass and site permissions.
class RigBrowserPermissionFlyout extends StatefulWidget {
  /// Creates a [RigBrowserPermissionFlyout].
  const RigBrowserPermissionFlyout({
    super.key,
    required this.rig,
    required this.permissions,
    required this.onNetworkSecurity,
    required this.onRespond,
    this.networkRestarting = false,
  });

  /// The live browser rig (network state lives here).
  final RigView rig;

  /// Site permissions asked this session, newest last.
  final List<BrowserPermissionEntry> permissions;

  /// Opens the existing allow-all-hosts confirm.
  final VoidCallback onNetworkSecurity;

  /// Answers a pending site permission.
  final void Function(String requestId, {required bool allow}) onRespond;

  /// Whether the unrestricted replacement is being started.
  final bool networkRestarting;

  @override
  State<RigBrowserPermissionFlyout> createState() =>
      _RigBrowserPermissionFlyoutState();
}

class _RigBrowserPermissionFlyoutState
    extends State<RigBrowserPermissionFlyout> {
  final CcOverlayController _overlay = CcOverlayController();
  int _pendingSeen = 0;

  int get _pendingCount => widget.permissions
      .where((e) => e.decision == BrowserPermissionDecision.pending)
      .length;

  @override
  void initState() {
    super.initState();
    _pendingSeen = _pendingCount;
    if (_pendingCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _overlay.show();
        }
      });
    }
  }

  @override
  void didUpdateWidget(RigBrowserPermissionFlyout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pending = _pendingCount;
    if (pending > _pendingSeen) {
      _overlay.show();
    }
    _pendingSeen = pending;
  }

  @override
  void dispose() {
    _overlay.hide();
    _overlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final unrestricted = widget.rig.networkIsUnrestricted;
    final pending = _pendingCount > 0;
    final tooltip = pending
        ? l10n.rigBrowserPermissionsTooltip
        : unrestricted
        ? l10n.rigNetworkUnrestricted
        : l10n.rigBrowserPermissionsTooltip;
    final icon = widget.networkRestarting
        ? AppIcons.refreshCw
        : unrestricted
        ? AppIcons.shieldOff
        : pending
        ? AppIcons.shieldAlert
        : AppIcons.shield;
    final color = unrestricted
        ? t.fgWarningPrimary
        : pending
        ? t.accent
        : t.fgSecondary;

    return CcPopover(
      controller: _overlay,
      semanticLabel: tooltip,
      targetAnchor: AlignmentDirectional.bottomEnd,
      followerAnchor: AlignmentDirectional.topEnd,
      offset: const Offset(0, 6),
      target: CcTooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 16, color: color),
              if (pending)
                PositionedDirectional(
                  end: -5,
                  top: -5,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.bgPrimary, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      overlayBuilder: (context, _) => RigBrowserPermissionFlyoutBody(
        rig: widget.rig,
        permissions: widget.permissions,
        networkRestarting: widget.networkRestarting,
        onAllowAllHosts: () {
          _overlay.hide();
          widget.onNetworkSecurity();
        },
        onRespond: widget.onRespond,
      ),
    );
  }
}
