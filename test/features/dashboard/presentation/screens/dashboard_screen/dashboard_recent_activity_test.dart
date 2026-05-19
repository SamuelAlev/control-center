import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_side_panels.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

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


void main() {
  testWidgets('renders panel header', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          workspacesProvider.overrideWith((ref) => const Stream<List<Workspace>>.empty()),
          // ActiveWorkspaceIdNotifier now reconciles against a Dao-backed
          // bootstrap list (composition flip), which would open the default
          // database here. Pin it so no DB/host is touched.
          activeWorkspaceIdProvider
              .overrideWith(() => _FixedActiveWorkspaceId(null)),
          notificationCenterProvider
              .overrideWith(() => _FixedNotificationCenter([])),
        ],
        child: testWrap(const DashboardRecentActivity(codeFont: 'Fira Code')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('renders empty state when no notifications', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          workspacesProvider.overrideWith((ref) => const Stream<List<Workspace>>.empty()),
          // ActiveWorkspaceIdNotifier now reconciles against a Dao-backed
          // bootstrap list (composition flip), which would open the default
          // database here. Pin it so no DB/host is touched.
          activeWorkspaceIdProvider
              .overrideWith(() => _FixedActiveWorkspaceId(null)),
          notificationCenterProvider
              .overrideWith(() => _FixedNotificationCenter([])),
        ],
        child: testWrap(const DashboardRecentActivity(codeFont: 'Fira Code')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No recent activity yet'), findsOneWidget);
  });

  testWidgets('renders with workspace id', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          workspacesProvider.overrideWith((ref) => const Stream<List<Workspace>>.empty()),
          activeWorkspaceIdProvider
              .overrideWith(() => _FixedActiveWorkspaceId('ws1')),
          notificationCenterProvider
              .overrideWith(() => _FixedNotificationCenter([])),
        ],
        child: testWrap(const DashboardRecentActivity(codeFont: 'Fira Code')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Recent activity'), findsOneWidget);
  });
}
