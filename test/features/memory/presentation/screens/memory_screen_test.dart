import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/memory/presentation/screens/memory_screen.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

Widget _wrap({
  required String workspaceId,
  List<MemoryFact> facts = const [],
  List<MemoryPolicy> policies = const [],
  List<ImprovementProposalView> improvements = const [],
}) => ProviderScope(
  overrides: [
    activeWorkspaceIdProvider.overrideWith(
      () => _FixedWorkspaceId(workspaceId),
    ),
    memoryFactsProvider(workspaceId).overrideWith((ref) => Stream.value(facts)),
    memoryPoliciesProvider(
      workspaceId,
    ).overrideWith((ref) => Stream.value(policies)),
    workspaceImprovementsProvider(
      workspaceId,
    ).overrideWith((ref) => Stream.value(improvements)),
  ],
  child: testWrap(const MemoryScreen()),
);

void main() {
  testWidgets('renders memory tabs', (tester) async {
    await tester.pumpWidget(_wrap(workspaceId: 'ws1'));
    await tester.pumpAndSettle();

    expect(find.text('Facts'), findsOneWidget);
    expect(find.text('Policies'), findsOneWidget);
    expect(find.text('Improvements'), findsOneWidget);
    expect(find.text('Knowledge graph'), findsOneWidget);
  });

  testWidgets('shows no-workspace message when null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId(null)),
        ],
        child: testWrap(const MemoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a workspace to view its memory.'), findsOneWidget);
  });
}
