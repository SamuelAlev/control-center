import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_slot_key.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:test/test.dart';

void main() {
  RigSlotKey? key(RigSpec spec, [String workspaceId = 'ws1']) =>
      RigSlotKey.of(workspaceId, spec);

  test('a spec with no owner never shares', () {
    expect(key(RigSpec(surface: RigSurface.computer)), isNull);
  });

  test('the same owner, surface and slot is one machine', () {
    expect(
      key(RigSpec(surface: RigSurface.computer, conversationId: 's1')),
      key(RigSpec(surface: RigSurface.computer, conversationId: 's1')),
    );
  });

  test('workspace, owner, slot and exec each make a different machine', () {
    final base = key(
      RigSpec(surface: RigSurface.computer, conversationId: 's1'),
    );
    expect(
      key(RigSpec(surface: RigSurface.computer, conversationId: 's1'), 'ws2'),
      isNot(base),
    );
    expect(
      key(RigSpec(surface: RigSurface.computer, conversationId: 's2')),
      isNot(base),
    );
    expect(
      key(
        RigSpec(
          surface: RigSurface.computer,
          conversationId: 's1',
          slotId: 'second',
        ),
      ),
      isNot(base),
    );
    expect(key(RigSpec.exec(conversationId: 's1')), isNot(base));
  });

  test('the engine matters on the browser surface only', () {
    expect(
      key(
        RigSpec(
          surface: RigSurface.browser,
          conversationId: 's1',
          browserEngine: RigBrowserEngine.firefox,
        ),
      ),
      isNot(
        key(
          RigSpec(
            surface: RigSurface.browser,
            conversationId: 's1',
            browserEngine: RigBrowserEngine.chromium,
          ),
        ),
      ),
    );
  });
}
