import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/am_modulator.dart';
import 'package:cc_domain/features/soundscape/domain/synth/lfo.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/arp_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/harmony_walk.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/motif_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/note_timbre.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/pulse_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/scale.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:cc_domain/features/soundscape/domain/synth/soundscape_mixer.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/motif_voice.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/noise_bed.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/pad_voice.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/sub_drone.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/tick_voice.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_arrangement.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';

/// The top-level generative audio engine for one soundscape.
///
/// Builds its layers — noise bed, voice-led pad, grounding sub drone,
/// phrase-scheduled motif swells, a broken-chord arp ladder, and an
/// energy-gated bass pulse — seeded deterministically from
/// [SoundscapeContext.seed], so two composers built from the same context
/// render identical audio (for the same block sizes). [renderBlock] produces
/// successive interleaved stereo blocks; [updateContext] retargets every
/// glidable parameter (gains, cutoffs, melodic density, AM depth, reverb)
/// through [ParamRamp]s so the arrangement morphs smoothly as
/// weather/daypart change — it never rebuilds or restarts the voices, so
/// there is no click or dropout. The mood-level musical identity (pentatonic
/// key, voicing, tempo, AM rate) is fixed at construction: mood is part of
/// the session key and a running session never changes it.
///
/// On top of the context mapping, a web of seeded [DriftLfo]s at
/// incommensurate periods and a slow cyclic intensity arc keep the mix in
/// constant sub-perceptual motion (nothing ever repeats, nothing ever jumps),
/// and sleep sessions wind their brightness and level down over the first
/// twenty minutes before holding a near-static floor.
class SoundscapeComposer {
  /// Builds a composer for [context] at [sampleRate] Hz.
  factory SoundscapeComposer({
    required int sampleRate,
    required SoundscapeContext context,
  }) {
    final targets = SoundscapeTargets.fromContext(context);
    final music = MoodMusic.of(context.mood);
    final sr = sampleRate.toDouble();
    final seed = context.seed;

    final noise = NoiseBed(
      SeededPrng(seed ^ 0x9E37),
      sr,
      color: targets.noiseColor,
      cutoffHz: targets.noiseCutoffHz,
      gustDepthDb: targets.gustDepthDb,
    );
    final harmony = HarmonyWalk(
      sr,
      SeededPrng(seed ^ 0x48A2),
      voices: music.harmonyVoices,
      intervalSeconds: music.harmonyIntervalSeconds,
    );
    final pad = PadVoice(
      sr,
      SeededPrng(seed ^ 0x1B56),
      initialFrequencies: <double>[
        for (final midi in harmony.currentMidi) midiToHz(midi),
      ],
      detuneCents: targets.padDetuneCents,
      cutoffHz: targets.padCutoffHz,
      spread: music.padSpread,
      partialGains: music.padPartialGains,
      innerSpread: music.padInnerSpread,
    );
    final sub = SubDrone(
      sr,
      SeededPrng(seed ^ 0x77C1),
      frequencyHz: music.subFrequencyHz,
      fifthGain: music.subFifthGain,
    );
    // Timbre banks: one MotifVoice per instrument color; the schedulers tag
    // every event with the color its phrase/section speaks in.
    final motifTimbres = music.motifTimbres.isNotEmpty
        ? music.motifTimbres
        : const <NoteTimbre>[NoteTimbre.bloom];
    final arpTimbres = music.arpTimbres.isNotEmpty
        ? music.arpTimbres
        : const <NoteTimbre>[NoteTimbre.piano];
    final scheduler = music.hasMotifs
        ? MotifScheduler(
            sr,
            SeededPrng(seed ^ 0x27D4),
            scaleMidi: music.motifScaleMidi,
            beatsPerMinute: music.beatsPerMinute,
            timbreCount: motifTimbres.length,
          )
        : null;
    final motifVoices = <MotifVoice>[
      if (music.hasMotifs)
        for (final timbre in motifTimbres)
          MotifVoice(
            sr,
            cutoffHz: timbre.cutoffHz,
            partialGains: timbre.partialGains,
            vibratoRateHz: timbre.vibratoRateHz,
            vibratoCents: timbre.vibratoCents,
          ),
    ];
    final arpScheduler = music.hasArp
        ? ArpScheduler(
            sr,
            SeededPrng(seed ^ 0x3C99),
            beatsPerMinute: music.beatsPerMinute,
            lowMidi: music.arpLowMidi,
            highMidi: music.arpHighMidi,
            timbreCount: arpTimbres.length,
          )
        : null;
    final arpVoices = <MotifVoice>[
      if (music.hasArp)
        for (final timbre in arpTimbres)
          MotifVoice(
            sr,
            maxVoices: 10,
            cutoffHz: timbre.cutoffHz,
            partialGains: timbre.partialGains,
            vibratoRateHz: timbre.vibratoRateHz,
            vibratoCents: timbre.vibratoCents,
          ),
    ];
    final pulseScheduler = music.hasPulse
        ? PulseScheduler(
            sr,
            SeededPrng(seed ^ 0x6B15),
            beatsPerMinute: music.beatsPerMinute,
          )
        : null;
    // Deep low-pass turns the pulse into a dark thump, never a click; the
    // fundamental-heavy recipe keeps its harmonics out of the mids.
    final pulseVoice = music.hasPulse
        ? MotifVoice(
            sr,
            maxVoices: 4,
            cutoffHz: 300.0,
            partialGains: const <double>[1.0, 0.32, 0.1],
          )
        : null;
    // The tick: gated noise bursts — the closed-hat analogue that gives the
    // energetic end its fast articulation. Noise, never a tone: a tonal
    // ping at hat register reads as an alarm bell.
    final tickVoice = music.hasPulse
        ? TickVoice(SeededPrng(seed ^ 0x71CC), sr)
        : null;
    // The backbeat: a muffled mid thock on beat three (half-time skeleton).
    final backbeatVoice = music.hasPulse
        ? MotifVoice(
            sr,
            maxVoices: 4,
            cutoffHz: 1400.0,
            partialGains: const <double>[1.0, 0.55, 0.3, 0.12],
          )
        : null;
    final am = AmModulator(sr, rateHz: music.amRateHz);
    final mixer = SoundscapeMixer(sr)
      ..setReverbWet(targets.reverbWet)
      ..setReverbDecay(targets.reverbDecay)
      ..setReverbDamp(targets.reverbDamp)
      ..setPreDelayMs(targets.preDelayMs)
      ..setWetHighPassHz(targets.wetHighPassHz);

    final driftPrng = SeededPrng(seed ^ 0x5EED);
    return SoundscapeComposer._(
      sampleRate: sampleRate,
      context: context,
      music: music,
      noise: noise,
      harmony: harmony,
      pad: pad,
      sub: sub,
      scheduler: scheduler,
      motifTimbres: motifTimbres,
      motifVoices: motifVoices,
      arpScheduler: arpScheduler,
      arpTimbres: arpTimbres,
      arpVoices: arpVoices,
      pulseScheduler: pulseScheduler,
      pulseVoice: pulseVoice,
      tickVoice: tickVoice,
      backbeatVoice: backbeatVoice,
      am: am,
      mixer: mixer,
      padCutoffDrift: DriftLfo(sr, driftPrng, periodSeconds: 73.0),
      padGainDrift: DriftLfo(sr, driftPrng, periodSeconds: 131.0),
      motifDensityDrift: DriftLfo(sr, driftPrng, periodSeconds: 293.0),
      wetDrift: DriftLfo(sr, driftPrng, periodSeconds: 41.0),
      // The "chapter" lane: a slow arp-emphasis wander so the density layer
      // surges and recedes over minutes, the way the reference tracks rotate
      // their layer sets in ~5-minute sections.
      arpDrift: DriftLfo(sr, driftPrng, periodSeconds: 331.0),
      intensityArc: Lfo(sr, 1.0 / 900.0, phase: driftPrng.nextDouble()),
      targets: targets,
    );
  }

