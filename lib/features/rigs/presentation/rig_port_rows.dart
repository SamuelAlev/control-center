// The rows inside the forwarded-ports popover: one port, its menu, the
// add-a-port field and the auto-forward toggle.
//
// Split out of `rig_ports_panel.dart` so the panel is the popover and these
// are its contents.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigPortView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which source the ports popover is talking to: an exec rig or a host-shell
/// PTY session. Mutations and the watch key both branch on this.
class PortsTarget {
  /// An enclosed Terminal (VM) identified by [rigId].
  const PortsTarget.rig({required this.workspaceId, required String this.rigId})
    : sessionId = null,
      spaceId = '';

  /// A host-shell PTY identified by [sessionId] in [spaceId].
  const PortsTarget.session({
    required this.workspaceId,
    required String this.sessionId,
    required this.spaceId,
  }) : rigId = null;

  /// The owning workspace.
  final String workspaceId;

  /// Exec rig id, when this is a Terminal (VM).
  final String? rigId;

  /// Server PTY session id, when this is a host-shell.
  final String? sessionId;

  /// The conversation the session belongs to. Empty for an exec rig (the
  /// rig already carries its conversation).
  final String spaceId;

  /// Whether this target is a host-shell session.
  bool get isSession => sessionId != null;
}

/// One forwarded port: what is listening, every address it answers on, and
/// the menu of things that can be done to it.
class PortRow extends ConsumerWidget {
  /// Creates a [PortRow].
  const PortRow({
    super.key,
    required this.target,
    required this.port,
    this.domainTls = false,
    this.browserReachable = false,
    this.androidReachable = false,
  });

  /// The rig or host-shell this row belongs to.
  final PortsTarget target;

  /// The forwarded port this row describes.
  final RigPortView port;

  /// Whether the dev-domain router serves HTTPS, so the domain renders with
  /// the scheme it actually answers on.
  final bool domainTls;

  /// Whether a Browser (VM) in this space is attached.
  final bool browserReachable;

  /// Whether an Android rig in this space is attached.
  final bool androidReachable;

  Future<void> _copyLocalUrl(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final url = 'http://localhost:${port.hostPort}';
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      CcToastScope.of(context).show(l10n.rigPortsCopiedUrl(url));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final subtitleParts = <String>[
      if (port.process != null) port.process! else l10n.rigPortsProcessUnknown,
      if (!port.active) l10n.rigPortsInactive,
      l10n.rigPortsDestDesktop(port.hostPort),
      if (browserReachable)
        l10n.rigPortsDestBrowser(port.guestPort)
      else
        l10n.rigPortsDestBrowserUnreachable,
      if (androidReachable)
        l10n.rigPortsDestAndroid(port.guestPort)
      else
        l10n.rigPortsDestAndroidUnreachable,
      if (port.lanPort != null) l10n.rigPortsLanShared,
      if (port.domain != null)
        '${domainTls ? 'https' : 'http'}://${port.domain}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          CcStatusDot(
            tone: port.active ? CcStatusTone.positive : CcStatusTone.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${port.guestPort}',
                      style: CcTypography.bodySm.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Icon(
                        AppIcons.arrowRight,
                        size: 12,
                        color: t.fgQuaternary,
                      ),
                    ),
                    Text(
                      '${port.hostPort}',
                      style: CcTypography.bodySm.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ),
          CcIconButton(
            icon: AppIcons.copy,
            tooltip: l10n.rigPortsCopyUrl,
            onPressed: () => unawaited(_copyLocalUrl(context)),
          ),
          PortMenu(target: target, port: port),
        ],
      ),
    );
  }
}

/// The per-port overflow menu: expose on the LAN, set a dev domain, stop
/// forwarding.
class PortMenu extends ConsumerWidget {
  /// Creates a [PortMenu].
  const PortMenu({super.key, required this.target, required this.port});

  /// The rig or host-shell this menu acts on.
  final PortsTarget target;

