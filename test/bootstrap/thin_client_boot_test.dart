import 'package:cc_infra/cc_infra.dart';
import 'package:control_center/bootstrap/thin_client_boot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the local desktop device id is a stable pairing identity', () {
    expect(localDesktopDeviceId, 'desktop-thin-local');
  });

  test('quit-signal watch is idempotent and can be released', () async {
    final holder = LocalServerProcessHolder(
      CcServerProcess(executable: 'true', args: const []),
    );
    holder.watchQuitSignals();
    holder.watchQuitSignals();
    await holder.stopWatchingQuitSignals();
    await holder.stopWatchingQuitSignals();
  });
}
