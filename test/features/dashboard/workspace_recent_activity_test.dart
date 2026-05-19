import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/features/dashboard/providers/dashboard_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a fixed active workspace id, bypassing the persisted lookup.
class _FixedActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedActiveWorkspaceId(this._id);

  final String? _id;

  @override
  String? build() => _id;
}

/// Returns a fixed notification list, bypassing `shared_preferences`.
class _FixedNotificationCenter extends NotificationCenter {
  _FixedNotificationCenter(this._entries);

  final List<NotificationEntry> _entries;

  @override
  List<NotificationEntry> build() => _entries;
}

NotificationEntry _entry(String? workspaceId, String title) => NotificationEntry(
      notification: AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: title,
        body: '',
        route: '/',
        workspaceId: workspaceId,
      ),
      receivedAt: DateTime(2026, 6, 8),
    );

void main() {
  group('workspaceRecentActivityProvider (dashboard workspace isolation)', () {
    test('keeps only entries for the active workspace', () {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider
              .overrideWith(() => _FixedActiveWorkspaceId('w1')),
          notificationCenterProvider.overrideWith(
            () => _FixedNotificationCenter([
              _entry('w1', 'mine'),
              _entry('w2', 'other-workspace'),
              _entry(null, 'global-unattributed'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(workspaceRecentActivityProvider);

      // Other-workspace and null-workspace entries must not leak in.
      expect(result.map((e) => e.notification.title).toList(), ['mine']);
    });

    test('returns empty when no workspace is active', () {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider
              .overrideWith(() => _FixedActiveWorkspaceId(null)),
          notificationCenterProvider.overrideWith(
            () => _FixedNotificationCenter([_entry('w1', 'mine')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(workspaceRecentActivityProvider), isEmpty);
    });
  });
}