  SoundscapeComposer._({
    required this.sampleRate,
    required SoundscapeContext context,
    required MoodMusic music,
    required NoiseBed noise,
    required HarmonyWalk harmony,
    required PadVoice pad,
    required SubDrone sub,
    required MotifScheduler? scheduler,
    required List<NoteTimbre> motifTimbres,
    required List<MotifVoice> motifVoices,
    required ArpScheduler? arpScheduler,
    required List<NoteTimbre> arpTimbres,
    required List<MotifVoice> arpVoices,
    required PulseScheduler? pulseScheduler,
    required MotifVoice? pulseVoice,
    required TickVoice? tickVoice,
    required MotifVoice? backbeatVoice,
    required AmModulator am,
    required SoundscapeMixer mixer,
    required DriftLfo padCutoffDrift,
    required DriftLfo padGainDrift,
    required DriftLfo motifDensityDrift,
    required DriftLfo wetDrift,
    required DriftLfo arpDrift,
    required Lfo intensityArc,
    required SoundscapeTargets targets,
  }) : _context = context,
       _music = music,
       _noise = noise,
       _harmony = harmony,
       _pad = pad,
       _sub = sub,
       _scheduler = scheduler,
       _motifTimbres = motifTimbres,
       _motifVoices = motifVoices,
       _arpScheduler = arpScheduler,
       _arpTimbres = arpTimbres,
       _arpVoices = arpVoices,
       _pulseScheduler = pulseScheduler,
       _pulseVoice = pulseVoice,
       _tickVoice = tickVoice,
       _backbeatVoice = backbeatVoice,
       _am = am,
       _mixer = mixer,
       _padCutoffDrift = padCutoffDrift,
       _padGainDrift = padGainDrift,
       _motifDensityDrift = motifDensityDrift,
       _wetDrift = wetDrift,
       _arpDrift = arpDrift,
       _intensityArc = intensityArc,
       _noiseGain = ParamRamp(targets.noiseGain),
       _noiseColor = ParamRamp(targets.noiseColor),
       _noiseCutoff = ParamRamp(targets.noiseCutoffHz),
       _gustDepth = ParamRamp(targets.gustDepthDb),
       _padGain = ParamRamp(targets.padGain),
       _padCutoff = ParamRamp(targets.padCutoffHz),
       _motifGain = ParamRamp(targets.motifGain),
       _motifDensity = ParamRamp(targets.motifNotesPerMinute),
       _motifAttack = ParamRamp(targets.motifAttackSeconds),
       _motifRelease = ParamRamp(targets.motifReleaseSeconds),
       _arpGain = ParamRamp(targets.arpGain),
       _arpFill = ParamRamp(targets.arpFill),
       _arpAttack = ParamRamp(targets.arpAttackSeconds),
       _arpRelease = ParamRamp(targets.arpReleaseSeconds),
       _pulseGain = ParamRamp(targets.pulseGain),
       _pulseFill = ParamRamp(targets.pulseFill),
       _subGain = ParamRamp(targets.subGain),
       _amDepth = ParamRamp(targets.amDepth),
       _reverbWet = ParamRamp(targets.reverbWet),
       _reverbDecay = ParamRamp(targets.reverbDecay),
       _reverbDamp = ParamRamp(targets.reverbDamp),
       _tuneEnergy = ParamRamp(SoundscapeTune.neutral.energy),
       _tuneBrightness = ParamRamp(SoundscapeTune.neutral.brightness);

