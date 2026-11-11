// A rig follows its space: the client starts from "may drive" and moves down
// on the first refusal by kind, or on a 403 from one of the rig's HTTP lanes.
import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/rigs/providers/rig_access_provider.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart'
    show rigAccessOf;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RemoteRpcException _refusal(Map<String, Object?>? data) =>
    RemoteRpcException(RpcErrorCodes.unauthorized, 'server words', data);

void main() {
  group('rigAccessFromRefusal', () {
    test('no write grant leaves watching', () {
      expect(
        rigAccessFromRefusal(
          _refusal({'kind': 'repo_grant_required', 'level': 'write'}),
        ),
        RigAccess.watch,
      );
    });

    for (final data in [
      {'kind': 'repo_grant_required', 'level': 'read'},
      {'kind': 'forge_cannot_read', 'forge': 'github'},
      {'kind': 'forge_unconfirmed'},
      {'kind': 'needs_sign_in', 'lane': 'github'},
      {'kind': 'repo_replaced'},
    ]) {
      test('${data['kind']} ${data['level'] ?? ''} leaves nothing', () {
        expect(rigAccessFromRefusal(_refusal(data)), RigAccess.none);
      });
    }

    test('anything that says nothing about the space changes nothing', () {
      expect(rigAccessFromRefusal(_refusal(null)), isNull);
      // One machine carrying somebody else's sign-ins says nothing about the
      // others in its space.
      expect(
        rigAccessFromRefusal(_refusal({'kind': 'rig_holder_only'})),
        isNull,
      );
      expect(
        rigAccessFromRefusal(
          RemoteRpcException(RpcErrorCodes.notFound, 'rig closed'),
        ),
        isNull,
      );
      expect(rigAccessFromRefusal(StateError('timeout')), isNull);
    });
  });

  group('rigAccessOf', () {
    RigView row({bool? canDrive, bool holderOnly = false}) => RigView(
      id: 'rig-1',
      surface: 'browser',
      backendLabel: 'smolvm',
      phase: 'ready',
      accelerated: true,
      conversationId: 'space-1',
      canDrive: canDrive,
      holderOnly: holderOnly,
    );

    test('a row that says follows the row, both ways round', () {
      expect(rigAccessOf(row(canDrive: true), RigAccess.watch), (
        access: RigAccess.drive,
        holderOnly: false,
      ));
      expect(rigAccessOf(row(canDrive: false), RigAccess.drive), (
        access: RigAccess.watch,
        holderOnly: false,
      ));
      expect(
        rigAccessOf(row(canDrive: false, holderOnly: true), RigAccess.drive),
        (access: RigAccess.watch, holderOnly: true),
      );
    });

    test('a row that does not say follows the space', () {
      expect(rigAccessOf(row(), RigAccess.watch), (
        access: RigAccess.watch,
        holderOnly: false,
      ));
      expect(rigAccessOf(row(), RigAccess.drive).access, RigAccess.drive);
    });

    test('an unreadable space wins over any row', () {
      expect(
        rigAccessOf(row(canDrive: true), RigAccess.none).access,
        RigAccess.none,
      );
    });
  });

  group('RigAccessNotifier', () {
    const key = (workspaceId: 'ws-1', spaceId: 'space-1');

    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
      // Held open like a rig tab on screen holds it.
      container.listen(rigAccessProvider(key), (_, _) {});
    });
    tearDown(() => container.dispose());

    RigAccessNotifier notifier() =>
        container.read(rigAccessProvider(key).notifier);
    RigAccess access() => container.read(rigAccessProvider(key)).access;

    test('starts at drive and keeps the refusal that lowered it', () {
      expect(access(), RigAccess.drive);
      final error = _refusal({'kind': 'repo_grant_required', 'level': 'write'});
      expect(notifier().noteRefusal(error), isTrue);
      expect(access(), RigAccess.watch);
      expect(container.read(rigAccessProvider(key)).refusal, same(error));
    });

    test('only ever moves down', () {
      notifier().noteRefusal(_refusal({'kind': 'repo_grant_required'}));
      expect(access(), RigAccess.none);
      notifier().noteRefusal(
        _refusal({'kind': 'repo_grant_required', 'level': 'write'}),
      );
      notifier().noteLaneForbidden(drive: true);
      expect(access(), RigAccess.none);
    });

    test('an unrelated failure is not a refusal', () {
      expect(notifier().noteRefusal(StateError('closed')), isFalse);
      expect(access(), RigAccess.drive);
    });

    test('a drive lane 403 leaves watching, a viewing lane 403 nothing', () {
      notifier().noteLaneForbidden(drive: true);
      expect(access(), RigAccess.watch);
      expect(container.read(rigAccessProvider(key)).refusal, isNull);
      notifier().noteLaneForbidden(drive: false);
      expect(access(), RigAccess.none);
    });

    test('another space is untouched', () {
      notifier().noteLaneForbidden(drive: true);
      const other = (workspaceId: 'ws-1', spaceId: 'space-2');
      container.listen(rigAccessProvider(other), (_, _) {});
      expect(container.read(rigAccessProvider(other)).access, RigAccess.drive);
    });
  });
}
