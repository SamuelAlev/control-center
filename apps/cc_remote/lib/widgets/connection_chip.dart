import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact connection-state chip for the header: a [CcBadge] that reflects
/// the live [RemoteUiState].
///
/// Sentence case throughout. Colour carries status but the label always states
/// it in words too (never colour alone).
class ConnectionChip extends ConsumerWidget {
  /// Creates a [ConnectionChip].
  const ConnectionChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remoteUiStateProvider);
    final session = ref.read(remoteSessionProvider);
    final state = async.value ?? session.currentUiState;

    final (label, variant, icon) = _resolve(AppLocalizations.of(context), state);
    return CcBadge(label: label, variant: variant, icon: icon);
  }

  (String, CcBadgeVariant, IconData?) _resolve(
    AppLocalizations l10n,
    RemoteUiState state,
  ) {
    switch (state.status) {
      case RemoteStatus.connected:
        return (
          l10n.statusConnected,
          CcBadgeVariant.success,
          AppIcons.circleCheck,
        );
      case RemoteStatus.connecting:
        return (l10n.statusConnecting, CcBadgeVariant.info, null);
      case RemoteStatus.connectionFailed:
        return (l10n.statusOffline, CcBadgeVariant.warning, AppIcons.wifiOff);
      case RemoteStatus.identityMismatch:
        return (
          l10n.statusIdentityMismatch,
          CcBadgeVariant.danger,
          AppIcons.triangleAlert,
        );
      case RemoteStatus.notPaired:
        return (
          l10n.statusNotPaired,
          CcBadgeVariant.neutral,
          AppIcons.scanLine,
        );
      case RemoteStatus.pendingPairing:
        return (
          l10n.statusConfirmPairing,
          CcBadgeVariant.info,
          AppIcons.scanLine,
        );
    }
  }
}
