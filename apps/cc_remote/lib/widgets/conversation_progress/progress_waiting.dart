import 'package:cc_domain/cc_domain.dart' show AgentDto, MessageDto;
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/limit_park_card.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_remote/widgets/conversation_progress/wake_card.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the conversation waits for: each provider-limit park (live, or what
/// came of it, as its row records) and every other pending or held wake, earliest due first.
class ProgressWaiting extends ConsumerWidget {
  const ProgressWaiting({super.key, required this.scope});

  final ProgressScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final wakes = ref.watch(
      phoneConversationWakesProvider((
        workspaceId: scope.workspaceId,
        conversationId: scope.conversationId,
      )),
    );
    final messages =
        ref.watch(progressRecentMessagesProvider(scope)).value?.messages ??
        const <MessageDto>[];
    final agents = ref.watch(agentsProvider).value ?? const <AgentDto>[];
    String? agentName(String id) =>
        agents.where((a) => a.id == id).firstOrNull?.name;
    if (wakes.hasError) {
      return progressError(
        l,
        wakes.error!,
        () => ref.invalidate(
          phoneConversationWakesProvider((
            workspaceId: scope.workspaceId,
            conversationId: scope.conversationId,
          )),
        ),
      );
    }
    if (wakes.isLoading) return const CcSpinner(size: 18);
    final live = wakes.value ?? const <WakeView>[];
    final parks = limitParkRows(messages);
    final parkIds = {for (final p in parks) p.wakeId};
    final others = [
      for (final w in live)
        if (!parkIds.contains(w.id)) w,
    ]..sort((a, b) => a.notBefore.compareTo(b.notBefore));
    if (parks.isEmpty && others.isEmpty) {
      return Text(
        l.progressNothingWaiting,
        style: CcTypography.bodySm.copyWith(color: t.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final park in parks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LimitParkCard(
              key: ValueKey('park:${park.wakeId}'),
              row: park,
              wake: live.where((w) => w.id == park.wakeId).firstOrNull,
            ),
          ),
        for (final wake in others)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WakeCard(
              key: ValueKey('wake:${wake.id}'),
              wake: wake,
              agentName: agentName,
            ),
          ),
      ],
    );
  }
}
