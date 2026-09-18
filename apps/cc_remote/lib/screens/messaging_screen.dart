import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Messaging tab: live spaces (`messaging.watchSpaces`), each pushing a
/// realtime thread route.
class MessagingScreen extends ConsumerWidget {
  /// Creates a [MessagingScreen].
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(spacesProvider);

    return ColoredBox(
      color: t.canvas,
      child: async.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: l10n.spacesLoadFailed,
          description: e.toString(),
        ),
        data: (spaces) {
          if (spaces.isEmpty) {
            return CcEmptyState(
              icon: AppIcons.messageCircle,
              message: l10n.noSpaces,
              description: l10n.spacesEmptyDescription,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: spaces.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _spaceCard(context, t, spaces[i]),
          );
        },
      ),
    );
  }

  Widget _spaceCard(
    BuildContext context,
    DesignSystemTokens t,
    SpaceDto space,
  ) {
    return CcCard(
      interactive: true,
      semanticLabel: space.name,
      onPressed: () => context.push('/spaces/${space.id}'),
      child: Row(
        children: [
          Icon(AppIcons.hash, size: 18, color: t.fgSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              space.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
