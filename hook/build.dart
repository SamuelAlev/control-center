import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:patchwork/patchwork.dart';

/// Build hook: re-materialize every committed third-party patch on each
/// `pub get` / build so the patched dependency copies under
/// `.dart_tool/patchwork/` always match the committed `patches/*.patch`.
///
/// patchwork 0.3.0 (the version this workspace can resolve — patchwork 0.4.0
/// needs `hooks ^2.0.2`, which conflicts with `sqlite_vector`'s `hooks ^1.0.0`)
/// exposes its apply logic on the `Patchwork` API rather than a
/// `package:patchwork/hooks.dart` helper, so call `applyAll()` directly. The
/// `pubspec_overrides.yaml` path override (also committed via patchwork) is what
/// actually reroutes the dependency; this hook just keeps the materialized copy
/// in sync. Best-effort — never fail a build if patches are absent/clean.
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    try {
      final patchwork = await Patchwork.open(
        Directory.fromUri(input.packageRoot),
      );
      await patchwork.applyAll();
    } on PatchworkException {
      // Nothing to apply (no patches committed, or already materialized).
    }
  });
}
