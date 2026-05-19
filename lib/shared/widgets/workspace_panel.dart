import 'package:flutter/material.dart';

/// A panel displayed in a workspace detail tab.
///
/// Features register panels via `workspacePanelRegistryProvider` so that
/// `WorkspaceDetailScreen` can compose them without importing feature-specific
/// widgets directly.
class WorkspacePanel {
  /// Creates a workspace panel.
  const WorkspacePanel({
    required this.label,
    required this.icon,
    required this.builder,
  });

  /// Tab label.
  final String label;

  /// Tab icon.
  final IconData icon;

  /// Builds the panel content for the given `workspaceId`.
  final Widget Function(String workspaceId) builder;
}
