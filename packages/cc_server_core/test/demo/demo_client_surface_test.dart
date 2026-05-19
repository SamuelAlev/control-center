import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/native_staging.dart';

/// Every op the FLUTTER CLIENT calls must exist on a demo server, or be
/// consciously listed here as a surface the client already handles.
///
/// This is the test that closes the whole class of bug the demo kept shipping:
/// an op removed on the server (a null port, or the profile's allowlist) that
/// some screen still calls, so a visitor sees
/// `RemoteRpcException(-33006): Unknown op: …` in red where content should be.
/// Five of those reached screenshots before this existed.
///
/// It boots the real demo server, asks it for its actual op catalogue
/// (`op/list`), and diffs that against every `.call('x.y')` in `lib/`. A new
/// screen that calls a denied op fails HERE, with the file that calls it,
/// rather than in a screenshot.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for demo server boot',
      () => fail('run scripts/natives/build_natives.sh'),
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  /// Client call sites that are EXPECTED to hit an absent op, because the
  /// calling surface already renders a demo notice or degrades on its own.
  ///
  /// Each entry is a promise that the client copes. Adding a name here without
  /// making the surface cope is how the red text comes back.
  const handledByTheClient = <String>{
    // Gated by `isDemoServerProvider` before the call — see
    // `lib/features/demo/presentation/widgets/demo_unavailable.dart` and its
    // call sites (terminal, rigs, editor, skills, MCP, forge card).
    'forge.listConnections',
    'forge.capabilities',
    'forge.testConnection',
    'credentials.clearForgeToken',
    'credentials.setTicketingToken',
    'credentials.clearTicketingToken',
    'oauth.begin',
    'oauth.providers',
    'mcp.status',
    'mcp.start',
    'mcp.stop',
    'mcp.setEnabled',
    'mcp.setToken',
    'codeServer.open',
    'codeServer.saveFile',
    // Settings surfaces that render their own "not available on this server"
    // state from an `opUnknown` (the SSO card's warning alert, the adapter
    // and provider-app panels).
    'sso.status',
    'sso.getConfig',
    'sso.saveConfig',
    'sso.testConnection',
    'sso.scimRegenerateToken',
    'providerApps.list',
    'providerApps.save',
    'providerApps.test',
    'connectivity.status',
    'pairing.rename',
    'pairing.revoke',
    'ticket_sync.syncNow',
    // Settings → Agent permissions → Policy templates disables itself on a
    // demo server (`isDemoServerProvider`). The `action_policy.` family is
    // denied there on purpose: the demo's own lockdown is the posture a
    // visitor must not be able to edit from inside it.
    'action_policy.applyTemplate',
    'action_policy.export',
    'action_policy.import',
    // The members role picker only offers a custom role when
    // `roles.watchForWorkspace` returns one, and a demo workspace has none:
    // `roles.upsert` is denied there, so nothing can create one. The call
    // site is therefore unreachable on a demo rather than gated by a flag.
    'roles.assign',
    // Settings → Server → Backup & restore gates the WHOLE page on
    // `isDemoServerProvider` and renders the serverAdmin notice instead, so a
    // visitor never issues one of these. They are denied for good reason:
    // `workspace.export` VACUUMs a whole database onto a public endpoint and
    // the other three are install-wide.
    'server.backupNow',
    'server.listBackups',
    'workspace.export',
    'workspace.import',
    // Repo + worktree surfaces: the demo registers a repo row but owns no
    // checkout, and every one of these is behind a disabled control or a
    // panel that reports "no changes".
    'repos.stage',
    'repos.unstage',
    'repos.changes',
    'repos.changesGrouped',
    'repos.listDirectory',
    'repos.readFile',
    'repos.searchContent',
    'repos.searchFiles',
    'worktree.writeFile',
    'worktree.readFile',
    'worktree.revertFiles',
    'worktree.commitAndPush',
    'worktree.publishBranch',
    'worktree.syncToPrHead',
    'worktree.searchContent',
    // Skills management, behind the skills page's demo notice.
    'skills.analyze',
    'skills.checkUpdates',
    'skills.installedList',
    'skills.repoSkills',
    'skills.saveLocal',
    'skills.scanInstalled',
    'skills.sourceInstall',
    'skills.sourceListings',
    'skills.sourceSkillDetail',
    'skills.sourcesAdd',
    'skills.sourcesList',
    'skills.sourcesRemove',
    'skills.uninstall',
    'skills.updateSkill',
    // On-device ML model management: downloads, refused by design.
    'models.cancelDiarization',
    'models.cancelEmbedding',
    'models.cancelVoice',
    'models.diarizationStatus',
    'models.embeddingStatus',
    'models.installDiarization',
    'models.installEmbedding',
    'models.installVoice',
    'models.selectVoice',
    'models.uninstallDiarization',
    'models.uninstallEmbedding',
    'models.uninstallVoice',
    'models.voiceCatalog',
    'models.voiceStatus',
    // Live GitHub reads behind PR compose / profile hovercards.
    'github.currentUser',
    'github.compareBranches',
    'github.defaultBranch',
    'github.prTemplates',
    'github.repoBranches',
    'github.orgMembers',
    // GIF picker (Klipy) — third-party media search.
    'gif.search',
    'gif.trending',
    // Gated on `isDemoServerProvider` in the provider itself, so the hovercard
    // renders initials instead of an error under every avatar on the PR
    // surface (`lib/shared/providers/github_user_profile_provider.dart`).
    'github.userProfile',
    // PR compose + issue search: reachable only from "open a pull request",
    // which needs a worktree the demo does not have.
    'github.prContent',
    'github.repoPermission',
    'github.searchIssues',
    // Swallows every error by design ("best-effort; the periodic host sweep
    // will catch up"), so an absent op is silent rather than red.
    'calendar.refreshNow',
    // Structurally unreachable: `CalendarRsvpService.canRespond` requires an
    // attendee with `self: true`, and the demo seeds none — so the RSVP
    // control never renders.
    'calendar.rsvp',
    // Behind the demo-gated code-server tab and the PR list's paging, neither
    // of which a visitor reaches (four PRs, no second page).
    'pr.ensureSpace',
    'pr.openPageForRepo',
    // Review-findings actions that POST to a forge. The findings themselves
    // are seeded and readable, and their triage state (`setFindingStatus`) is
    // allowed — only publishing back to GitHub is refused.
    'pr_review.commentFindings',
    'pr_review.publishReview',
    // Server-administration surfaces that render their own unavailable state.
    'connectivity.setTunnel',
    'sso.setPairingEnabled',
    'sso.spMetadata',
    // Pasting a forge token, behind the demo-gated connections card.
    'credentials.setForgeToken',
    // The ticketing connections card, same shape as the forge one: the
    // credential port is absent, so the card reports nothing connected.
    'ticketing.listConnections',
  };

  test('every op the client calls exists on a demo server', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_demo_surface');
    addTearDown(() => deleteDirBestEffort(tmp));
    await stageServerNatives(tmp.path);
    final server = await runCcServer(
      args: [
        '--data-dir',
        tmp.path,
        '--port',
        '0',
        '--code-index',
        'off',
      ],
      demoBuilder: buildDemoWiring,
    );
    addTearDown(server.shutdown);

    // Redeem so the client is a real, member-scoped session.
    final http = HttpClient();
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'demo'}));
    final resp = await req.close();
    final envelope =
        jsonDecode(await resp.transform(utf8.decoder).join())
            as Map<String, dynamic>;
    http.close(force: true);

    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: envelope['device_id'] as String,
      psk: envelope['psk'] as String,
    );
    addTearDown(client.close);
    final handshake = await client.initialize();
    expect(handshake, isNotNull);

    final available = server.rpc.repoOps == null
        ? <String>{}
        : {for (final op in server.rpc.repoOps!.registry.ops) op.name};
    expect(
      available,
      isNotEmpty,
      reason: 'the demo server exposes no ops at all — the lockdown is broken',
    );

    // Sanity: ops the demo is supposed to KEEP. A regression that empties the
    // registry would otherwise make the diff below vacuously pass.
    for (final kept in [
      'messaging.sendMessage',
      'tickets.list',
      'cache.read',
      'cache.write',
    ]) {
      expect(
        available,
        contains(kept),
        reason: '$kept must remain available on a demo server',
      );
    }

    // Every `.call('x.y'` the client can reach — BOTH trees. The root `lib/`
    // holds ~106 direct calls; `packages/cc_data` holds ~387, because that is
    // where the repository adapters live. Scanning only the first missed the
    // three quarters of the surface that actually talks to the server.
    //
    // A `cc_data` call that catches `opUnknown` and returns an empty/false
    // value is already the fix this test asks for, so it is not a finding.
    // Those catches are the reason the adapter tree can be scanned at all
    // without a hundred-line allowlist.
    // In the adapter tree only READS are enforced, and that split is the
    // point of the test rather than a shortcut. A read runs when a screen
    // opens, so its failure IS the screen — that is the red text in the
    // screenshots. A mutation runs when someone presses a control they chose
    // to press, and its failure is a toast over a page that still looks right.
    // The demo disables the controls that matter (add/delete repo, save
    // lifecycle script) and the rest are behind surfaces a visitor does not
    // reach; enforcing all 164 of them here would mean an allowlist longer
    // than the test.
    final root = _repoRoot();
    final called = <String, Set<String>>{};
    for (final tree in ['lib', 'packages/cc_data/lib']) {
      final readsOnly = tree != 'lib';
      for (final file in Directory('${root.path}/$tree')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        for (final m in RegExp(
          r"""\.call\(\s*'([a-zA-Z_]+\.[a-zA-Z_]+)'""",
        ).allMatches(source)) {
          final op = m.group(1)!;
          if (readsOnly && !_looksLikeRead(op)) {
            continue;
          }
          if (_swallowsOpUnknown(source, m.end)) {
            continue;
          }
          called
              .putIfAbsent(op, () => <String>{})
              .add(file.path.substring(root.path.length + 1));
        }
      }
    }
    expect(
      called,
      isNotEmpty,
      reason: 'found no client call sites — the scan regex probably broke',
    );

    final leaking = <String>[];
    for (final entry in called.entries) {
      if (available.contains(entry.key)) {
        continue;
      }
      if (handledByTheClient.contains(entry.key)) {
        continue;
      }
      leaking.add('${entry.key}  ← ${entry.value.join(', ')}');
    }
    leaking.sort();

    expect(
      leaking,
      isEmpty,
      reason:
          'These ops are called by the Flutter client but do NOT exist on a '
          'demo server, and no surface claims to handle it — a visitor sees '
          'red "Unknown op" text where content should be.\n'
          'Either gate the call on `isDemoServerProvider` (and add it to '
          '`handledByTheClient` here), or admit the op in DemoProfile:\n'
          '  ${leaking.join("\n  ")}',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}

