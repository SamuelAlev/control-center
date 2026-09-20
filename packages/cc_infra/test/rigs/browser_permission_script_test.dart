import 'package:cc_infra/src/rigs/browser_permission_probe.dart';
import 'package:cc_infra/src/rigs/browser_permission_script.dart';
import 'package:cc_infra/src/rigs/cdp_permissions.dart';
import 'package:test/test.dart';

void main() {
  test('the interceptor wraps every prompting API the flyout lists', () {
    expect(kBrowserPermissionInstallScript, contains('persistent-storage'));
    expect(kBrowserPermissionInstallScript, contains('notifications'));
    expect(kBrowserPermissionInstallScript, contains('getUserMedia'));
    expect(kBrowserPermissionInstallScript, contains('getDisplayMedia'));
    expect(kBrowserPermissionInstallScript, contains('geolocation'));
    expect(kBrowserPermissionInstallScript, contains('clipboard'));
    expect(kBrowserPermissionInstallScript, contains('requestMIDIAccess'));
    expect(kBrowserPermissionInstallScript, contains('__ccPermInstalled'));
    expect(kBrowserPermissionPreloadFunction, contains('__ccPermChannel'));
  });

  test('a binding payload becomes a probe', () {
    final probe = probeFromCdpBinding(
      method: 'Runtime.bindingCalled',
      params: {
        'name': kBrowserPermissionBinding,
        'payload':
            '{"id":"1","kind":"persistent-storage","origin":"http://localhost:5173"}',
        'executionContextId': 4,
      },
    );
    expect(probe, isNotNull);
    expect(probe!.id, '1');
    expect(probe.kind, 'persistent-storage');
    expect(probe.origin, 'http://localhost:5173');
    expect(probe.contextId, 4);
  });

  test('a foreign binding is ignored', () {
    expect(
      probeFromCdpBinding(
        method: 'Runtime.bindingCalled',
        params: {'name': 'other', 'payload': '{"id":"1","kind":"camera"}'},
      ),
      isNull,
    );
  });

  test('headless Chromium does not auto-grant persistent storage', () {
    expect(kCdpHeadlessPermissionGrants, isNot(contains('durableStorage')));
    expect(kCdpPermissionTypeByKind['persistent-storage'], 'durableStorage');
  });

  test('parse accepts a queued WebKit payload', () {
    final probe = BrowserPermissionProbe.parse({
      'id': '2',
      'kind': 'notifications',
      'origin': 'https://example.test',
    });
    expect(probe?.id, '2');
    expect(probe?.kind, 'notifications');
  });
}
