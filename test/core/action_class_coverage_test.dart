import 'dart:io';

import 'package:test/test.dart';

/// The ActionClass ratchet (PRD 24 §1): keeps the unified-guardrail effect
/// declarations honest and complete.
///
/// Every concrete harness tool (`packages/cc_infra/lib/src/harness/tools/*.dart`)
/// and every MCP tool (`packages/cc_mcp/lib/src/tools/*.dart`) declares the
/// worst-case `ActionClass` set it can effect. The base classes supply a
/// conservative default (harness: exec ⇒ {processSpawn}, write ⇒
/// {fileWriteOutsideWorktree}, read ⇒ {}; MCP ⇒ {}); a tool whose worst case
/// exceeds that default overrides `Set<ActionClass> get actionClasses`.
///
/// This is a SOURCE-LEVEL (grep) ratchet — the same style as
/// `undo_class_coverage_test.dart` — because most tools need heavy
/// repositories/ports/services to construct. It enforces two invariants against
/// the real tool source:
///
///   1. Each tool's EFFECTIVE ActionClass set (its override, or the base
///      default it inherits) EXACTLY equals a curated `expected` entry — the
///      human-reviewed source of truth for a security-sensitive declaration.
///   2. Every tool file on disk is present in `expected` and every `expected`
///      key exists on disk. A NEW mutating tool therefore fails CI until a human
///      adds it here and states its effects — it cannot silently ship with an
///      undeclared (falsely-harmless) effect set.
///
/// Under-declaring an effect is a silent security hole; over-declaring only
/// costs an extra prompt. When in doubt the curated set includes the effect.
void main() {
  final root = _repoRoot();

  // ---------------------------------------------------------------------------
  // Curated source of truth. Sets are the ActionClass ENUM MEMBER NAMES (which
  // equal their wire strings). Empty set = inherits the base default and adds
  // no extra effect. A human reviews every change to these two maps.
  // ---------------------------------------------------------------------------

  // Harness tools. The empty-set entries are read-tier (default {}); the
  // non-empty entries are either a write/exec default or an explicit override.
  const expectedHarness = <String, Set<String>>{
    // Overrides (worst case exceeds the tier default):
    'apply_patch': {'fileWriteOutsideWorktree', 'fileDelete'},
    'web_fetch': {'networkEgress'},
    'web_search': {'networkEgress'},
    // Tier defaults (no override):
    'bash': {'processSpawn'}, // exec; command policy refines per-command
    'write': {'fileWriteOutsideWorktree'}, // write tier
    'edit': {'fileWriteOutsideWorktree'}, // write tier
    'read': <String>{}, // read tier
    'search': <String>{},
    'search_files': <String>{},
    'find': <String>{},
    'task': <String>{}, // spawns an in-process subagent loop, not a process
    'checkpoint': <String>{},
    'rewind': <String>{},
  };

  // MCP tools. Non-empty entries are mutating tools whose worst case reaches an
  // external/dangerous effect; every other tool is a pure read/query or a
  // local-DB-only write (neither is an ActionClass) and inherits the {} default.
  const expectedMcp = <String, Set<String>>{
    // --- Publishing / dispatch / external network ---
    'publish_review_to_github': {'prPublish'},
    'start_ai_review': {'processSpawn'}, // starts the pr_review pipeline
    'dispatch_reviewers': {'processSpawn'}, // spawns reviewer subagents
    'doctor': {
      'processSpawn',
      'networkEgress',
    }, // runs `df`, dials api.github.com
    'install_skill': {
      'packageInstall',
      'networkEgress',
    }, // fetches + installs from GitHub
    'update_skill': {
      'packageInstall',
      'networkEgress',
    }, // re-fetches + re-installs from GitHub
    'refresh_feeds': {'networkEgress'}, // fetches RSS over HTTP
    // --- Enclosures (rigs) ---
    // Booting a VM spawns a hypervisor process; driving one is enclosure
    // control; the guest reaches the network through the egress proxy. All
    // three `*_use` tools inherit the set from their shared `RigUseTool`.
    'computer_use': {
      'enclosureControl',
      'networkEgress',
      'processSpawn',
    },
    'browser_use': {'enclosureControl', 'networkEgress', 'processSpawn'},
    'mobile_use': {'enclosureControl', 'networkEgress', 'processSpawn'},
    'rig_close': {'enclosureControl'}, // destroys a machine
    'rig_list': <String>{}, // read-only
    // --- Workspace structure (create/mutate repos/channels/agents/workspaces) ---
    'hire_agent': {'workspaceMutation'},
    'fire_agent': {'workspaceMutation'},
    'update_agent': {'workspaceMutation'},
    'create_workspace': {'workspaceMutation'},
    'kill_agent': {'processSpawn'}, // enumerates + kills the agent's processes
    'send_to_agent': {
      'workspaceMutation',
      'processSpawn',
    }, // may create DM channel + dispatch
    'ask_agent': {
      'workspaceMutation',
      'processSpawn',
    }, // may create DM channel + dispatch
    'consult_agent': {'processSpawn'}, // dispatches the specialist
    // --- Skill files on disk (outside the worktree) ---
    'create_skill': {'fileWriteOutsideWorktree'},
    'pin_skill': {'fileWriteOutsideWorktree'},

    // --- Ticket writes: propagate to external vendors via the sync path and
    //     some dispatch agents. See MultiVendorTicketSyncCoordinator /
    //     TicketRemoteSyncHandler + TeamRoutingService. ---
    'create_ticket': {'vendorSyncWrite'},
    'update_ticket': {'vendorSyncWrite'},
    'close_ticket': {'vendorSyncWrite'},
    'fail_ticket': {'vendorSyncWrite'},
    'delegate_ticket': {'vendorSyncWrite'},
    'delegate_task': {'vendorSyncWrite'},
    'link_tickets': {'vendorSyncWrite'}, // setParent emits TicketDetailsUpdated
    'unlink_tickets': {
      'vendorSyncWrite',
    }, // clearParent emits TicketDetailsUpdated
    'checkout_task': {'vendorSyncWrite'}, // moves ticket -> in_progress
    'release_task': {'vendorSyncWrite'}, // moves ticket -> open
    'set_ticket_project': {'vendorSyncWrite'}, // emits TicketDetailsUpdated
    'assign_ticket': {
      'vendorSyncWrite',
      'processSpawn',
    }, // vendor assign + team-leader dispatch
    'reassign_ticket': {'vendorSyncWrite', 'processSpawn'},
    'comment_on_ticket': {
      'processSpawn',
    }, // sendAndDispatch: @mentions dispatch agents
    'propose_orchestration': {
      'vendorSyncWrite',
    }, // blocks the anchor ticket (status change)
    'run_playbook': {'vendorSyncWrite'}, // delegates to propose_orchestration
    // --- Everything below inherits the {} default: pure read/query, or a
    //     local-DB / messaging / in-memory write with no ActionClass effect. ---
    'add_review_diagram': <String>{},
    'add_review_node': <String>{},
    'add_ticket_collaborator': <String>{},
    'agent_heartbeat': <String>{},
    'ask_user_question': <String>{},
    'code_callees': <String>{},
    'code_callers': <String>{},
    'code_impact': <String>{},
    'code_symbol': <String>{},
    'comment_approval': <String>{},
    // Terminates the caller's own durable goal: upserts the goal row and posts
    // one system message to its channel. Both are local-DB writes and it only
    // ever REDUCES activity (cancels the supervisor's timer, so no further runs
    // are dispatched) — same shape as its sibling `update_goal_progress`.
    'complete_goal': <String>{},
    'confirm_review_node': <String>{},
    'consolidate_memory': <String>{},
    'create_approval': <String>{},
    'create_goal': <String>{},
    'create_playbook': <String>{},
    'create_project': <String>{},
    'create_runtime_profile': <String>{},
    'create_work_product': <String>{},
    'decide_approval': <String>{},
    'delete_project': <String>{},
    'dismiss_review_node': <String>{},
    'exit_plan_mode': <String>{},
    'finalize_review': <String>{}, // posts summary; does NOT publish to GitHub
    'get_agent_run_logs': <String>{},
    'get_article': <String>{},
    // Artifacts (block documents): one local `work_products` row + one
    // channel message. No filesystem, no process, no external system — the
    // same effect profile as `send_channel_message`, which is why they are
    // allowed in every conversation mode.
    'get_artifact': <String>{},
    'get_channel_messages': <String>{},
    'get_channel_notes': <String>{}, // read: returns a channel's notes
    'get_my_notes': <String>{},
    'get_org_chart': <String>{},
    'get_ticket': <String>{},
    'get_work_product': <String>{},
    'harmonize_memory': <String>{},
    'link_ticket_to_pr': <String>{}, // local mutate, no event
    'list_agent_presence': <String>{},
    'list_agents': <String>{},
    'list_approvals': <String>{},
    'list_articles': <String>{},
    'list_artifacts': <String>{},
    'list_channels': <String>{},
    'list_feeds': <String>{},
    'list_goals': <String>{},
    'list_memory_conflicts': <String>{},
    'list_memory_domains': <String>{},
    'list_policies': <String>{},
    'list_projects': <String>{},
    'list_pull_requests': <String>{},
    'list_repos': <String>{},
    'list_runtime_health': <String>{},
    'list_runtime_profiles': <String>{},
    'list_skill_updates':
        <String>{}, // read: checks upstream refs, writes nothing
    'list_skills': <String>{},
    'list_ticket_relations': <String>{},
    'list_tickets': <String>{},
    'list_work_products': <String>{},
    'list_workspaces': <String>{},
    'preview_trigger': <String>{}, // dry-run, read-only
    'propose_fact': <String>{},
    'propose_hire':
        <String>{}, // posts a proposal card; hire happens on approval
    'propose_policy': <String>{},
    'publish_artifact': <String>{},
    'record_observation': <String>{},
    'record_team_activity': <String>{},
    'remember': <String>{},
    'request_confirmation': <String>{}, // blocks on a human decision
    'request_peer_review': <String>{}, // posts a message; does NOT dispatch
    'revise_artifact': <String>{},
    'save_work_product_revision': <String>{},
    'search_code': <String>{},
    'search_memory': <String>{},
    'send_channel_message': <String>{},
    'set_article_read': <String>{},
    'set_article_saved': <String>{},
    'set_cohort_summary': <String>{},
    'submit_output': <String>{},
    'submit_plan': <String>{},
    'submit_reviewer_verdict': <String>{},
    'supersede_fact': <String>{},
    'supersede_policy': <String>{},
    'todo_read': <String>{},
    'todo_write': <String>{},
    'unlink_ticket_from_pr': <String>{}, // local mutate, no event
    'update_goal_progress': <String>{},
    'update_channel_notes':
        <String>{}, // edits a channel's free-text notes field
    'update_my_notes': <String>{},
    'update_project': <String>{},
    'verify_skills':
        <String>{}, // reads + hashes on-disk skills, writes nothing
  };

  test('harness tools declare exactly their curated ActionClass sets', () {
    // PRD 26: the built-in tools live in cc_harness_runtime; only the
    // CC-coupled apply_patch (Edit/FileEditService) stays in cc_infra.
    final declared =
        _scanTools(
          dir: '${root.path}/packages/cc_harness_runtime/lib/src/tools',
          base: 'HarnessTool',
        )..addAll(
          _scanTools(
            dir: '${root.path}/packages/cc_infra/lib/src/harness/tools',
            base: 'HarnessTool',
          ),
        );
    _assertMatches(declared, expectedHarness, scope: 'harness');
  });

  test('MCP tools declare exactly their curated ActionClass sets', () {
    final declared = _scanTools(
      dir: '${root.path}/packages/cc_mcp/lib/src/tools',
      base: 'McpTool',
    );
    _assertMatches(declared, expectedMcp, scope: 'MCP');
  });

  // ---------------------------------------------------------------------------
  // RepoOps. The RPC catalog is the OTHER surface that performs effects — a
  // connected client drives it exactly the way a model drives a tool, and the
  // same guardrail store gates both (`repo_op.dart` forwards `actionClasses`
  // into the policy check). It was invisible to this ratchet, which is how
  // three rig port ops shipped as `mutate` with no declaration at all.
  //
  // Scanning all ~490 ops for a curated map would be unmaintainable, so the
  // ratchet is two narrower invariants that between them close the hole:
  //
  //   1. Every op that DECLARES classes matches a curated map exactly, both
  //      directions — so a declaration cannot be weakened or dropped silently.
  //   2. Every MUTATING op in an EFFECT FAMILY (the prefixes below, whose ops
  //      by construction reach a hypervisor, a host listener, a git remote or
  //      the filesystem) must declare at least one class. A new `rig.*` op
  //      therefore fails CI until a human states its effects.
  // ---------------------------------------------------------------------------

  // Curated source of truth for the RPC catalog, same contract as the tool
  // maps above: a human reviews every change.
  const expectedRepoOps = <String, Set<String>>{
    // Enclosures: booting spawns a hypervisor, driving one is enclosure
    // control, and the guest reaches the network through the egress proxy.
    'rig.open': {'enclosureControl', 'processSpawn'},
    'rig.act': {'enclosureControl'},
    'rig.takeControl': {'enclosureControl'},
    'rig.releaseControl': {'enclosureControl'},
    'rig.destroy': {'enclosureControl'},
    'rig.downloadImage': {'networkEgress', 'packageInstall'},
    'rig.importImage': {'packageInstall'},
    // Enclosure ports: each one reconfigures a host listener or the name that
    // reaches it. `setPortsAutoForward` stands in for an unbounded number of
    // `addPort`s, which is why it is not exempt for being a toggle.
    'rig.addPort': {'networkEgress'},
    'rig.removePort': {'networkEgress'},
    'rig.setPortLan': {'networkEgress'},
    'rig.setPortDomain': {'networkEgress'},
    'rig.setPortsAutoForward': {'networkEgress'},
    // Git plumbing on the operator's own repositories.
    'worktree.commitAndPush': {'gitCommit', 'gitPush'},
    'worktree.publishBranch': {'gitPush'},
    'worktree.syncToPrHead': {'networkEgress'}, // fetches before it checks out
    // Files outside any worktree (agent/skill definitions on disk).
    'fs.writeAgentFile': {'fileWriteOutsideWorktree'},
    'fs.deleteAgentDir': {'fileDelete'},
    'fs.writeSkillFile': {'fileWriteOutsideWorktree'},
    'fs.deleteSkillDir': {'fileDelete'},
    'skills.saveLocal': {'fileWriteOutsideWorktree'},
    // Forge writes.
    'pr_lifecycle.publish': {'prCreate'},
    'pr_review.publishReview': {'prPublish'},
    // Review Hub: both ops dispatch agent runs on the host.
    'review_hub.start': {'processSpawn'},
    'review_hub.askArea': {'processSpawn'},
  };

  /// Op-name prefixes whose MUTATING members reach a real-world effect. A new
  /// op under one of these must declare a class or be argued into
  /// [noEffectExemptions] below.
  const effectFamilies = <String>['rig.', 'worktree.'];

  /// Mutating ops in an effect family that genuinely effect NO ActionClass.
  ///
  /// The exemption is the point: over-declaring costs a prompt, but declaring
  /// a class a call does not actually effect is a FALSE claim, and a taxonomy
  /// people stop believing stops being read. Each entry states why.
  const noEffectExemptions = <String, String>{
    'worktree.writeFile':
        'Writes INSIDE the isolated conversation worktree. The taxonomy has no '
        'class for that — the worktree IS the containment, the same reasoning '
        'that makes `enclosureControl` allow-by-default — and '
        '`fileWriteOutsideWorktree` would be a false claim.',
    'worktree.revertFiles':
        'Restores TRACKED files to HEAD inside the isolated worktree and '
        'reports untracked ones as skipped, so it neither deletes a file nor '
        'writes outside the worktree.',
  };

  test('RPC catalog ops declare exactly their curated ActionClass sets', () {
    final declared = _scanRepoOps(
      '${root.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
    );
    final withClasses = {
      for (final op in declared.entries)
        if (op.value.classes.isNotEmpty) op.key: op.value.classes,
    };
    _assertMatches(withClasses, expectedRepoOps, scope: 'RepoOp');
  });

  test('every mutating op in an effect family declares an ActionClass', () {
    final declared = _scanRepoOps(
      '${root.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
    );
    final undeclared = <String>[
      for (final op in declared.entries)
        if (op.value.classes.isEmpty &&
            op.value.kind != 'read' &&
            !noEffectExemptions.containsKey(op.key) &&
            effectFamilies.any(op.key.startsWith))
          '${op.key} (${op.value.kind})',
    ]..sort();
    expect(
      undeclared,
      isEmpty,
      reason:
          'These mutating RPC ops reach a hypervisor, a host listener or a git '
          'remote but declare no ActionClass, so the unified guardrails cannot '
          'see them: $undeclared. Declare the honest worst-case set on the '
          'RepoOp and add it to `expectedRepoOps` above — or, if the call '
          'genuinely effects nothing in the taxonomy, argue it into '
          '`noEffectExemptions`.',
    );

    // An exemption for an op that no longer exists (or that has since gained a
    // declaration) is a stale excuse; drop it rather than leave a hole named
    // after something that moved.
    bool isStaleExemption(String name) =>
        !declared.containsKey(name) || declared[name]!.classes.isNotEmpty;
    final stale = noEffectExemptions.keys.where(isStaleExemption).toList()
      ..sort();
    expect(
      stale,
      isEmpty,
      reason:
          'These `noEffectExemptions` entries no longer describe a real, '
          'undeclared op: $stale. Remove them.',
    );
  });
}

