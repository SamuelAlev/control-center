/// A code editor / IDE the app can open a local directory in.
///
/// The full catalog for the current platform is reported regardless of
/// install state — [installed] flags whether the editor was actually found on
/// this machine. Not-installed entries are still returned so the UI can list
/// them in a muted "not installed" section, the way native "open in…" menus do.
class IdeEditor {
  /// Creates an [IdeEditor].
  const IdeEditor({
    required this.id,
    required this.displayName,
    required this.installed,
  }) : assert(id != '', 'IdeEditor id must not be empty');

  /// Stable, platform-independent identifier (e.g. `vscode`, `cursor`, `files`).
  ///
  /// Keys the brand logo asset, the persisted preferred-editor setting, and the
  /// launch request, so it must stay constant once shipped.
  final String id;

  /// Human-facing name shown in the menu (e.g. `VS Code`, `Finder`).
  ///
  /// These are product / OS names, so they are intentionally not localized.
  final String displayName;

  /// Whether this editor was detected on the current machine.
  final bool installed;

  /// Returns a copy with the given fields replaced.
  IdeEditor copyWith({String? id, String? displayName, bool? installed}) {
    return IdeEditor(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      installed: installed ?? this.installed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeEditor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          installed == other.installed;

  @override
  int get hashCode => Object.hash(id, displayName, installed);

  @override
  String toString() =>
      'IdeEditor(id: $id, displayName: $displayName, installed: $installed)';
}
