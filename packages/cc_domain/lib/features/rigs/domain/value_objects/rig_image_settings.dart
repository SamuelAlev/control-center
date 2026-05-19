/// Per-workspace overrides for the enclosed Terminal (VM) and Browser (VM)
/// images.
///
/// A workspace can point either surface at its own OCI image — typically one
/// built on top of the defaults with extra tooling baked in — via the
/// workspace settings store (admin-gated, like every workspace policy). The
/// override is a REGISTRY REFERENCE only: the machine still boots inside the
/// same enclosure, behind the same egress gate, driven through the same
/// contract (the browser must serve DevTools where ours does, the terminal
/// must carry the tools ours carries — see the rigs guide in the docs).
library;

/// Workspace-settings key for the Terminal (VM) image override.
const String kRigExecImageSettingKey = 'rigs.smolvm.execImage';

/// Workspace-settings key for the Browser (VM) image override.
const String kRigBrowserImageSettingKey = 'rigs.smolvm.browserImage';

/// A plausible OCI registry reference: `[registry[:port]/]repo[/…][:tag]
/// [@sha256:…]`.
///
/// Deliberately stricter than what a registry client accepts, because this
/// value crosses from a workspace SETTING into a host command line. Local
/// sources (`./archive.tar`, `/rootfs/`, `-` for stdin) are how the runtime
/// would be talked into reading arbitrary host files as an image, so nothing
/// that could name one passes: no leading `/ . -`, no whitespace, no archive
/// suffixes.
final RegExp _kImageRefPattern = RegExp(
  r'^[a-z0-9]+((\.|__|[_-]+)[a-z0-9]+)*'
  r'(:[0-9]+)?'
  r'(/[a-z0-9]+((\.|__|[_-]+)[a-z0-9]+)*)*'
  r'(:[a-zA-Z0-9_][a-zA-Z0-9._-]{0,127})?'
  r'(@sha256:[a-f0-9]{64})?$',
);

/// Normalizes a stored override: trimmed, with blank collapsing to null
/// (meaning "use the default image").
String? normalizeCustomRigImageRef(String? raw) {
  final trimmed = raw?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Whether [ref] is safe to hand to the microVM runtime as an image source.
bool isValidCustomRigImageRef(String ref) {
  if (ref.isEmpty || ref.length > 512) {
    return false;
  }
  if (ref.startsWith('.') || ref.startsWith('/') || ref.startsWith('-')) {
    return false;
  }
  for (final suffix in const ['.tar', '.tar.gz', '.tgz']) {
    if (ref.endsWith(suffix)) {
      return false;
    }
  }
  return _kImageRefPattern.hasMatch(ref);
}

/// The registry-pull hosts a machine booting [ref] needs admitted through its
/// egress gate.
///
/// The image is pulled by the GUEST agent from inside the gated network, so
/// a machine created without these can never boot an uncached image. The
/// well-known registries need their blob CDNs alongside the API host; a
/// registry not listed here gets its own host admitted and may still fail to
/// pull if it hands blobs off to a separate CDN — the docs say which
/// registries are known to work.
List<String> registryHostsForImageRef(String ref) {
  // A reference with no path separator has no registry component at all
  // (`ubuntu:24.04` is a Hub library image; its colon is the TAG's, not a
  // port's). With one, the first segment is a registry only when it looks
  // like a host: a dot, a port, or `localhost`.
  final segments = ref.split('/');
  final firstSegment = segments.first;
  final isExplicitRegistry =
      segments.length > 1 &&
      (firstSegment.contains('.') ||
          firstSegment.contains(':') ||
          firstSegment == 'localhost');
  final registry = isExplicitRegistry
      ? firstSegment.split(':').first
      : 'docker.io';
  return switch (registry) {
    'docker.io' || 'registry-1.docker.io' || 'index.docker.io' => const [
      'docker.io',
      'production.cloudflare.docker.com',
    ],
    'ghcr.io' => const ['ghcr.io', 'pkg-containers.githubusercontent.com'],
    'quay.io' => const [
      'quay.io',
      'cdn01.quay.io',
      'cdn02.quay.io',
      'cdn03.quay.io',
    ],
    'registry.gitlab.com' => const [
      'registry.gitlab.com',
      'cdn.registry.gitlab-static.net',
    ],
    'public.ecr.aws' => const ['public.ecr.aws'],
    'gcr.io' => const ['gcr.io', 'storage.googleapis.com'],
    _ => [registry],
  };
}
