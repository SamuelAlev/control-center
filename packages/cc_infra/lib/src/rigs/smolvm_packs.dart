part of 'smolvm_enclosure_backend.dart';

/// Pre-extracted, warmed image packs: a faster way to the same bytes, never
/// a different policy.
extension _SmolvmPacks on SmolvmEnclosureBackend {
  /// Builds the pack for [image] in the background.
  ///
  /// After the image is already in smolvm's cache (so no second download).
  /// Written beside the destination and renamed in — a killed build must not
  /// leave a file a later boot trusts. Best-effort: pack failures must not
  /// surface near a boot.
  /// Browser image packs directly (fully baked). Exec packs a warmed
  /// throwaway template after init installs the toolset — no secrets,
  /// worktree, or per-rig state — so later boots skip apt and mirrors.
  Future<void> _buildPack(
    String binary,
    String image, {
    String variant = '',
    String? warmInit,
    List<String> warmMirrors = const [],
    String? warmProbe,
    List<String>? warmWorkload,
    int warmStorageGb = 8,
    int warmOverlayGb = 16,
  }) async {
    final destination = packPathFor(image, variant: variant);
    // Keyed on image AND variant, like the pack itself: Firefox and WebKit
    // share a base image, and keying on the image alone would have the
    // first of them to boot block the other's pack from ever being built.
    final key = '$image#$variant';
    if (!_packsBuilding.add(key)) {
      return;
    }
    try {
      if (File(destination).existsSync()) {
        return;
      }
      await Directory(_packsDir).create(recursive: true);
      // `pack create -o X` writes an executable stub at X and the actual
      // artifact at X.smolmachine; only the artifact is kept. X must NOT end
      // in `.smolmachine` — the tool refuses an output named like the
      // sidecar it is about to create.
      final stub = p.join(
        _packsDir,
        '.building-${p.basenameWithoutExtension(destination)}',
      );
      final warms = warmInit != null && warmProbe != null;
      final ProcessResult result;
      if (warms) {
        final template = await _buildWarmTemplate(
          binary,
          image,
          init: warmInit,
          mirrors: warmMirrors,
          probe: warmProbe,
          workload: warmWorkload,
          storageGb: warmStorageGb,
          overlayGb: warmOverlayGb,
        );
        if (template == null) {
          return;
        }
        try {
          result = await _run(binary, [
            'pack',
            'create',
            '--from-vm',
            template,
            '-o',
            stub,
          ], timeout: SmolvmEnclosureBackend._packTimeout);
        } finally {
          await _deleteQuietly(binary, template);
        }
      } else {
        result = await _run(binary, [
          'pack',
          'create',
          '--image',
          image,
          '-o',
          stub,
        ], timeout: SmolvmEnclosureBackend._packTimeout);
      }
      if (result.exitCode != 0) {
        CcInfraLog.warning(
          'rig/smolvm: pack build for $image failed (exit ${result.exitCode}):'
          ' ${result.stderr}',
        );
        return;
      }
      await File('$stub.smolmachine').rename(destination);
      await _deleteFileQuietly(stub);
      CcInfraLog.info(
        'rig/smolvm: cached $image as a pre-extracted pack '
        '(${p.basename(destination)}) — later machines skip the pull'
        '${warms ? ' and the first-start package install' : ''}',
      );
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: pack build for $image failed: $e');
    } finally {
      _packsBuilding.remove(key);
    }
  }

