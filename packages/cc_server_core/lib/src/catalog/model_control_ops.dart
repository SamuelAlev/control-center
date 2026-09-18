import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_host/cc_host.dart';

/// The four `models.<prefix>*` ops that expose one on-device model's lifecycle
/// over RPC, backed by a host-side [ModelControl].
///
/// Host-global (a model is a single device-local asset, not workspace data), so
/// every op is `workspaceScoped: false`. `<prefix>Status` returns the snapshot
/// wire map; each mutator (`install`/`cancel`/`uninstall`) applies the action
/// and returns the FRESH snapshot, so the thin client refreshes its UI without a
/// second round-trip — the same shape the desktop reads in-process.
List<RepoOp> modelControlOps({
  required String prefix,
  required ModelControl control,
  void Function(RepoOpContext ctx)? guard,
}) {
  final capitalized = '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  final authority = guard == null
      ? ServerAuthority.none
      : ServerAuthority.serverOwner;
  return [
    RepoOp(
      name: 'models.${prefix}Status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => (await control.status()).toJson(),
    ),
    RepoOp(
      name: 'models.install$capitalized',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: authority,
      handler: (ctx) async {
        guard?.call(ctx);
        await control.install();
        return (await control.status()).toJson();
      },
    ),
    RepoOp(
      name: 'models.cancel$capitalized',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: authority,
      handler: (ctx) async {
        guard?.call(ctx);
        await control.cancel();
        return (await control.status()).toJson();
      },
    ),
    RepoOp(
      name: 'models.uninstall$capitalized',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: authority,
      handler: (ctx) async {
        guard?.call(ctx);
        await control.uninstall();
        return (await control.status()).toJson();
      },
    ),
  ];
}

/// The `models.watch<Prefix>` subscription that streams one on-device model's
/// lifecycle (status / progress / phase / error) as the SERVER downloads +
/// unpacks it, backed by a host-side [ModelControl].
///
/// Host-global (a model is a single device-local asset, not workspace data), so
/// `workspaceScoped: false`. Each emission is the snapshot wire map (the same
/// shape `models.<prefix>Status` returns); the thin client subscribes to animate
/// a live progress bar while the server does the work — the model-download
/// counterpart to `meeting.watchSegments`.
WatchQuery modelControlWatchQuery({
  required String prefix,
  required ModelControl control,
}) {
  final capitalized = '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  return WatchQuery(
    name: 'models.watch$capitalized',
    workspaceScoped: false,
    handler: (ctx) => control.watch().map((snapshot) => snapshot.toJson()),
  );
}

/// The two voice-only ops that expose the ASR model SELECTION over RPC, backed
/// by a host-side [SelectableModelControl]: `models.voiceCatalog` lists the
/// installable models + which is active and `models.selectVoice` switches the
/// active one (returning the fresh status snapshot the now-selected model
/// reports, so the thin client refreshes its picker + status row without a
/// second round-trip).
///
/// Host-global (a model is a single device-local asset, not workspace data), so
/// both ops are `workspaceScoped: false`. Only voice is selectable — embedding &
/// diarization are single fixed models, so they wire only [modelControlOps].
/// These are added on top of the voice `modelControlOps` (status/install/…), so
/// a server that hosts a selectable voice control exposes the full surface.
List<RepoOp> voiceSelectionOps({
  required SelectableModelControl control,
  void Function(RepoOpContext ctx)? guard,
}) {
  return [
    RepoOp(
      name: 'models.voiceCatalog',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => (await control.catalog()).toJson(),
    ),
    RepoOp(
      name: 'models.selectVoice',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: guard == null
          ? ServerAuthority.none
          : ServerAuthority.serverOwner,
      requiredArgs: const ['model_id'],
      handler: (ctx) async {
        guard?.call(ctx);
        final modelId = ctx.args['model_id'] as String;
        return (await control.select(modelId)).toJson();
      },
    ),
  ];
}
