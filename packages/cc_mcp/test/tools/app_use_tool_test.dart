import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/window_action.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/rig_use_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeRigs rigs;
  late AppUseTool tool;

  setUp(() {
    rigs = _FakeRigs();
    tool = AppUseTool(rigs: rigs);
  });

  Map<String, dynamic> call(String action, [Map<String, dynamic>? extra]) => {
    'workspace_id': 'ws-1',
    'space_id': 'space-1',
    'agent_id': 'agent-1',
    'action': action,
    ...?extra,
  };

  test('never boots anything when the space has no app', () async {
    final result = await tool.run(call('screenshot'));
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('No desktop app is running'));
    expect(rigs.opened, isEmpty);
  });

  test('finds the app in the space, whichever slot it is in', () async {
    rigs.rigs.add(_rig('r1', slotId: 'desktop'));
    final result = await tool.run(call('list_windows'));
    expect(result.isError, isFalse);
    expect(rigs.acted.single, isA<WindowList>());
  });

  test('ignores a rig in another space', () async {
    rigs.rigs.add(_rig('r1', conversationId: 'space-2'));
    final result = await tool.run(call('screenshot'));
    expect(result.isError, isTrue);
    expect(rigs.acted, isEmpty);
  });

  test('refuses a rig of another surface named by id', () async {
    rigs.rigs.add(_rig('r1', surface: RigSurface.computer));
    final result = await tool.run(call('screenshot', {'rig_id': 'r1'}));
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('app_use drives window rigs'));
  });

  test('passes the window verbs and the computer verbs through', () async {
    rigs.rigs.add(_rig('r1'));
    await tool.run(call('select_window', {'window_id': 7}));
    await tool.run(
      call('left_click', {
        'coordinate': [1, 2],
      }),
    );
    expect(rigs.acted.first, const WindowSelect(7));
    expect(rigs.acted.last.verb, 'left_click');
  });

  test('acts as the agent, so take-over can refuse it', () async {
    rigs.rigs.add(_rig('r1'));
    await tool.run(call('list_windows'));
    expect(rigs.actors.single, const AgentPrincipal('agent-1'));
  });

  test('a refusal from the rig reaches the model as an error', () async {
    rigs.rigs.add(_rig('r1'));
    rigs.answer = RigActionResult.error('A person has taken control.');
    final result = await tool.run(call('type', {'text': 'hi'}));
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('taken control'));
  });

  test('a bad argument is refused before any rig is touched', () async {
    final result = await tool.run(call('select_window'));
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('window_id'));
    expect(rigs.acted, isEmpty);
  });

  group('the description', () {
    test('promises no isolation', () {
      final text = tool.description.toLowerCase();
      expect(text, isNot(contains('enclosed')));
      expect(text, isNot(contains('nothing you do here touches')));
      expect(text, isNot(contains('disposable')));
      expect(text, isNot(contains('isolated')));
      expect(text, contains('not in a vm or sandbox'));
      expect(text, contains('real machine'));
    });

    test('says what the coordinates are', () {
      expect(tool.description, contains('window pixels'));
    });
  });

  test('the schema offers the window verbs and hides what always fails', () {
    final actions =
        ((tool.inputSchema['properties'] as Map)['action'] as Map)['enum']
            as List;
    expect(
      actions,
      containsAll(['list_windows', 'select_window', 'read_ui', 'screenshot']),
    );
    expect(actions, isNot(contains('set_display')));
    expect(actions, isNot(contains('clipboard_read')));
    expect(actions, isNot(contains('clipboard_write')));
  });

  test('declares more than the enclosed tools do', () {
    expect(
      tool.actionClasses,
      containsAll(ComputerUseTool(rigs: rigs).actionClasses),
    );
    expect(tool.actionClasses, contains(ActionClass.fileDelete));
    expect(tool.actionClasses, contains(ActionClass.fileWriteOutsideWorktree));
  });
}

Rig _rig(
  String id, {
  RigSurface surface = RigSurface.window,
  String conversationId = 'space-1',
  String? slotId,
}) {
  final now = DateTime(2026);
  return Rig(
    id: id,
    workspaceId: 'ws-1',
    surface: surface,
    backend: EnclosureBackend.hostWindow,
    status: const RigReady(),
    spec: RigSpec(
      surface: surface,
      conversationId: conversationId,
      slotId: slotId,
    ),
    createdBy: const UserPrincipal('u1'),
    conversationId: conversationId,
    createdAt: now,
    lastActivityAt: now,
  );
}

class _FakeRigs implements RigPort {
  final List<Rig> rigs = [];
  final List<RigSpec> opened = [];
  final List<RigAction> acted = [];
  final List<Principal> actors = [];
  RigActionResult answer = RigActionResult.ok('done');

  @override
  Future<List<Rig>> list(String workspaceId) async => rigs;

  @override
  Future<Rig?> get(String workspaceId, String rigId) async {
    for (final rig in rigs) {
      if (rig.id == rigId) {
        return rig;
      }
    }
    return null;
  }

  @override
  Future<Rig> open({
    required String workspaceId,
    required RigSpec spec,
    required Principal openedBy,
  }) async {
    opened.add(spec);
    throw StateError('app_use must never open a rig.');
  }

  @override
  Future<RigActionResult> act({
    required String workspaceId,
    required String rigId,
    required RigAction action,
    required Principal actor,
  }) async {
    acted.add(action);
    actors.add(actor);
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
