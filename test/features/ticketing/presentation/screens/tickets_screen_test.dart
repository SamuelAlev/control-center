import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:control_center/features/ticketing/presentation/screens/tickets_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

void main() {
  testWidgets('renders empty state when no workspace', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspacesProvider.overrideWith((ref) => const Stream<List<Workspace>>.empty()),
          activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId(null)),
        ],
        child: testWrap(const TicketsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(TicketsScreen), findsOneWidget);
    expect(find.text('No tickets yet'), findsOneWidget);
  });

}
