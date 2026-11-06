part of 'smolvm_enclosure_backend.dart';

/// The OCI image every environment rig boots, pinned by digest.
///
/// Docker's own engine image: dockerd, the compose plugin and an Alpine
/// userland. The digest is the Hub index digest, so one pin serves arm64 and
/// x64 hosts. Separate from [kSmolvmExecImage], which excludes Docker on
/// purpose.
const String kSmolvmEnvironmentImage =
    'docker:29-dind'
    '@sha256:4495bd03abbe729dae065ecc187801a19820fd19159948f01d68a57a8d281bd0';

/// The largest storage disk an environment rig can have, in GiB.
///
/// Measured on smolvm 1.16.1, not chosen: a machine with a dockerd workload
/// and a larger storage disk, or a larger overlay than
/// [kSmolvmEnvironmentOverlayGb], boots once and then fails every later
/// `machine start` with `crun create failed: crun exit status: 127`. A retry
/// does not recover it. Stopping keeps a rig's disk, so a size that cannot
/// restart is refused at create instead of failing at resume.
const int kSmolvmEnvironmentMaxStorageGb = 16;

/// The overlay disk of an environment rig, in GiB. See
/// [kSmolvmEnvironmentMaxStorageGb].
const int kSmolvmEnvironmentOverlayGb = 8;

/// Bumps when what the environment image warms changes.
const String kSmolvmEnvironmentPackVariant = 'environment-v2';

/// Where the worktree appears in an environment guest.
const String kSmolvmEnvironmentWorkdir = '/workspace';

/// Every guest path an environment rig shows a worktree at, with the host
/// directory behind it.
Map<String, String> environmentRigMountTargets(RigSpec spec) => {
  kSmolvmEnvironmentWorkdir: ?spec.worktreePath,
  ...spec.extraMounts,
};

/// Where the read-only share of [target] lands in the guest.
String smolvmEnvironmentLowerDir(String target) => '/mnt/cc-ro$target';

/// Mounts a writable overlay at each of [targets] over its read-only share.
///
/// The upper layer is on the guest's own disk, so writes, `.git` included,
/// never reach the host, while host edits show through the lower layer live.
/// Run with `machine exec`, which shares dockerd's mount namespace (an
/// `--init` runs elsewhere and is invisible to both). Idempotent, and needed
/// after every start: the mount does not survive a restart, the upper does.
String smolvmEnvironmentOverlayScript(Iterable<String> targets) =>
    targets.map(_overlayMountFor).join(' && ');

String _overlayMountFor(String target) {
  final layers = '/storage/cc-overlay$target';
  final options =
      'lowerdir=${smolvmEnvironmentLowerDir(target)},'
      'upperdir=$layers/upper,workdir=$layers/work';
  return 'mkdir -p $layers/upper $layers/work $target && '
      '(grep -q " $target overlay " /proc/mounts || '
      'mount -t overlay overlay -o $options $target)';
}

/// dockerd as an environment machine's workload.
///
/// Every flag is load-bearing, and measured: overlay on the guest rootfs fails
/// with `invalid argument`, so the data root goes on the storage disk, and the
/// containerd snapshotter would put it back on the rootfs.
const List<String> kSmolvmEnvironmentWorkload = [
  'dockerd',
  '--data-root=/storage/docker',
  '--storage-driver=overlay2',
  '--feature',
  'containerd-snapshotter=false',
];

/// The Alpine mirror an environment guest reaches to install socat, the port
/// mux's only dependency. Admitted only until the pack exists, because nothing
/// the stack does goes through it.
const List<String> kEnvironmentRigApkMirrors = ['dl-cdn.alpinelinux.org'];

/// First-start install for an environment guest. A no-op once warmed.
String smolvmEnvironmentInit() =>
    'command -v socat >/dev/null 2>&1 || apk add --no-cache -q socat';

/// Probe that a warmed environment template received socat.
const String kSmolvmEnvironmentWarmProbe = 'command -v socat >/dev/null 2>&1';

/// The `smolvm machine exec` argument vector for [argv] in [machine].
List<String> buildSmolvmExecArgs(
  String machine,
  List<String> argv, {
  String? workdir,
  Map<String, String> environment = const {},
  Duration timeout = const Duration(minutes: 10),
}) => [
  'machine',
  'exec',
  '--name',
  machine,
  '--timeout',
  '${timeout.inSeconds}s',
  if (workdir != null) ...['--workdir', workdir],
  for (final entry in environment.entries) ...[
    '-e',
    '${entry.key}=${entry.value}',
  ],
  '--',
  ...argv,
];

/// What only an environment machine needs at boot.
extension _SmolvmEnvironmentBoot on SmolvmEnclosureBackend {
  /// Waits until dockerd answers: an environment rig's readiness.
  Future<void> _awaitDocker(
    String binary,
    String name, {
    void Function(String step)? onProgress,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    onProgress?.call('Waiting for Docker');
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      final result = await _run(binary, [
        'machine',
        'exec',
        '--name',
        name,
        '--timeout',
        '10s',
        '--',
        'docker',
        'version',
        '--format',
        '{{.Server.Version}}',
      ], timeout: const Duration(seconds: 20));
      if (result.exitCode == 0) {
        return;
      }
      lastError = result.stderr;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw RigToolException(
      tool: 'docker',
      stderr: '$lastError',
      hint: 'dockerd did not answer in the environment rig.',
    );
  }

  Future<void> _mountEnvironmentOverlays(
    String binary,
    String name,
    RigSpec spec,
  ) => _runChecked(binary, [
    'machine',
    'exec',
    '--name',
    name,
    '--timeout',
    '30s',
    '--',
    'sh',
    '-c',
    smolvmEnvironmentOverlayScript(environmentRigMountTargets(spec).keys),
  ], hint: 'Without the overlay the worktree is read-only in the rig.');
}
