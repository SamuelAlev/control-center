import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Stops an asynchronous workspace redirect displaying the previous scope.
class WorkspaceRouteGate extends ConsumerWidget {
  const WorkspaceRouteGate({
    required this.workspaceId,
    required this.child,
    super.key,
  });
  final String? workspaceId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId != null && active.value != workspaceId) {
      return const Center(child: CcSpinner());
    }
    return KeyedSubtree(key: ValueKey(active.value), child: child);
  }
}

class RemoteDetailPage extends StatelessWidget {
  const RemoteDetailPage({required this.title, required this.child, super.key});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        DetailHeader(title: title),
        Expanded(child: child),
      ],
    ),
  );
}

class RemoteUnavailablePage extends StatelessWidget {
  const RemoteUnavailablePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CcEmptyState(
            icon: AppIcons.triangleAlert,
            message: l10n.mobileWorkspaceUnavailable,
          ),
          CcButton(
            size: CcButtonSize.lg,
            onPressed: () => context.go('/workspaces'),
            child: Text(l10n.workspaces),
          ),
        ],
      ),
    );
  }
}
