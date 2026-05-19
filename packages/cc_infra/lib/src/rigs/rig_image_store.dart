import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// The running host's architecture, as the image catalogue keys it.
///
/// `Platform.version` rather than a uname shell-out: it is already in memory
/// and this is read on every capability probe.
String get hostArchitecture {
  final version = Platform.version;
  return version.contains('arm64') || version.contains('aarch64')
      ? 'arm64'
      : 'x64';
}

/// One downloadable artifact: a URL and the hash it must match.
class RigImageArtifact {
  /// Creates a [RigImageArtifact].
  const RigImageArtifact({required this.url, required this.sha256});

  /// Immutable URL. A "latest" pointer is deliberately NOT usable here: its
  /// bytes change under a pinned hash, which would turn every future download
  /// into a checksum failure.
  final String url;

  /// Lower-case hex SHA-256 of exactly those bytes.
  final String sha256;
}

/// One base image a rig can boot.
///
/// Images are the ONLY thing rigs fetch at runtime, and they follow the same
/// policy the on-device models already do: user-initiated download, never
/// silent; checksum-pinned; stored under the data dir; removable with it. A
/// rig image is a whole operating system, so "we quietly downloaded 2 GB" is
/// not an acceptable surprise.
class RigImageSpec {
  /// Creates a [RigImageSpec].
  const RigImageSpec({
    required this.id,
    required this.surface,
    required this.description,
    required this.artifacts,
    required this.sizeBytes,
  });

  /// Stable image id, also its directory name.
  final String id;

  /// Which surface it serves.
  final RigSurface surface;

  /// One line for the settings UI.
  final String description;

  /// Where the rootfs/disk comes from on THIS host's architecture.
  ///
  /// A qcow2 holds a compiled operating system, so one URL cannot serve both
  /// an Apple Silicon Mac and an x86 server. [artifacts] holds one entry per
  /// architecture and this resolves the running one.
  String get url => _artifactFor(hostArchitecture)?.url ?? '';

  /// The expected SHA-256 of the downloaded file, lower-case hex.
  ///
  /// Verified before the file is moved into place. A mismatch deletes the
  /// download and fails loudly: a base image is the root of trust for
  /// everything that runs inside the rig, so "close enough" is not a state
  /// this store has.
  String get sha256 => _artifactFor(hostArchitecture)?.sha256 ?? '';

  /// Per-architecture artifacts, keyed `arm64` / `x64`.
  final Map<String, RigImageArtifact> artifacts;

  RigImageArtifact? _artifactFor(String architecture) =>
      artifacts[architecture];

  /// Whether an artifact exists for [architecture].
  bool supportsArchitecture(String architecture) =>
      artifacts.containsKey(architecture);

  /// Approximate download size, so the UI can warn before starting.
  final int sizeBytes;

  /// Whether this entry can actually be downloaded ON THIS HOST.
  ///
  /// False when no artifact has been published for the running architecture:
  /// there is no URL and no pinned hash, and [RigImageStore.download] refuses
  /// it. Surfaced so the UI can say "not published yet — import one instead"
  /// rather than offering a button that always fails.
  bool get isPublished => sha256.isNotEmpty && url.startsWith('https://');

  /// The disk/rootfs filename inside the image directory.
  String get diskFileName => 'disk.qcow2';
}

/// Where an image sits on disk, and whether it is usable.
class RigImageStatus {
  /// Creates a [RigImageStatus].
  const RigImageStatus({
    required this.spec,
    required this.present,
    required this.directory,
    this.downloadedBytes,
  });

  /// The image this describes.
  final RigImageSpec spec;

  /// Whether every artifact is present and verified.
  final bool present;

  /// Where it lives (whether or not it is there yet).
  final String directory;

  /// Bytes on disk so far, for a partial download.
  final int? downloadedBytes;
}

/// Progress of an in-flight image download.
class RigImageDownloadProgress {
  /// Creates a [RigImageDownloadProgress].
  const RigImageDownloadProgress({
    required this.imageId,
    required this.receivedBytes,
    required this.totalBytes,
    this.stage = 'downloading',
  });

  /// Which image.
  final String imageId;

  /// Bytes received so far.
  final int receivedBytes;

