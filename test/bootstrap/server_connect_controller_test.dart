import 'dart:async';

import 'package:control_center/bootstrap/server_connect_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session {
  _Session(this.name);

  final String name;
  bool retired = false;
}

void main() {
  testWidgets('a second switch to the same server joins the first; another '
      'server is refused while one connects', (tester) async {
    // A double click used to run two switches at once — for the bundled
    // server, two children on one data directory.
    final controller = ServerConnectController<_Session>(
      retire: (s) async => s.retired = true,
    );
    final pending = Completer<_Session>();
    var connects = 0;
    Future<_Session> connect() {
      connects++;
      return pending.future;
    }

    final first = controller.switchTo('local', connect);
    final second = controller.switchTo('local', connect);
    await expectLater(
      controller.switchTo('remote', () async => _Session('remote')),
      throwsStateError,
    );
    pending.complete(_Session('local'));
    await Future.wait([first, second]);

    expect(connects, 1);
    expect(controller.current?.name, 'local');
    expect(controller.isSwitching, isFalse);
  });

  testWidgets('a failed switch keeps the live session and frees the gate', (
    tester,
  ) async {
    final controller = ServerConnectController<_Session>(
      retire: (s) async => s.retired = true,
    );
    final live = _Session('live');
    controller.adopt(live);

    await expectLater(
      controller.switchTo('remote', () async => throw StateError('refused')),
      throwsStateError,
    );

    expect(controller.current, same(live));
    expect(controller.isSwitching, isFalse);
  });

  testWidgets('the outgoing session retires only after the remount frame', (
    tester,
  ) async {
    final controller = ServerConnectController<_Session>(
      retire: (s) async => s.retired = true,
    );
    final old = _Session('old');
    controller.adopt(old);
    controller.adopt(_Session('new'));

    expect(old.retired, isFalse);
    await tester.pump();
    expect(old.retired, isTrue);
  });
}
