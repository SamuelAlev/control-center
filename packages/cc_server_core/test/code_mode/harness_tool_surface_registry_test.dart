import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';

/// The three tool lists over the registry a harness run is built from: the
/// production builder (`buildHarnessToolRegistry`, which a dispatch and the
/// context explorer both call) over the server's own MCP registry, so the
/// bridged tools a script may not call (`ask_agent`, `delegate_task`,
/// `create_approval`, …) are the real ones, and so is the endpoint's
/// `search_tool_bm25`, which no harness surface offers. A surface
/// built from hand-written fakes would not have caught a run with repl
/// sending every one of them on every request.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  HarnessToolRegistry registryFor(Mode mode, {bool withRepl = true}) =>
      buildHarnessToolRegistry(
        mode: mode,
        networkEnabled: true,
        env: const {},
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        fileSearch: _NoFileSearch(),
        mcpRegistry: buildTestServerMcpRegistry(global: global, dbs: dbs),
        replSlot: withRepl,
      )..register(TaskTool(_NeverSpawns()));

  HarnessToolSurface surfaceFor(
    Mode mode, {
    bool withRepl = true,
    bool deferral = true,
  }) {
    final profile = profileFor(mode);
    return materializeHarnessToolSurface(
      registry: registryFor(mode, withRepl: withRepl),
      surface: profile.toToolSurfaceSpec(),
      residency: profile.toToolResidencySpec(enabled: deferral),
    );
  }

  List<String> names(List<HarnessTool> tools) => [
    for (final t in tools) t.name,
  ];

  Set<String> directFor(Mode mode) {
    final profile = profileFor(mode);
    return {
      ...ModeToolPolicy.directNamesFor(mode),
      ...profile.pinnedVerbs,
      ...ModeCapabilityProfile.interactionVerbs,
    };
  }

  test('with repl: repl, search_tools and the direct set are sent, what a '
      'script may call is script-only and the rest deferred', () {
    for (final mode in Mode.values) {
      final profile = profileFor(mode);
      final admitted = registryFor(mode).toolsFor(profile.toToolSurfaceSpec());
      final direct = directFor(mode);
      final surface = surfaceFor(mode);
      expect(surface.hasRepl, isTrue, reason: mode.name);
      expect(surface.deferred, isNotEmpty, reason: mode.name);
      expect(names(surface.resident).take(2), [
        'repl',
        'search_tools',
      ], reason: mode.name);
      expect(names(surface.resident).skip(2).toList(), [
        for (final t in admitted)
          if (direct.contains(t.name)) t.name,
      ], reason: mode.name);
      final rest = [
        for (final t in admitted)
          if (!direct.contains(t.name) &&
              t.name != 'repl' &&
              !ModeToolPolicy.residentDiscovery.contains(t.name) &&
              !endpointOnlyTools.contains(t.name))
            t,
      ];
      expect(names(surface.scriptOnly), [
        for (final t in rest)
          if (t.scriptCallable) t.name,
      ], reason: mode.name);
      expect(names(surface.deferred), [
        for (final t in rest)
          if (!t.scriptCallable) t.name,
      ], reason: mode.name);
    }
  });

  test('without repl: the same direct set, the discovery tools, and the '
      'rest deferred', () {
    for (final mode in Mode.values) {
      final with_ = surfaceFor(mode);
      final without = surfaceFor(mode, withRepl: false);
      expect(without.hasRepl, isFalse, reason: mode.name);
      expect(without.scriptOnly, isEmpty, reason: mode.name);
      expect(names(without.resident).first, 'search_tools');
      expect(
        names(without.resident).where(
          (n) =>
              n != 'search_tools' &&
              !ModeToolPolicy.residentDiscovery.contains(n),
        ),
        names(with_.resident).skip(2),
        reason: mode.name,
      );
      expect(
        names(without.resident),
        containsAll(
          ModeToolPolicy.residentDiscovery.intersection({
            for (final t in registryFor(
              mode,
              withRepl: false,
            ).toolsFor(profileFor(mode).toToolSurfaceSpec()))
              t.name,
          }),
        ),
        reason: mode.name,
      );
    }
  });

  test('no tool a script may not call is script-only, and every admitted '
      'tool is in exactly one list', () {
    for (final mode in Mode.values) {
      final profile = profileFor(mode);
      for (final withRepl in [true, false]) {
        final admitted = registryFor(
          mode,
          withRepl: withRepl,
        ).toolsFor(profile.toToolSurfaceSpec()).map((t) => t.name).toSet();
        for (final deferral in [true, false]) {
          final reason = '${mode.name} repl=$withRepl deferral=$deferral';
          final surface = surfaceFor(
            mode,
            withRepl: withRepl,
            deferral: deferral,
          );
          expect(
            names(surface.scriptOnly.where((t) => !t.scriptCallable).toList()),
            isEmpty,
            reason: reason,
          );
          if (withRepl) {
            expect(
              names(surface.deferred.where((t) => t.scriptCallable).toList()),
              isEmpty,
              reason: reason,
            );
          }
          final listed = [
            for (final t in surface.all)
              if (t.name != 'search_tools') t.name,
          ];
          expect(listed.toSet().length, listed.length, reason: reason);
          // With repl the discovery tools are not offered (`search_tools`
          // is the surface's own, and only when something is deferred); the
          // endpoint's search never is.
          final expected = {
            for (final name in admitted)
              if (!(withRepl &&
                      ModeToolPolicy.residentDiscovery.contains(name)) &&
                  !endpointOnlyTools.contains(name))
                name,
          };
          expect(listed.toSet(), expected, reason: reason);
        }
      }
    }
  });

  test('search_tool_bm25 is on no harness surface: every mode, with repl or '
      'without, deferral on or off', () {
    for (final mode in Mode.values) {
      // Non-vacuity: the registry the surface is built from has it.
      expect(
        names(registryFor(mode).toolsFor(profileFor(mode).toToolSurfaceSpec())),
        contains('search_tool_bm25'),
        reason: mode.name,
      );
      for (final withRepl in [true, false]) {
        for (final deferral in [true, false]) {
          final surface = surfaceFor(
            mode,
            withRepl: withRepl,
            deferral: deferral,
          );
          expect(
            names(surface.all),
            isNot(contains('search_tool_bm25')),
            reason: '${mode.name} repl=$withRepl deferral=$deferral',
          );
        }
      }
    }
  });

  test('search_tools finds no hit named search_tool_bm25', () async {
    for (final withRepl in [true, false]) {
      final search = surfaceFor(
        Mode.chat,
        withRepl: withRepl,
      ).resident.whereType<HarnessToolSearchTool>().single;
      for (final query in [
        'search_tool_bm25',
        'search tool bm25 catalogue keyword',
        'search the tool catalogue by keyword',
      ]) {
        final result = await search.execute({
          'query': query,
          'limit': 50,
        }, const HarnessToolContext(workingDirectory: '.'));
        final answer = jsonDecode(result.content) as Map<String, dynamic>;
        final hits = [
          for (final m in answer['matches'] as List)
            (m as Map<String, dynamic>)['name'],
        ];
        expect(hits, isNotEmpty, reason: 'repl=$withRepl $query');
        expect(
          hits,
          isNot(contains('search_tool_bm25')),
          reason: 'repl=$withRepl $query',
        );
      }
    }
  });
}

class _NeverSpawns implements SubagentSpawner {
  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) =>
      throw StateError('not spawned in this test');
}

class _NoFileSearch implements FileSearchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no file search in this test');
}