  /// Seconds over which [updateContext] glides to the new arrangement.
  static const double rampSeconds = 10.0;

  /// Seconds over which [updateTune] glides — short enough that dragging the
  /// tune pad feels live, long enough to stay click-free.
  static const double tuneRampSeconds = 1.5;

  /// Seconds a sleep session takes to wind down to its static floor.
  static const double sleepWindDownSeconds = 1200.0;

  /// The render sample rate in Hz.
  final int sampleRate;

  final MoodMusic _music;
  final NoiseBed _noise;
  final HarmonyWalk _harmony;
  final PadVoice _pad;
  final SubDrone _sub;
  final MotifScheduler? _scheduler;
  final List<NoteTimbre> _motifTimbres;
  final List<MotifVoice> _motifVoices;
  final ArpScheduler? _arpScheduler;
  final List<NoteTimbre> _arpTimbres;
  final List<MotifVoice> _arpVoices;
  final PulseScheduler? _pulseScheduler;
  final MotifVoice? _pulseVoice;
  final TickVoice? _tickVoice;
  final MotifVoice? _backbeatVoice;
  final AmModulator _am;
  final SoundscapeMixer _mixer;

  final DriftLfo _padCutoffDrift;
  final DriftLfo _padGainDrift;
  final DriftLfo _motifDensityDrift;
  final DriftLfo _wetDrift;
  final DriftLfo _arpDrift;
  final Lfo _intensityArc;

