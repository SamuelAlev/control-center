part of 'dispatch_session.dart';

/// Where a dispatch's directories are: the per-agent overlay's shared
/// worktrees and the space's attachments, derived from the directory layout
/// the provisioner creates — never from a path or symlink the agent could
/// change.
class _OverlayLayout {
  const _OverlayLayout({
    required this.isOverlay,
    this.reposDir,
    this.attachmentsDir,
  });

  /// Whether the cwd is a per-agent overlay (a config dir distinct from it):
  /// `<convRoot>/agents/<slug>`, with the space's shared directories two
  /// levels up.
  final bool isOverlay;

  /// `<convRoot>/repos`, when the overlay has one.
  final String? reposDir;

  /// `<spaceRoot>/attachments`, when anything was attached to the space —
  /// overlay or not. A space with no repository runs in the agent's own
  /// directory, and its prompt still names files in here.
  final String? attachmentsDir;

  static bool _overlay(String cwd, String? configDir) =>
      configDir != null && configDir.isNotEmpty && !p.equals(configDir, cwd);

  static String _repos(String cwd) =>
      p.join(p.dirname(p.dirname(cwd)), 'repos');

  static String _attachments(String cwd) =>
      p.join(p.dirname(p.dirname(cwd)), SpacePromptAttachments.dirName);

  /// `<wsRoot>/spaces/<spaceId>/attachments` for a run in the agent's own
  /// directory (`<wsRoot>/agents/<slug>`, the same root the skills mount is
  /// derived from). Null when [configDir] is not laid out that way or
  /// [spaceId] is not a single path segment: the id is the server's, but it
  /// is joined onto a path all the same.
  static String? _fallbackAttachments(String? configDir, String? spaceId) {
    if (configDir == null || configDir.isEmpty) {
      return null;
    }
    if (!_isPathSegment(spaceId)) {
      return null;
    }
    final agentsDir = p.dirname(configDir);
    if (p.basename(agentsDir) != 'agents') {
      return null;
    }
    return p.join(
      p.dirname(agentsDir),
      'spaces',
      spaceId,
      SpacePromptAttachments.dirName,
    );
  }

  static bool _isPathSegment(String? id) =>
      id != null &&
      id.isNotEmpty &&
      id != '.' &&
      id != '..' &&
      !id.contains('/') &&
      !id.contains(r'\');

  static String? _existing(String? dir) =>
      dir != null && Directory(dir).existsSync() ? dir : null;

  /// [dir], created when its parent (the space's directory) exists.
  ///
  /// The sandbox profile is fixed when the run starts and grants only
  /// directories that exist then, while a space's first attachment can be
  /// written later — a message steered into the live run. Without the
  /// directory up front, that file lands in a tree the run cannot read.
  /// A missing space directory is never conjured; falls back to [_existing]
  /// when the directory cannot be created.
  static String? _ensured(String? dir) {
    if (dir == null || !Directory(p.dirname(dir)).existsSync()) {
      return null;
    }
    try {
      Directory(dir).createSync();
    } on FileSystemException {
      return _existing(dir);
    }
    return dir;
  }

  static _OverlayLayout resolve({
    required String cwd,
    required String? configDir,
    required String? spaceId,
  }) {
    if (!_overlay(cwd, configDir)) {
      return _OverlayLayout(
        isOverlay: false,
        attachmentsDir: _ensured(_fallbackAttachments(configDir, spaceId)),
      );
    }
    final attachments = _attachments(cwd);
    return _OverlayLayout(
      isOverlay: true,
      reposDir: _existing(_repos(cwd)),
      // Created only for a run in a space: an overlay outside one has no
      // attachments to receive.
      attachmentsDir: _isPathSegment(spaceId)
          ? _ensured(attachments)
          : _existing(attachments),
    );
  }
}
