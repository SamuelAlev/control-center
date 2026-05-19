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

/// One forwarded port: what is listening, every address it answers on, and
/// the menu of things that can be done to it.
class PortRow extends ConsumerWidget {
  /// Creates a [PortRow].
  const PortRow({
    super.key,
    required this.workspaceId,
    required this.rigId,
    required this.port,
    this.domainTls = false,
  });

  /// The workspace the rig belongs to.
  final String workspaceId;

  /// The rig whose port this is.
  final String rigId;

  /// The forwarded port this row describes.
  final RigPortView port;

  /// Whether the dev-domain router serves HTTPS, so the domain renders with
  /// the scheme it actually answers on.
  final bool domainTls;

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
                    maxLines: 1,
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
          PortMenu(workspaceId: workspaceId, rigId: rigId, port: port),
        ],
      ),
    );
  }
}

/// The per-port overflow menu: expose on the LAN, set a dev domain, stop
/// forwarding.
///
/// A `ConsumerWidget` that resolves its repository through `ref`, rather than
/// receiving one as widget config. Data access travelling as a constructor
/// argument is how a widget ends up holding a handle its own subtree can no
/// longer see the provenance of.
class PortMenu extends ConsumerWidget {
  /// Creates a [PortMenu].
  const PortMenu({
    super.key,
    required this.workspaceId,
    required this.rigId,
    required this.port,
  });

  /// The workspace the rig belongs to.
  final String workspaceId;

  /// The rig whose port this is.
  final String rigId;

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
          onSelected: () => unawaited(
            repo.setPortLan(
              workspaceId,
              rigId,
              port.guestPort,
              exposed: port.lanPort == null,
            ),
          ),
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
          onSelected: () =>
              unawaited(repo.removePort(workspaceId, rigId, port.guestPort)),
        ),
      ],
      target: Icon(
        AppIcons.moreHorizontal,
        size: 16,
        color: (context.designSystem ?? DesignSystemTokens.light()).fgSecondary,
      ),
    );
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
      await repo.setPortDomain(
        workspaceId,
        rigId,
        port.guestPort,
        domain.isEmpty ? null : domain,
      );
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
  const AddPortRow({super.key, required this.workspaceId, required this.rigId});

  /// The workspace the rig belongs to.
  final String workspaceId;

  /// The rig to forward a port on.
  final String rigId;

  @override
  ConsumerState<AddPortRow> createState() => _AddPortRowState();
}

class _AddPortRowState extends ConsumerState<AddPortRow> {
  final TextEditingController _controller = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final port = int.tryParse(_controller.text.trim());
    if (port == null || port <= 0 || port > 65535 || _adding) {
      return;
    }
    setState(() => _adding = true);
    try {
      await ref
          .read(rigRepositoryProvider)
          .addPort(widget.workspaceId, widget.rigId, port);
      _controller.clear();
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
      child: Row(
        children: [
          Expanded(
            child: CcTextField(
              controller: _controller,
              hintText: l10n.rigPortsAddHint,
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
    );
  }
}

/// The auto-forward toggle: whether every port a guest opens is forwarded.
class AutoForwardRow extends ConsumerWidget {
  /// Creates an [AutoForwardRow].
  const AutoForwardRow({
    super.key,
    required this.workspaceId,
    required this.rigId,
    required this.enabled,
  });

  /// The workspace the rig belongs to.
  final String workspaceId;

  /// The rig this toggle applies to.
  final String rigId;

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
            onChanged: (next) => unawaited(
              ref
                  .read(rigRepositoryProvider)
                  .setPortsAutoForward(workspaceId, rigId, enabled: next),
            ),
          ),
        ],
      ),
    );
  }
}
