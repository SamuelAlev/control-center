import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_domain/core/domain/ports/editor_launcher_port.dart';

/// Tests the OS launch process. Injected so launching can be exercised in
/// unit tests without spawning real processes.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> args, {
  String? workingDirectory,
});

/// Probes whether a filesystem path exists (file, directory, or — on macOS —
/// an `.app` bundle, which is a directory). Injected for testing.
typedef PathProbe = bool Function(String path);

/// A concrete, runnable way to open a directory in an editor.
class _Resolved {
  const _Resolved({
    required this.id,
    required this.displayName,
    required this.executable,
    required this.argsFor,
    this.passDirAsCwd = false,
  });

  final String id;
  final String displayName;

  /// Absolute path to the launch binary, or a baseline system command
  /// (`/usr/bin/open`) that always resolves.
  final String executable;

  /// Builds the argv (excluding [executable]) for a target directory.
  final List<String> Function(String dir) argsFor;

  /// When true the directory is passed as the process working directory rather
  /// than as an argument (used for terminals that open in their CWD).
  final bool passDirAsCwd;
}

/// A platform catalog entry that knows how to (best-effort) resolve itself.
class _CatalogEntry {
  const _CatalogEntry({
    required this.id,
    required this.displayName,
    required this.resolve,
  });

  final String id;
  final String displayName;

  /// Returns a [_Resolved] launcher when the editor is installed, else `null`.
  final _Resolved? Function() resolve;
}

/// Cross-platform [EditorLauncherPort] backed by `dart:io`.
///
/// Detection never spawns subprocesses — it only checks well-known absolute
/// install locations (and `PATH` directories, when present) for existence — so
/// it is fast and works under the stripped `PATH` of a packaged desktop app.
/// Launching uses the platform's native opener (`open` on macOS, `explorer` on
/// Windows, `xdg-open` on Linux) or the editor's resolved binary directly.
class NativeEditorLauncher implements EditorLauncherPort {
  /// Creates a launcher. The named parameters are test seams; production code
  /// constructs it with no arguments.
  NativeEditorLauncher({
    String? operatingSystem,
    Map<String, String>? environment,
    PathProbe? pathExists,
    ProcessRunner? runProcess,
  })  : _os = operatingSystem ?? Platform.operatingSystem,
        _env = environment ?? Platform.environment,
        _exists = pathExists ?? _defaultExists,
        _run = runProcess ?? _defaultRun;

  final String _os;
  final Map<String, String> _env;
  final PathProbe _exists;
  final ProcessRunner _run;

  List<_CatalogEntry>? _catalogCache;
  Map<String, _Resolved>? _resolvedCache;

  static const String _macOpen = '/usr/bin/open';

  static bool _defaultExists(String path) =>
      path.isNotEmpty &&
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  static Future<ProcessResult> _defaultRun(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) =>
      Process.run(executable, args, workingDirectory: workingDirectory);

  @override
  Future<List<IdeEditor>> detectEditors() async {
    final resolved = _resolveAll();
    return [
      for (final entry in _catalog())
        IdeEditor(
          id: entry.id,
          displayName: entry.displayName,
          installed: resolved.containsKey(entry.id),
        ),
    ];
  }

  @override
  Future<void> openDirectory({
    required String editorId,
    required String directoryPath,
  }) async {
    final dir = directoryPath.trim();
    if (dir.isEmpty) {
      throw const EditorLaunchException('No local directory to open.');
    }

    final resolved = _resolveAll()[editorId];
    if (resolved == null) {
      final known = _catalog().any((e) => e.id == editorId);
      throw EditorLaunchException(
        known
            ? 'This editor is not installed on this machine.'
            : 'Unknown editor "$editorId".',
      );
    }

    try {
      final result = await _run(
        resolved.executable,
        resolved.argsFor(dir),
        workingDirectory: resolved.passDirAsCwd ? dir : null,
      );
      if (result.exitCode != 0) {
        final err = result.stderr?.toString().trim() ?? '';
        throw EditorLaunchException(
          'Failed to open ${resolved.displayName}'
          '${err.isNotEmpty ? ': $err' : ' (exit code ${result.exitCode}).'}',
        );
      }
    } on ProcessException catch (e) {
      throw EditorLaunchException(
        'Could not launch ${resolved.displayName}: ${e.message}',
      );
    }
  }

  // ── Catalog & resolution ──────────────────────────────────────────────

  List<_CatalogEntry> _catalog() => _catalogCache ??= _buildCatalog();

  Map<String, _Resolved> _resolveAll() {
    if (_resolvedCache != null) {
      return _resolvedCache!;
    }
    final map = <String, _Resolved>{};
    for (final entry in _catalog()) {
      final resolved = entry.resolve();
      if (resolved != null) {
        map[entry.id] = resolved;
      }
    }
    return _resolvedCache = map;
  }

