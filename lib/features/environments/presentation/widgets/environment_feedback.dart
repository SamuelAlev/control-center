import 'dart:async';

import 'package:cc_data/cc_data.dart' show RpcEnvironmentRepository;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The readable part of a failed call.
String environmentFailureMessage(Object error) =>
    error is RemoteRpcException ? error.message : '$error';

/// Forwards one environment action and toasts its failure.
Future<void> runEnvironmentAction(
  BuildContext context,
  WidgetRef ref,
  EnvironmentSpaceKey key,
  String action,
  Future<void> Function(RpcEnvironmentRepository repository) body,
) async {
  final toasts = CcToastScope.maybeOf(context);
  try {
    await ref.read(environmentActionsProvider(key).notifier).run(action, body);
  } on Object catch (error) {
    toasts?.show(
      environmentFailureMessage(error),
      variant: CcToastVariant.danger,
    );
  }
}

/// Copies [text] and confirms it.
void copyEnvironmentText(BuildContext context, String text) {
  final l10n = AppLocalizations.of(context);
  final toasts = CcToastScope.maybeOf(context);
  unawaited(
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      toasts?.show(l10n.environmentCopied, variant: CcToastVariant.success);
    }),
  );
}
