import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_state.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/rig_use_tool.dart';
import 'package:test/test.dart';

/// A [RigPort] that records what it was asked and answers from a fixture set.
class _FakeRigPort implements RigPort {
  _FakeRigPort({List<Rig>? rigs}) : _rigs = rigs ?? [];

  final List<Rig> _rigs;

  /// Actions that reached the port, in order.
  final List<({String workspaceId, String rigId, RigAction action})> acted = [];

  /// Specs that were opened.
  final List<RigSpec> opened = [];

  /// What `act` should answer with.
  RigActionResult response = RigActionResult.ok('done');

  @override
  Future<RigActionResult> act({
    required String workspaceId,
    required String rigId,
    required RigAction action,
    required Principal actor,
  }) async {
    acted.add((workspaceId: workspaceId, rigId: rigId, action: action));
    return response;
  }

  @override
  Future<RigBrowserState?> browserState({
    required String workspaceId,
    required String rigId,
  }) async => null;

  // The clipboard and file lanes are reachable only from the HUMAN client
  // (the signed `/rig/clipboard` and `/rig/files` routes), never through an
  // MCP tool — an agent moves clipboard content with the `clipboard_read` /
  // `clipboard_write` ACTIONS, which arrive through [act] above. These stubs
  // exist to satisfy the interface, and answering emptily is what the port
  // itself does for a rig that is not there.

  @override
  Future<RigClipboardData> readClipboard({
    required String workspaceId,
    required String rigId,
    required Principal actor,
    RigClipboardSelection selection = RigClipboardSelection.clipboard,
  }) async => RigClipboardData.empty;

  @override
  Future<RigActionResult> writeClipboard({
    required String workspaceId,
    required String rigId,
    required RigClipboardData data,
    required Principal actor,
  }) async => RigActionResult.ok('written');

  @override
  Future<RigDropResult> dropFiles({
    required String workspaceId,
    required String rigId,
    required RigDropRequest request,
    required Principal actor,
  }) async => RigDropResult.error('not wired in this fake');

  @override
  Future<RigFileBytes?> readFile({
    required String workspaceId,
    required String rigId,
    required String guestPath,
    required Principal actor,
  }) async => null;

  @override
  Future<void> close({
    required String workspaceId,
    required String rigId,
    RigCloseReason? reason,
  }) async {
    _rigs.removeWhere((r) => r.id == rigId && r.workspaceId == workspaceId);
  }

  @override
  Future<void> disposeAll() async {}

  @override
  Future<Rig?> get(String workspaceId, String rigId) async {
    for (final rig in _rigs) {
      // Scoped by workspace on purpose: an id alone never identifies a rig.
      if (rig.id == rigId && rig.workspaceId == workspaceId) {
        return rig;
      }
    }
    return null;
  }

  @override
  Future<List<Rig>> list(String workspaceId) async =>
      _rigs.where((r) => r.workspaceId == workspaceId).toList();

  @override
  Future<Rig> open({
    required String workspaceId,
    required RigSpec spec,
    required Principal openedBy,
  }) async {
    opened.add(spec);
    final rig = _rig(
      id: 'opened-${opened.length}',
      workspaceId: workspaceId,
      surface: spec.surface,
      conversationId: spec.conversationId,
    );
    _rigs.add(rig);
    return rig;
  }

  @override
  Future<RigStream?> watchStream({
    required String workspaceId,
    required String rigId,
    required RigWatchRequest request,
  }) async => null;

  @override
  Future<Rig> releaseControl({
    required String workspaceId,
    required String rigId,
    required Principal actor,
  }) async => (await get(workspaceId, rigId))!;

  @override
  Future<Rig> takeControl({
    required String workspaceId,
    required String rigId,
    required Principal actor,
  }) async => (await get(workspaceId, rigId))!;

  @override
  Future<RigCapabilities> probe() async => RigCapabilities.none;

  @override
  List<Map<String, dynamic>> imageStatuses() => const [];

  @override
  Future<void> downloadImage(String imageId) async {}

  @override
  Future<void> importImage({
    required String imageId,
    required String sourcePath,
  }) async {}

  @override
  Stream<List<Rig>> watch(String workspaceId) =>
      Stream.value(_rigs.where((r) => r.workspaceId == workspaceId).toList());
}

Rig _rig({
  required String id,
  required String workspaceId,
  RigSurface surface = RigSurface.computer,
  RigStatus status = const RigReady(),
  String? conversationId,
}) => Rig(
  id: id,
  workspaceId: workspaceId,
  surface: surface,
  backend: EnclosureBackend.qemuHvf,
  status: status,
  spec: RigSpec(surface: surface, conversationId: conversationId),
  createdBy: const AgentPrincipal('a1'),
  conversationId: conversationId,
  createdAt: DateTime.utc(2026),
  lastActivityAt: DateTime.utc(2026),
);

