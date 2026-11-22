part of 'agent_loop_runner.dart';

/// The run's tool catalog: which tools are callable, which schemas go on the
/// wire, and how deferred tools are activated.
///
/// Deferred tools are CALLABLE from the first turn — only their schemas are
/// withheld. Keeping them in [byName] is what makes a direct call to a name the
/// model saw in the prompt index work in one step instead of costing an
/// "unknown tool" round trip.
///
/// Script-only tools are a third set: callable through a [ToolReentry] and
/// nothing else. They are never in [byName], never sent to the provider and
/// never activated, so a direct call to one falls through every lane to the
/// gate, which answers it with directions to call it from a script.
class _ToolCatalog {
  _ToolCatalog({
    required List<HarnessTool> tools,
    required this.deferredTools,
    required List<HarnessTool> scriptTools,
    required this.nativeDeferral,
  }) : byName = {
         for (final t in tools) t.name: t,
         for (final t in deferredTools) t.name: t,
       },
       deferredByName = {for (final t in deferredTools) t.name: t},
       scriptOnlyByName = {for (final t in scriptTools) t.name: t},
       residentSchemas = tools.map((t) => t.toSchema()).toList() {
    admitted = Map.unmodifiable({...scriptOnlyByName, ...byName});
    callable = Map.unmodifiable({
      for (final entry in admitted.entries)
        if (entry.value.scriptCallable &&
            !harnessControlToolNames.contains(entry.key))
          entry.key: entry.value,
    });
    deferredSchemas = nativeDeferral
        ? {
            for (final tool in deferredTools)
              tool.name: tool.toSchema().copyWith(deferLoading: true),
          }
        : const <String, LlmToolSchema>{};
    schemas = residentSchemas;
  }

  final List<HarnessTool> deferredTools;

  /// Whether the provider defers schemas natively (Anthropic tool search).
  /// Native search keeps one fixed, authorized catalog; other providers append
  /// activated schemas behind the unchanged resident cache prefix.
  final bool nativeDeferral;
  final Map<String, HarnessTool> byName;
  final Map<String, HarnessTool> deferredByName;

  /// Tools callable only through a [ToolReentry], until [withdrawScripts].
  final Map<String, HarnessTool> scriptOnlyByName;

  /// Whether [withdrawScripts] ran: the run's scripts can no longer run.
  bool scriptsWithdrawn = false;

  /// The script-only tools [withdrawScripts] made deferred, in order.
  final List<HarnessTool> _withdrawn = [];

  /// Makes the run's script-only tools callable directly, for the rest of
  /// the run, because its scripts can no longer run
  /// ([HarnessToolResult.withdrawsScripts]): each becomes a deferred tool,
  /// callable by name and loaded on first use or by a search, exactly like
  /// the tools that were deferred from the start. Nothing else changes:
  /// [admitted] and [callable] already held them, so the mode's filter and
  /// the gate see the same tools. Runs once; later calls do nothing.
  void withdrawScripts() {
    scriptsWithdrawn = true;
    final fresh = [
      for (final tool in scriptOnlyByName.values)
        if (!byName.containsKey(tool.name)) tool,
    ];
    if (fresh.isEmpty) {
      return;
    }
    final declared = <LlmToolSchema>[];
    for (final tool in fresh) {
      byName[tool.name] = tool;
      deferredByName[tool.name] = tool;
      _withdrawn.add(tool);
      if (nativeDeferral) {
        final schema = tool.toSchema().copyWith(deferLoading: true);
        deferredSchemas[tool.name] = schema;
        declared.add(schema);
      }
    }
    // Natively deferred tools are declared up front, deferred; elsewhere a
    // schema joins the request when the tool is first used.
    if (declared.isNotEmpty) {
      schemas = [...schemas, ...declared];
    }
  }

  /// Every tool on the run's surface: resident, deferred and script-only. A
  /// name in both a model-facing list and the script-only list is the
  /// model-facing tool.
  late final Map<String, HarnessTool> admitted;

  /// What a nested call may reach: [admitted] minus the tools a script may
  /// not call ([HarnessTool.scriptCallable], the loop-handled tools). Never
  /// the raw registry: a tool the mode removed is not here.
  late final Map<String, HarnessTool> callable;
  final List<LlmToolSchema> residentSchemas;
  late final Map<String, LlmToolSchema> deferredSchemas;

  /// The schemas the next request sends.
  late List<LlmToolSchema> schemas;
  final Set<String> activatedNames = <String>{};

  /// Estimated tokens of schemas activated mid-run (request bytes the
  /// compaction budget must count).
  int activatedOverheadTokens = 0;

  /// Deferred tools this history activated whose carrier ON THE WIRE is gone.
  ///
  /// A native activation is carried by a `tool_reference` inside a result
  /// block. A fold replaces that block with a summary, so the reference — the
  /// only thing the provider can expand into a schema — disappears while the
  /// tool stays nominally active. A name known ONLY from activation metadata
  /// must be admitted as a real, non-deferred definition or the model loses a
  /// tool the history says it has. Recomputed from the current history because
  /// a rewrite is exactly what removes the carrier.
  Set<String> _carriedOnlyActivations(List<HarnessMessage> history) {
    final restored = <String>{};
    final referenced = <String>{};
    for (final message in history) {
      restored.addAll(message.activatedToolNames);
      for (final block in message.content) {
        if (block is HarnessToolResultBlock) {
          restored.addAll(block.toolReferences);
          referenced.addAll(block.toolReferences);
        } else if (block is HarnessToolUseBlock) {
          restored.add(block.name);
          referenced.add(block.name);
        }
      }
    }
    return {
      for (final name in restored)
        if (deferredByName.containsKey(name) && !referenced.contains(name))
          name,
    };
  }

  /// Rebuilds the native catalog for [history], in the fixed declared order:
  /// the resident block, then every deferred tool — with a carried-only
  /// activation admitted as a real definition in its own position (no
  /// fabricated call or result, and no reordering that would churn the tools
  /// prefix beyond the rewrite that caused it).
  void rebuildNative(List<HarnessMessage> history) {
    if (!nativeDeferral) {
      return;
    }
    final carried = _carriedOnlyActivations(history);
    schemas = <LlmToolSchema>[
      ...residentSchemas,
      for (final tool in [...deferredTools, ..._withdrawn])
        carried.contains(tool.name)
            ? tool.toSchema()
            : deferredSchemas[tool.name]!,
    ];
  }

  /// Activates the deferred tools among [names]; returns the newly activated
  /// ones in order.
  List<String> activate(Iterable<String> names) {
    final fresh = <String>[];
    for (final name in names) {
      if (deferredByName.containsKey(name) && activatedNames.add(name)) {
        fresh.add(name);
      }
    }
    if (fresh.isEmpty) {
      return const [];
    }
    final added = [
      for (final name in fresh)
        deferredSchemas[name] ?? deferredByName[name]!.toSchema(),
    ];
    for (final schema in added) {
      activatedOverheadTokens += _schemaTokens(schema);
    }
    if (!nativeDeferral) {
      schemas = [...schemas, ...added];
    }
    return fresh;
  }

  /// The `tool_reference`s a result block must carry for [call]/[result].
  List<String> referencesFor(_PendingTool call, HarnessToolResult result) {
    final direct = deferredByName.containsKey(call.name);
    if (!direct && result.activateTools.isEmpty) {
      return const [];
    }
    final names = <String>{
      if (direct) call.name,
      for (final name in result.activateTools)
        if (deferredByName.containsKey(name)) name,
    };
    return names.isEmpty ? const [] : names.toList(growable: false);
  }
}
