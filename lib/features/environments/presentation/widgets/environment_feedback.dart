import 'dart:async';

import 'package:cc_data/cc_data.dart' show RpcEnvironmentRepository;
import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host_approval.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The words for a refused environment call: an unapproved definition that
/// may not run on the server (`environment.host_unapproved`, by kind) in the
/// app's words for [owner] or anyone else, anything else as the server said.
String environmentRefusalMessage(
  AppLocalizations l10n,
  Object error, {
  required bool owner,
}) => isEnvironmentHostUnapproved(error)
    ? environmentHostUnapprovedMessage(l10n, owner: owner)
    : failureMessage(l10n, error);

/// The words for a failed save or approval of a definition: the owner-only
/// refusal (it places something on the server host) in the app's own words,
/// anything else as the server said it.
String environmentSaveFailureMessage(AppLocalizations l10n, Object error) =>
    error is ServerOwnerRequiredException
    ? l10n.environmentHostOwnerOnly
    : failureMessage(l10n, error);

/// Whether the controls of [key]'s environment may be pressed: only once the
/// server has said this person may operate it (`can_operate`). Everything
/// that starts, stops, restarts, launches or resets reads this, so a control
/// that would be refused is disabled instead of failing on press.
bool environmentOperable(WidgetRef ref, EnvironmentSpaceKey key) =>
    ref.watch(spaceEnvironmentCanOperateProvider(key)) ?? false;

/// Forwards one environment action and toasts its failure. Does nothing when
/// the server has said this person may not operate the environment.
Future<void> runEnvironmentAction(
  BuildContext context,
  WidgetRef ref,
  EnvironmentSpaceKey key,
  String action,
  Future<void> Function(RpcEnvironmentRepository repository) body,
) async {
  if (ref.read(spaceEnvironmentCanOperateProvider(key)) == false) {
    return;
  }
  final toasts = CcToastScope.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  final owner = ref.read(canUseHostProvider);
  try {
    await ref.read(environmentActionsProvider(key).notifier).run(action, body);
  } on Object catch (error) {
    toasts?.show(
      environmentRefusalMessage(l10n, error, owner: owner),
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

/// The one quiet line, under an environment's controls, for someone who may
/// watch it but not operate it. Renders nothing otherwise.
class EnvironmentOperateNote extends ConsumerWidget {
  /// Creates the note for [spaceKey]'s environment.
  const EnvironmentOperateNote({
    super.key,
    required this.spaceKey,
    this.padding = EdgeInsetsDirectional.zero,
  });

  /// The space whose environment it explains.
  final EnvironmentSpaceKey spaceKey;

  /// Space around the line, only while it shows.
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(spaceEnvironmentCanOperateProvider(spaceKey)) != false) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: padding,
      child: Text(
        AppLocalizations.of(context).environmentOperateNeedsWrite,
        textAlign: TextAlign.start,
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      ),
    );
  }
}