/// Whether [op] names a read — one a screen issues just by opening.
///
/// Matched on the verb rather than asked of the server, because the catalogue
/// a DEMO server exposes is precisely the set that excludes these; the name is
/// the only signal available for an op that is already gone.
bool _looksLikeRead(String op) {
  final member = op.split('.').last;
  return RegExp(
    r'^(get|list|read|load|search|fetch|detect|resolve|preview|count|'
    r'summar|histor|available|catalog|state|info|usage|metrics|stats|'
    r'current|all|status|by|is|has|check)',
  ).hasMatch(member);
}

/// Whether the call at [callEnd] sits inside a method that handles
/// `opUnknown` itself.
///
/// The window runs to the next member declaration rather than a fixed
/// character count, so a long method is still read to its end and a short one
/// cannot borrow the next method's catch block.
bool _swallowsOpUnknown(String source, int callEnd) {
  final nextMember = RegExp(
    r'\n  (?:@override\n  )?[A-Za-z_][\w<>,\[\]? ]*\s+[a-zA-Z_]+[(<]',
  ).firstMatch(source.substring(callEnd));
  final end = nextMember == null
      ? source.length
      : callEnd + nextMember.start;
  return source.substring(callEnd, end).contains('opUnknown');
}

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (Directory('${dir.path}/lib/features').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/packages').existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  fail('could not locate the repo root from ${Directory.current.path}');
}