  List<_CatalogEntry> _buildCatalog() {
    switch (_os) {
      case 'macos':
        return _macCatalog();
      case 'windows':
        return _windowsCatalog();
      case 'linux':
        return _linuxCatalog();
      default:
        return const [];
    }
  }

  String? get _home => _env['HOME'];

  String? _firstExisting(Iterable<String> paths) {
    for (final p in paths) {
      if (_exists(p)) {
        return p;
      }
    }
    return null;
  }

  // ── macOS ─────────────────────────────────────────────────────────────

  List<_CatalogEntry> _macCatalog() {
    final home = _home;
    final roots = <String>[
      '/Applications',
      if (home != null && home.isNotEmpty) '$home/Applications',
      '/System/Applications',
      '/System/Applications/Utilities',
      '/Applications/Utilities',
    ];

    String? appPath(List<String> bundleNames) => _firstExisting([
          for (final name in bundleNames)
            for (final root in roots) '$root/$name',
        ]);

    _CatalogEntry app(String id, String name, List<String> bundles) {
      return _CatalogEntry(
        id: id,
        displayName: name,
        resolve: () {
          final path = appPath(bundles);
          if (path == null) {
            return null;
          }
          return _Resolved(
            id: id,
            displayName: name,
            executable: _macOpen,
            argsFor: (dir) => ['-a', path, dir],
          );
        },
      );
    }

    return [
      app('vscode', 'VS Code', ['Visual Studio Code.app']),
      app('cursor', 'Cursor', ['Cursor.app']),
      app('zed', 'Zed', ['Zed.app']),
      app('antigravity', 'Antigravity', ['Antigravity.app']),
      app('windsurf', 'Windsurf', ['Windsurf.app']),
      app('intellij', 'IntelliJ IDEA', [
        'IntelliJ IDEA.app',
        'IntelliJ IDEA CE.app',
        'IntelliJ IDEA Ultimate.app',
      ]),
      app('webstorm', 'WebStorm', ['WebStorm.app']),
      app('pycharm', 'PyCharm', [
        'PyCharm.app',
        'PyCharm CE.app',
        'PyCharm Community Edition.app',
        'PyCharm Professional Edition.app',
      ]),
      app('sublime', 'Sublime Text', ['Sublime Text.app']),
      app('warp', 'Warp', ['Warp.app']),
    ];
  }

  // ── Windows ───────────────────────────────────────────────────────────

  List<_CatalogEntry> _windowsCatalog() {
    final localAppData = _env['LOCALAPPDATA'];
    final programFiles = _env['ProgramFiles'];
    final programFilesX86 = _env['ProgramFiles(x86)'];
    final programW6432 = _env['ProgramW6432'];

    List<String> join(List<String?> bases, String rel) => [
          for (final base in bases)
            if (base != null && base.isNotEmpty) '$base\\$rel',
        ];

    _CatalogEntry exe(String id, String name, List<String> candidates) {
      return _CatalogEntry(
        id: id,
        displayName: name,
        resolve: () {
          final path = _firstExisting(candidates);
          if (path == null) {
            return null;
          }
          return _Resolved(
            id: id,
            displayName: name,
            executable: path,
            argsFor: (dir) => [dir],
          );
        },
      );
    }

    return [
      exe('vscode', 'VS Code', [
        ...join([localAppData], r'Programs\Microsoft VS Code\Code.exe'),
        ...join(
          [programFiles, programW6432, programFilesX86],
          r'Microsoft VS Code\Code.exe',
        ),
      ]),
      exe('cursor', 'Cursor', join([localAppData], r'Programs\cursor\Cursor.exe')),
      exe('zed', 'Zed', [
        ...join([localAppData], r'Zed\Zed.exe'),
        ...join([localAppData], r'Programs\Zed\Zed.exe'),
      ]),
      exe(
        'antigravity',
        'Antigravity',
        join([localAppData], r'Programs\Antigravity\Antigravity.exe'),
      ),
      exe(
        'windsurf',
        'Windsurf',
        join([localAppData], r'Programs\Windsurf\Windsurf.exe'),
      ),
      exe('intellij', 'IntelliJ IDEA', [
        ...join([localAppData], r'Programs\IntelliJ IDEA Ultimate\bin\idea64.exe'),
        ...join(
          [localAppData],
          r'Programs\IntelliJ IDEA Community Edition\bin\idea64.exe',
        ),
        ...join(
          [programFiles, programW6432],
          r'JetBrains\IntelliJ IDEA\bin\idea64.exe',
        ),
      ]),
      exe('webstorm', 'WebStorm', [
        ...join([localAppData], r'Programs\WebStorm\bin\webstorm64.exe'),
        ...join(
          [programFiles, programW6432],
          r'JetBrains\WebStorm\bin\webstorm64.exe',
        ),
      ]),
      exe('pycharm', 'PyCharm', [
        ...join(
          [localAppData],
          r'Programs\PyCharm Community Edition\bin\pycharm64.exe',
        ),
        ...join(
          [programFiles, programW6432],
          r'JetBrains\PyCharm Community Edition\bin\pycharm64.exe',
        ),
      ]),
      exe('sublime', 'Sublime Text', [
        ...join([programFiles, programW6432], r'Sublime Text\sublime_text.exe'),
        ...join([programFiles, programW6432], r'Sublime Text 3\sublime_text.exe'),
      ]),
      exe('warp', 'Warp', join([localAppData], r'Programs\Warp\Warp.exe')),
    ];
  }

