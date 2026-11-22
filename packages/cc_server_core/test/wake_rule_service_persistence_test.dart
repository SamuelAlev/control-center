import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_persistence/cc_persistence.dart';

import '../../cc_infra/test/dispatch/wake_rule_service_scenarios.dart';
import 'helpers/test_database.dart';

/// The real repositories over in-memory workspace databases: what drift
/// reads back (whole seconds, as stored) is what the rule service compares.
class _DbStores implements WakeRuleStores {
  _DbStores(this._global, this._dbs, DateTime Function() clock)
    : wakes = DaoWakeRepository(_dbs, clock: clock),
      rules = DaoWakeRuleRepository(_dbs, clock: clock);

  final GlobalDatabase _global;
  final WorkspaceDatabaseManager _dbs;

  @override
  final DaoWakeRepository wakes;

  @override
  final DaoWakeRuleRepository rules;

  static const _conversations = {
    'ws-1': ['conv-1', 'conv-2'],
    'ws-2': ['conv-9'],
  };

  static Future<_DbStores> open(DateTime Function() clock) async {
    final global = createTestGlobalDatabase();
    final dbs = createTestWorkspaceDatabases(global: global);
    for (final (ws, agents, convs) in [
      ('ws-1', ['agent-1', 'agent-2'], {'conv-1': 'sp-1', 'conv-2': 'sp-2'}),
      ('ws-2', ['agent-1'], {'conv-9': 'sp-9'}),
    ]) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      for (final agent in agents) {
        await db.customStatement(
          'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
          "skills) VALUES (?, ?, 'Agent', '', ?, '')",
          [agent, agent, ws],
        );
      }
      for (final MapEntry(key: conv, value: space) in convs.entries) {
        await db.customStatement(
          'INSERT INTO spaces (id, name, workspace_id) VALUES (?, ?, ?)',
          [space, space, ws],
        );
        await db.customStatement(
          'INSERT INTO conversations (id, space_id, workspace_id) '
          'VALUES (?, ?, ?)',
          [conv, space, ws],
        );
      }
    }
    final t0 = DateTime.utc(2026, 5, 1);
    await DaoAgentGoalRunRepository(dbs).upsert(
      AgentGoalRun(
        id: 'goal-1',
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        userText: 'ship it',
        costCapMicros: 1000000,
        createdAt: t0,
        updatedAt: t0,
      ),
    );
    return _DbStores(global, dbs, clock);
  }

  @override
  Future<List<Wake>> all(String workspaceId) async => [
    for (final conv in _conversations[workspaceId] ?? const <String>[])
      ...await wakes.listForConversation(workspaceId, conv),
  ];

  @override
  Future<void> close() async {
    await _dbs.closeAll();
    await _global.close();
  }
}

/// Every scenario of `cc_infra`'s `wake_rule_service_test.dart`, on the
/// real repositories.
void main() {
  wakeRuleServiceScenarios(_DbStores.open);
}
