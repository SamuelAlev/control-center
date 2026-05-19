import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `Cc*` component cc_ui exports must appear in at least one Widgetbook
/// use case.
///
/// The gallery calls itself "the living design-system reference", but nothing
/// checked that claim: five exported components (`CcGauge`, `CcSlider`,
/// `CcLinkText`, `CcFadeEdges`, `CcImageFade`) had drifted out of it entirely —
/// roughly 10% of the surface, silently uncatalogued. A reference that is
/// only mostly complete is worse than one you know is partial, because the
/// absence reads as "this component does not exist".
///
/// Source-level (grep), like the RPC-op and action-class ratchets: no need to
/// build a Widgetbook to know whether a `@UseCase` names a type.
void main() {
  test('every exported cc_ui component has a Widgetbook use case', () {
    final root = _repoRoot();
    final barrel = File('${root.path}/packages/cc_ui/lib/cc_ui.dart');
    expect(
      barrel.existsSync(),
      isTrue,
      reason: 'cc_ui barrel not found — fix this test\'s path resolution',
    );

    // Component classes, taken from the files the barrel exports. Only
    // `components/` counts: tokens, theme and typography are not widgets a
    // gallery entry can render on their own.
    final exported = <String>{};
    final classPattern = RegExp(
      r'^class (Cc[A-Za-z0-9]+) extends',
      multiLine: true,
    );
    for (final line in barrel.readAsLinesSync()) {
      final match = RegExp(
        r"export 'package:cc_ui/(src/components/[^']+)';",
      ).firstMatch(line.trim());
      if (match == null) {
        continue;
      }
      final file = File('${root.path}/packages/cc_ui/lib/${match.group(1)}');
      if (!file.existsSync()) {
        continue;
      }
      for (final m in classPattern.allMatches(file.readAsStringSync())) {
        exported.add(m.group(1)!);
      }
    }
    expect(exported, isNotEmpty, reason: 'no exported components found');

    // A component counts as catalogued when the gallery MENTIONS it — either
    // as a `@UseCase(type:)` of its own or rendered inside another
    // component's entry, which is the honest home for a sub-component
    // (`CcSidebarItem` lives inside the sidebar's use case; a standalone
    // entry for it would be a worse reference, not a better one).
    final useCaseDir = Directory('${root.path}/apps/cc_gallery/lib/use_cases');
    final catalogued = <String>{};
    final mentionPattern = RegExp(r'\b(Cc[A-Za-z0-9]+)\b');
    for (final entity in useCaseDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final m in mentionPattern.allMatches(entity.readAsStringSync())) {
        catalogued.add(m.group(1)!);
      }
    }

    // Structural plumbing rather than a thing to LOOK at: a gallery entry for
    // these would be an empty frame.
    const notShowable = <String>{
      'CcToastScope', // an inherited scope; toasts are shown via CcToast
      'CcSelectionScope', // marker for "an ancestor owns selection"
      'CcSidebarScope', // inherited state for the sidebar's children
      'CcResizableController', // a controller, not a widget
      'CcScrollBehavior', // ambient scroll configuration
    };

    final missing = exported.difference(catalogued).difference(notShowable)
      ..removeWhere((name) => name.endsWith('State'));
    expect(
      missing.toList()..sort(),
      isEmpty,
      reason:
          'These exported cc_ui components have no @UseCase in the gallery. '
          'Add one to apps/cc_gallery/lib/use_cases/, or add it to '
          '`notShowable` above with a reason.',
    );
  });
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/packages/cc_ui/lib/cc_ui.dart').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate the repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
