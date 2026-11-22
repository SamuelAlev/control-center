import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/harness_tool_registry_builder.dart';
import 'package:cc_infra/src/harness/harness_tool_search_tool.dart';
import 'package:cc_infra/src/harness/harness_tool_surface.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:test/test.dart';

class _Tool extends HarnessTool {
  _Tool(
    this.name, {
    this.approvalTier = ToolApprovalTier.read,
    this.scriptCallable = true,
    String? description,
  }) : description = description ?? 'The $name operation.';

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  @override
  final bool scriptCallable;
  @override
  final String description;

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('$name ran');
}

/// A registry shaped like a real run's: built-ins (some direct, some not),
/// the discovery browser, a few bridged tools, the plan verbs and, when
/// [withRepl], a fake `repl`. When [withUnscriptable], also the tools a
/// script may not call that are not direct (`checkpoint`, `rewind`,
/// `submit_plan`, `ask_agent`, `assign_ticket`), as the server's registry
/// has them.
HarnessToolRegistry _registry({
  bool withRepl = true,
  bool withUnscriptable = true,
}) => HarnessToolRegistry.of([
  _Tool('read'),
  _Tool('write', approvalTier: ToolApprovalTier.write),
  _Tool('edit', approvalTier: ToolApprovalTier.write),
  _Tool('bash', approvalTier: ToolApprovalTier.exec),
  _Tool('search'),
  if (withUnscriptable) ...[
    _Tool('checkpoint', scriptCallable: false),
    _Tool('rewind', scriptCallable: false),
  ],
  _Tool('task', scriptCallable: false),
  _Tool('ask_user'),
  _Tool('lsp'),
  if (withRepl) _Tool('repl', scriptCallable: false),
  _Tool('todo_write', approvalTier: ToolApprovalTier.write),
  _Tool('todo_read'),
  _Tool('list_my_tools', scriptCallable: false),
  _Tool('search_memory'),
  _Tool('send_message', scriptCallable: false),
  _Tool(
    'get_ticket',
    description: 'Reads one ticket with its comments and status.',
  ),
  _Tool('list_tickets'),
  if (withUnscriptable) ...[
    _Tool(
      'submit_plan',
      approvalTier: ToolApprovalTier.write,
      scriptCallable: false,
    ),
    _Tool('ask_agent', scriptCallable: false),
    _Tool(
      'assign_ticket',
      approvalTier: ToolApprovalTier.write,
      scriptCallable: false,
    ),
  ],
]);

HarnessToolSurface _surface(
  Mode mode, {
  bool withRepl = true,
  bool withUnscriptable = true,
  bool deferral = true,
}) {
  final profile = profileFor(mode);
  return materializeHarnessToolSurface(
    registry: _registry(withRepl: withRepl, withUnscriptable: withUnscriptable),
    surface: profile.toToolSurfaceSpec(),
    residency: profile.toToolResidencySpec(enabled: deferral),
  );
}

List<String> _names(List<HarnessTool> tools) => [for (final t in tools) t.name];

/// Never asked to run a script: only the surface is under test.
class _NoScripts implements CodeExecutionPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _binding = ReplBinding(
  executions: _NoScripts(),
  run: ReplRunIdentity(
        workspaceId: 'ws-1',
        runId: 'run-1',
        readOnly: false,
        past: null,
      ),
  limits: CodeModeLimits.defaults,
);

Future<Map<String, dynamic>> _search(
  HarnessToolSurface surface,
  String query,
) => _searchIn(surface.resident, query);

Future<Map<String, dynamic>> _searchIn(
  List<HarnessTool> resident,
  String query,
) async {
  final search = resident.whereType<HarnessToolSearchTool>().single;
  final result = await search.execute({
    'query': query,
  }, const HarnessToolContext(workingDirectory: '.'));
  final body = jsonDecode(result.content) as Map<String, dynamic>;
  return {...body, 'activated': result.activateTools.toList()};
}

Map<String, dynamic> _match(Map<String, dynamic> body, String name) =>
    (body['matches'] as List).cast<Map<String, dynamic>>().singleWhere(
      (m) => m['name'] == name,
    );

