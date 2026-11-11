/// The contract between Control Center Connect and the servers that use it.
///
/// Pure Dart: no `dart:io`, FFI, Flutter, drift or infrastructure packages
/// (pinned by `test/purity_test.dart`), so the same code signs on a server,
/// verifies on Cloud Run and runs inside an embedded Connect.
library;

export 'src/connect_config.dart';
export 'src/connect_env.dart';
export 'src/connect_responses.dart';
export 'src/encoding.dart'
    show
        b64url,
        canonicalJson,
        constantTimeEquals,
        crockfordBase32,
        randomBytes,
        unb64url;
export 'src/github_scope.dart';
export 'src/http_signature.dart';
export 'src/install_identity.dart';
export 'src/lanes.dart';
export 'src/oauth_handoff.dart';
export 'src/oauth_refresh.dart';
export 'src/sign_in_failure.dart';
export 'src/sign_in_lane_mode.dart';
export 'src/sign_in_status.dart';
export 'src/wire.dart';