  /// Expected total, or -1 when the server did not say.
  final int totalBytes;

  /// `downloading` / `verifying` / `done`.
  final String stage;

  /// 0..1, or null when the total is unknown.
  double? get fraction =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0, 1) : null;
}

/// The built-in image catalogue.
///
/// Deliberately small and explicit. Adding an entry is a supply-chain
/// decision — this is the software that runs inside the boundary — so it is a
/// code change with a pinned hash, not a config file a workspace can point at
/// an arbitrary URL.
///
/// Only the QEMU desktop image lives here: it is NOT published yet — it needs
/// our own guest agent baked in, which a stock cloud image has no way to
/// provide. It carries no artifacts, so [RigImageSpec.isPublished] is false,
/// the UI offers import instead of download, and
/// `scripts/rigs/build_image.sh` builds one.
///
/// Terminal (exec) and browser rigs need no entry at all: they are smolvm
/// microVMs whose images are digest-pinned OCI references
/// (`kSmolvmExecImage` / `kSmolvmBrowserImage`) pulled by the runtime itself.
const List<RigImageSpec> kRigImageCatalog = [
  RigImageSpec(
    id: 'cc-desktop-linux',
    surface: RigSurface.computer,
    description:
        'X11 desktop + window manager + the capture agent (computer use). '
        'Enabled by importing a compatible disk image.',
    sizeBytes: 1200 * 1024 * 1024,
    artifacts: {},
  ),
];

/// Manages the on-disk rig image store under `<dataDir>/rigs/images/`.
class RigImageStore {
  /// Creates a [RigImageStore] rooted at [dataDir].
  RigImageStore({
    required String dataDir,
    List<RigImageSpec> catalog = kRigImageCatalog,
    HttpClient Function()? httpClientFactory,
  }) : _root = p.join(dataDir, 'rigs', 'images'),
       _catalog = catalog,
       _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final String _root;
  final List<RigImageSpec> _catalog;
  final HttpClient Function() _httpClientFactory;

  /// The catalogue this store serves.
  List<RigImageSpec> get catalog => List.unmodifiable(_catalog);

  /// The image directory root.
  String get root => _root;

  /// The default image for [surface], or null when there is none.
  ///
  /// Every catalogued image serves a surface someone looks at. Terminal and
  /// browser rigs are smolvm machines and never consult the store.
  RigImageSpec? defaultFor(RigSurface surface) {
    for (final spec in _catalog) {
      if (spec.surface == surface) {
        return spec;
      }
    }
    return null;
  }

  /// Looks an image up by id.
  RigImageSpec? byId(String id) {
    for (final spec in _catalog) {
      if (spec.id == id) {
        return spec;
      }
    }
    return null;
  }

  /// Where [spec]'s artifacts live.
  String directoryFor(RigImageSpec spec) => p.join(_root, spec.id);

  /// The bootable disk path for [spec].
  String diskPathFor(RigImageSpec spec) =>
      p.join(directoryFor(spec), spec.diskFileName);

  /// Whether every artifact for [spec] is on disk.
  ///
  /// Presence only — the hash was verified when the file was moved into place
  /// and re-hashing a 2 GB file on every probe would make the settings page
  /// cost a minute of disk I/O.
  bool isPresent(RigImageSpec spec) {
    if (!File(diskPathFor(spec)).existsSync()) {
      return false;
    }
    return true;
  }

  /// Status for every catalogued image.
  List<RigImageStatus> statuses() => [
    for (final spec in _catalog)
      RigImageStatus(
        spec: spec,
        present: isPresent(spec),
        directory: directoryFor(spec),
        downloadedBytes: _sizeOrNull(diskPathFor(spec)),
      ),
  ];

  /// The wire form of every image's status, for `rig.images`.
  List<Map<String, dynamic>> statusesToJson() => [
    for (final status in statuses())
      {
        'id': status.spec.id,
        'surface': status.spec.surface.wire,
        'description': status.spec.description,
        'size_bytes': status.spec.sizeBytes,
        'present': status.present,
        'published': status.spec.isPublished,
        'directory': status.directory,
        if (status.downloadedBytes != null)
          'downloaded_bytes': status.downloadedBytes,
      },
  ];