void main() {
  group('argument validation', () {
    test('workspace_id is required', () async {
      final port = _FakeRigPort();
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'action': 'screenshot'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
      expect(
        port.acted,
        isEmpty,
        reason: 'Nothing may reach a machine before the scope is known.',
      );
    });

    test('a malformed action is refused with a usable message', () async {
      final port = _FakeRigPort();
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'action': 'mouse_move'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('coordinate'));
      expect(port.acted, isEmpty);
    });
  });

  group('workspace isolation', () {
    test('a rig in another workspace reads as absent', () async {
      final port = _FakeRigPort(
        rigs: [_rig(id: 'r1', workspaceId: 'other')],
      );
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1', 'action': 'screenshot'});
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('No rig "r1" in this workspace'),
        reason:
            'Distinguishing "forbidden" from "absent" would confirm the id '
            'exists somewhere.',
      );
      expect(port.acted, isEmpty);
    });

    test('rig_list only sees its own workspace', () async {
      final port = _FakeRigPort(
        rigs: [
          _rig(id: 'mine', workspaceId: 'ws1'),
          _rig(id: 'theirs', workspaceId: 'ws2'),
        ],
      );
      final result = await RigListTool(
        rigs: port,
      ).call({'workspace_id': 'ws1'});
      final decoded =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      final ids = [for (final r in decoded['rigs'] as List) (r as Map)['id']];
      expect(ids, ['mine']);
    });

    test('rig_close refuses a foreign rig', () async {
      final port = _FakeRigPort(
        rigs: [_rig(id: 'r1', workspaceId: 'other')],
      );
      final result = await RigCloseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1'});
      expect(result.isError, isTrue);
      expect(await port.get('other', 'r1'), isNotNull);
    });
  });

  group('surface matching', () {
    test('a tool refuses a rig of the wrong surface', () async {
      final port = _FakeRigPort(
        rigs: [_rig(id: 'r1', workspaceId: 'ws1', surface: RigSurface.browser)],
      );
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1', 'action': 'screenshot'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('browser rig'));
    });

    test('a space reuses its existing rig', () async {
      final port = _FakeRigPort(
        rigs: [_rig(id: 'r1', workspaceId: 'ws1', conversationId: 'c1')],
      );
      await ComputerUseTool(rigs: port).call({
        'workspace_id': 'ws1',
        'space_id': 'c1',
        'action': 'screenshot',
      });
      expect(
        port.opened,
        isEmpty,
        reason: 'A second call must not boot a second copy of the machine.',
      );
      expect(port.acted.single.rigId, 'r1');
    });

    test('a space with no rig gets one opened', () async {
      final port = _FakeRigPort();
      await BrowserUseTool(rigs: port).call({
        'workspace_id': 'ws1',
        'space_id': 'c1',
        'action': 'screenshot',
      });
      expect(port.opened.single.surface, RigSurface.browser);
      expect(port.opened.single.conversationId, 'c1');
    });
  });

  group('results', () {
    test('an image comes back as an image content piece', () async {
      final port =
          _FakeRigPort(
              rigs: [_rig(id: 'r1', workspaceId: 'ws1')],
            )
            ..response = const RigActionResult(
              text: 'the desktop',
              imageBase64: 'QUJD',
              imageMediaType: 'image/jpeg',
            );
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1', 'action': 'screenshot'});
      expect(result.isError, isFalse);
      final imagePiece = result.content.firstWhere((c) => c.isImage);
      expect(imagePiece.data, 'QUJD');
      expect(imagePiece.mimeType, 'image/jpeg');
      // Text stays present: an image with no words is unreadable to a
      // text-only provider and worthless after compaction sheds the frame.
      expect(result.content.first.text, contains('the desktop'));
    });

    test('a take-over refusal is surfaced verbatim', () async {
      final port =
          _FakeRigPort(
              rigs: [_rig(id: 'r1', workspaceId: 'ws1')],
            )
            ..response = RigActionResult.error(
              'A person has taken control of this rig.',
            );
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1', 'action': 'left_click'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('taken control'));
    });

    test('a still-provisioning rig says so instead of acting', () async {
      final port = _FakeRigPort(
        rigs: [
          _rig(
            id: 'r1',
            workspaceId: 'ws1',
            status: const RigProvisioning(step: 'Creating the disk overlay'),
          ),
        ],
      );
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1', 'action': 'left_click'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Creating the disk overlay'));
      expect(
        port.acted,
        isEmpty,
        reason: 'A click into a booting machine lands nowhere.',
      );
    });

    test('a failed rig reports why', () async {
      final port = _FakeRigPort(
        rigs: [
          _rig(
            id: 'r1',
            workspaceId: 'ws1',
            status: const RigFailed('QEMU exited immediately'),
          ),
        ],
      );
      final result = await ComputerUseTool(
        rigs: port,
      ).call({'workspace_id': 'ws1', 'rig_id': 'r1', 'action': 'screenshot'});
      expect(result.content.first.text, contains('QEMU exited immediately'));
    });
  });

  group('declared effects', () {
    test('the use tools declare enclosure control', () {
      final port = _FakeRigPort();
      for (final tool in [
        ComputerUseTool(rigs: port),
        BrowserUseTool(rigs: port),
        MobileUseTool(rigs: port),
      ]) {
        expect(tool.actionClasses, contains(ActionClass.enclosureControl));
        expect(tool.actionClasses, contains(ActionClass.processSpawn));
        expect(tool.actionClasses, contains(ActionClass.networkEgress));
      }
    });

    test('listing rigs is effect-free but closing one is not', () {
      final port = _FakeRigPort();
      expect(RigListTool(rigs: port).actionClasses, isEmpty);
      expect(
        RigCloseTool(rigs: port).actionClasses,
        contains(ActionClass.enclosureControl),
      );
    });

    test('every use tool requires workspace_id in its schema', () {
      final port = _FakeRigPort();
      for (final tool in [
        ComputerUseTool(rigs: port),
        BrowserUseTool(rigs: port),
        MobileUseTool(rigs: port),
        RigListTool(rigs: port),
        RigCloseTool(rigs: port),
      ]) {
        expect(
          tool.inputSchema['required'],
          contains('workspace_id'),
          reason: '${tool.name} must be workspace-scoped at the schema level.',
        );
      }
    });
  });
}
