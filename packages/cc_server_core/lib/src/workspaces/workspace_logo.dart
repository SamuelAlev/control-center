/// Where a workspace's logo may live, so the logo routes never serve a file
/// a caller named.
library;

import 'package:cc_server_core/src/fs_confinement.dart';
import 'package:path/path.dart' as p;

/// The extensions `fs.persistLogoBytes` accepts: the logo picker's image
/// types, or none.
const workspaceLogoExtensions = {
  '',
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.bmp',
};

/// Whether [path] is the logo file the `fs.persistLogo*` ops write:
/// `logo` or `logo.<image extension>` directly in [workspaceDir], with every
/// symlink resolved.
bool isWorkspaceLogoPath(String workspaceDir, String path) {
  final realDir = confinedRealPath(workspaceDir, workspaceDir);
  final real = confinedRealPath(workspaceDir, path);
  if (realDir == null || real == null) {
    return false;
  }
  return p.equals(p.dirname(real), realDir) &&
      p.basenameWithoutExtension(real) == 'logo' &&
      workspaceLogoExtensions.contains(p.extension(real));
}
