import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/server_discovery.dart'
    if (dart.library.js_interop) 'package:control_center/core/server/server_discovery_web.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A suffix affordance for the server-URL field: scans for `cc_server`
/// instances on the LAN (mDNS) and the tailnet (Tailscale peers), badges the
/// button with the found count so a reachable server is glanceable, and opens
/// the servers-list dialog on tap. Selecting a server reports it through
/// [onSelected] (the caller fills the URL field with `server.rpcUrl`).
///
/// Desktop-oriented: on web the combined discovery stub returns nothing, so
/// the badge never appears and the dialog shows the empty state — callers may
/// hide the button on web entirely.
class ServerDiscoveryButton extends StatefulWidget {
  /// Creates a [ServerDiscoveryButton].
  const ServerDiscoveryButton({
    super.key,
    required this.onSelected,
    this.discovery = const ServerDiscovery(),
    this.excludeServerIds = const {},
  });

  /// Called with the server picked in the dialog.
  final ValueChanged<DiscoveredServer> onSelected;

  /// The discovery backend — injectable so tests can substitute a fake (the
  /// real one needs multicast and the `tailscale` CLI).
  final ServerDiscovery discovery;

  /// Server ids to hide from the results (e.g. already-paired servers in the
  /// settings add-server flow).
  final Set<String> excludeServerIds;

  @override
  State<ServerDiscoveryButton> createState() => _ServerDiscoveryButtonState();
}

class _ServerDiscoveryButtonState extends State<ServerDiscoveryButton> {
  List<DiscoveredServer> _servers = const [];
  StreamSubscription<List<DiscoveredServer>>? _scan;

  @override
  void initState() {
    super.initState();
    // One background scan on mount: keeps the found-count badge fresh so a
    // reachable server is visible without opening the dialog, and seeds the
    // dialog so it paints instantly instead of re-scanning from zero.
    _scan = widget.discovery.watch().listen((servers) {
      if (mounted) {
        setState(() => _servers = servers);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _scan?.cancel();
    super.dispose();
  }

  List<DiscoveredServer> get _visible => _servers
      .where((s) => !widget.excludeServerIds.contains(s.serverId))
      .toList(growable: false);

  Future<void> _openDialog() async {
    final selected = await showServerDiscoveryDialog(
      context,
      discovery: widget.discovery,
      initialServers: _servers,
      excludeServerIds: widget.excludeServerIds,
    );
    if (selected != null) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final button = CcIconButton(
      icon: AppIcons.radio,
      size: CcButtonSize.sm,
      tooltip: l10n.serverDiscoveryTooltip,
      onPressed: _openDialog,
    );
    final count = _visible.length;
    if (count == 0) {
      return button;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -4,
          right: -4,
          child: IgnorePointer(
            child: CcBadge(label: '$count', variant: CcBadgeVariant.brand),
          ),
        ),
      ],
    );
  }
}

/// Opens the servers-list dialog: every `cc_server` found on the LAN and the
/// tailnet, refreshing live while open. Resolves with the picked server, or
/// null when dismissed.
///
/// [initialServers] seeds the list (typically the caller's own background
/// scan) so the dialog paints instantly; a fresh scan runs regardless and
/// updates the list as results land.
Future<DiscoveredServer?> showServerDiscoveryDialog(
  BuildContext context, {
  ServerDiscovery discovery = const ServerDiscovery(),
  List<DiscoveredServer> initialServers = const [],
  Set<String> excludeServerIds = const {},
}) {
  return showCcDialog<DiscoveredServer>(
    context: context,
    builder: (dialogContext) => _ServerDiscoveryDialog(
      discovery: discovery,
      initialServers: initialServers,
      excludeServerIds: excludeServerIds,
    ),
  );
}

class _ServerDiscoveryDialog extends StatefulWidget {
  const _ServerDiscoveryDialog({
    required this.discovery,
    required this.initialServers,
    required this.excludeServerIds,
  });

  final ServerDiscovery discovery;
  final List<DiscoveredServer> initialServers;
  final Set<String> excludeServerIds;

  @override
  State<_ServerDiscoveryDialog> createState() => _ServerDiscoveryDialogState();
}

class _ServerDiscoveryDialogState extends State<_ServerDiscoveryDialog> {
  late List<DiscoveredServer> _servers = _filter(widget.initialServers);
  late bool _scanning = true;
  StreamSubscription<List<DiscoveredServer>>? _scanSub;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  List<DiscoveredServer> _filter(List<DiscoveredServer> servers) => servers
      .where((s) => !widget.excludeServerIds.contains(s.serverId))
      .toList(growable: false);

  void _scan() {
    final generation = ++_generation;
    _scanSub?.cancel();
    // Keep the current list while refreshing — only the spinner state flips.
    setState(() => _scanning = true);
    // Tracks whether THIS scan produced any server: a refresh that finds
    // nothing must clear stale rows (the server may have stopped), which the
    // stream alone no longer signals (empty snapshots are suppressed).
    var emitted = false;
    _scanSub = widget.discovery.watch().listen(
      (servers) {
        if (!mounted || generation != _generation) {
          return;
        }
        emitted = true;
        setState(() => _servers = _filter(servers));
      },
      onError: (_) {},
      onDone: () {
        if (mounted && generation == _generation) {
          setState(() {
            if (!emitted) {
              _servers = const [];
            }
            _scanning = false;
          });
        }
      },
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: l10n.serverDiscoveryTitle,
      onClose: () => Navigator.of(context).pop(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_servers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                children: [
                  if (_scanning) ...[
                    Icon(AppIcons.loaderCircle, size: 16, color: t.fgTertiary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      _scanning
                          ? l10n.serverDiscoverySearching
                          : l10n.serverDiscoveryEmpty,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _servers.length; i++)
                      _ServerResultRow(
                        server: _servers[i],
                        autofocus: i == 0,
                        onTap: () => Navigator.of(context).pop(_servers[i]),
                      ),
                  ],
                ),
              ),
            ),
          if (_scanning && _servers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(AppIcons.loaderCircle, size: 14, color: t.fgTertiary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.serverDiscoverySearching,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          onPressed: _scanning ? null : _scan,
          variant: CcButtonVariant.secondary,
          child: Text(l10n.serverDiscoveryRefresh),
        ),
      ],
    );
  }
}

/// One discovered-server row: name, `host:port`, and a source badge
/// (LAN / tailnet). Tap picks the server and closes the dialog. Built on
/// [CcTappable] so it is pointer- AND keyboard-operable (focus ring,
/// Enter/Space activation, semantic button).
class _ServerResultRow extends StatelessWidget {
  const _ServerResultRow({
    required this.server,
    required this.onTap,
    this.autofocus = false,
  });

  final DiscoveredServer server;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    const radius = BorderRadius.all(Radius.circular(8));
    return CcTappable(
      onPressed: onTap,
      autofocus: autofocus,
      borderRadius: radius,
      semanticLabel: '${server.name} ${server.host}:${server.port}',
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: hovered ? t.bgSecondary : const Color(0x00000000),
            borderRadius: radius,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(AppIcons.radio, size: 18, color: t.fgTertiary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${server.host}:${server.port}',
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcBadge(
                label: switch (server.source) {
                  DiscoverySource.local => l10n.connectionPathLocal,
                  DiscoverySource.lan => l10n.connectionPathLan,
                  DiscoverySource.tailscale => l10n.connectionPathTailnet,
                },
                variant: server.source == DiscoverySource.tailscale
                    ? CcBadgeVariant.info
                    : CcBadgeVariant.neutral,
              ),
            ],
          ),
        );
      },
    );
  }
}