  final ParamRamp _noiseGain;
  final ParamRamp _noiseColor;
  final ParamRamp _noiseCutoff;
  final ParamRamp _gustDepth;
  final ParamRamp _padGain;
  final ParamRamp _padCutoff;
  final ParamRamp _motifGain;
  final ParamRamp _motifDensity;
  final ParamRamp _motifAttack;
  final ParamRamp _motifRelease;
  final ParamRamp _arpGain;
  final ParamRamp _arpFill;
  final ParamRamp _arpAttack;
  final ParamRamp _arpRelease;
  final ParamRamp _pulseGain;
  final ParamRamp _pulseFill;
  final ParamRamp _subGain;
  final ParamRamp _amDepth;
  final ParamRamp _reverbWet;
  final ParamRamp _reverbDecay;
  final ParamRamp _reverbDamp;
  final ParamRamp _tuneEnergy;
  final ParamRamp _tuneBrightness;

  SoundscapeContext _context;
  int _samplesDone = 0;

  Float32List _bedBuf = Float32List(0);
  Float32List _padBuf = Float32List(0);
  Float32List _subBuf = Float32List(0);
  Float32List _motifBuf = Float32List(0);
  Float32List _arpBuf = Float32List(0);
  Float32List _pulseBuf = Float32List(0);
  Float32List _sendBuf = Float32List(0);

  /// Reverb send levels per stem (the tail is built pre-AM so it never pumps).
  static const double _sendMotif = 0.75;
  static const double _sendPad = 0.35;
  static const double _sendArp = 0.45;
  static const double _sendPulse = 0.06;
  static const double _sendBed = 0.12;

  /// The context this composer is currently rendering (or gliding toward).
  SoundscapeContext get context => _context;

  void _ensureBuffers(int frames) {
    final n = frames * 2;
    if (_bedBuf.length < n) {
      _bedBuf = Float32List(n);
      _padBuf = Float32List(n);
      _subBuf = Float32List(n);
      _motifBuf = Float32List(n);
      _arpBuf = Float32List(n);
      _pulseBuf = Float32List(n);
      _sendBuf = Float32List(n);
    }
  }

  /// Smoothstep progress of the sleep wind-down, 0 at session start to 1 at
  /// the static floor. Always 0 for non-sleep moods.
  double _windDown() {
    if (_context.mood != SoundscapeMood.sleep) {
      return 0.0;
    }
    final t = (_samplesDone / (sleepWindDownSeconds * sampleRate)).clamp(
      0.0,
      1.0,
    );
    return t * t * (3.0 - 2.0 * t);
  }

