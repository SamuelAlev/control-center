// What a `[+]` press addresses when a conversation already has machines.
//
// The bug behind this: re-picking "WebKit (VM)" walked back to the tab already
// on screen AND shut its machine down, because the entry always addressed the
// conversation's one WebKit rig and re-opening a deduped tab swapped its
// instance. A press now takes the next machine without a tab instead — but the
// first one is still the DEFAULT machine an agent drives, so a person and an
// agent talking about "the browser" mean one machine until the person opens
// another on purpose.
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slot allocation', () {
    test('the first machine of a kind is the conversation default', () {
      // Null, not "s1": an agent's browser_use opens the conversation's
      // default machine, so the first tab has to be that same one or the
      // human and the agent are looking at two different browsers.
      expect(RigTabSurfaces.allocateSlot(const {}), isNull);
    });

    test('the next press takes the lowest free slot', () {
      expect(RigTabSurfaces.allocateSlot(const {null}), 's2');
      expect(RigTabSurfaces.allocateSlot(const {null, 's2'}), 's3');
      expect(RigTabSurfaces.allocateSlot(const {null, 's2', 's3'}), 's4');
    });

    test('a freed slot is reused before a higher one', () {
      // Closing #2 and opening another gives #2 back rather than drifting to
      // #7 — the numbers are what a person calls these machines.
      expect(RigTabSurfaces.allocateSlot(const {null, 's3'}), 's2');
    });

    test('the default is taken first even when only slots are open', () {
      // The default machine's tab was closed while a second one stayed open:
      // the next press goes back to the default rather than minting s3. On the
      // browser surface that default may be a machine an agent is driving, and
      // landing on it is the point — the alternative is booting a second
      // browser next to the one already doing the work.
      expect(RigTabSurfaces.allocateSlot(const {'s2'}), isNull);
    });
  });

  group('which tabs count as the same kind', () {
    const webkit = RigTabTarget(
      RigTabSurfaces.browser,
      engine: RigBrowserEngine.webkit,
    );

    test('another engine does not number this one', () {
      // A Firefox press counting the Chromium tabs would open its FIRST
      // machine as "#2" — and, worse, skip the default slot an agent drives.
      final taken = RigTabSurfaces.takenSlots(const [
        {'surface': 'browser', 'engine': 'chromium'},
        {'surface': 'browser', 'engine': 'firefox'},
      ], webkit);
      expect(taken, isEmpty);
      expect(RigTabSurfaces.allocateSlot(taken), isNull);
    });

    test('another surface does not number this one', () {
      final taken = RigTabSurfaces.takenSlots(const [
        {'surface': 'computer'},
        {'surface': 'mobile'},
      ], webkit);
      expect(taken, isEmpty);
    });

    test('the same engine counts, slots and all', () {
      final taken = RigTabSurfaces.takenSlots(const [
        {'surface': 'browser', 'engine': 'webkit'},
        {'surface': 'browser', 'engine': 'webkit', 'slot': 's2'},
        {'surface': 'browser', 'engine': 'chromium'},
      ], webkit);
      expect(taken, {null, 's2'});
      expect(RigTabSurfaces.allocateSlot(taken), 's3');
    });

    test('a pre-engines browser tab counts as Chromium', () {
      // Those tabs are Chromium ones — that is all such a layout ever ran — so
      // a Chromium press must see one as taken rather than opening a second
      // machine on top of it.
      const chromium = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.chromium,
      );
      final taken = RigTabSurfaces.takenSlots(const [
        {'surface': 'browser'},
      ], chromium);
      expect(taken, {null});
      expect(RigTabSurfaces.allocateSlot(taken), 's2');
    });

    test('desktops of one conversation number together', () {
      const computer = RigTabTarget(RigTabSurfaces.computer);
      final taken = RigTabSurfaces.takenSlots(const [
        {'surface': 'computer'},
        {'surface': 'computer', 'slot': 's2'},
      ], computer);
      expect(RigTabSurfaces.allocateSlot(taken), 's3');
    });
  });

  group('what a [+] press opens', () {
    test('the first press of a kind takes the default machine', () {
      const webkit = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.webkit,
      );
      expect(RigTabSurfaces.nextTarget(webkit, const []).slotId, isNull);
    });

    test('a press with that tab open takes a second machine', () {
      const webkit = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.webkit,
      );
      final next = RigTabSurfaces.nextTarget(webkit, const [
        {'surface': 'browser', 'engine': 'webkit'},
      ]);
      expect(next.slotId, 's2');
      expect(next.engine, RigBrowserEngine.webkit);
    });

    test('the phone always addresses the one device', () {
      // The mobile surface drives the HOST's attached phone. A second slot is
      // refused by RigSpec, so allocating one would turn a second press into a
      // validation error at Start instead of the machine's tab.
      const phone = RigTabTarget(RigTabSurfaces.mobile);
      expect(
        RigTabSurfaces.nextTarget(phone, const [
          {'surface': 'mobile'},
        ]).slotId,
        isNull,
      );
    });
  });

  group('tab identity', () {
    test('two slots of one engine are two tabs', () {
      const first = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.webkit,
      );
      const second = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.webkit,
        slotId: 's2',
      );
      expect(first.dedupKey, isNot(second.dedupKey));
      expect(first == second, isFalse);
    });

    test('the default machine writes no slot arg', () {
      // A tab that names no slot is what every layout written before slots
      // existed contains, so the default must serialise as exactly that.
      const target = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.chromium,
      );
      expect(target.args.containsKey('slot'), isFalse);
      expect(RigTabSurfaces.slotFromArgs(target.args), isNull);
      expect(target.dedupKey, 'rig:browser:chromium');
    });

    test('a slot round-trips through the tab args', () {
      const target = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.firefox,
        slotId: 's3',
      );
      expect(target.args['slot'], 's3');
      expect(RigTabSurfaces.slotFromArgs(target.args), 's3');
    });

    test('an empty slot arg reads as the default machine', () {
      // Not as a machine called "": a persisted layout is data from disk, and
      // a blank slot must not address a machine nothing will ever open.
      expect(RigTabSurfaces.slotFromArgs(const {'slot': ''}), isNull);
    });
  });

  group('naming', () {
    test('the default machine is unnumbered and the next ones are not', () {
      expect(rigSlotSuffix(null), isNull);
      expect(rigSlotSuffix('s2'), '2');
      expect(rigSlotSuffix('s10'), '10');
    });

    test('an unrecognised slot still tells two machines apart', () {
      // Only this app mints slots, so this is defensive — but a suffix that
      // silently vanished would leave two rows reading "WebKit", which is the
      // one thing the suffix exists to prevent.
      expect(rigSlotSuffix('legacy'), 'legacy');
    });
  });

  group('menu order', () {
    test('browsers, then the phone, then the desktop', () {
      // The desktop is the heavyweight machine a conversation needs least
      // often, so it follows the phone rather than leading the browsers.
      final targets = RigTabSurfaces.targets({
        RigBrowserEngine.chromium,
        RigBrowserEngine.firefox,
        RigBrowserEngine.webkit,
      });
      expect(targets.map((t) => t.surface), [
        RigTabSurfaces.browser,
        RigTabSurfaces.browser,
        RigTabSurfaces.browser,
        RigTabSurfaces.mobile,
        RigTabSurfaces.computer,
      ]);
    });
  });
}
