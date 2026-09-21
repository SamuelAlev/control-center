// Built-in third-party credentials, rewritten at release build by
// `scripts/release/builtin_credentials.sh` (`dart build cli` has no `-D`).
// Empty in-repo on purpose. Only vendor-documented non-confidential values:
// Google device-code client, Klipy app key, GitHub App client id (device flow
// needs no secret). Never bake GitHub private key, client secret, or any signing key —
// the binary is on every user's disk.

/// The built-in Google OAuth **device-code** client id, or empty when this build
/// carries none (a dev build, or a build from the public repository).
const String builtinGoogleClientId = '';

/// The client secret paired with [builtinGoogleClientId]. Empty when this build
/// carries no built-in Google client.
const String builtinGoogleClientSecret = '';

/// The built-in Klipy GIF app key, or empty when this build carries none. Klipy
/// keys are not secrets: the key is part of every request path.
const String builtinKlipyAppKey = '';

/// The built-in GitHub App **client id** for the device-flow sign-in, or empty
/// when this build carries none.
///
/// What this buys: an official build offers "Sign in with GitHub" out of the
/// box, with nothing to register. What it does not buy: the server's own app
/// identity, which needs the private key that never ships — so background work
/// still falls back to the signed-in owner's credential unless an operator
/// configures their own app. A user token from this flow reaches only what the
/// app is INSTALLED on, so a person still installs it where they want it.
const String builtinGitHubClientId = '';
