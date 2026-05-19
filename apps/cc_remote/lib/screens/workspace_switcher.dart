import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_remote/widgets/workspace_avatar.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The header control that shows the ACTIVE workspace (resolved reactively from
/// the persisted id + the live workspace list) and, on tap, opens the full-screen
/// [WorkspaceSwitcherScreen].
///
/// Because the session auto-selects + persists a workspace (falling back to the
/// first), this shows the workspace NAME as soon as one resolves — never a stale
/// "Choose workspace" while a workspace is in fact active.
class WorkspaceSwitcherButton extends ConsumerWidget {
  /// Creates a [WorkspaceSwitcherButton].
  const WorkspaceSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final activeId = ref.watch(activeWorkspaceIdProvider).value;
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    final active = _resolve(activeId, workspaces);
    final name = active?.name ?? (activeId == null ? null : 'Choose workspace');

    return CcTappable(
      onPressed: () => context.push('/workspaces'),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      builder: (context, states) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active != null)
                WorkspaceAvatar(
                  workspaceId: active.id,
                  name: active.name,
                  hasLogo: _hasLogo(active),
                  size: 20,
                )
              else
                Icon(AppIcons.layers, size: 16, color: t.fgSecondary),
              const SizedBox(width: 8),
              Text(
                name ?? 'Choose workspace',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: name == null ? t.fgTertiary : t.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronDown, size: 14, color: t.fgTertiary),
            ],
          ),
        );
      },
    );
  }

  WorkspaceDto? _resolve(String? activeId, List<WorkspaceDto> workspaces) {
    if (activeId == null) {
      return null;
    }
    for (final w in workspaces) {
      if (w.id == activeId) {
        return w;
      }
    }
    return null;
  }
}

/// Whether the server holds a logo file for [w].
///
/// `logo_path` is a path on the SERVER's disk that a phone can neither read nor
/// resolve — its only use here is as the "a logo exists" flag that gates the
/// signed `/workspace/logo` fetch, so a logo-less workspace never spends a
/// request on a guaranteed 404.
bool _hasLogo(WorkspaceDto w) => (w.logoPath ?? '').isNotEmpty;

/// Full-screen workspace picker: lists the live workspaces and points the
/// session's active workspace at the chosen one (persisted; the stateless server
/// has no binding to set).
class WorkspaceSwitcherScreen extends ConsumerWidget {
  /// Creates a [WorkspaceSwitcherScreen].
  const WorkspaceSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final activeId = ref.watch(activeWorkspaceIdProvider).value;
    final async = ref.watch(workspacesProvider);

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, t),
            Expanded(child: _body(context, ref, t, async, activeId)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DesignSystemTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          PhoneIconButton(
            icon: AppIcons.arrowLeft,
            semanticLabel: 'Back',
            onPressed: () => context.pop(),
            color: t.fgSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Workspaces',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DesignSystemTokens t,
    AsyncValue<List<WorkspaceDto>> async,
    String? activeId,
  ) {
    return async.when(
      loading: () => const Center(child: CcSpinner(size: 22)),
      error: (e, _) => CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: "Couldn't load workspaces",
        description: e.toString(),
      ),
      data: (workspaces) {
        if (workspaces.isEmpty) {
          return const CcEmptyState(
            icon: AppIcons.layers,
            message: 'No workspaces yet',
          );
        }
        return ListView(
          children: [
            for (final w in workspaces)
              CcCard(
                interactive: true,
                semanticLabel: 'Select ${w.name}',
                onPressed: () {
                  ref.read(remoteSessionProvider).setActiveWorkspace(w.id);
                  context.pop();
                },
                child: Row(
                  children: [
                    WorkspaceAvatar(
                      workspaceId: w.id,
                      name: w.name,
                      hasLogo: _hasLogo(w),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.name,
                        style: TextStyle(fontSize: 15, color: t.textPrimary),
                      ),
                    ),
                    if (w.id == activeId)
                      Icon(AppIcons.check, size: 18, color: t.accent),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
