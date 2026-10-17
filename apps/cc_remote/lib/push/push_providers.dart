import 'package:cc_remote/providers.dart';
import 'package:cc_remote/push/push_browser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const pushCategoryNames = <String>[
  'agentRunCompleted',
  'agentAwaitingInput',
  'newMessage',
  'pullRequestPublished',
  'prMerged',
  'prMentioned',
  'reviewRequested',
  'reviewStale',
  'prMergeReadiness',
  'prReviewDecision',
  'prChecksStatus',
  'prThreadActivity',
  'ticketAssigned',
  'ticketStatusChanged',
  'meetingStartsSoon',
  'calendarAuthExpired',
  'rigStatusChanged',
];

class RemotePushStatus {
  const RemotePushStatus({
    required this.enabled,
    required this.browserSubscribed,
    required this.permission,
    required this.unsupportedReason,
    required this.quiet,
    required this.categories,
    required this.vapidPublicKey,
  });
  final bool enabled;
  final bool browserSubscribed;
  final String permission;
  final String? unsupportedReason;
  final bool quiet;
  final Set<String> categories;
  final String vapidPublicKey;
}

final remotePushStatusProvider = FutureProvider<RemotePushStatus>((ref) async {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) throw StateError('Server disconnected');
  final status = await client.call('push.status', const {});
  const browser = BrowserPush();
  final subscription = await browser.existing();
  return RemotePushStatus(
    enabled: status['enabled'] == true,
    browserSubscribed: subscription != null,
    permission: browser.permission,
    unsupportedReason: browser.unsupportedReason,
    quiet: status['quiet'] == true,
    categories: (status['categories'] as List? ?? const [])
        .whereType<String>()
        .toSet(),
    vapidPublicKey: status['vapid_public_key'] as String,
  );
});

/// Enable via explicit UI gesture. Calling subscribe() is the FIRST async
/// action, so the browser permission prompt retains user activation.
Future<void> enableRemotePush(
  WidgetRef ref,
  RemotePushStatus status, {
  Set<String>? categories,
  bool? quiet,
}) async {
  final client = ref.read(rpcClientProvider).value;
  if (client == null) throw StateError('Server disconnected');
  final selection =
      categories ??
      (status.enabled ? status.categories : pushCategoryNames.toSet());
  // subscribe() starts the browser permission request synchronously, before
  // any RPC. Even a rejected prompt must refresh the reported permission.
  try {
    final subscription = await const BrowserPush().subscribe(
      status.vapidPublicKey,
    );
    try {
      await client.call('push.register', {
        'endpoint': subscription.endpoint,
        'p256dh': subscription.p256dh,
        'auth': subscription.auth,
        'categories': selection.toList(),
        'quiet': quiet ?? status.quiet,
      });
    } on Object {
      if (!status.enabled) await const BrowserPush().unsubscribe();
      rethrow;
    }
  } finally {
    ref.invalidate(remotePushStatusProvider);
  }
}

Future<void> disableRemotePush(WidgetRef ref) async {
  final client = ref.read(rpcClientProvider).value;
  if (client == null) throw StateError('Server disconnected');
  await client.call('push.remove', const {});
  await const BrowserPush().unsubscribe();
  ref.invalidate(remotePushStatusProvider);
}