  /// Renders [frames] interleaved stereo frames into [outStereo] (which must
  /// have length at least `frames * 2`). Every layer mixes at its current
  /// (ramped and drifted) gain, and the master reverb + limiter is applied so
  /// no sample leaves the range `[-1, 1]`.
  void renderBlock(Float32List outStereo, int frames) {
    _ensureBuffers(frames);
    final n = frames * 2;

    // Glidable context targets (end-of-block values; ramps span seconds).
    final noiseGain = _noiseGain.advanceBy(frames);
    final noiseColor = _noiseColor.advanceBy(frames);
    final noiseCutoff = _noiseCutoff.advanceBy(frames);
    final gustDepth = _gustDepth.advanceBy(frames);
    final padGain = _padGain.advanceBy(frames);
    final padCutoff = _padCutoff.advanceBy(frames);
    final motifGain = _motifGain.advanceBy(frames);
    final motifDensity = _motifDensity.advanceBy(frames);
    final motifAttack = _motifAttack.advanceBy(frames);
    final motifRelease = _motifRelease.advanceBy(frames);
    final arpGain = _arpGain.advanceBy(frames);
    final arpFill = _arpFill.advanceBy(frames);
    final arpAttack = _arpAttack.advanceBy(frames);
    final arpRelease = _arpRelease.advanceBy(frames);
    final pulseGain = _pulseGain.advanceBy(frames);
    final pulseFill = _pulseFill.advanceBy(frames);
    final subGain = _subGain.advanceBy(frames);
    final amDepth = _amDepth.advanceBy(frames);
    final reverbWet = _reverbWet.advanceBy(frames);
    final reverbDecay = _reverbDecay.advanceBy(frames);
    final reverbDamp = _reverbDamp.advanceBy(frames);

    // The listener's tune-pad position, remapped to [-1, 1] per axis. At the
    // neutral center every multiplier below is exactly 1 and the pulse gate
    // is exactly 0 — bit-identical to an untuned engine.
    final e = _tuneEnergy.advanceBy(frames) * 2.0 - 1.0;
    final b = _tuneBrightness.advanceBy(frames) * 2.0 - 1.0;
    final ePos = math.max(0.0, e);
    final tuneCutoffMul = math.pow(2.0, 0.5 * b).toDouble();

    // Macro life: incommensurate drift lanes + a slow cyclic intensity arc.
    final arc = _intensityArc.nextBy(frames);
    final padCutoffMul = math
        .pow(2.0, _padCutoffDrift.next(frames) * 0.25 + arc * 0.15)
        .toDouble();
    final padGainMul =
        math.pow(10.0, _padGainDrift.next(frames) * 1.2 / 20.0).toDouble() *
        (1.0 + 0.08 * arc);
    final densityMul = 1.0 + 0.3 * _motifDensityDrift.next(frames);
    final wetMul = 1.0 + 0.12 * _wetDrift.next(frames);

    // Sleep wind-down: darker, quieter, browner, more grounded — then hold.
    final wind = _windDown();
    final windCutoffMul = 1.0 - 0.4 * wind;
    final windPadMul = 1.0 - 0.2 * wind;
    final windNoiseMul = 1.0 - 0.15 * wind;
    final windSubMul = 1.0 + 0.3 * wind;
    final windColorAdd = 0.25 * wind;

    // Harmony: at most a voice or two start their multi-second glides. The
    // sub drone follows the root voice an octave down so the ground moves
    // with the chord.
    final rootPlanMidi = _music.harmonyVoices.first.initialMidi;
    for (final change in _harmony.advance(frames)) {
      _pad.retuneVoice(
        change.voice,
        midiToHz(change.midi),
        offsetFrames: change.offsetFrames,
      );
      if (change.voice == 0) {
        _sub.retune(
          _music.subFrequencyHz *
              math.pow(2.0, (change.midi - rootPlanMidi) / 12.0).toDouble(),
          offsetFrames: change.offsetFrames,
        );
      }
    }

    for (var i = 0; i < n; i++) {
      _bedBuf[i] = 0.0;
      _padBuf[i] = 0.0;
      _subBuf[i] = 0.0;
      _motifBuf[i] = 0.0;
      _arpBuf[i] = 0.0;
      _pulseBuf[i] = 0.0;
    }

    // Energy tilts the mix the way the reference pair differs: energetic
    // recedes the noise bed and grows the bass floor (music carries the
    // energy); mellow leans back into the bed.
    _noise
      ..setColor((noiseColor + windColorAdd - 0.15 * b).clamp(0.0, 1.0))
      ..setCutoff(noiseCutoff * windCutoffMul * tuneCutoffMul)
      ..setGustDepth(gustDepth * (1.0 + 0.4 * e))
      ..renderAdd(
        _bedBuf,
        frames,
        noiseGain * windNoiseMul * (1.0 - 0.25 * ePos - 0.1 * math.min(0.0, e)),
      );

    _pad.setCutoff(
      (padCutoff * padCutoffMul * windCutoffMul * tuneCutoffMul).clamp(
        120.0,
        6000.0,
      ),
    );
    // The pad steps back as energy rises so the note layers sit in front —
    // wash is what read as "sleepy" at the energetic end.
    _pad.renderAdd(
      _padBuf,
      frames,
      padGain * padGainMul * windPadMul * (1.0 - 0.22 * ePos),
    );

    _sub.renderAdd(_subBuf, frames, subGain * windSubMul * (1.0 + 0.25 * ePos));

    final scheduler = _scheduler;
    if (scheduler != null && _motifVoices.isNotEmpty) {
      final events = scheduler.advance(
        frames,
        notesPerMinute:
            motifDensity * densityMul * math.pow(2.0, 0.85 * e).toDouble(),
        chordMidi: _harmony.currentMidi,
      );
      for (final event in events) {
        final timbre = _motifTimbres[event.timbre % _motifTimbres.length];
        _motifVoices[event.timbre % _motifVoices.length].noteOn(
          frequencyHz: event.frequencyHz,
          velocity: event.velocity,
          pan: event.pan,
          attackSeconds:
              math.max(0.15, motifAttack * (1.0 - 0.3 * e)) *
              timbre.attackScale,
          releaseSeconds: motifRelease * timbre.releaseScale,
          offsetFrames: event.offsetFrames,
        );
      }
      for (var v = 0; v < _motifVoices.length; v++) {
        _motifVoices[v].renderAdd(
          _motifBuf,
          frames,
          motifGain * (1.0 + 0.15 * e) * _motifTimbres[v].gainScale,
        );
      }
    }

    // Broken-chord arp: the density layer. Energy roughly halves it at
    // mellow and doubles it at energetic; the chapter drift and the slow
    // intensity arc make it surge and recede over minutes.
    final arpScheduler = _arpScheduler;
    if (arpScheduler != null && _arpVoices.isNotEmpty) {
      final chapter = _arpDrift.next(frames);
      final fillLive =
          (arpFill *
                  math.pow(2.0, 1.1 * e).toDouble() *
                  (1.0 + 0.25 * arc + 0.3 * chapter))
              .clamp(0.0, 0.95);
      final events = arpScheduler.advance(
        frames,
        fill: fillLive,
        chordMidi: _harmony.currentMidi,
      );
      // Rising energy makes the plucks percussive (attacks shrink toward
      // ~8 ms), tighter (shorter ring), and brighter (stems open ~an
      // octave) — the staccato bite of the reference energy tracks. Mellow
      // keeps the soft swells.
      final arpAttackMul = e >= 0.0 ? (1.0 - 0.75 * e) : (1.0 - 0.3 * e);
      final arpCutoffMul = math.pow(2.0, 0.9 * ePos).toDouble() * tuneCutoffMul;
      for (final event in events) {
        final timbre = _arpTimbres[event.timbre % _arpTimbres.length];
        _arpVoices[event.timbre % _arpVoices.length].noteOn(
          frequencyHz: event.frequencyHz,
          velocity: event.velocity,
          pan: event.pan,
          attackSeconds: math.max(
            0.008,
            arpAttack * arpAttackMul * timbre.attackScale,
          ),
          releaseSeconds: arpRelease * timbre.releaseScale * (1.0 - 0.3 * ePos),
          offsetFrames: event.offsetFrames,
        );
      }
      for (var v = 0; v < _arpVoices.length; v++) {
        _arpVoices[v]
          ..setCutoff(
            (_arpTimbres[v].cutoffHz * arpCutoffMul).clamp(500.0, 9000.0),
          )
          ..renderAdd(
            _arpBuf,
            frames,
            arpGain * (1.0 + 0.8 * e) * _arpTimbres[v].gainScale,
          );
      }
    }

    // The beat kit: gated in from silence by the energy axis (smoothstep),
    // so the neutral center has no beat at all and full energy carries a
    // clear groove — bass thump, half-time backbeat, and the fast tick
    // articulation that reads as tempo. Energy also fills the pattern in
    // and tightens the bass ring.
    final pulseScheduler = _pulseScheduler;
    final pulseVoice = _pulseVoice;
    final tickVoice = _tickVoice;
    final backbeatVoice = _backbeatVoice;
    if (pulseScheduler != null &&
        pulseVoice != null &&
        tickVoice != null &&
        backbeatVoice != null) {
      final gate = ePos * ePos * (3.0 - 2.0 * ePos);
      final events = pulseScheduler.advance(
        frames,
        fill: gate <= 0.0 ? 0.0 : (pulseFill + 0.5 * ePos).clamp(0.0, 1.0),
        rootMidi: _harmony.currentMidi.first,
      );
      for (final event in events) {
        switch (event.timbre) {
          case 1:
            tickVoice.noteOn(
              velocity: event.velocity,
              pan: event.pan,
              releaseSeconds: 0.05,
              offsetFrames: event.offsetFrames,
            );
          case 2:
            backbeatVoice.noteOn(
              frequencyHz: event.frequencyHz,
              velocity: event.velocity,
              pan: event.pan,
              attackSeconds: 0.008,
              releaseSeconds: 0.14,
              offsetFrames: event.offsetFrames,
            );
          default:
            pulseVoice.noteOn(
              frequencyHz: event.frequencyHz,
              velocity: event.velocity,
              pan: event.pan,
              attackSeconds: 0.025,
              releaseSeconds: 0.34 * (1.0 - 0.35 * ePos),
              offsetFrames: event.offsetFrames,
            );
        }
      }
      pulseVoice.renderAdd(_pulseBuf, frames, pulseGain * gate);
      // The band-shaped noise is sparse in time and spectrum, so the tick
      // lane needs a hotter gain than the tonal lanes to read at all.
      tickVoice.renderAdd(_pulseBuf, frames, pulseGain * gate * 0.9);
      backbeatVoice.renderAdd(_pulseBuf, frames, pulseGain * gate * 0.7);
    }

    // Reverb send from the unmodulated stems; dry sum gets the neural AM on
    // the sustained beds only (motifs, arp, pulse, and sub stay clean).
    for (var i = 0; i < n; i++) {
      _sendBuf[i] =
          _motifBuf[i] * _sendMotif +
          _padBuf[i] * _sendPad +
          _arpBuf[i] * _sendArp +
          _pulseBuf[i] * _sendPulse +
          _bedBuf[i] * _sendBed;
      outStereo[i] = _bedBuf[i] + _padBuf[i];
    }
    _am.processInPlace(
      outStereo,
      frames,
      (amDepth * (1.0 + 0.35 * e)).clamp(0.0, 0.5),
    );
    for (var i = 0; i < n; i++) {
      outStereo[i] += _subBuf[i] + _motifBuf[i] + _arpBuf[i] + _pulseBuf[i];
    }

    _mixer
      ..setReverbWet(
        (reverbWet * wetMul * (1.0 - 0.35 * b) * (1.0 - 0.3 * ePos)).clamp(
          0.0,
          0.7,
        ),
      )
      ..setReverbDecay((reverbDecay - 0.08 * b).clamp(0.0, 0.95))
      ..setReverbDamp(reverbDamp);
    _mixer.masterProcess(outStereo, _sendBuf, frames);

    _samplesDone += frames;
  }