  /// The port this menu acts on.
  final RigPortView port;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(rigRepositoryProvider);
    return CcMenu(
      items: [
        CcMenuItem(
          label: port.lanPort == null
              ? l10n.rigPortsExposeLan
              : l10n.rigPortsLanPrivate,
          icon: AppIcons.globe,
          onSelected: () =>
              unawaited(_setLan(repo, exposed: port.lanPort == null)),
        ),
        CcMenuItem(
          label: l10n.rigPortsSetDomain,
          icon: AppIcons.link,
          onSelected: () => unawaited(_promptDomain(context, repo)),
        ),
        CcMenuItem(
          label: l10n.rigPortsStopForward,
          icon: AppIcons.x,
          destructive: true,
          onSelected: () => unawaited(_remove(repo)),
        ),
      ],
      target: CcIcon(
        AppIcons.moreHorizontal,
        size: 16,
        color: (context.designSystem ?? DesignSystemTokens.light()).fgSecondary,
      ),
    );
  }

  Future<void> _setLan(RemoteRigRepository repo, {required bool exposed}) {
    if (target.isSession) {
      return repo.setTerminalPortLan(
        target.workspaceId,
        target.sessionId!,
        spaceId: target.spaceId,
        guestPort: port.guestPort,
        exposed: exposed,
      );
    }
    return repo.setPortLan(
      target.workspaceId,
      target.rigId!,
      port.guestPort,
      exposed: exposed,
    );
  }

  Future<void> _remove(RemoteRigRepository repo) {
    if (target.isSession) {
      return repo.removeTerminalPort(
        target.workspaceId,
        target.sessionId!,
        spaceId: target.spaceId,
        guestPort: port.guestPort,
      );
    }
    return repo.removePort(target.workspaceId, target.rigId!, port.guestPort);
  }

  Future<void> _promptDomain(
    BuildContext context,
    RemoteRigRepository repo,
  ) async {
    final value = await showCcDialog<String?>(
      context: context,
      builder: (context) => DomainDialog(initial: port.domain ?? ''),
    );
    // A null result is "cancelled"; an empty string is "clear the domain".
    if (value == null) {
      return;
    }
    final domain = value.trim();
    try {
      if (target.isSession) {
        await repo.setTerminalPortDomain(
          target.workspaceId,
          target.sessionId!,
          spaceId: target.spaceId,
          guestPort: port.guestPort,
          domain: domain.isEmpty ? null : domain,
        );
      } else {
        await repo.setPortDomain(
          target.workspaceId,
          target.rigId!,
          port.guestPort,
          domain.isEmpty ? null : domain,
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }
}

/// A one-field dialog for a port's dev domain. Pops the entered value (empty
/// to clear), or null on cancel.
class DomainDialog extends StatefulWidget {
  /// Creates a [DomainDialog].
  const DomainDialog({super.key, required this.initial});

  /// The domain currently assigned, or empty when there is none.
  final String initial;

  @override
  State<DomainDialog> createState() => _DomainDialogState();
}

class _DomainDialogState extends State<DomainDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: l10n.rigPortsSetDomain,
      onClose: () => Navigator.of(context).pop(),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.rigPortsDomainHint,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          CcTextField(
            controller: _controller,
            autofocus: true,
            hintText: 'myapp.test',
            onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
          ),
        ],
      ),
    );
  }
}

/// The "forward another port" field at the foot of the popover.
class AddPortRow extends ConsumerStatefulWidget {
  /// Creates an [AddPortRow].
  const AddPortRow({super.key, required this.target});

  /// The rig or host-shell to forward a port on.
  final PortsTarget target;

  @override
  ConsumerState<AddPortRow> createState() => _AddPortRowState();
}

class _AddPortRowState extends ConsumerState<AddPortRow> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _local = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    _local.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final port = int.tryParse(_controller.text.trim());
    if (port == null || port <= 0 || port > 65535 || _adding) {
      return;
    }
    final localText = _local.text.trim();
    final localPort = localText.isEmpty ? null : int.tryParse(localText);
    if (localText.isNotEmpty &&
        (localPort == null || localPort <= 0 || localPort > 65535)) {
      return;
    }
    setState(() => _adding = true);
    try {
      final repo = ref.read(rigRepositoryProvider);
      if (widget.target.isSession) {
        await repo.addTerminalPort(
          widget.target.workspaceId,
          widget.target.sessionId!,
          spaceId: widget.target.spaceId,
          guestPort: port,
          hostPort: localPort,
        );
      } else {
        await repo.addPort(
          widget.target.workspaceId,
          widget.target.rigId!,
          port,
        );
      }
      _controller.clear();
      _local.clear();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _controller,
                  hintText: widget.target.isSession
                      ? l10n.rigPortsAddHintHost
                      : l10n.rigPortsAddHint,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => unawaited(_add()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                loading: _adding,
                icon: AppIcons.plus,
                onPressed: () => unawaited(_add()),
                child: Text(l10n.rigPortsAdd),
              ),
            ],
          ),
          if (widget.target.isSession) ...[
            const SizedBox(height: AppSpacing.xs),
            CcTextField(
              controller: _local,
              hintText: l10n.rigPortsLocalPortHint,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => unawaited(_add()),
            ),
          ],
        ],
      ),
    );
  }
}

/// The auto-forward toggle: whether every port a guest opens is forwarded.
class AutoForwardRow extends ConsumerWidget {
  /// Creates an [AutoForwardRow].
  const AutoForwardRow({
    super.key,
    required this.target,
    required this.enabled,
  });

  /// The rig or host-shell this toggle applies to.
  final PortsTarget target;

  /// Whether auto-forwarding is on right now.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(AppIcons.sparkles, size: 14, color: t.fgSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.rigPortsAutoForward,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
          CcSwitch(
            value: enabled,
            onChanged: (next) => unawaited(_set(ref, next)),
          ),
        ],
      ),
    );
  }

  Future<void> _set(WidgetRef ref, bool next) {
    final repo = ref.read(rigRepositoryProvider);
    if (target.isSession) {
      return repo.setTerminalPortsAutoForward(
        target.workspaceId,
        target.sessionId!,
        spaceId: target.spaceId,
        enabled: next,
      );
    }
    return repo.setPortsAutoForward(
      target.workspaceId,
      target.rigId!,
      enabled: next,
    );
  }
}
