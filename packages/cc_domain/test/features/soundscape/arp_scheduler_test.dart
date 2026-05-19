import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/arp_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/motif_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/scale.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:test/test.dart';

const double _sampleRate = 8000.0;
const int _block = 1024;

/// The focus chord the pad holds at build time (root walk D3 + inner voices
/// + sparkle E5).
const List<int> _focusChord = <int>[50, 57, 66, 69, 76];

class _Note {
  _Note(this.atSample, this.event);
  final int atSample;
  final MotifEvent event;
}

ArpScheduler _focusArp(int seed) {
  final music = MoodMusic.of(SoundscapeMood.focus);
  return ArpScheduler(
    _sampleRate,
    SeededPrng(seed),
    beatsPerMinute: music.beatsPerMinute,
    lowMidi: music.arpLowMidi,
    highMidi: music.arpHighMidi,
  );
}

List<_Note> _run(
  ArpScheduler scheduler, {
  required double seconds,
  required double fill,
  List<int> chordMidi = _focusChord,
}) {
  final notes = <_Note>[];
  final blocks = (seconds * _sampleRate / _block).round();
  for (var b = 0; b < blocks; b++) {
    for (final event in scheduler.advance(
      _block,
      fill: fill,
      chordMidi: chordMidi,
    )) {
      notes.add(_Note(b * _block + event.offsetFrames, event));
    }
  }
  return notes;
}

int _toMidi(double frequencyHz) =>
    (69 + 12 * (math.log(frequencyHz / 440.0) / math.ln2)).round();

void main() {
  final music = MoodMusic.of(SoundscapeMood.focus);

  group('ArpScheduler', () {
    test('every note is a chord tone inside the configured range', () {
      final notes = _run(_focusArp(7), seconds: 600, fill: 0.5);
      expect(notes, isNotEmpty);
      final chordClasses = <int>{for (final m in _focusChord) m % 12};
      for (final note in notes) {
        final midi = _toMidi(note.event.frequencyHz);
        expect(midi, inInclusiveRange(music.arpLowMidi, music.arpHighMidi));
        expect(
          chordClasses,
          contains(midi % 12),
          reason: 'midi $midi is not a chord tone',
        );
      }
    });

    test('sweeps a multi-octave register, not a single octave', () {
      final notes = _run(_focusArp(13), seconds: 900, fill: 0.5);
      final midis = <int>{for (final n in notes) _toMidi(n.event.frequencyHz)};
      final lo = midis.reduce(math.min);
      final hi = midis.reduce(math.max);
      expect(
        hi - lo,
        greaterThanOrEqualTo(24),
        reason: 'the ladder must span at least two octaves',
      );
    });

    test('density rises with fill and is silent at zero', () {
      expect(_run(_focusArp(3), seconds: 600, fill: 0.0), isEmpty);
      final sparse = _run(_focusArp(3), seconds: 600, fill: 0.15).length;
      final dense = _run(_focusArp(3), seconds: 600, fill: 0.75).length;
      expect(sparse, greaterThan(0));
      expect(dense, greaterThan(sparse * 2));
    });

    test('a focus-like fill lands in the reference event-density zone', () {
      // ~0.24 base fill at 96 BPM should produce tens of events per minute
      // (the analysed tracks carry ~40/min across all layers).
      final notes = _run(_focusArp(11), seconds: 1200, fill: 0.24);
      final perMinute = notes.length / 20.0;
      expect(perMinute, greaterThan(15.0));
      expect(perMinute, lessThan(70.0));
    });

    test('notes land on the eighth-note grid (within jitter)', () {
      final notes = _run(_focusArp(29), seconds: 300, fill: 0.6);
      final stepSamples = _sampleRate * 30.0 / music.beatsPerMinute;
      const jitterSamples = 0.010 * _sampleRate; // +/- 9 ms + rounding
      for (final note in notes) {
        final phase = note.atSample % stepSamples;
        final offGrid = math.min(phase, stepSamples - phase);
        expect(
          offGrid,
          lessThanOrEqualTo(jitterSamples),
          reason: 'onset ${note.atSample} is off-grid by $offGrid samples',
        );
      }
    });

    test('the event stream is invariant to the live fill value', () {
      // Same seed, different fills: the sounding notes of the sparse run
      // must be a subset of the dense run at identical sample positions.
      final sparse = _run(_focusArp(41), seconds: 600, fill: 0.2);
      final dense = _run(_focusArp(41), seconds: 600, fill: 0.9);
      final denseOnsets = <int, double>{
        for (final n in dense) n.atSample: n.event.frequencyHz,
      };
      for (final n in sparse) {
        expect(
          denseOnsets[n.atSample],
          n.event.frequencyHz,
          reason: 'sparse note at ${n.atSample} missing from dense stream',
        );
      }
    });

    test('holds one instrument color per 4-bar section, rotating between '
        'sections', () {
      final scheduler = ArpScheduler(
        _sampleRate,
        SeededPrng(63),
        beatsPerMinute: music.beatsPerMinute,
        lowMidi: music.arpLowMidi,
        highMidi: music.arpHighMidi,
        timbreCount: 2,
      );
      final notes = _run(scheduler, seconds: 1800, fill: 0.6);
      expect(notes, isNotEmpty);
      final stepSamples = _sampleRate * 30.0 / music.beatsPerMinute;
      final bySection = <int, Set<int>>{};
      final timbres = <int>{};
      for (final n in notes) {
        expect(n.event.timbre, inInclusiveRange(0, 1));
        timbres.add(n.event.timbre);
        // The grid eases in by one bar (8 steps), so section boundaries sit
        // at grid steps 8, 40, 72, …
        final step = (n.atSample / stepSamples).round() - 8;
        bySection.putIfAbsent(step ~/ 32, () => <int>{}).add(n.event.timbre);
      }
      expect(
        timbres.length,
        2,
        reason: 'both colors must appear over half an hour',
      );
      for (final entry in bySection.entries) {
        expect(
          entry.value.length,
          1,
          reason: 'section ${entry.key} mixes timbres',
        );
      }
    });

    test('is deterministic for a given seed', () {
      final a = _run(_focusArp(99), seconds: 300, fill: 0.5);
      final b = _run(_focusArp(99), seconds: 300, fill: 0.5);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].atSample, b[i].atSample);
        expect(a[i].event.frequencyHz, b[i].event.frequencyHz);
        expect(a[i].event.velocity, b[i].event.velocity);
        expect(a[i].event.pan, b[i].event.pan);
      }
    });

    test('re-ladders when the chord changes', () {
      final scheduler = _focusArp(55);
      _run(scheduler, seconds: 120, fill: 0.6);
      // Root walked D3 -> B2: B enters the chord classes.
      final changed = _run(
        scheduler,
        seconds: 600,
        fill: 0.6,
        chordMidi: const <int>[47, 57, 66, 69, 76],
      );
      final classes = <int>{
        for (final n in changed) _toMidi(n.event.frequencyHz) % 12,
      };
      expect(classes, contains(47 % 12));
    });
  });
}
