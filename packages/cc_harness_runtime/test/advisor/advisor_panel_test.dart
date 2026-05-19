import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:test/test.dart';

class _Fixed implements Advisor {
  _Fixed(this.note, {this.throws = false});
  final AdvisorNote? note;
  final bool throws;
  int reviews = 0;
  int resets = 0;

  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async {
    reviews++;
    if (throws) {
      throw StateError('advisor exploded');
    }
    return note;
  }

  @override
  void reset() => resets++;
}

AdvisorNote _note(AdvisorSeverity severity, String text) =>
    AdvisorNote(text, severity: severity);

void main() {
  final history = [HarnessMessage.user('do the thing')];

  test('surfaces the most severe note', () async {
    final panel = AdvisorPanel([
      _Fixed(_note(AdvisorSeverity.nit, 'style')),
      _Fixed(_note(AdvisorSeverity.blocker, 'this breaks the build')),
      _Fixed(_note(AdvisorSeverity.concern, 'maybe wrong')),
    ]);
    final note = await panel.review(history);
    expect(note!.severity, AdvisorSeverity.blocker);
    expect(note.note, 'this breaks the build');
  });

  test('a tie leaves the more senior advisor in place', () async {
    // Roster order is precedence: the first-declared advisor is the senior one.
    final panel = AdvisorPanel([
      _Fixed(_note(AdvisorSeverity.concern, 'first')),
      _Fixed(_note(AdvisorSeverity.concern, 'second')),
    ]);
    expect((await panel.review(history))!.note, 'first');
  });

  test('injects at most ONE note per turn', () async {
    // Three notes a turn does not produce three times the course correction;
    // it produces an agent that stops reading advisories.
    final panel = AdvisorPanel([
      _Fixed(_note(AdvisorSeverity.concern, 'a')),
      _Fixed(_note(AdvisorSeverity.concern, 'b')),
    ]);
    expect(await panel.review(history), isA<AdvisorNote>());
  });

  test('silence from everyone is silence', () async {
    final panel = AdvisorPanel([_Fixed(null), _Fixed(null)]);
    expect(await panel.review(history), isNull);
  });

  test('a throwing advisor costs its note, not the run', () async {
    final good = _Fixed(_note(AdvisorSeverity.concern, 'still here'));
    final panel = AdvisorPanel([_Fixed(null, throws: true), good]);
    expect((await panel.review(history))!.note, 'still here');
    expect(good.reviews, 1);
  });

  test('every member reviews the same turn', () async {
    final a = _Fixed(null);
    final b = _Fixed(null);
    await AdvisorPanel([a, b]).review(history);
    expect(a.reviews, 1);
    expect(b.reviews, 1);
  });

  test('reset re-primes every member', () {
    final a = _Fixed(null);
    final b = _Fixed(null);
    AdvisorPanel([a, b]).reset();
    expect(a.resets, 1);
    expect(b.resets, 1);
  });

  test('an empty panel is silent, not an error', () async {
    expect(await AdvisorPanel(const []).review(history), isNull);
    AdvisorPanel(const []).reset();
  });
}
