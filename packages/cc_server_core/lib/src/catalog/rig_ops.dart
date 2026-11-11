import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_ports_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/rig_access.dart';
import 'package:cc_server_core/src/rig_rpc_ops.dart';
import 'package:cc_server_core/src/rig_wire.dart';

/// A rig is a disposable VM an agent or a human drives. These ops exist only
/// when the host wired a [RigPort]: a server with no hypervisor leaves it
/// null, the ops are absent and the client renders an honest "enclosed VMs
/// are unavailable on this server" state instead of failing per action.
///
/// Every op is `fullClientOnly`: the paired phone is a lower-privilege
/// principal whose surface is tickets/messaging/newsfeed, and booting a
/// machine is not on that list. `RemoteToolPolicy` denies the MCP side by
/// default for the same reason.
///
/// Who may see or drive one is [RigAccess]: a rig in a space reads and
/// operates that space.
List<RepoOp> buildRigOps({
  required RigPort rigs,
  required RigAccess access,
  required ServerSettingsRepository? serverSettingsRepository,
}) => [
  RepoOp(
    name: 'rig.detect',
    kind: RepoOpKind.read,
    handler: (ctx) async => (await rigs.probe()).toJson(),
  ),
  buildRigInstallBackendSetupOp(rigs: rigs),
  RepoOp(
    name: 'rig.list',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final all = await access.visible(
        ctx.workspaceId!,
        ctx.userId,
        await rigs.list(ctx.workspaceId!),
      );
      return {'rigs': await access.rowsFor(ctx.workspaceId!, ctx.userId, all)};
    },
  ),
  RepoOp(
    name: 'rig.open',
    kind: RepoOpKind.mutate,
    // Opening boots or joins the space's machine: operating it.
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfSpaceArg('conversation_id'),
    requiredArgs: ['surface'],
    actionClasses: const {
      ActionClass.enclosureControl,
      ActionClass.processSpawn,
    },
    handler: (ctx) async {
      // Build the spec from a CLOSED set of client-supplied fields.
      //
      // Splatting `ctx.args` into `RigSpec.fromJson` handed the caller
      // every field the spec has: `worktreePath` would tar an arbitrary
      // host directory (`~/.ssh` — the sync excludes `.env` and `*.pem`,
      // not `id_ed25519`) into a VM the caller drives, and `memoryMb` /
      // `cpuCount` / `ttlSeconds` would let one call evict every other
      // rig on the host or mint one with no effective lifetime. The
      // client only ever sends these two, and the resource envelope is
      // the server's to choose.
      final surface = ctx.args['surface'];
      if (surface is! String) {
        throw const ValidationException('Missing or invalid argument: surface');
      }
      final parsedSurface = RigSurface.fromWire(surface);
      if (parsedSurface == null) {
        throw ValidationException('Unknown rig surface "$surface"');
      }
      // A window rig opens against an app a person launched, never on
      // a client's say-so: this op would otherwise reach a refusal
      // whose ArgumentError reads as an internal error.
      if (parsedSurface == RigSurface.window) {
        throw const ValidationException(
          'An app window rig opens when its app launches.',
        );
      }
      // Its image, mount and egress come from a resolved definition,
      // none of which this op carries.
      if (parsedSurface == RigSurface.environment) {
        throw const ValidationException(
          'An environment rig opens when its environment starts.',
        );
      }
      // Read, not cast: a client that sends a number here produced a
      // raw `TypeError` (mapped to the generic internal error) instead
      // of a named validation failure the caller can act on.
      final conversationId = ctx.args['conversation_id'];
      if (conversationId != null && conversationId is! String) {
        throw const ValidationException(
          'Invalid argument: conversation_id (expected a string)',
        );
      }
      // Which browser, when the surface is one. Refused rather than
      // defaulted on an unknown name: a client asking for an engine
      // this server cannot boot is asking a compatibility question, and
      // answering it with a different browser is worse than not
      // answering it.
      final engineArg = ctx.args['engine'];
      if (engineArg != null && engineArg is! String) {
        throw const ValidationException(
          'Invalid argument: engine (expected a string)',
        );
      }
      // WHICH machine of this kind in the conversation. Absent is the
      // conversation's default — what an agent's `*_use` calls reach —
      // so a client that names none behaves exactly as before slots.
      // `RigSpec` validates the shape; a wrong TYPE is caught here so
      // it reads as a named validation failure rather than a TypeError.
      final slotArg = ctx.args['slot_id'];
      if (slotArg != null && slotArg is! String) {
        throw const ValidationException(
          'Invalid argument: slot_id (expected a string)',
        );
      }
      final slotError = RigSpec.slotIdError(slotArg as String?, parsedSurface);
      if (slotError != null) {
        throw ValidationException('Invalid argument: slot_id. $slotError');
      }
      final engine = engineArg == null
          ? RigBrowserEngine.fallback
          : RigBrowserEngine.fromWire(engineArg as String);
      if (engine == null) {
        throw ValidationException(
          'Unknown browser engine "$engineArg". Use '
          '${RigBrowserEngine.values.map((e) => e.wire).join(', ')}.',
        );
      }
      // The home page's color scheme is baked into the guest at boot,
      // so it has to arrive WITH the open. An explicit `home_theme`
      // wins and is remembered: an agent-opened rig (the browser_use
      // tool sends none) then follows the last theme any app named
      // rather than the server's static default.
      final themeArg = ctx.args['home_theme'];
      if (themeArg != null && themeArg is! String) {
        throw const ValidationException(
          'Invalid argument: home_theme (expected a string)',
        );
      }
      var homeTheme = RigBrowserHomeTheme.fromWire(themeArg as String?);
      if (themeArg != null && homeTheme == null) {
        throw ValidationException(
          'Unknown home theme "$themeArg". Use '
          '${RigBrowserHomeTheme.values.map((t) => t.wire).join(', ')}.',
        );
      }
      if (homeTheme != null) {
        await serverSettingsRepository?.set(
          kRigHomeThemeSettingKey,
          homeTheme.wire,
        );
      } else {
        homeTheme = RigBrowserHomeTheme.fromWire(
          await serverSettingsRepository?.get(kRigHomeThemeSettingKey),
        );
      }
      final rig = await rigs.open(
        workspaceId: ctx.workspaceId!,
        spec: RigSpec(
          surface: parsedSurface,
          browserEngine: engine,
          conversationId: conversationId as String?,
          slotId: slotArg,
          homeTheme: homeTheme,
          // A browser rig boots to its home page, so its default
          // allowlist admits that page's host — an empty list left the
          // tab a white rectangle whose first navigation anywhere was
          // refused. Still the caller's to widen, never the client's:
          // the egress envelope is the server's to choose.
          egressAllowlist: parsedSurface == RigSurface.browser
              ? browserRigEgressAllowlist()
              : const [],
          // Whose forge access anything inside this machine is bounded
          // by. A rig cannot tell which process is asking, so the
          // credential grant is bound to the person who opened it.
          openedByUserId: ctx.userId,
        ),
        openedBy: ctx.principal,
      );
      return access.rowFor(ctx.workspaceId!, ctx.userId, rig);
    },
  ),
  RepoOp(
    name: 'rig.restartUnrestricted',
    // This removes a host-level network boundary and can expose the
    // server's LAN from inside the guest. Workspace membership alone is
    // not authority to make that machine-wide security decision.
    serverAuthority: ServerAuthority.serverOwner,
    kind: RepoOpKind.mutate,
    requiredArgs: ['rig_id'],
    actionClasses: const {
      ActionClass.enclosureControl,
      ActionClass.networkEgress,
      ActionClass.processSpawn,
    },
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      // Restarting replaces the machine and rebinds it to the caller: a
      // machine carrying somebody else's credentials is theirs to restart.
      final rig = await access.requireHolder(
        workspaceId,
        ctx.userId,
        ctx.args['rig_id'] as String,
      );
      if (rig.status.phase.isTerminal) {
        throw const NotFoundException('Rig not found in this workspace');
      }
      if (!rig.backend.hasEnforcedEgress) {
        throw const ValidationException(
          'This backend already allows every network host; it has no '
          'egress gate to bypass.',
        );
      }
      if (rig.spec.unrestrictedNetwork) {
        return access.rowFor(ctx.workspaceId!, ctx.userId, rig);
      }

      // The existing row is closed BEFORE the replacement is opened:
      // reuse matching would otherwise hand the caller the restricted
      // machine it is trying to replace. Only this one policy bit is
      // widened; every server-owned resource and filesystem field comes
      // from the persisted spec, never from client arguments.
      await rigs.close(
        workspaceId: workspaceId,
        rigId: rig.id,
        reason: RigCloseReason.requested,
      );
      final restarted = await rigs.open(
        workspaceId: workspaceId,
        spec: rig.spec.copyWith(
          unrestrictedNetwork: true,
          openedByUserId: ctx.userId,
        ),
        openedBy: ctx.principal,
      );
      return access.rowFor(ctx.workspaceId!, ctx.userId, restarted);
    },
  ),
  RepoOp(
    name: 'rig.act',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id', 'action'],
    // Human take-over: attributed to the caller's own principal, never
    // to the agent that owns the rig.
    //
    // Out of the GENERIC audit trail (like `terminal.resize`) because a
    // person driving a rig emits a mouse event per frame — mirroring
    // those into the per-user audit would bury every real accountability
    // event under pointer noise. They are not unrecorded: every one lands
    // in `rig_action_log` with its principal and a monotonic sequence,
    // which is the purpose-built record and the finer one.
    audited: false,
    actionClasses: const {ActionClass.enclosureControl},
    handler: (ctx) async {
      final rig = await rigs.get(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
      );
      if (rig == null) {
        throw const NotFoundException('Rig not found in this workspace');
      }
      final parse = parseRigAction(rig.surface, ctx.args);
      if (parse is RigActionInvalid) {
        throw ValidationException(parse.message);
      }
      final result = await rigs.act(
        workspaceId: ctx.workspaceId!,
        rigId: rig.id,
        action: (parse as RigActionParsed).action,
        actor: ctx.principal,
      );
      return {
        'text': result.text,
        'is_error': result.isError,
        if (result.displaySize != null) 'display': result.displaySize,
        if (result.imageBase64 != null) 'image_base64': result.imageBase64,
        if (result.imageMediaType != null)
          'image_media_type': result.imageMediaType,
      };
    },
  ),
  RepoOp(
    name: 'rig.browserState',
    kind: RepoOpKind.read,
    repoAccess: RepoGrantLevel.read,
    repoAccessVia: access.reposOfRig,
    requiredArgs: ['rig_id'],
    handler: (ctx) async {
      // The address bar's live half: back/forward reachability comes
      // from the page's own session history, so it has to be asked for
      // — the pushed `current_url` on the rig row is the other half.
      final rig = await rigs.get(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
      );
      if (rig == null) {
        throw const NotFoundException('Rig not found in this workspace');
      }
      if (rig.surface != RigSurface.browser) {
        throw ValidationException(
          'Rig ${rig.id} is a ${rig.surface.wire} rig; only a browser '
          'rig has navigation state.',
        );
      }
      final state = await rigs.browserState(
        workspaceId: ctx.workspaceId!,
        rigId: rig.id,
      );
      // Not live (booting, closed): report the last known URL with no
      // history rather than erroring a toolbar that races the boot.
      return state?.toJson() ??
          {
            'url': rig.currentUrl ?? '',
            'can_go_back': false,
            'can_go_forward': false,
            'loading': false,
          };
    },
  ),
  RepoOp(
    name: 'rig.takeControl',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id'],
    actionClasses: const {ActionClass.enclosureControl},
    handler: (ctx) async {
      final rig = await rigs.takeControl(
        workspaceId: ctx.workspaceId!,
        rigId: ctx.args['rig_id'] as String,
        actor: ctx.principal,
      );
      return access.rowFor(ctx.workspaceId!, ctx.userId, rig);
    },
  ),
  RepoOp(
    name: 'rig.releaseControl',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id'],
    actionClasses: const {ActionClass.enclosureControl},
    handler: (ctx) async {
      final rig = await rigs.releaseControl(
        workspaceId: ctx.workspaceId!,
        rigId: ctx.args['rig_id'] as String,
        actor: ctx.principal,
      );
      return access.rowFor(ctx.workspaceId!, ctx.userId, rig);
    },
  ),
  RepoOp(
    name: 'rig.images',
    serverAuthority: ServerAuthority.serverOwner,
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async {
      // Admin-gated like its two mutations. This is host inventory —
      // which operating systems this machine has on disk and how far a
      // download got — not workspace data, and it is only ever read by
      // the Settings → Enclosures page, which is already operator-only.
      // A viewer in any workspace could read it before.
      return {'images': rigs.imageStatuses()};
    },
  ),
  RepoOp(
    name: 'rig.downloadImage',
    serverAuthority: ServerAuthority.serverOwner,
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['image_id'],
    // Fetching an operating system onto the host. Not `enclosureControl`
    // — nothing is driven — but it is a real network fetch and a
    // multi-gigabyte write, so it declares both.
    actionClasses: const {
      ActionClass.networkEgress,
      ActionClass.packageInstall,
    },
    handler: (ctx) async {
      // Returns as soon as the download is ACCEPTED, not when it
      // finishes: a base image is ~590 MB and holding an RPC call open
      // for minutes ties up the connection and times the client out on a
      // download that is working fine. The service owns the transfer;
      // progress rides on `rig.images` (the partial size on disk).
      await rigs.downloadImage(ctx.args['image_id'] as String);
      return const {'started': true};
    },
  ),
  RepoOp(
    name: 'rig.importImage',
    serverAuthority: ServerAuthority.serverOwner,
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['image_id', 'path'],
    actionClasses: const {ActionClass.packageInstall},
    handler: (ctx) async {
      // Reading a caller-named path off the server's disk, so it is
      // operator-only: this is the same trust level as choosing which
      // operating system every rig on this host boots.
      await rigs.importImage(
        imageId: ctx.args['image_id'] as String,
        sourcePath: ctx.args['path'] as String,
      );
      return const {};
    },
  ),
  RepoOp(
    name: 'rig.removeImage',
    serverAuthority: ServerAuthority.serverOwner,
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['image_id'],
    actionClasses: const {ActionClass.fileDelete},
    handler: (ctx) async {
      await rigs.removeImage(ctx.args['image_id'] as String);
      return const {};
    },
  ),
  RepoOp(
    name: 'rig.destroy',
    // Mutate, like `terminal.kill` — NOT destructive. A rig is
    // disposable by construction (overlay discarded, TTL-bounded), so
    // stopping one is routine lifecycle, and `destructive` is denied
    // outright wherever no confirmation flow is wired ("Operation
    // requires approval") — which made the panel's stop button fail
    // with a permission error on every press.
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id'],
    actionClasses: const {ActionClass.enclosureControl},
    handler: (ctx) async {
      // Parsed HERE, at the wire edge, so an unknown reason is a named
      // validation error rather than a silent fall back to `requested`
      // in the service — the row's close reason is the only surviving
      // answer to "where did my machine go".
      final rawReason = ctx.args['reason'];
      if (rawReason != null && rawReason is! String) {
        throw const ValidationException(
          'Invalid argument: reason (expected a string)',
        );
      }
      final reason = rawReason == null
          ? null
          : RigCloseReason.fromWire(rawReason as String);
      if (rawReason != null && reason == null) {
        throw ValidationException(
          'Unknown close reason "$rawReason". Expected one of: '
          '${RigCloseReason.values.map((r) => r.wire).join(', ')}.',
        );
      }
      // Look the row up BEFORE close so the audit trail can say
      // which machine and which space, not just `rig.destroy`.
      final existing = await rigs.get(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
      );
      await rigs.close(
        workspaceId: ctx.workspaceId!,
        rigId: ctx.args['rig_id'] as String,
        reason: reason,
      );
      return {
        if (existing?.conversationId != null)
          'conversation_id': existing!.conversationId,
        if (existing != null) 'surface': existing.surface.wire,
      };
    },
  ),
];

