/// @docImport 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
library;

import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/note_timbre.dart';

/// Converts a MIDI note number to its equal-tempered frequency in Hz.
double midiToHz(int midi) => 440.0 * math.pow(2.0, (midi - 69) / 12.0);

/// The movement plan for one pad voice inside the harmony walk.
///
/// A voice holds one chord tone and may wander between [candidatesMidi]
/// (adjacent entries are adjacent scale tones — a move is always one step along this list). A single-element candidate list makes the voice a pedal that never moves.
class HarmonyVoicePlan {
  /// Creates a plan starting at [initialMidi] with the allowed [candidatesMidi]
  /// (ascending, must contain [initialMidi]) and a relative [moveWeight]
  /// deciding how often this voice is the one that moves.
  const HarmonyVoicePlan({
    required this.initialMidi,
    required this.candidatesMidi,
    this.moveWeight = 1.0,
  });

  /// The MIDI note this voice starts on.
  final int initialMidi;

  /// The ascending set of MIDI notes this voice may hold.
  final List<int> candidatesMidi;

  /// Relative probability of this voice being chosen to move.
  final double moveWeight;
}

/// The mood-fixed musical identity of a soundscape session.
///
/// Everything here is chosen once per mood and never glides: the pentatonic key (any two pentatonic tones are consonant, so no random combination can clash),
/// the pad voicing plans, the motif register, the pulse grid and the amplitude-modulation rate (the rate is an integer multiple of the beat so the modulation reads as musical tremolo).
/// Mood is part of the session key, so a running composer never changes scale.
class MoodMusic {
  const MoodMusic._({
    required this.beatsPerMinute,
    required this.amRateHz,
    required this.harmonyVoices,
    required this.harmonyIntervalSeconds,
    required this.motifScaleMidi,
    required this.subFrequencyHz,
    required this.subFifthGain,
    required this.padPartialGains,
    required this.padSpread,
    required this.padInnerSpread,
    required this.arpLowMidi,
    required this.arpHighMidi,
    required this.hasPulse,
    required this.motifTimbres,
    required this.arpTimbres,
    this.motifAscentBias = 0.5,
  });

