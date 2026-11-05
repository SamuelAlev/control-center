// Composes the reminder for unanswered agent waits from the bell's feed and the
// OS notification service. Its own file because the bell providers already
// import `notification_providers.dart`.
library;

import 'package:control_center/app/app_window_focused.dart';
import 'package:control_center/core/notifications/agent_wait_reminder.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/shell/providers/notification_center_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-raises the OS notification for an agent wait nobody has answered and
/// withdraws it when the wait ends. Read once at session start to activate;
/// it then follows the active workspace's notification feed.
final agentWaitReminderProvider = Provider<AgentWaitReminder>((ref) {
  final reminder = AgentWaitReminder(
    port: ref.watch(desktopNotificationServiceProvider),
    // The same mapping, with the same mutes and identity, as the live toast
    // and the bell, so a reminder never says something they would not.
    render: (item) => mapNotificationFrame(
      item.method,
      item.params,
      l10n: notificationLocalizations(ref),
      currentUserId: ref.read(currentUserIdProvider),
      mutedRepos: ref.read(mutedReposProvider).value ?? const {},
      viewerLogins: ref.read(viewerLoginSetProvider),
    ),
    reminderTitle: (title) =>
        notificationLocalizations(ref).notificationWaitReminder(title),
    isAppFocused: appWindowFocused,
  );
  ref
    ..listen(notificationFeedProvider, (_, next) {
      final items = next.value;
      if (items != null) {
        reminder.update(items);
      }
    }, fireImmediately: true)
    ..onDispose(reminder.dispose);
  return reminder;
});
