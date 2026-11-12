import 'dart:async';

import 'package:cc_data/cc_data.dart' show ConnectModeSetting, ConnectStatus;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The command-line equivalent of this card, for a headless server.
const String kConnectCliHint =
    'cc_server connect status | enable [--url] | disable';

/// This server's identity on Connect and the operations on it: the install
/// id to hand to an allowlist or an org owner, a configuration test, a key
/// rotation (here only), and the CLI for the rest from a terminal.
class ConnectServerActions extends ConsumerStatefulWidget {
  /// Creates the actions.
  const ConnectServerActions({super.key, required this.status});

  /// The current status.
  final ConnectStatus status;

  @override
  ConsumerState<ConnectServerActions> createState() =>
      _ConnectServerActionsState();
}

class _ConnectServerActionsState extends ConsumerState<ConnectServerActions> {
  bool _testing = false;
  bool _rotating = false;

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _testing = true);
    try {
      final status = await ConnectSettingsActions(ref).test();
      if (mounted) {
        final ok = status.usable;
        CcToastScope.maybeOf(context)?.show(
          ok ? l10n.connectTestOk : l10n.connectHealthDown,
          variant: ok ? CcToastVariant.success : CcToastVariant.danger,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(failureMessage(l10n, e), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _rotate() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.connectRotateKeyTitle,
        content: Text(l10n.connectRotateKeyBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.connectRotateKey),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _rotateKey(force: false);
  }

  /// A Connect could not retire the old key, so nothing changed. Shows the
  /// server's account of which Connect failed and how, and offers to rotate
  /// anyway, saying what that leaves behind.
  Future<void> _offerForce(String reason) async {
    final l10n = AppLocalizations.of(context);
    final force = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.connectRotateKeyRetireFailedTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.connectRotateKeyForceBody),
          ],
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.connectRotateKeyAnyway),
          ),
        ],
      ),
    );
    if (force == true && mounted) {
      await _rotateKey(force: true);
    }
  }

  Future<void> _rotateKey({required bool force}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _rotating = true);
    String? retireFailure;
    try {
      await ConnectSettingsActions(ref).rotateKey(force: force);
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.connectRotateKeyDone, variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      // A Connect that could not retire the old key answers `validation`,
      // naming each Connect and its error code: offer to rotate anyway.
      if (!force && e is RemoteRpcException) {
        if (e.code == RpcErrorCodes.validation) {
          retireFailure = e.message;
        }
      }
      if (retireFailure == null && mounted) {
        // Nothing changed: the rotation was refused whole. The button stays
        // for another try.
        CcToastScope.maybeOf(context)?.show(
          storageRefusalMessage(l10n, e) ??
              l10n.connectRotateKeyFailed(
                e is RemoteRpcException ? e.message : '$e',
              ),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _rotating = false);
      }
    }
    if (retireFailure case final reason? when mounted) {
      await _offerForce(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = widget.status;
    final active =
        status.mode == ConnectModeSetting.hosted ||
        status.mode == ConnectModeSetting.custom;
    return SettingsGroup(
      title: l10n.connectServerGroup,
      gap: AppSpacing.md,
      children: [
        SettingsField(
          label: l10n.connectInstallId,
          description: l10n.connectInstallIdHint,
          layout: SettingsFieldLayout.stacked,
          child: SettingsCopyField(
            value: status.installId,
            emptyLabel: l10n.connectInstallIdEmpty,
          ),
        ),
        if (active)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                icon: AppIcons.refreshCw,
                loading: _testing,
                onPressed: _testing ? null : () => unawaited(_test()),
                child: Text(l10n.testLabel),
              ),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                icon: AppIcons.keyRound,
                loading: _rotating,
                onPressed: _rotating ? null : () => unawaited(_rotate()),
                child: Text(l10n.connectRotateKey),
              ),
            ],
          ),
        SettingsField(
          label: l10n.connectCliLabel,
          layout: SettingsFieldLayout.stacked,
          child: const SettingsCopyField(value: kConnectCliHint),
        ),
      ],
    );
  }
}