  /// The music for [mood].
  factory MoodMusic.of(SoundscapeMood mood) {
    switch (mood) {
      case SoundscapeMood.focus:
        // D major pentatonic (D E F# A B). 120 BPM -> 2 Hz beat, so the
        // 16 Hz beta-band AM (validated best for sustained attention) is an
        // exact 8x subdivision of the pulse. The reference energy tracks
        // run a chill-DnB-style groove (measured 8th/16th articulation at
        // 5-11 Hz over a half-time bass) and spread tonal material over 5-6
        // octaves, so the voicing runs A2 up to A5 (a root that walks, three
        // inner voices, a high sparkle voice) and the motif scale spans
        // three octaves D3-D6. The arp ladder tiles chord tones over the
        // same span; the pulse hangs one octave below the walking root
        // (A1-D2, the measured 50-90 Hz bassline zone) with a high tick and
        // a half-time backbeat that the energy axis fades in.
        return const MoodMusic._(
          beatsPerMinute: 120.0,
          amRateHz: 16.0,
          harmonyVoices: <HarmonyVoicePlan>[
            HarmonyVoicePlan(
              initialMidi: 50,
              candidatesMidi: <int>[45, 47, 50],
              moveWeight: 0.5,
            ),
            HarmonyVoicePlan(
              initialMidi: 57,
              candidatesMidi: <int>[57, 59],
              moveWeight: 0.5,
            ),
            HarmonyVoicePlan(
              initialMidi: 66,
              candidatesMidi: <int>[62, 64, 66, 69],
            ),
            HarmonyVoicePlan(
              initialMidi: 69,
              candidatesMidi: <int>[69, 71, 74],
            ),
            HarmonyVoicePlan(
              initialMidi: 76,
              candidatesMidi: <int>[74, 76, 78, 81],
              moveWeight: 0.7,
            ),
          ],
          harmonyIntervalSeconds: 30.0,
          motifScaleMidi: <int>[
            50, 52, 54, 57, 59, // D3 octave
            62, 64, 66, 69, 71, // D4 octave
            74, 76, 78, 81, 83, // D5 octave
            86, // D6
          ],
          subFrequencyHz: 73.42, // D2
          subFifthGain: 0.0,
          padPartialGains: <double>[1.0, 0.5, 0.26, 0.12],
          padSpread: 0.85,
          padInnerSpread: 1.0,
          arpLowMidi: 50, // D3
          arpHighMidi: 86, // D6
          hasPulse: true,
          motifTimbres: <NoteTimbre>[
            NoteTimbre.bloom,
            NoteTimbre.flute,
            NoteTimbre.reed,
          ],
          arpTimbres: <NoteTimbre>[NoteTimbre.piano, NoteTimbre.guitar],
        );
      case SoundscapeMood.relax:
        // C major pentatonic (C D E G A), root C3. 50 BPM -> 0.8333 Hz beat,
        // so the 10 Hz alpha-band AM is an exact 12x subdivision. No arp, no
        // pulse ("more movement, but never a beat or pulse") — the width
        // comes from warm pad partials and a two-octave motif scale.
        return const MoodMusic._(
          beatsPerMinute: 50.0,
          amRateHz: 10.0,
          harmonyVoices: <HarmonyVoicePlan>[
            HarmonyVoicePlan(initialMidi: 48, candidatesMidi: <int>[48]),
            HarmonyVoicePlan(
              initialMidi: 55,
              candidatesMidi: <int>[55, 57],
              moveWeight: 0.5,
            ),
            HarmonyVoicePlan(
              initialMidi: 64,
              candidatesMidi: <int>[60, 62, 64, 67],
            ),
            HarmonyVoicePlan(
              initialMidi: 67,
              candidatesMidi: <int>[64, 67, 69],
            ),
          ],
          harmonyIntervalSeconds: 90.0,
          motifScaleMidi: <int>[55, 57, 60, 62, 64, 67, 69, 72, 74, 76],
          subFrequencyHz: 65.41, // C2
          subFifthGain: 0.0,
          padPartialGains: <double>[1.0, 0.4, 0.18],
          padSpread: 0.75,
          padInnerSpread: 0.7,
          arpLowMidi: 0,
          arpHighMidi: 0,
          hasPulse: false,
          motifTimbres: <NoteTimbre>[NoteTimbre.bloom, NoteTimbre.flute],
          arpTimbres: <NoteTimbre>[],
        );
      case SoundscapeMood.sleep:
        // A1 drone + fifth + octave, static harmony, no melody: "homogenous and even".
        // The 0.8 Hz AM rate is the continuous pink-noise slow-oscillation stimulation rate from the Papalambros sleep studies.
        // Pure-sine pad partials keep sleep exactly as dark as before.
        return const MoodMusic._(
          beatsPerMinute: 40.0,
          amRateHz: 0.8,
          harmonyVoices: <HarmonyVoicePlan>[
            HarmonyVoicePlan(initialMidi: 33, candidatesMidi: <int>[33]),
            HarmonyVoicePlan(initialMidi: 40, candidatesMidi: <int>[40]),
            HarmonyVoicePlan(initialMidi: 45, candidatesMidi: <int>[45]),
          ],
          harmonyIntervalSeconds: 0.0,
          motifScaleMidi: <int>[],
          subFrequencyHz: 55.0, // A1
          subFifthGain: 0.4,
          padPartialGains: <double>[1.0],
          padSpread: 0.6,
          padInnerSpread: 0.0,
          arpLowMidi: 0,
          arpHighMidi: 0,
          hasPulse: false,
          motifTimbres: <NoteTimbre>[],
          arpTimbres: <NoteTimbre>[],
        );
      case SoundscapeMood.rise:
        // A major pentatonic (A B C# E F#). 96 BPM -> 1.6 Hz beat, so the
        // 16 Hz beta-band AM is an exact 10x subdivision — same attention
        // rate as focus, a slower pulse than 120 so the kit stays gentle.
        // Motifs sit a register above focus (A3–A6); the sub hangs at E2
        // (the measured 30–90 Hz body of the reference tracks).
        return const MoodMusic._(
          beatsPerMinute: 96.0,
          amRateHz: 16.0,
          harmonyVoices: <HarmonyVoicePlan>[
            HarmonyVoicePlan(
              initialMidi: 45,
              candidatesMidi: <int>[40, 42, 45],
              moveWeight: 0.5,
            ),
            HarmonyVoicePlan(
              initialMidi: 57,
              candidatesMidi: <int>[57, 59],
              moveWeight: 0.5,
            ),
            HarmonyVoicePlan(
              initialMidi: 61,
              candidatesMidi: <int>[57, 59, 61, 64],
            ),
            HarmonyVoicePlan(
              initialMidi: 64,
              candidatesMidi: <int>[64, 66, 69],
            ),
            HarmonyVoicePlan(
              initialMidi: 73,
              candidatesMidi: <int>[69, 71, 73, 76],
              moveWeight: 0.7,
            ),
          ],
          harmonyIntervalSeconds: 20.0,
          motifScaleMidi: <int>[
            57, 59, 61, 64, 66, // A3 octave
            69, 71, 73, 76, 78, // A4 octave
            81, 83, 85, 88, 90, // A5 octave
            93, // A6
          ],
          subFrequencyHz: 82.41, // E2
          subFifthGain: 0.0,
          padPartialGains: <double>[1.0, 0.48, 0.24, 0.10],
          padSpread: 0.80,
          padInnerSpread: 0.85,
          arpLowMidi: 57, // A3
          arpHighMidi: 93, // A6
          hasPulse: true,
          motifTimbres: <NoteTimbre>[
            NoteTimbre.bloom,
            NoteTimbre.flute,
            NoteTimbre.piano,
          ],
          arpTimbres: <NoteTimbre>[NoteTimbre.piano, NoteTimbre.guitar],
          motifAscentBias: 0.7,
        );
    }
  }

