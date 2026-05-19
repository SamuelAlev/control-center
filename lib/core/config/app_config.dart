/// Application configuration constants.
library;

/// Application name.
const String appName = 'Control Center';

/// Application version.
const String appVersion = '0.0.1';

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
