import 'dart:async';

import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_browser_vm.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where an environment can be reached.
///
/// A URL is a row that opens when pressed. A bare port can't be opened, so the
/// ports share one line underneath rather than posing as links.
class EnvironmentEndpointRows extends ConsumerWidget {
  /// Creates an [EnvironmentEndpointRows].
  const EnvironmentEndpointRows({
    super.key,
    required this.spaceKey,
    required this.endpoints,
    this.host,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// The endpoints, in reported order.
  final List<EnvironmentEndpoint> endpoints;

  /// Overrides the inherited host, for a popover that lives in the root
  /// overlay and can't see it.
  final EnvironmentHost? host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final remote = ref.watch(environmentEndpointsAreRemoteProvider);
    final host = this.host ?? EnvironmentHostScope.maybeOf(context);
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final ports = [
      for (final endpoint in endpoints)
        if (endpoint.url == null && endpoint.hostPort != null) endpoint,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Said once: it is true of every row here.
        if (remote)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Text(l10n.environmentOnTheServer, style: caption),
          ),
        for (final endpoint in endpoints)
          if (endpoint.url != null)
            _EndpointRow(
              spaceKey: spaceKey,
              endpoint: endpoint,
              remote: remote,
              host: host,
            ),
        if (ports.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Wrap(
              spacing: AppSpacing.md,
              children: [
                for (final port in ports)
                  // RTL carve-out: an address reads left to right everywhere.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${port.label} ${port.hostPort}',
                      style: CcFonts.code(textStyle: caption),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EndpointRow extends ConsumerWidget {
  const _EndpointRow({
    required this.spaceKey,
    required this.endpoint,
    required this.remote,
    required this.host,
  });

  final EnvironmentSpaceKey spaceKey;
  final EnvironmentEndpoint endpoint;
  final bool remote;
  final EnvironmentHost? host;

  /// The address without its scheme: the host is what tells rows apart, and
  /// the sidebar has no width to spare.
  String _shown(String url) => url.replaceFirst(RegExp('^[a-z]+://'), '');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final url = endpoint.url!;
    final host = this.host;
    void openVm() => unawaited(
      openEndpointInBrowserVm(
        context,
        ref,
        spaceKey: spaceKey,
        url: url,
        host: host!,
      ),
    );
    void openTab() => host!.openUrl(url: url, label: endpoint.label);
    // A remote client can't resolve these names, so the remote-safe way leads.
    final open = host == null ? null : (remote ? openVm : openTab);
    return Row(
      children: [
        Expanded(
          child: CcTappable(
            onPressed: open,
            semanticLabel: endpoint.label,
            builder: (context, states) => Container(
              color: states.contains(WidgetState.hovered) ? t.hover : null,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endpoint.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: endpoint.primary
                          ? CcTypography.semiboldWeight
                          : null,
                    ),
                  ),
                  // RTL carve-out: a URL reads left to right in every locale.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _shown(url),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcFonts.code(
                        textStyle: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (host != null)
          CcIconButton(
            icon: remote ? AppIcons.externalLink : AppIcons.monitor,
            size: CcButtonSize.sm,
            tooltip: remote
                ? l10n.artifactOpenInTab
                : l10n.environmentOpenInBrowserVm,
            onPressed: remote ? openTab : openVm,
          ),
        CcIconButton(
          icon: AppIcons.copy,
          size: CcButtonSize.sm,
          tooltip: l10n.environmentCopyUrl,
          onPressed: () => copyEnvironmentText(context, url),
        ),
      ],
    );
  }
}