  /// The ids of images [surface] needs but does not have.
  List<String> missingFor(RigSurface surface) => [
    for (final spec in _catalog)
      if (spec.surface == surface && !isPresent(spec)) spec.id,
  ];

  /// Downloads [spec]'s artifacts, verifying each checksum before it lands.
  ///
  /// USER-INITIATED ONLY — nothing calls this on a probe, a boot or a timer.
  /// Progress is streamed so the UI can show it; the download writes to a
  /// `.part` file and is renamed into place only after the hash matches, so a
  /// killed download never leaves a half-image that looks bootable.
  Stream<RigImageDownloadProgress> download(RigImageSpec spec) async* {
    if (!spec.isPublished) {
      // Said here rather than after a 404 or, worse, after installing an
      // unverified operating system.
      throw RigImageException(
        'The base image "${spec.id}" has not been published yet, so there is '
        'nothing to download. Import a compatible disk image instead.',
      );
    }
    final dir = Directory(directoryFor(spec));
    await dir.create(recursive: true);

    yield* _downloadOne(
      imageId: spec.id,
      url: spec.url,
      expectedSha256: spec.sha256,
      destination: diskPathFor(spec),
      totalHint: spec.sizeBytes,
    );
    yield RigImageDownloadProgress(
      imageId: spec.id,
      receivedBytes: spec.sizeBytes,
      totalBytes: spec.sizeBytes,
      stage: 'done',
    );
  }

  /// Adopts an existing disk image at [sourcePath] as [spec]'s artifact.
  ///
  /// The path that works TODAY: the catalogue's own artifacts are not
  /// published, so an operator who built an image locally (or already has a
  /// qcow2) needs a way in that does not involve a URL.
  ///
  /// Copied rather than referenced, because the store owns its files: a rig
  /// boots an overlay whose backing file must not move or change underneath
  /// it, and a symlink into the operator's Downloads folder is exactly the
  /// kind of thing that gets cleaned up mid-session.
  ///
  /// **Verified, like the download path.** This is the production path for the
  /// desktop and browser images (their artifacts are not published), so
  /// installing whatever bytes were named would mean the "base images are
  /// checksum-pinned" invariant simply does not hold where it is actually
  /// used. Three checks, in ascending strength:
  ///
  ///  * a size floor — a bootable qcow2 is never under a megabyte;
  ///  * the qcow2 magic (`QFI\xFB`) — a tarball, a truncated download or the
  ///    wrong file entirely becomes `disk.qcow2` and reports `present`
  ///    otherwise, deferring the failure to a confusing first boot minutes
  ///    later;
  ///  * the catalogue's pinned SHA-256 when there is one. When there is not,
  ///    the digest of what WAS installed is logged, so the bytes a host is
  ///    running are at least recorded rather than unknown.
  Stream<RigImageDownloadProgress> importFrom(
    RigImageSpec spec,
    String sourcePath,
  ) async* {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw RigImageException('No file at $sourcePath');
    }
    final total = source.lengthSync();
    if (total < 1024 * 1024) {
      // A qcow2 of a bootable system is never this small. Catching it here
      // beats a QEMU error three minutes into a first boot.
      throw RigImageException(
        'The file at $sourcePath is only $total bytes — that is not a disk '
        'image.',
      );
    }
    await _requireQcow2(source);
    await Directory(directoryFor(spec)).create(recursive: true);
    final destination = diskPathFor(spec);
    final partPath = '$destination.part';
    final part = File(partPath);
    if (part.existsSync()) {
      await part.delete();
    }