  // ── Linux ─────────────────────────────────────────────────────────────

  List<_CatalogEntry> _linuxCatalog() {
    final binDirs = _linuxBinDirs();
    final flatpakDirs = _flatpakExportDirs();

    String? bin(List<String> names) {
      for (final dir in binDirs) {
        for (final name in names) {
          final candidate = '$dir/$name';
          if (_exists(candidate)) {
            return candidate;
          }
        }
      }
      return null;
    }

    String? flatpak(String appId) =>
        _firstExisting([for (final dir in flatpakDirs) '$dir/$appId']);

    _CatalogEntry editor(
      String id,
      String name,
      List<String> bins, {
      String? flatpakId,
      List<String> extraPaths = const [],
    }) {
      return _CatalogEntry(
        id: id,
        displayName: name,
        resolve: () {
          final path = bin(bins) ??
              _firstExisting(extraPaths) ??
              (flatpakId != null ? flatpak(flatpakId) : null);
          if (path == null) {
            return null;
          }
          return _Resolved(
            id: id,
            displayName: name,
            executable: path,
            argsFor: (dir) => [dir],
          );
        },
      );
    }

    return [
      editor('vscode', 'VS Code', ['code', 'code-insiders', 'codium', 'vscodium'],
          flatpakId: 'com.visualstudio.code'),
      editor('cursor', 'Cursor', ['cursor']),
      editor('zed', 'Zed', ['zed', 'zeditor'], flatpakId: 'dev.zed.Zed'),
      editor('antigravity', 'Antigravity', ['antigravity']),
      editor('windsurf', 'Windsurf', ['windsurf']),
      editor(
        'intellij',
        'IntelliJ IDEA',
        ['idea', 'intellij-idea-community', 'intellij-idea-ultimate'],
        extraPaths: ['/snap/intellij-idea-community/current/bin/idea.sh'],
      ),
      editor('webstorm', 'WebStorm', ['webstorm']),
      editor('pycharm', 'PyCharm',
          ['pycharm', 'pycharm-community', 'pycharm-professional', 'charm']),
      editor('sublime', 'Sublime Text', ['subl', 'sublime_text']),
      _CatalogEntry(
        id: 'warp',
        displayName: 'Warp',
        resolve: () {
          final path = bin(['warp-terminal', 'warp']);
          if (path == null) {
            return null;
          }
          return _Resolved(
            id: 'warp',
            displayName: 'Warp',
            executable: path,
            argsFor: (_) => const [],
            passDirAsCwd: true,
          );
        },
      ),
    ];
  }

  List<String> _linuxBinDirs() {
    final dirs = <String>[];
    final path = _env['PATH'];
    if (path != null) {
      dirs.addAll(path.split(':').where((e) => e.isNotEmpty));
    }
    dirs.addAll(const [
      '/usr/bin',
      '/usr/local/bin',
      '/bin',
      '/snap/bin',
      '/var/lib/flatpak/exports/bin',
      '/nix/var/nix/profiles/default/bin',
      '/run/current-system/sw/bin',
    ]);
    final home = _home;
    if (home != null && home.isNotEmpty) {
      dirs.addAll([
        '$home/.local/bin',
        '$home/bin',
        '$home/.nix-profile/bin',
        '$home/.local/share/flatpak/exports/bin',
      ]);
    }
    final seen = <String>{};
    return [
      for (final dir in dirs)
        if (seen.add(dir)) dir,
    ];
  }

  List<String> _flatpakExportDirs() {
    final home = _home;
    return [
      '/var/lib/flatpak/exports/bin',
      if (home != null && home.isNotEmpty)
        '$home/.local/share/flatpak/exports/bin',
    ];
  }
}
