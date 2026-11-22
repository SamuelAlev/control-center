import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show MessageDto;
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [message] is steering the server held because its run stopped.
bool isHeldSteering(MessageDto message) =>
    message.messageType == 'steering' &&
    message.metadata is Map &&
    (message.metadata as Map)['steerState'] == 'held';

Map<dynamic, dynamic> _meta(MessageDto m) =>
    m.metadata is Map ? m.metadata as Map : const {};

/// Who holds a held card (`steerHeldBy`): `stop` (the person's Stop) or
/// `limit:<runId>` (a run paused at a provider's usage limit).
String? heldSteeringHolder(MessageDto message) {
  final holder = _meta(message)['steerHeldBy'];
  return holder is String && holder.isNotEmpty ? holder : null;
}

/// When the provider said its limit resets, on a card a pause holds.
DateTime? heldSteeringResetsAt(MessageDto message) {
  final at = _meta(message)['steerLimitResetsAt'];
  return at is String ? DateTime.tryParse(at) : null;
}

/// Held steering, by who holds it. Stop's cards (a person's Stop, or a run
/// that ended at a usage limit with no pause): their order, and "Send held
/// messages" (`steering.release` with `held_by: stop`) only for a viewer
/// with a card of their own there, because the server sends only the
/// caller's own cards. A pause's cards, one group per pause with its own
/// reset: they wait for that pause; no manual send. A card with no holder this version knows can only be removed.
/// Anyone may remove any card. A card someone else wrote (`sender_id`
/// against the signed-in person, the server's own rule for who sends) says
/// whose it is.
class HeldSteering extends ConsumerStatefulWidget {
  const HeldSteering({
    super.key,
    required this.scope,
    required this.messages,
    required this.canWrite,
  });

  final RemoteConversationKey scope;
  final List<MessageDto> messages;
  final bool canWrite;

  @override
  ConsumerState<HeldSteering> createState() => _HeldSteeringState();
}

class _HeldSteeringState extends ConsumerState<HeldSteering> {
  bool _busy = false;
  Object? _error;

  List<MessageDto> get _ordered => [...widget.messages]
    ..sort((a, b) {
      num order(MessageDto m) => m.metadata is Map
          ? ((m.metadata as Map)['steerOrder'] as num? ?? 0)
          : 0;
      return order(a).compareTo(order(b));
    });

  Future<void> _run(Future<void> Function() action) async {
    final scope = widget.scope;
    if (_busy ||
        !widget.canWrite ||
        ref.read(activeWorkspaceIdProvider).value != scope.workspaceId) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _release() async {
    final repo = ref.read(phoneHeldSteeringRepositoryProvider);
    if (repo == null) return;
    final scope = widget.scope;
    await _run(
      () => repo.release(
        workspaceId: scope.workspaceId,
        spaceId: scope.spaceId,
        conversationId: scope.conversationId,
      ),
    );
  }

  Future<void> _delete(MessageDto message) async {
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    final scope = widget.scope;
    await _run(() async {
      final removed = await RemoteMessagingDispatch(client).deleteSteering(
        workspaceId: scope.workspaceId,
        spaceId: scope.spaceId,
        conversationId: scope.conversationId,
        messageId: message.id,
      );
      if (!removed && mounted) {
        throw StateError(AppLocalizations.of(context).mobileQueueChanged);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    ref
      ..watch(activeWorkspaceIdProvider)
      ..watch(rpcClientProvider);
    final me = ref.watch(remoteIdentityProvider).value?.userId;
    final users = ref.watch(remoteUsersProvider).value ?? const {};
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    bool mine(MessageDto m) => me != null && m.senderId == me;
    String? writer(MessageDto m) {
      if (mine(m)) return null;
      final user = users[m.senderId];
      if (user == null) return l.teammate;
      return inertText(
        user.displayName.isNotEmpty ? user.displayName : '@${user.handle}',
        singleLine: true,
      );
    }

    final ordered = _ordered;
    final byStop = [
      for (final m in ordered)
        if (heldSteeringHolder(m) == 'stop') m,
    ];
    final byLimit = [
      for (final m in ordered)
        if (heldSteeringHolder(m)?.startsWith('limit:') ?? false) m,
    ];
    final other = [
      for (final m in ordered)
        if (!byStop.contains(m) && !byLimit.contains(m)) m,
    ];
    // One group per pause (`limit:<runId>`), in the order its first card
    // appears, each with that pause's own reset: the earliest any of its
    // cards carries.
    final pauses = <String, List<MessageDto>>{};
    for (final m in byLimit) {
      (pauses[heldSteeringHolder(m)!] ??= []).add(m);
    }
    DateTime? resetOf(List<MessageDto> cards) {
      DateTime? earliest;
      for (final m in cards) {
        final at = heldSteeringResetsAt(m);
        if (at != null && (earliest == null || at.isBefore(earliest))) {
          earliest = at;
        }
      }
      return earliest;
    }

    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (byStop.isNotEmpty)
          _group(
            context,
            byStop.any(mine) ? l.heldSteeringTitle : l.heldSteeringOthersTitle,
            byStop,
            writer,
            release: byStop.any(mine),
            onlyYours: byStop.any(mine) && !byStop.every(mine),
          ),
        for (final cards in pauses.values)
          if (resetOf(cards) case final at)
            _group(
              context,
              at == null
                  ? l.heldSteeringLimitTitle
                  : l.heldSteeringLimitAt(workTime(context, at)),
              cards,
              writer,
            ),
        if (other.isNotEmpty)
          _group(context, l.heldSteeringOtherTitle, other, writer),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: error is StateError
                ? Text(
                    error.message,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textErrorPrimary,
                    ),
                  )
                : WorkFailureLine(error: error),
          ),
      ],
    );
  }

  Widget _group(
    BuildContext context,
    String title,
    List<MessageDto> messages,
    String? Function(MessageDto) writer, {
    bool release = false,
    bool onlyYours = false,
  }) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 8),
            for (final message in messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WorkQuote(message.content, maxLines: 4),
                          if (writer(message) case final name?)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 11,
                                top: 2,
                              ),
                              child: Text(
                                l.heldSteeringWrittenBy(name),
                                style: CcTypography.caption.copyWith(
                                  color: t.textTertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.canWrite)
                      CcButton(
                        size: CcButtonSize.lg,
                        variant: CcButtonVariant.ghost,
                        onPressed: _busy ? null : () => _delete(message),
                        child: Text(l.mobileRemove),
                      ),
                  ],
                ),
              ),
            if (release && widget.canWrite && onlyYours)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l.heldSteeringOnlyYours,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
              ),
            if (release && widget.canWrite)
              CcButton(
                fullWidth: true,
                size: CcButtonSize.lg,
                loading: _busy,
                onPressed: _busy ? null : _release,
                child: Text(l.heldSteeringRelease),
              ),
          ],
        ),
      ),
    );
  }
}
