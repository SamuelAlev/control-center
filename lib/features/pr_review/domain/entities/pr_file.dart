/// Pr file status.
enum PrFileStatus {
  /// Added.
  added,
  /// Modified.
  modified,
  /// Removed.
  removed,
  /// Renamed.
  renamed,
  /// Unchanged.
  unchanged,
}

/// PrFileStatusExtension helpers.
extension PrFileStatusExtension on PrFileStatus {
  /// Name.
  String get name {
    switch (this) {
      case PrFileStatus.added:
        return 'added';
      case PrFileStatus.modified:
        return 'modified';
      case PrFileStatus.removed:
        return 'removed';
      case PrFileStatus.renamed:
        return 'renamed';
      case PrFileStatus.unchanged:
        return 'unchanged';
    }
  }

  /// From string.
  static PrFileStatus fromString(String value) {
    switch (value) {
      case 'added':
        return PrFileStatus.added;
      case 'modified':
        return PrFileStatus.modified;
      case 'removed':
        return PrFileStatus.removed;
      case 'renamed':
        return PrFileStatus.renamed;
      case 'unchanged':
        return PrFileStatus.unchanged;
      default:
        return PrFileStatus.modified;
    }
  }
}

/// Viewer-viewed state for a PR file, mirroring GitHub's GraphQL
/// `FileViewedState` enum.
enum PrFileViewedState {
  /// The viewer has not marked the file as viewed.
  unviewed,
  /// The viewer has marked the file as viewed.
  viewed,
  /// The file was marked viewed but has since changed (`DISMISSED`).
  dismissed,
}

/// PrFileViewedStateExtension helpers.
extension PrFileViewedStateExtension on PrFileViewedState {
  /// Whether the file should render as "viewed" in the UI. GitHub treats
  /// `DISMISSED` as no longer viewed (file changed since last viewing).
  bool get isViewed => this == PrFileViewedState.viewed;

  /// Wire name matching GitHub's GraphQL enum values.
  String get wireName {
    switch (this) {
      case PrFileViewedState.unviewed:
        return 'UNVIEWED';
      case PrFileViewedState.viewed:
        return 'VIEWED';
      case PrFileViewedState.dismissed:
        return 'DISMISSED';
    }
  }

  /// Parses the GraphQL enum value.
  static PrFileViewedState fromWireName(String? value) {
    switch (value) {
      case 'VIEWED':
        return PrFileViewedState.viewed;
      case 'DISMISSED':
        return PrFileViewedState.dismissed;
      case 'UNVIEWED':
      default:
        return PrFileViewedState.unviewed;
    }
  }
}

/// Pr file.
class PrFile {
  /// Creates a new [Pr file].
  PrFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.patch,
    this.previousFilename,
    this.viewerViewedState = PrFileViewedState.unviewed,
  }) : assert(filename.isNotEmpty, 'PrFile filename must not be empty');

  /// filename.
  final String filename;
  /// Status.
  final PrFileStatus status;
  /// Additions.
  final int additions;
  /// Deletions.
  final int deletions;
  /// patch.
  final String patch;
  final String? previousFilename;
  /// The viewer's "viewed" state for this file on GitHub.
  final PrFileViewedState viewerViewedState;

  /// Extension.
  String get extension {
    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) {
      return '';
    }

    return filename.substring(dot + 1).toLowerCase();
  }

  /// Returns a copy of this [PrFile] with the given fields replaced.
  PrFile copyWith({PrFileViewedState? viewerViewedState}) {
    return PrFile(
      filename: filename,
      status: status,
      additions: additions,
      deletions: deletions,
      patch: patch,
      previousFilename: previousFilename,
      viewerViewedState: viewerViewedState ?? this.viewerViewedState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrFile &&
          runtimeType == other.runtimeType &&
          filename == other.filename;

  @override
  int get hashCode => filename.hashCode;
}
