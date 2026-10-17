import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/requests_activity_providers.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OperationLinks extends ConsumerWidget {
  const OperationLinks({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspace = ref.watch(activeWorkspaceIdProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final link in <(String, String, IconData)>[
          ('/activity', l10n.mobileActivity, CcIcons.bell),
          ('/plans', l10n.mobilePlans, AppIcons.fileText),
          ('/goals', l10n.mobileGoals, AppIcons.bot),
          ('/permissions', l10n.mobilePermissions, CcIcons.lock),
          ('/credentials', l10n.mobileCredentials, CcIcons.keyRound),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              icon: link.$3,
              fullWidth: true,
              onPressed: workspace == null
                  ? null
                  : () => context.push(
                      remoteWorkspaceLocation(link.$1, workspace),
                    ),
              child: Text(link.$2),
            ),
          ),
      ],
    );
  }
}

/// Durable unread activity is intentionally separate from the Needs you badge.
class ActivityButton extends ConsumerWidget {
  const ActivityButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadActivityCountProvider);
    final workspace = ref.watch(activeWorkspaceIdProvider).value;
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      children: [
        PhoneIconButton(
          icon: CcIcons.bell,
          semanticLabel: unread == 0
              ? l10n.mobileActivity
              : l10n.tabWaitingCount(l10n.mobileActivity, unread),
          onPressed: workspace == null
              ? null
              : () => context.push(
                  remoteWorkspaceLocation('/activity', workspace),
                ),
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 7,
            end: 7,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.accent,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
            ),
          ),
      ],
    );
  }
}