  /// Retargets every glidable parameter toward the arrangement for [next],
  /// over [rampSeconds]. Does not rebuild or restart the voices — the
  /// pentatonic key, voicing, tempo, and AM rate stay as built (mood is
  /// session-fixed); only gains, cutoffs, density, depth, and reverb glide.
  void updateContext(SoundscapeContext next) {
    _context = next;
    final targets = SoundscapeTargets.fromContext(next);
    final samples = (sampleRate * rampSeconds).round();
    _noiseGain.setTarget(targets.noiseGain, samples);
    _noiseColor.setTarget(targets.noiseColor, samples);
    _noiseCutoff.setTarget(targets.noiseCutoffHz, samples);
    _gustDepth.setTarget(targets.gustDepthDb, samples);
    _padGain.setTarget(targets.padGain, samples);
    _padCutoff.setTarget(targets.padCutoffHz, samples);
    _motifGain.setTarget(targets.motifGain, samples);
    _motifDensity.setTarget(targets.motifNotesPerMinute, samples);
    _motifAttack.setTarget(targets.motifAttackSeconds, samples);
    _motifRelease.setTarget(targets.motifReleaseSeconds, samples);
    _arpGain.setTarget(targets.arpGain, samples);
    _arpFill.setTarget(targets.arpFill, samples);
    _arpAttack.setTarget(targets.arpAttackSeconds, samples);
    _arpRelease.setTarget(targets.arpReleaseSeconds, samples);
    _pulseGain.setTarget(targets.pulseGain, samples);
    _pulseFill.setTarget(targets.pulseFill, samples);
    _subGain.setTarget(targets.subGain, samples);
    _amDepth.setTarget(targets.amDepth, samples);
    _reverbWet.setTarget(targets.reverbWet, samples);
    _reverbDecay.setTarget(targets.reverbDecay, samples);
    _reverbDamp.setTarget(targets.reverbDamp, samples);
  }

  /// Glides the listener's tune-pad position into the running mix over
  /// [tuneRampSeconds]. The neutral center reproduces the untuned engine
  /// exactly; energy sweeps the mellow→energetic arc (melodic and arp
  /// density, the bass pulse gate, sub weight, AM depth, gusts, noise-bed
  /// balance) and brightness trades reverb space for filter openness.
  void updateTune(SoundscapeTune tune) {
    final samples = (sampleRate * tuneRampSeconds).round();
    _tuneEnergy.setTarget(tune.energy, samples);
    _tuneBrightness.setTarget(tune.brightness, samples);
  }

  /// The mood-fixed music (scale, tempo, AM rate) this composer was built
  /// with. Exposed for tests and diagnostics.
  MoodMusic get music => _music;
}
