import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/memory/presentation/screens/memory_screen.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}) =>
    ProviderScope(
      overrides: [
        activeWorkspaceIdProvider.overrideWith(
          () => _FixedWorkspaceId(workspaceId),
        ),
        memoryFactsProvider(workspaceId)
            .overrideWith((ref) => Stream.value(facts)),
        memoryPoliciesProvider(workspaceId)
            .overrideWith((ref) => Stream.value(policies)),
      ],
      child: testWrap(const MemoryScreen()),
    );

void main() {
  testWidgets('renders memory tabs', (tester) async {
    await tester.pumpWidget(_wrap(workspaceId: 'ws1'));
    await tester.pumpAndSettle();

    expect(find.text('Facts'), findsOneWidget);
    expect(find.text('Policies'), findsOneWidget);
    expect(find.text('Graph'), findsOneWidget);
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

    expect(find.text('No workspace'), findsOneWidget);
  });
}