void main() {
  group('without repl', () {
    test('is the residency split with the search tool in front', () {
      for (final mode in [Mode.chat, Mode.plan]) {
        final profile = profileFor(mode);
        final admitted = _registry(
          withRepl: false,
        ).toolsFor(profile.toToolSurfaceSpec());
        final split = profile.toToolResidencySpec().partition(admitted);

        final surface = _surface(mode, withRepl: false);
        expect(surface.hasRepl, isFalse);
        expect(_names(surface.resident), [
          'search_tools',
          ..._names(split.resident),
        ]);
        expect(_names(surface.deferred), _names(split.deferred));
        expect(surface.scriptOnly, isEmpty);
      }
    });

    test('keeps the direct set and the discovery tools resident and defers '
        'the rest', () {
      final surface = _surface(Mode.chat, withRepl: false);
      expect(_names(surface.resident), [
        'search_tools',
        'read',
        'write',
        'edit',
        'bash',
        'search',
        'task',
        'ask_user',
        'todo_write',
        'list_my_tools',
        'search_memory',
        'send_message',
      ]);
      expect(_names(surface.deferred), [
        'checkpoint',
        'rewind',
        'lsp',
        'todo_read',
        'get_ticket',
        'list_tickets',
        'submit_plan',
        'ask_agent',
        'assign_ticket',
      ]);
    });

    test('with deferral off everything is resident and nothing searchable', () {
      final surface = _surface(Mode.chat, withRepl: false, deferral: false);
      expect(_names(surface.resident), isNot(contains('search_tools')));
      expect(surface.deferred, isEmpty);
      expect(
        _names(surface.resident),
        _names(
          _registry(
            withRepl: false,
          ).toolsFor(profileFor(Mode.chat).toToolSurfaceSpec()),
        ),
      );
    });
  });

  group('with repl', () {
    test('sends repl, the search tool and the direct set; scripts what a '
        'script may call and defers the rest', () {
      final surface = _surface(Mode.chat);

      expect(surface.hasRepl, isTrue);
      expect(_names(surface.resident), [
        'repl',
        'search_tools',
        'read',
        'write',
        'edit',
        'bash',
        'search',
        'task',
        'ask_user',
        'todo_write',
        'search_memory',
        'send_message',
      ]);
      expect(_names(surface.scriptOnly), [
        'lsp',
        'todo_read',
        'get_ticket',
        'list_tickets',
      ]);
      expect(_names(surface.deferred), [
        'checkpoint',
        'rewind',
        'submit_plan',
        'ask_agent',
        'assign_ticket',
      ]);
    });

    test('has the same direct set as a run without repl', () {
      for (final mode in [Mode.chat, Mode.plan]) {
        final with_ = _surface(mode);
        final without = _surface(mode, withRepl: false);
        expect(
          [
            for (final name in _names(with_.resident))
              if (name != 'repl' && name != 'search_tools') name,
          ],
          [
            for (final name in _names(without.resident))
              if (name != 'search_tools' && name != 'list_my_tools') name,
          ],
          reason: mode.name,
        );
      }
    });

    test('never offers list_my_tools', () {
      for (final deferral in [true, false]) {
        expect(
          _names(_surface(Mode.chat, deferral: deferral).all),
          isNot(contains('list_my_tools')),
        );
      }
    });

    test('with nothing deferred, offers no search tool', () {
      final surface = _surface(Mode.chat, withUnscriptable: false);
      expect(surface.deferred, isEmpty);
      expect(_names(surface.resident), [
        'repl',
        'read',
        'write',
        'edit',
        'bash',
        'search',
        'task',
        'ask_user',
        'todo_write',
        'search_memory',
        'send_message',
      ]);
    });

    test('a read-only mode still removes what it removes and keeps its '
        'pinned verbs direct', () {
      final surface = _surface(Mode.plan);
      final all = _names(surface.all);
      for (final removed in ['write', 'edit', 'bash', 'assign_ticket']) {
        expect(all, isNot(contains(removed)), reason: removed);
      }
      expect(
        _names(surface.resident),
        containsAll(['submit_plan', 'ask_user']),
      );
      expect(
        _names(surface.scriptOnly),
        containsAll(['lsp', 'get_ticket', 'list_tickets']),
      );
      expect(_names(surface.deferred), contains('ask_agent'));
    });

    test('with deferral off the script-only list is the same and what a '
        'script may not call is resident', () {
      final on = _surface(Mode.chat);
      final killed = _surface(Mode.chat, deferral: false);
      expect(_names(killed.scriptOnly), _names(on.scriptOnly));
      expect(killed.deferred, isEmpty);
      expect(_names(killed.resident), [
        'repl',
        'read',
        'write',
        'edit',
        'bash',
        'search',
        'checkpoint',
        'rewind',
        'task',
        'ask_user',
        'todo_write',
        'search_memory',
        'send_message',
        'submit_plan',
        'ask_agent',
        'assign_ticket',
      ]);
    });
  });

  group('search with repl', () {
    test(
      'indexes what a direct call reaches and loads a deferred match',
      () async {
        final body = await _search(_surface(Mode.chat), 'checkpoint');
        final hit = _match(body, 'checkpoint');
        expect(hit['already_loaded'], isFalse);
        expect(body['activated'], contains('checkpoint'));
        expect(hit.containsKey('script_only'), isFalse);
      },
    );

    test(
      'answers a script-only match with how to call it from a script',
      () async {
        final body = await _search(
          _surface(Mode.chat),
          'read one ticket with its comments',
        );
        final hit = _match(body, 'get_ticket');
        expect(hit['script_only'], isTrue);
        expect(hit['already_loaded'], isFalse);
        expect(body['activated'], isNot(contains('get_ticket')));
        expect(body['hint'], contains('repl'));
      },
    );

    test('a repl bound with no script-only tools (the vibe orchestrator) '
        'points no search at a script', () async {
      final surface = _surface(Mode.chat);
      final bound = bindReplTool(resident: surface.resident, binding: _binding);
      expect(bound.first, isA<ReplTool>());
      final body = await _searchIn(bound, 'read one ticket with its comments');
      final hits = (body['matches'] as List).cast<Map<String, dynamic>>();
      expect(hits.where((m) => m['script_only'] == true), isEmpty);
      expect(hits.map((m) => m['name']), isNot(contains('get_ticket')));
    });

    test(
      'a run whose repl was taken away finds its script-only tools as loaded',
      () async {
        final surface = _surface(Mode.chat);
        final direct = withoutReplTool(
          resident: surface.resident,
          scriptOnly: surface.scriptOnly,
        );
        expect(_names(direct), isNot(contains('repl')));
        final body = await _searchIn(
          direct,
          'read one ticket with its comments',
        );
        final hit = _match(body, 'get_ticket');
        expect(hit['already_loaded'], isTrue);
        expect(hit.containsKey('script_only'), isFalse);
        expect(body['activated'], isNot(contains('get_ticket')));
      },
    );

    test('its description is the one without repl, byte for byte', () {
      final without = _surface(Mode.chat, withRepl: false);
      final with_ = _surface(Mode.chat);
      expect(with_.resident[1].description, without.resident.first.description);
      expect(
        jsonEncode(with_.resident[1].inputSchema),
        jsonEncode(without.resident.first.inputSchema),
      );
    });
  });

  void forEverySurface(
    void Function(
      HarnessToolSurface surface, {
      required bool withRepl,
      required bool deferral,
      required Mode mode,
      required String reason,
    })
    check,
  ) {
    for (final withRepl in [true, false]) {
      for (final deferral in [true, false]) {
        for (final mode in [Mode.chat, Mode.plan]) {
          check(
            _surface(mode, withRepl: withRepl, deferral: deferral),
            withRepl: withRepl,
            deferral: deferral,
            mode: mode,
            reason: 'repl=$withRepl deferral=$deferral ${mode.name}',
          );
        }
      }
    }
  }

  test('a tool a script may not call is never script-only', () {
    forEverySurface((
      surface, {
      required withRepl,
      required deferral,
      required mode,
      required reason,
    }) {
      expect(
        surface.scriptOnly.where((t) => !t.scriptCallable),
        isEmpty,
        reason: reason,
      );
    });
  });

  test('repl comes first, and the rest of the resident list keeps registry '
      'order', () {
    forEverySurface((
      surface, {
      required withRepl,
      required deferral,
      required mode,
      required reason,
    }) {
      final order = _names(_registry(withRepl: withRepl).tools);
      final resident = [
        for (final name in _names(surface.resident))
          if (name != 'repl' && name != 'search_tools') name,
      ];
      expect(
        resident,
        [...resident]..sort((a, b) => order.indexOf(a) - order.indexOf(b)),
        reason: reason,
      );
      if (withRepl) {
        expect(surface.resident.first.name, 'repl', reason: reason);
      }
    });
  });

  test('every admitted tool is in exactly one list', () {
    forEverySurface((
      surface, {
      required withRepl,
      required deferral,
      required mode,
      required reason,
    }) {
      final profile = profileFor(mode);
      final admitted = {
        for (final t in _registry(
          withRepl: withRepl,
        ).toolsFor(profile.toToolSurfaceSpec()))
          t.name,
      };
      final listed = [
        for (final t in surface.all)
          if (t.name != 'search_tools') t.name,
      ];
      expect(listed.toSet().length, listed.length, reason: reason);
      // A run with repl has no list_my_tools.
      expect(
        listed.toSet(),
        withRepl ? admitted.difference({'list_my_tools'}) : admitted,
        reason: reason,
      );
    });
  });
}
