/// Application configuration constants.
library;

import 'package:cc_domain/cc_domain.dart';

/// Application name.
const String appName = 'Control Center';

/// Application version — the CI-stamped build identity (see
/// `packages/cc_domain/lib/src/build_info.dart`), not a hand-maintained
/// constant: it must agree with what the server reports on /healthz.
const String appVersion = BuildInfo.buildVersion;

/// Default base path for workspace directories.
///
/// Note: The tilde (~) is a shell expansion. For app data, resolve at
/// runtime via `controlCenterRootDir()` in `core/storage/control_center_paths.dart`
/// (which uses `path_provider.getApplicationSupportDirectory()`).
const String defaultWorkspaceBasePath = '~/control-center-workspaces';

/// Starting port for the first workspace.
const int defaultPortStart = 3000;

/// Name of the Claude binary.
const String claudeBinary = 'claude';

/// Name of the Pi binary.
const String piBinary = 'pi';