/// A RepoOp as the catalog source declares it.
typedef _RepoOpDecl = ({String kind, Set<String> classes});

/// Scans the RPC catalog source for `RepoOp(...)` literals.
///
/// Source-level (grep) for the same reason the tool scans are: building the
/// catalog needs the entire server graph — every repository, every port, a
/// database. Splitting on the constructor name and reading a bounded window is
/// enough because every op in the file states `name:` and `kind:` before its
/// `handler:`.
Map<String, _RepoOpDecl> _scanRepoOps(String path) {
  final src = File(path).readAsStringSync();
  final nameRe = RegExp(r"name:\s*'([^']+)'");
  final kindRe = RegExp(r'kind:\s*RepoOpKind\.(\w+)');
  final classesRe = RegExp(r'actionClasses:\s*const\s*\{([^}]*)\}');
  final out = <String, _RepoOpDecl>{};

  for (final chunk in src.split('RepoOp(').skip(1)) {
    // The window stops at `handler:` — a handler body can contain another
    // op's name in a string, and reading past it would attribute it here.
    final handlerAt = chunk.indexOf('handler:');
    final head = handlerAt >= 0 ? chunk.substring(0, handlerAt) : chunk;
    final name = nameRe.firstMatch(head)?.group(1);
    if (name == null) {
      continue;
    }
    final kind = kindRe.firstMatch(head)?.group(1) ?? 'read';
    final classesMatch = classesRe.firstMatch(head);
    final classes = classesMatch == null
        ? <String>{}
        : RegExp(r'ActionClass\.(\w+)')
              .allMatches(classesMatch.group(1)!)
              .map((m) => m.group(1)!)
              .toSet();
    out[name] = (kind: kind, classes: classes);
  }
  return out;
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

/// A tool's effective ActionClass set (its override or inherited default).
final _nameRe = RegExp(r"String\s+get\s+name\s*=>\s*'([^']+)'");
final _tierRe = RegExp(
  r'ToolApprovalTier\s+get\s+approvalTier\s*=>\s*ToolApprovalTier\.(\w+)',
);
final _overrideRe = RegExp(
  r'Set<ActionClass>\s+get\s+actionClasses\s*=>\s*const\s*\{([^}]*)\}',
);
final _memberRe = RegExp(r'ActionClass\.(\w+)');

/// Scans every top-level `*.dart` file in [dir] for classes extending [base]
/// (`HarnessTool` or `McpTool`) and returns name -> effective ActionClass set.
///
/// Non-recursive, matching the `tools/*.dart` glob.
Map<String, Set<String>> _scanTools({
  required String dir,
  required String base,
}) {
  // Tools that extend an ABSTRACT INTERMEDIATE rather than the base directly
  // (the three `*_use` rig tools share a `RigUseTool` that declares their
  // effects once) must still be seen here. Scanning only `extends <base>` made
  // them invisible to this ratchet — a security check that silently skipped
  // the highest-privilege tools in the app. So the scan runs twice: once to
  // learn which intermediates exist and what they declare, then again to pick
  // up their subclasses with the inherited set.
  final intermediates = _findIntermediates(dir: dir, base: base);
  final bases = <String>[base, ...intermediates.keys];
  final classRe = RegExp(
    'class\\s+(\\w+)\\s+extends\\s+(${bases.join('|')})\\b',
  );
  final result = <String, Set<String>>{};

  final files = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final file in files) {
    final src = file.readAsStringSync();
    final classes = classRe.allMatches(src).toList();
    for (var i = 0; i < classes.length; i++) {
      final start = classes[i].start;
      final end = i + 1 < classes.length ? classes[i + 1].start : src.length;
      final body = src.substring(start, end);

      final nameMatch = _nameRe.firstMatch(body);
      if (nameMatch == null) {
        continue; // abstract intermediate (none exist today), skip.
      }
      final name = nameMatch.group(1)!;

      final override = _overrideRe.firstMatch(body);
      final Set<String> effective;
      if (override != null) {
        effective = _memberRe
            .allMatches(override.group(1)!)
            .map((m) => m.group(1)!)
            .toSet();
        expect(
          effective,
          isNotEmpty,
          reason:
              'Tool "$name" declares an EMPTY actionClasses override. Do not '
              'add an empty override — delete it and inherit the default.',
        );
      } else if (intermediates.containsKey(classes[i].group(2))) {
        // Inherited from the abstract intermediate this tool extends.
        effective = intermediates[classes[i].group(2)]!;
      } else if (base == 'HarnessTool') {
        final tier = _tierRe.firstMatch(body)?.group(1);
        effective = switch (tier) {
          'exec' => {'processSpawn'},
          'write' => {'fileWriteOutsideWorktree'},
          _ => <String>{}, // read (or unknown -> conservative empty)
        };
      } else {
        effective = <String>{}; // McpTool default.
      }

      expect(
        result.containsKey(name),
        isFalse,
        reason: 'Duplicate tool name "$name" found across $base files.',
      );
      result[name] = effective;
    }
  }
  return result;
}

