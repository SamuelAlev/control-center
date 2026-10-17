import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CredentialBlockCard extends ConsumerStatefulWidget {
  const CredentialBlockCard({super.key, required this.block});
  final RunCredentialBlockDto block;

  @override
  ConsumerState<CredentialBlockCard> createState() =>
      _CredentialBlockCardState();
}

class _CredentialBlockCardState extends ConsumerState<CredentialBlockCard> {
  bool _working = false;
  String? _error;

  Future<void> _resolve({required bool cancel}) async {
    final l10n = AppLocalizations.of(context);
    if (_working || ref.read(workspaceRoleProvider).value?.canWrite != true) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    final workspaceId = ref.read(activeWorkspaceIdProvider).value;
    if (client == null ||
        workspaceId == null ||
        widget.block.workspaceId != workspaceId) {
      setState(() => _error = l10n.requestUnavailable);
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final gate = RemoteCredentialGateRepository(client);
      final ok = cancel
          ? await gate.cancel(widget.block.id)
          : await gate.retry(widget.block.id);
      if (!ok) throw StateError(l10n.requestAlreadyResolved);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final enabled =
        !_working && ref.watch(workspaceRoleProvider).value?.canWrite == true;
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            block.agentName ?? l10n.inboxCredentialsBlocked,
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(block.detail, style: TextStyle(color: t.textSecondary)),
          if (_error != null)
            Text(_error!, style: TextStyle(color: t.textErrorPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.secondary,
                  onPressed: enabled ? () => _resolve(cancel: true) : null,
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.primary,
                  onPressed: enabled ? () => _resolve(cancel: false) : null,
                  child: Text(l10n.retry),
                ),
              ),
            ],
          ),
          if (block.workspaceId != null) ...[
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.ghost,
              onPressed: () => context.push(
                remoteWorkspaceLocation('/credentials', block.workspaceId!),
              ),
              child: Text(l10n.inboxConfigureCredentials),
            ),
            if (block.spaceId != null)
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.ghost,
                onPressed: () => context.push(
                  remoteSpaceLocation(
                    workspaceId: block.workspaceId!,
                    spaceId: block.spaceId!,
                    conversationId: block.conversationId,
                  ),
                ),
                child: Text(l10n.openConversation),
              ),
          ],
        ],
      ),
    );
  }
}
