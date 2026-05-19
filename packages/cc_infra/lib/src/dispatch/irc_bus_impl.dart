import 'dart:async';

import 'package:cc_domain/core/utils/cancellation_token.dart';
import 'package:cc_domain/features/dispatch/domain/irc/irc_bus.dart';
import 'package:cc_domain/features/dispatch/domain/irc/irc_message.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_lifecycle.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:uuid/uuid.dart';

/// Mailbox-backed implementation of [IrcBus].
///
/// Holds per-agent mailboxes (cap [_mailboxCap], oldest dropped) and pending
/// waiters. Resolves recipients through the [AgentRegistry], reviving parked
/// recipients through the [AgentLifecycleManager], and hands live sessions
/// their message through the injected [AgentMessageSinkResolver] — falling back
/// to buffering when no live sink exists. Every send is workspace-scoped: a
/// cross-workspace send fails, honoring the isolation boundary.
class IrcBusImpl implements IrcBus {
  /// Creates an [IrcBusImpl].
  ///
  /// [lifecycle] is consulted only to revive a parked recipient; pass null to
  /// disable revival (a parked recipient then fails delivery). [sinkResolver]
  /// resolves a recipient's live-session sink; when null (or it returns null)
  /// delivery falls back to mailbox buffering.
  IrcBusImpl(
    this._registry, {
    AgentLifecycleManager? lifecycle,
    AgentMessageSinkResolver? sinkResolver,
    Uuid? uuid,
  })  : _lifecycle = lifecycle,
        _sinkResolver = sinkResolver,
        _uuid = uuid ?? const Uuid();

  /// Per-agent mailbox cap; oldest messages are dropped beyond it.
  static const int _mailboxCap = 100;

  final AgentRegistry _registry;
  final AgentLifecycleManager? _lifecycle;
  final AgentMessageSinkResolver? _sinkResolver;
  final Uuid _uuid;

  final Map<String, List<IrcMessage>> _mailboxes = {};
  final Map<String, List<_IrcWaiter>> _waiters = {};

  @override
  Future<IrcDeliveryReceipt> send({
    required String from,
    required String to,
    required String body,
    String? replyTo,
    bool expectsReply = false,
  }) async {
    final recipient = _registry.get(to);
    if (recipient == null || recipient.status == AgentStatus.aborted) {
      return IrcDeliveryReceipt(
        to: to,
        outcome: IrcDeliveryOutcome.failed,
        error: 'Unknown or terminated agent "$to".',
      );
    }
    // Advisor refs are observability-only transcripts, never messageable peers.
    if (recipient.kind == AgentKind.advisor) {
      return IrcDeliveryReceipt(
        to: to,
        outcome: IrcDeliveryOutcome.failed,
        error: 'Agent "$to" is a read-only advisor transcript '
            'and cannot be messaged.',
      );
    }
    // Workspace isolation: a send only crosses agents in the same workspace.
    final sender = _registry.get(from);
    if (sender != null && sender.workspaceId != recipient.workspaceId) {
      return IrcDeliveryReceipt(
        to: to,
        outcome: IrcDeliveryOutcome.failed,
        error: 'Agent "$to" belongs to a different workspace.',
      );
    }

    final message = IrcMessage(
      id: _uuid.v4(),
      from: from,
      to: to,
      body: body,
      ts: DateTime.now().millisecondsSinceEpoch,
      replyTo: replyTo,
    );

    var revived = false;
    if (recipient.status == AgentStatus.parked) {
      final lifecycle = _lifecycle;
      if (lifecycle == null) {
        return IrcDeliveryReceipt(
          to: to,
          outcome: IrcDeliveryOutcome.failed,
          error: 'Agent "$to" is parked and no reviver is available.',
        );
      }
      try {
        await lifecycle.ensureLive(to);
        revived = true;
      } on Object catch (error) {
        return IrcDeliveryReceipt(
          to: to,
          outcome: IrcDeliveryOutcome.failed,
          error: error.toString(),
        );
      }
    }

    // A pending wait consumes the message directly — it never hits the mailbox.
    final waiter = _takeMatchingWaiter(to, from);
    if (waiter != null) {
      waiter.resolve(message);
      return IrcDeliveryReceipt(
        to: to,
        outcome: revived ? IrcDeliveryOutcome.revived : IrcDeliveryOutcome.injected,
      );
    }

    // Hand off to the live session sink when one exists; otherwise buffer.
    final sink = _sinkResolver?.call(to);
    if (sink != null) {
      try {
        final delivery = await sink.deliver(message, expectsReply: expectsReply);
        return IrcDeliveryReceipt(
          to: to,
          outcome: revived ? IrcDeliveryOutcome.revived : delivery,
        );
      } on Object catch (error) {
        // Live hand-off failed: buffer so a later wait/inbox can still pick it
        // up. The receipt stays failed — the recipient has not seen it.
        _enqueue(message);
        return IrcDeliveryReceipt(
          to: to,
          outcome: IrcDeliveryOutcome.failed,
          error: error.toString(),
        );
      }
    }

    // No live sink (the common case for a CLI-dispatched agent): buffer the
    // message for the recipient to drain via `wait`/`inbox`.
    _enqueue(message);
    return IrcDeliveryReceipt(
      to: to,
      outcome: revived ? IrcDeliveryOutcome.revived : IrcDeliveryOutcome.failed,
      error: revived ? null : 'Buffered for "$to" (no live session).',
    );
  }