  /// Boots a pristine template of [image], lets [init] warm the overlay,
  /// verifies with [probe] that the warm actually took, and returns the
  /// STOPPED machine's name ready to snapshot — or null on any failure.
  ///
  /// Used for both kinds of warm start: the exec image's toolset and a
  /// browser engine's own packages. The template carries NO secrets, NO
  /// worktree and no per-rig state — it never gets any: no broker secret, no
  /// port forwards, nothing synced in — so the snapshot is safe to share
  /// across every later rig and conversation.
  ///
  /// The caller deletes the machine; a builder that dies mid-flight leaves a
  /// labelled machine the next start's orphan sweep collects.
  Future<String?> _buildWarmTemplate(
    String binary,
    String image, {
    required String init,
    required String probe,
    List<String> mirrors = const [],
    List<String>? workload,
    int storageGb = 8,
    int overlayGb = 16,
  }) async {
    // Unique per attempt: two servers with different data dirs share one
    // global machine store, and a fixed name would have them fighting over
    // one record.
    final template =
        'ccpack-tmpl-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    try {
      await _runChecked(binary, [
        'machine', 'create',
        '--name', template,
        '--image', image,
        '--cpus', '2',
        '--mem', '1024',
        // The same disk shape the rigs booting from it get, so the snapshot's
        // layout matches.
        '--storage', '$storageGb', '--overlay', '$overlayGb',
        // Owned like every rig machine, so a crashed builder's template is
        // swept at the next service start instead of leaking forever.
        '--label', '$kSmolvmOwnerLabel=$kSmolvmOwnerValue',
        '--label', '$kSmolvmDataDirLabel=$_dataDir',
        '--label', 'cc-surface=pack-template',
        // Exactly the egress a real exec rig's warm-up needs and nothing
        // else: apt mirrors for the install, the image's own registry for
        // the pull.
        '--outbound-localhost-only',
        for (final host in {
          ...mirrors,
          ...registryHostsForImageRef(image),
        }) ...['--allow-host', host],
        '--init', init,
        if (workload != null) ...['--', ...workload],
      ]);
      // Start blocks until init finishes, but verify anyway: an apt failure
      // exits init non-fatally and a snapshot of a HALF-warm template would
      // cache the breakage for every later rig.
      await _runChecked(binary, [
        'machine',
        'start',
        '--name',
        template,
      ], timeout: SmolvmEnclosureBackend._startTimeout);
      final check = await _run(binary, [
        'machine',
        'exec',
        '--name',
        template,
        '--timeout',
        '30s',
        '--',
        'sh',
        '-c',
        probe,
      ]);
      if (check.exitCode != 0) {
        CcInfraLog.warning(
          'rig/smolvm: the template for $image never warmed (are the apt '
          'mirrors reachable?); keeping the plain-boot path',
        );
        await _deleteQuietly(binary, template);
        return null;
      }
      // A snapshot needs a stopped machine.
      await _runChecked(binary, [
        'machine',
        'stop',
        '--name',
        template,
      ], timeout: SmolvmEnclosureBackend._deleteTimeout);
      return template;
    } on Object catch (e) {
      CcInfraLog.warning('rig/smolvm: template build for $image failed: $e');
      await _deleteQuietly(binary, template);
      return null;
    }
  }

  /// Removes pack files no pinned image references any more (an image bump
  /// changes the pack name) and the debris of interrupted builds.
  Future<void> _prunePacks() async {
    final dir = Directory(_packsDir);
    if (!dir.existsSync()) {
      return;
    }
    final wanted = {
      smolvmPackFileName(
        kSmolvmExecImage,
        variant: smolvmPackVariantFor(RigSpec.exec(conversationId: '_pack')),
      ),
      smolvmPackFileName(
        kSmolvmEnvironmentImage,
        variant: kSmolvmEnvironmentPackVariant,
      ),
      for (final engine in RigBrowserEngine.values)
        smolvmPackFileName(
          smolvmBrowserImageFor(engine),
          variant: smolvmPackVariantFor(
            RigSpec(
              surface: RigSurface.browser,
              conversationId: '_pack',
              browserEngine: engine,
            ),
          ),
        ),
    };
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && !wanted.contains(p.basename(entity.path))) {
        CcInfraLog.info(
          'rig/smolvm: pruning stale pack ${p.basename(entity.path)}',
        );
        await _deleteFileQuietly(entity.path);
      }
    }
  }
}