    final sink = part.openWrite();
    var copied = 0;
    var lastReport = 0;
    var installed = false;
    String digest = '';
    try {
      // Hashed while streaming rather than by re-reading the finished file: a
      // multi-gigabyte image would otherwise be read twice.
      Digest? computed;
      final hasher = sha256.startChunkedConversion(
        ChunkedConversionSink<Digest>.withCallback(
          (digests) => computed = digests.single,
        ),
      );
      await for (final chunk in source.openRead()) {
        sink.add(chunk);
        hasher.add(chunk);
        copied += chunk.length;
        if (copied - lastReport >= 4 * 1024 * 1024) {
          lastReport = copied;
          yield RigImageDownloadProgress(
            imageId: spec.id,
            receivedBytes: copied,
            totalBytes: total,
            stage: 'importing',
          );
        }
      }
      hasher.close();
      await sink.flush();
      await sink.close();
      digest = computed.toString();

      final expected = spec.sha256;
      if (expected.isNotEmpty && digest != expected.toLowerCase()) {
        // The catalogue knows what this image is supposed to be, so importing
        // something else is a mistake worth naming — not a local override.
        throw RigImageException(
          'Checksum mismatch importing $sourcePath as ${spec.id}\n'
          '  expected $expected\n'
          '  got      $digest\n'
          'The file was not installed.',
        );
      }
      // Written fully, then moved into place in one atomic rename within the
      // same directory: at no point is there a short file at the path a rig
      // would boot from.
      await part.rename(destination);
      installed = true;
    } finally {
      try {
        await sink.close();
      } on Object {
        // Already closed, or the failure that brought us here closed it.
      }
      if (!installed) {
        await _discardPartial(partPath);
      }
    }
    // Recorded even when nothing was pinned: an operator who later wonders
    // which build a host is running has an answer in the log rather than a
    // filename.
    CcInfraLog.info(
      'rig/images: imported $sourcePath as ${spec.id} (sha256:$digest)',
    );
    yield RigImageDownloadProgress(
      imageId: spec.id,
      receivedBytes: total,
      totalBytes: total,
      stage: 'done',
    );
  }

  /// Deletes the artifacts of the image with id [imageId].
  ///
  /// Deleting NOTHING is an error, not a success. A remove that quietly
  /// no-ops when there was nothing there makes a typo — a stale id, the wrong
  /// store root, a directory some other process already took — indistinguish-
  /// able from a real deletion, and the operator walks away believing gigabytes
  /// were reclaimed. Say so instead.
  Future<void> removeById(String imageId) async {
    final spec = byId(imageId);
    if (spec == null) {
      throw RigImageException(
        'No base image "$imageId" is catalogued, so there was nothing to '
        'remove.',
      );
    }
    await remove(spec);
  }

  /// Deletes [spec]'s artifacts. Throws when there was nothing to delete.
  Future<void> remove(RigImageSpec spec) async {
    final dir = Directory(directoryFor(spec));
    if (!dir.existsSync()) {
      throw RigImageException(
        'Nothing to remove for "${spec.id}": ${dir.path} does not exist. '
        'Either it was never downloaded or the store root is not the one you '
        'think it is.',
      );
    }
    final contents = dir.listSync(followLinks: false);
    await dir.delete(recursive: true);
    CcInfraLog.info(
      'rig/images: removed ${dir.path} (${contents.length} entr'
      '${contents.length == 1 ? 'y' : 'ies'})',
    );
  }

  Stream<RigImageDownloadProgress> _downloadOne({
    required String imageId,
    required String url,
    required String? expectedSha256,
    required String destination,
    required int totalHint,
  }) async* {
    final partPath = '$destination.part';
    final partFile = File(partPath);
    if (partFile.existsSync()) {
      await partFile.delete();
    }
    final client = _httpClientFactory();
    IOSink? sink;
    // Set only once the verified bytes are at their final path. Anything else
    // — an HTTP error, a socket that died mid-stream, a checksum mismatch, a
    // cancelled subscription — leaves the `.part` file behind, and a partial
    // download that survives is a file `_sizeOrNull` reports as progress and a
    // later run may be tempted to trust.
    var installed = false;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw RigImageException(
          'Download of $url failed with HTTP ${response.statusCode}',
        );
      }
      final total = response.contentLength > 0
          ? response.contentLength
          : totalHint;
      sink = partFile.openWrite();
      // Hash while streaming rather than re-reading the finished file: a
      // multi-gigabyte image would otherwise be read twice, once to write and
      // once to verify.
      Digest? computed;
      final hasher = sha256.startChunkedConversion(
        ChunkedConversionSink<Digest>.withCallback(
          (digests) => computed = digests.single,
        ),
      );
      var received = 0;
      var lastReport = 0;
      await for (final chunk in response) {
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        // Report roughly every 4 MB rather than per chunk: a 2 GB download is
        // ~130k chunks and one event each would flood every subscriber.
        if (received - lastReport >= 4 * 1024 * 1024) {
          lastReport = received;
          yield RigImageDownloadProgress(
            imageId: imageId,
            receivedBytes: received,
            totalBytes: total,
          );
        }
      }
      hasher.close();
      await sink.flush();
      await sink.close();
      sink = null;

      yield RigImageDownloadProgress(
        imageId: imageId,
        receivedBytes: received,
        totalBytes: total,
        stage: 'verifying',
      );
      final actual = computed.toString();
      if (expectedSha256 == null || expectedSha256.isEmpty) {
        // A catalogue entry with no pin is a build-time omission, not a
        // runtime condition to paper over. Refuse rather than install
        // unverified system software.
        throw RigImageException(
          'No checksum is pinned for $url — refusing to install an unverified '
          'base image. This is a build configuration error.',
        );
      }
      if (actual != expectedSha256.toLowerCase()) {
        throw RigImageException(
          'Checksum mismatch for $url\n'
          '  expected $expectedSha256\n'
          '  got      $actual\n'
          'The download was discarded.',
        );
      }
      // Verified first, renamed second, and the temp file lives in the SAME
      // directory as its destination so the rename is atomic rather than a
      // cross-device copy that can be interrupted halfway.
      await partFile.rename(destination);
      installed = true;
      CcInfraLog.info('rig/images: installed $destination ($received bytes)');
    } on RigImageException {
      rethrow;
    } on Object catch (e) {
      // A socket that died mid-stream, a full disk, a DNS failure: all of them
      // are "this image is not installed", and the operator needs the URL and
      // the cause, not a bare HttpException from three layers down.
      throw RigImageException(
        'Download of $url failed: $e\nThe partial file was discarded.',
      );
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } on Object {
          // Already closed / failed mid-write.
        }
      }
      if (!installed) {
        await _discardPartial(partPath);
      }
      client.close(force: true);
    }
  }

  /// The four magic bytes every qcow2 starts with: `QFI\xFB`.
  ///
  /// Cheap, and it catches the whole family of "wrong file" mistakes an
  /// operator actually makes — a `.tar.gz` of the image, a half-finished
  /// download, a raw disk, the wrong build entirely — at the moment the path
  /// is typed rather than three minutes into a first boot that reports
  /// nothing more useful than a timeout.
  static Future<void> _requireQcow2(File source) async {
    final handle = await source.open();
    try {
      final header = await handle.read(4);
      if (header.length < 4 ||
          header[0] != 0x51 || // 'Q'
          header[1] != 0x46 || // 'F'
          header[2] != 0x49 || // 'I'
          header[3] != 0xFB) {
        throw RigImageException(
          '${source.path} is not a qcow2 disk image (its first bytes are not '
          'the qcow2 magic). If it is an archive, extract it first; if it is a '
          'raw disk, convert it with '
          '`qemu-img convert -O qcow2 <in> <out>`.',
        );
      }
    } finally {
      await handle.close();
    }
  }

  /// Removes a `.part` file left by a download or import that did not finish.
  static Future<void> _discardPartial(String partPath) async {
    final part = File(partPath);
    if (!part.existsSync()) {
      return;
    }
    try {
      await part.delete();
    } on Object catch (e) {
      // Worth saying out loud: a leftover `.part` is reported as download
      // progress by `_sizeOrNull`, so a silent failure here shows up later as
      // a download that appears to resume from bytes nobody verified.
      CcInfraLog.warning('rig/images: could not discard $partPath: $e');
    }
  }

  static int? _sizeOrNull(String path) {
    final f = File(path);
    if (f.existsSync()) {
      return f.lengthSync();
    }
    final part = File('$path.part');
    return part.existsSync() ? part.lengthSync() : null;
  }
}

/// An image could not be fetched or verified.
class RigImageException implements Exception {
  /// Creates a [RigImageException].
  const RigImageException(this.message);

  /// What went wrong, phrased for the operator.
  final String message;

  @override
  String toString() => message;
}