  /// The (inaudible) pulse grid the motif scheduler and AM rate lock to.
  final double beatsPerMinute;

  /// The amplitude-modulation rate in Hz (16 beta / 10 alpha / 0.8 delta).
  final double amRateHz;

  /// The pad voicing plans, low to high. Voice 0 is the root pedal.
  final List<HarmonyVoicePlan> harmonyVoices;

  /// Seconds between harmony-walk steps; `<= 0` freezes the harmony.
  final double harmonyIntervalSeconds;

  /// The ascending MIDI table motifs walk over; empty disables motifs.
  final List<int> motifScaleMidi;

  /// The grounding sub-drone fundamental in Hz.
  final double subFrequencyHz;

  /// Gain of the sub drone's fifth partner (sleep only), relative to the root.
  final double subFifthGain;

  /// Relative gains of the pad oscillators' harmonic partials (1f, 2f, …).
  ///
  /// `[1.0]` is a pure sine (sleep); focus/relax add a gentle low-passed
  /// harmonic series so each chord tone reads as a rich voice, not a single
  /// spectral line.
  final List<double> padPartialGains;

  /// Stereo spread of the pad's chord tones, `0` mono to `1` hard-panned.
  final double padSpread;

  /// Stereo fan of each pad note's detuned unison around its position —
  /// different frequencies land in different spaces, decorrelating L/R
  /// (the ensemble-width trick). `0` keeps the unison point-panned.
  final double padInnerSpread;

  /// Lowest MIDI note of the broken-chord arp ladder (0 disables the arp).
  final int arpLowMidi;

  /// Highest MIDI note of the broken-chord arp ladder (0 disables the arp).
  final int arpHighMidi;

  /// Whether this mood carries the energy-gated bass pulse layer.
  final bool hasPulse;

  /// The instrument colors the motif line rotates through, phrase by phrase
  /// (a flute phrase answers a piano-ish one, the way sampled-instrument
  /// functional music alternates its lead voices).
  final List<NoteTimbre> motifTimbres;

  /// The instrument colors the arp ladder rotates through per 4-bar section.
  final List<NoteTimbre> arpTimbres;

  /// Probability that a non-edge motif step goes up, in `[0, 1]`.
  ///
  /// `0.5` is the unbiased walk (focus / relax / sleep). Rise is biased
  /// upward so phrases tend to rise. The scheduler still draws one
  /// [SeededPrng.nextBool] per step, so a bias of `0.5` is stream-identical
  /// to the historical coin flip.
  final double motifAscentBias;

  /// Whether this mood plays melodic motifs at all.
  bool get hasMotifs => motifScaleMidi.isNotEmpty;

  /// Whether this mood plays the broken-chord arp layer at all.
  bool get hasArp => arpHighMidi > arpLowMidi;
}
