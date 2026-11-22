import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';

import 'fake_wake_repository.dart';
import 'fake_wake_rule_repository.dart';
import 'wake_rule_service_scenarios.dart';

class _FakeStores implements WakeRuleStores {
  @override
  final FakeWakeRepository wakes = FakeWakeRepository();

  @override
  final WakeRuleRepository rules = FakeWakeRuleRepository();

  @override
  Future<List<Wake>> all(String workspaceId) async => wakes.all(workspaceId);

  @override
  Future<void> close() async {}
}

/// The rule service's scenarios on the in-memory fakes; the same scenarios
/// run on the real repositories in `cc_server_core`.
void main() {
  wakeRuleServiceScenarios((clock) async => _FakeStores());
}
