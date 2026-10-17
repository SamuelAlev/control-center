import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/permission_workspace.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/permissions` — inspect effective action policies; admins may edit rules
/// and inspect the authorization trail.
class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspace = ref.watch(activeWorkspaceIdProvider);
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.topbar,
                border: Border(bottom: BorderSide(color: t.borderSoft)),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
                child: Row(
                  children: [
                    PhoneIconButton(
                      icon: AppIcons.arrowLeft,
                      semanticLabel: l.back,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.permissionTitle,
                      style: CcTypography.body.copyWith(color: t.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: switch (workspace) {
                AsyncData(value: final String id) when id.isNotEmpty =>
                  WorkspacePermissions(key: ValueKey(id), workspaceId: id),
                AsyncError(error: final error) => _notice(
                  l.permissionWorkspaceFailed,
                  '$error',
                  l,
                  () => ref.invalidate(activeWorkspaceIdProvider),
                ),
                AsyncData() => _notice(
                  l.permissionNoWorkspace,
                  null,
                  l,
                  () => ref.invalidate(activeWorkspaceIdProvider),
                ),
                _ => Center(
                  child: Text(
                    l.permissionLoading,
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice(
    String title,
    String? detail,
    AppLocalizations l,
    VoidCallback retry,
  ) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      CcAlert(
        title: title,
        description: detail == null ? null : Text(detail),
        variant: CcAlertVariant.danger,
        action: CcButton(
          size: CcButtonSize.lg,
          onPressed: retry,
          child: Text(l.retry),
        ),
      ),
    ],
  );
}
