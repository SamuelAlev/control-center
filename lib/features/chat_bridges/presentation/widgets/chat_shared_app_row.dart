import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInLaneMode;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Add Control Center to Slack": installs the shared Control Center app into
/// the provider-side workspace through [lane]'s browser sign-in, with
/// [workspaceId] as the slot that owns the grant.
///
/// The browser flow is the shared sign-in dialog, the same one every other
/// lane uses; this row only decides whether it can start. Renders nothing
/// until the server says who runs [lane] here, and says why when nobody can.
class ChatSharedAppRow extends ConsumerWidget {
  /// Creates a [ChatSharedAppRow].
  const ChatSharedAppRow({
    super.key,
    required this.lane,
    required this.workspaceId,
    required this.providerName,
    required this.canManage,
  });

  /// The shared-app install lane.
  final ConnectOAuthLane lane;

  /// The workspace the app is installed for.
  final String workspaceId;

  /// The provider's product name.
  final String providerName;

  /// Whether the reader may install it (workspace admins only).
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(oauthLanesProvider(workspaceId)).value?[lane];
    if (info == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final available = info.mode != SignInLaneMode.unavailable;
    final String subtitle;
    if (available) {
      subtitle = l10n.chatSharedAppHint(providerName);
    } else {
      // A sign-in nobody can start must say why, not just grey out.
      subtitle = signInUnavailableMessage(l10n, lane, info);
    }
    return SettingsRow(
      icon: AppIcons.sparkles,
      title: signInActionLabel(l10n, lane),
      subtitle: subtitle,
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        icon: AppIcons.plug,
        onPressed: available && canManage
            ? () => unawaited(
                showProviderSignInDialog(
                  context,
                  lane: lane,
                  workspaceId: workspaceId,
                ),
              )
            : null,
        child: Text(l10n.chatAddToProvider(providerName)),
      ),
    );
  }
}
