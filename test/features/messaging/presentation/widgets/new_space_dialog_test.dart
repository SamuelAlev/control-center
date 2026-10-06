import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_rpc_client.dart';

class _Ws extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

void main() {
  // Regression: the handler awaited `ref.read(...future)` on providers nothing
  // else watched; Riverpod paused them, so the dialog never opened.
  testWidgets('sidebar + opens the dialog when nothing else watches agents', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/workspaces/ws-1/inbox',
      routes: [
        ShellRoute(
          builder: (_, _, child) => Scaffold(
            body: Row(
              children: [
                const SizedBox(
                  width: 280,
                  child: ConversationsSidebarSection(),
                ),
                Expanded(child: child),
              ],
            ),
          ),
          routes: [
            GoRoute(
              path: '/workspaces/:workspaceId/inbox',
              builder: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_Ws.new),
          rpcClientProvider.overrideWithValue(
            (FakeRpcHost()..onCall = (op, args) => const <String, dynamic>{})
                .client(),
          ),
          workspaceVisibleSpacesProvider('ws-1').overrideWithValue(const []),
          appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          workspaceAgentsProvider(
            'ws-1',
          ).overrideWith((ref) => Stream.value(const <Agent>[])),
          reposForWorkspaceProvider(
            'ws-1',
          ).overrideWith((ref) => Stream.value(const <Repo>[])),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final plus = find.byWidgetPredicate(
      (w) => w is CcIconButton && w.icon == AppIcons.plus,
    );
    expect(plus, findsOneWidget);
    await tester.tap(plus);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CcDialog), findsOneWidget);
  });
}
