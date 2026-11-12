import 'package:cc_persistence/cc_persistence.dart';

// Parent rows for tests of the agent, run, ticket, pipeline and governance
// tables, whose foreign keys are enforced.
//
// Each helper inserts the smallest valid row with `INSERT OR IGNORE`, so a
// test can seed a parent it may already have created. The rows carry the
// database's own workspace id.

/// Seeds space [id].
Future<void> seedSpace(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO spaces (id, name, workspace_id) VALUES (?, ?, ?)',
  [id, 'Space $id', db.workspaceId],
);

/// Seeds conversation [id] in space [spaceId] (seeded too), or in a space
/// of the same id when none is named.
Future<void> seedConversation(
  WorkspaceDatabase db,
  String id, {
  String? spaceId,
}) async {
  final space = spaceId ?? id;
  await seedSpace(db, space);
  await db.customStatement(
    'INSERT OR IGNORE INTO conversations (id, space_id, workspace_id) '
    'VALUES (?, ?, ?)',
    [id, space, db.workspaceId],
  );
}

/// Seeds agent [id]. Agent names are unique in a file, so [name] defaults to
/// the id.
Future<void> seedAgent(WorkspaceDatabase db, String id, {String? name}) =>
    db.customStatement(
      'INSERT OR IGNORE INTO agents '
      '(id, name, title, agent_md_path, workspace_id, skills) '
      "VALUES (?, ?, 'Agent', '', ?, '')",
      [id, name ?? id, db.workspaceId],
    );

/// Seeds ticket [id].
Future<void> seedTicket(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO tickets (id, workspace_id, title) VALUES (?, ?, ?)',
  [id, db.workspaceId, 'Ticket $id'],
);

/// Seeds team [id].
Future<void> seedTeam(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO teams (id, workspace_id, name) VALUES (?, ?, ?)',
  [id, db.workspaceId, 'Team $id'],
);

/// Seeds project [id].
Future<void> seedProject(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO projects (id, workspace_id, name) '
  'VALUES (?, ?, ?)',
  [id, db.workspaceId, 'Project $id'],
);

/// Seeds pipeline template [id].
Future<void> seedPipelineTemplate(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO pipeline_templates (id, workspace_id, name) '
      'VALUES (?, ?, ?)',
      [id, db.workspaceId, 'Template $id'],
    );

/// Seeds pipeline trigger [id] of template [templateId] (seeded too). The
/// event type is the id, so several triggers of one template stay distinct.
Future<void> seedPipelineTrigger(
  WorkspaceDatabase db,
  String id, {
  String templateId = 'template',
}) async {
  await seedPipelineTemplate(db, templateId);
  await db.customStatement(
    'INSERT OR IGNORE INTO pipeline_triggers '
    '(id, event_type, template_id, workspace_id) VALUES (?, ?, ?, ?)',
    [id, id, templateId, db.workspaceId],
  );
}

/// Seeds pipeline run [id] of [templateId] (a run keeps no key to its
/// template, so the template is not seeded).
Future<void> seedPipelineRun(
  WorkspaceDatabase db,
  String id, {
  String templateId = 'template',
}) => db.customStatement(
  'INSERT OR IGNORE INTO pipeline_runs (id, template_id, workspace_id) '
  'VALUES (?, ?, ?)',
  [id, templateId, db.workspaceId],
);

/// Seeds run log [id] of agent [agentId] (seeded too).
Future<void> seedRunLog(
  WorkspaceDatabase db,
  String id, {
  String agentId = 'agent',
}) async {
  await seedAgent(db, agentId);
  await db.customStatement(
    'INSERT OR IGNORE INTO agent_run_logs (id, agent_id, workspace_id) '
    'VALUES (?, ?, ?)',
    [id, agentId, db.workspaceId],
  );
}

/// Seeds a finished run log [id] of agent [agentId] (seeded too), with
/// [status] (a terminal `RunStatus` name) and [completedAt], the two
/// columns the retention sweep selects on.
Future<void> seedFinishedRunLog(
  WorkspaceDatabase db,
  String id, {
  required DateTime completedAt,
  String agentId = 'agent',
  String status = 'completed',
}) async {
  await seedAgent(db, agentId);
  final seconds = completedAt.millisecondsSinceEpoch ~/ 1000;
  await db.customStatement(
    'INSERT OR IGNORE INTO agent_run_logs '
    '(id, agent_id, workspace_id, status, started_at, completed_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [id, agentId, db.workspaceId, status, seconds, seconds],
  );
}

/// Seeds cron execution [id] of trigger [triggerId] (seeded too, with its
/// template), planned and recorded at [at].
Future<void> seedCronExecution(
  WorkspaceDatabase db,
  String id, {
  required DateTime at,
  String triggerId = 'trigger',
  String status = 'fired',
}) async {
  await seedPipelineTrigger(db, triggerId);
  final seconds = at.millisecondsSinceEpoch ~/ 1000;
  await db.customStatement(
    'INSERT OR IGNORE INTO cron_executions '
    '(id, workspace_id, trigger_id, planned_at, status, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [id, db.workspaceId, triggerId, seconds, status, seconds],
  );
}

/// Seeds eval suite [id] (suite names are unique in a file, so the name is
/// the id).
Future<void> seedEvalSuite(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO eval_suites (id, workspace_id, name) '
      'VALUES (?, ?, ?)',
      [id, db.workspaceId, id],
    );

/// Seeds session recording [id] of run log [runLogId] (seeded too, with its
/// agent).
Future<void> seedSessionRecording(
  WorkspaceDatabase db,
  String id, {
  String runLogId = 'run',
}) async {
  await seedRunLog(db, runLogId);
  await db.customStatement(
    'INSERT OR IGNORE INTO session_recordings '
    "(id, workspace_id, run_log_id, config_hash) VALUES (?, ?, ?, 'hash')",
    [id, db.workspaceId, runLogId],
  );
}

/// Seeds budget policy [id] on the scope `agent:[id]`.
Future<void> seedBudgetPolicy(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO budget_policy '
      "(id, workspace_id, scope_type, scope_id) VALUES (?, ?, 'agent', ?)",
      [id, db.workspaceId, id],
    );

/// Seeds runtime profile [id].
Future<void> seedRuntimeProfile(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO runtime_profiles '
      "(id, workspace_id, name, command) VALUES (?, ?, ?, 'true')",
      [id, db.workspaceId, 'Profile $id'],
    );

/// Seeds every listed parent, by kind, for tests that write a child
/// with several references at once.
Future<void> seedParents(
  WorkspaceDatabase db, {
  Iterable<String> agents = const [],
  Iterable<String> spaces = const [],
  Iterable<String> conversations = const [],
  Iterable<String> tickets = const [],
  Iterable<String> teams = const [],
  Iterable<String> projects = const [],
  Iterable<String> pipelineTemplates = const [],
  Iterable<String> pipelineRuns = const [],
  Iterable<String> runLogs = const [],
}) async {
  for (final id in agents) {
    await seedAgent(db, id);
  }
  for (final id in spaces) {
    await seedSpace(db, id);
  }
  for (final id in conversations) {
    await seedConversation(db, id);
  }
  for (final id in tickets) {
    await seedTicket(db, id);
  }
  for (final id in teams) {
    await seedTeam(db, id);
  }
  for (final id in projects) {
    await seedProject(db, id);
  }
  for (final id in pipelineTemplates) {
    await seedPipelineTemplate(db, id);
  }
  for (final id in pipelineRuns) {
    await seedPipelineRun(db, id);
  }
  for (final id in runLogs) {
    await seedRunLog(db, id);
  }
}