  @override
  Future<IrcMessage?> wait(
    String agentId, {
    String? from,
    required int timeoutMs,
    CancellationToken? signal,
    bool drainPending = true,
  }) {
    if (signal != null && signal.isCancelled) {
      return Future<IrcMessage?>.error(CancelledException(signal.reason));
    }
    if (drainPending) {
      final pending = _takeFromMailbox(agentId, from);
      if (pending != null) {
        return Future<IrcMessage?>.value(pending);
      }
    }

    final completer = Completer<IrcMessage?>();
    Timer? timer;
    StreamSubscription<void>? abortSub;

    final waiter = _IrcWaiter(from: from);
    void cleanup() {
      _removeWaiter(agentId, waiter);
      timer?.cancel();
      unawaited(abortSub?.cancel());
    }

    waiter.onResolve = (message) {
      if (completer.isCompleted) {
        return;
      }
      cleanup();
      completer.complete(message);
    };

    if (signal != null) {
      abortSub = signal.whenCancelled.asStream().listen((_) {
        if (completer.isCompleted) {
          return;
        }
        cleanup();
        completer.completeError(CancelledException(signal.reason));
      });
    }
    if (timeoutMs > 0) {
      timer = Timer(Duration(milliseconds: timeoutMs), () {
        if (completer.isCompleted) {
          return;
        }
        cleanup();
        completer.complete(null);
      });
    }

    (_waiters[agentId] ??= []).add(waiter);
    return completer.future;
  }

  @override
  List<IrcMessage> inbox(String agentId, {bool peek = false}) {
    final mailbox = _mailboxes[agentId];
    if (mailbox == null || mailbox.isEmpty) {
      return const [];
    }
    if (peek) {
      return List.unmodifiable(mailbox);
    }
    _mailboxes.remove(agentId);
    return mailbox;
  }

  @override
  int unreadCount(String agentId) => _mailboxes[agentId]?.length ?? 0;

  void _enqueue(IrcMessage message) {
    final mailbox = _mailboxes.putIfAbsent(message.to, () => []);
    mailbox.add(message);
    if (mailbox.length > _mailboxCap) {
      mailbox.removeAt(0);
    }
  }

  /// Resolves the OLDEST waiter for [agentId] whose from-filter accepts [from].
  _IrcWaiter? _takeMatchingWaiter(String agentId, String from) {
    final waiters = _waiters[agentId];
    if (waiters == null) {
      return null;
    }
    final index =
        waiters.indexWhere((w) => w.from == null || w.from == from);
    if (index == -1) {
      return null;
    }
    final waiter = waiters.removeAt(index);
    if (waiters.isEmpty) {
      _waiters.remove(agentId);
    }
    return waiter;
  }

  void _removeWaiter(String agentId, _IrcWaiter waiter) {
    final waiters = _waiters[agentId];
    if (waiters == null) {
      return;
    }
    waiters.remove(waiter);
    if (waiters.isEmpty) {
      _waiters.remove(agentId);
    }
  }

  IrcMessage? _takeFromMailbox(String agentId, String? from) {
    final mailbox = _mailboxes[agentId];
    if (mailbox == null || mailbox.isEmpty) {
      return null;
    }
    final index = from == null ? 0 : mailbox.indexWhere((m) => m.from == from);
    if (index == -1) {
      return null;
    }
    final message = mailbox.removeAt(index);
    if (mailbox.isEmpty) {
      _mailboxes.remove(agentId);
    }
    return message;
  }
}

class _IrcWaiter {
  _IrcWaiter({this.from});

  final String? from;
  void Function(IrcMessage message)? onResolve;

  void resolve(IrcMessage message) => onResolve?.call(message);
}