void _assertMatches(
  Map<String, Set<String>> declared,
  Map<String, Set<String>> expected, {
  required String scope,
}) {
  final missingFromExpected =
      declared.keys.where((k) => !expected.containsKey(k)).toList()..sort();
  final missingFromSource =
      expected.keys.where((k) => !declared.containsKey(k)).toList()..sort();

  expect(
    missingFromExpected,
    isEmpty,
    reason:
        '$scope tool(s) exist in source but are NOT in this ratchet\'s curated '
        'map: $missingFromExpected. A new tool must be added here with its '
        'honest worst-case ActionClass set before it can ship.',
  );
  expect(
    missingFromSource,
    isEmpty,
    reason:
        '$scope tool(s) are in this ratchet\'s curated map but no longer exist '
        'in source (renamed/removed?): $missingFromSource. Update the map.',
  );

  for (final entry in declared.entries) {
    expect(
      entry.value,
      expected[entry.key],
      reason:
          '$scope tool "${entry.key}" declares ActionClass set ${entry.value} '
          'but the curated ratchet expects ${expected[entry.key]}. Either the '
          'tool\'s effects changed (update the override + this map together) or '
          'the declaration is wrong. Be honest about the worst case.',
    );
  }
}

/// Abstract classes in [dir] that extend [base] and declare an
/// `actionClasses` override, mapped to that override's members.
///
/// These are shared bases for a family of tools (the rig `*_use` tools). Their
/// subclasses inherit the declaration, so the scan has to know about them or
/// it reports those tools as effect-free.
Map<String, Set<String>> _findIntermediates({
  required String dir,
  required String base,
}) {
  final re = RegExp('abstract\\s+class\\s+(\\w+)\\s+extends\\s+$base\\b');
  final out = <String, Set<String>>{};
  for (final file in Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final src = file.readAsStringSync();
    for (final match in re.allMatches(src)) {
      final body = src.substring(match.start);
      final override = _overrideRe.firstMatch(body);
      out[match.group(1)!] = override == null
          ? <String>{}
          : _memberRe
                .allMatches(override.group(1)!)
                .map((m) => m.group(1)!)
                .toSet();
    }
  }
  return out;
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(
      '${dir.path}/packages/cc_mcp/lib/src/tools/tools.dart',
    ).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}