/// What is listening inside a Terminal (VM), and every address each port
/// answers on: host loopback (`localhost:<port>`), an optional LAN port
/// (`<server-ip>:<random>`), and a dev domain in the Browser (VM). Present
/// only when the host wired a [RigPortsPort] alongside the rigs. Reads are
/// plain reads; each mutation reconfigures a host listener, so it declares
/// `networkEgress`.
/// Seeing them needs the rig's space; changing them operates it
/// ([RigAccess]).
List<RepoOp> buildRigPortOps({
  required RigPortsPort rigPorts,
  required RigAccess access,
}) => [
  RepoOp(
    name: 'rig.setPortsAutoForward',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id', 'enabled'],
    // The WIDEST of the port ops: with this on, every port a guest opens
    // is forwarded automatically, so one call stands in for an unbounded
    // number of `rig.addPort`s. It shipped with no class and
    // `audited: false` — an egress decision that neither the guardrails
    // nor the activity log could see.
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final ok = await rigPorts.setPortsAutoForward(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
        enabled: ctx.args['enabled'] == true,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'rig.addPort',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id', 'guest_port'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final port = _asPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      final ok = await rigPorts.addPortForward(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
        port,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'rig.removePort',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id', 'guest_port'],
    // Reconfigures the same host listener its sibling opens. Declared
    // even though this direction only ever NARROWS exposure: the class
    // is what a read-only mode denies, and a mode that refuses `addPort`
    // has nothing left for this to close.
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final port = _asPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      final ok = await rigPorts.removePortForward(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
        port,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'rig.setPortLan',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id', 'guest_port', 'exposed'],
    // Publishing a guest port on the LAN is a real egress decision, so
    // it declares the class — read-only modes deny it, and the autonomy
    // dial can demote it to a prompt.
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final port = _asPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      final ok = await rigPorts.setPortLanExposed(
        ctx.workspaceId!,
        ctx.args['rig_id'] as String,
        port,
        exposed: ctx.args['exposed'] == true,
      );
      return {'ok': ok};
    },
  ),
  RepoOp(
    name: 'rig.setPortDomain',
    kind: RepoOpKind.mutate,
    repoAccess: RepoGrantLevel.write,
    repoAccessVia: access.reposOfDrivenRig,
    requiredArgs: ['rig_id', 'guest_port'],
    // Mapping a dev domain onto a guest port is the same kind of
    // exposure decision `setPortLan` declares — it changes which name
    // reaches what is listening inside the machine.
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final port = _asPort(ctx.args['guest_port']);
      if (port == null) {
        throw const ValidationException(
          'Invalid argument: guest_port (expected 1-65535)',
        );
      }
      try {
        final ok = await rigPorts.setPortDomain(
          ctx.workspaceId!,
          ctx.args['rig_id'] as String,
          port,
          ctx.args['domain'] as String?,
        );
        return {'ok': ok};
      } on ArgumentError catch (e) {
        // The domain validation message reaches the client verbatim.
        throw ValidationException('${e.message}');
      }
    },
  ),
];

/// Reads a guest port from a client arg, accepting the int and the numeric
/// string a JSON client may send. Null on anything outside 1–65535.
int? _asPort(Object? raw) {
  final port = switch (raw) {
    final int i => i,
    final String s => int.tryParse(s),
    _ => null,
  };
  return (port == null || port <= 0 || port > 65535) ? null : port;
}
