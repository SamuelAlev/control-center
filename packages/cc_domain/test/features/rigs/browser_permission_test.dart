import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:test/test.dart';

void main() {
  test('wire names match the Permissions API spellings', () {
    expect(BrowserPermissionKind.persistentStorage.wire, 'persistent-storage');
    expect(BrowserPermissionKind.clipboard.wire, 'clipboard-read');
    expect(
      BrowserPermissionKind.fromWire('geolocation'),
      BrowserPermissionKind.geolocation,
    );
    expect(BrowserPermissionKind.fromWire('unknown'), isNull);
  });

  test('an origin label keeps the host and non-default port', () {
    const entry = BrowserPermissionEntry(
      id: '1',
      origin: 'http://localhost:5173',
      kind: BrowserPermissionKind.persistentStorage,
      decision: BrowserPermissionDecision.pending,
    );
    expect(entry.originLabel, 'localhost:5173');
    expect(entry.toJson()['kind'], 'persistent-storage');
    expect(
      entry.withDecision(BrowserPermissionDecision.granted).decision,
      BrowserPermissionDecision.granted,
    );
  });
}
