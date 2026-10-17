import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> openRemoteThread(
  BuildContext context,
  WidgetRef ref,
  MessageDto message,
) async {
  final workspace = ref.read(activeWorkspaceIdProvider).value;
  final client = ref.read(rpcClientProvider).value;
  final space = message.spaceId;
  final l = AppLocalizations.of(context);
  if (workspace == null || client == null || space == null || space.isEmpty) {
    throw StateError(l.requestUnavailable);
  }
  final repo = RpcConversationRepository(client);
  final conversations = await repo.listForSpace(
    workspaceId: workspace,
    spaceId: space,
  );
  if (!context.mounted ||
      ref.read(activeWorkspaceIdProvider).value != workspace) {
    return;
  }
  final existing = conversations
      .where((c) => c.anchorMessageId == message.id)
      .firstOrNull;
  final title = message.content.trim();
  final conversation =
      existing ??
      await repo.create(
        workspaceId: workspace,
        spaceId: space,
        title: title.isEmpty ? l.thread : title.characters.take(80).toString(),
        anchorMessageId: message.id,
      );
  if (context.mounted &&
      ref.read(activeWorkspaceIdProvider).value == workspace) {
    await context.push(
      remoteSpaceLocation(
        workspaceId: workspace,
        spaceId: space,
        conversationId: conversation.id,
      ),
    );
  }
}
