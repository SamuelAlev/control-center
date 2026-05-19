import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show SoundscapeHub;

/// The reactive scene metadata for the soundscape UI.
///
/// The AUDIO itself never travels over RPC — it streams as an infinite MP3 over
/// the `/soundscape/stream` HTTP route (or HLS), keyed by `(workspaceId, mood)`.
/// This watch carries only the DISPLAY state: the current mood, the weather and
/// daypart the server folded into the running mix, and a human-readable scene
/// name. It re-emits whenever the weather or daypart shifts, so the mini-player
/// can update its label and glyph without touching the audio connection (the
/// mix adapts in place via parameter ramps on the server).
///
/// Injected via `extraWatchQueries` so `remote_rpc_catalog.dart` is untouched.
List<WatchQuery> buildSoundscapeWatchQueries(SoundscapeHub hub) => [
  WatchQuery(
    name: 'soundscape.watchScene',
    handler: (ctx) {
      final mood = (ctx.args['mood'] as String?) ?? 'focus';
      return hub.watchScene(workspaceId: ctx.workspaceId!, mood: mood);
    },
  ),
];

/// Mutations for the soundscape: the tune pad.
///
/// `soundscape.setTune` glides the listener's 2D tune (energy: mellow→
/// energetic, brightness: spacy→bright, both `[0, 1]`) into the running
/// `(workspaceId, mood)` session — live, no restart — and stores it for
/// sessions created later. Injected via `extraOps`, the same seam the weather
/// and fleet ops use.
List<RepoOp> buildSoundscapeOps(SoundscapeHub hub) => [
  RepoOp(
    name: 'soundscape.setTune',
    kind: RepoOpKind.mutate,
    // Live pad — fires continuously while dragging; not an accountability event.
    audited: false,
    requiredArgs: ['mood', 'energy', 'brightness'],
    handler: (ctx) async {
      final mood = ctx.args['mood'] as String;
      final energy = (ctx.args['energy'] as num).toDouble();
      final brightness = (ctx.args['brightness'] as num).toDouble();
      hub.setTune(
        workspaceId: ctx.workspaceId!,
        mood: mood,
        tune: SoundscapeTune(energy: energy, brightness: brightness),
      );
      return {'ok': true};
    },
  ),
];
