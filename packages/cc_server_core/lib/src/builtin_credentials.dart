// Built-in third-party app credentials, injected at RELEASE BUILD TIME.
//
// Empty in the repository ON PURPOSE. This file exists instead of
// `String.fromEnvironment` because `dart build cli` — unlike
// `dart compile exe` — has no `-D` flag, so a compile-time define cannot reach
// the server binary at all. The release scripts rewrite these constants from CI
// secrets, build, and restore the file; see
// `scripts/release/builtin_credentials.sh`. A source build from the public
// repository therefore ships no credentials and every affected surface falls
// back to bring-your-own, which is also what a contributor gets.
//
// What may live here is narrow: credentials the vendor documents as
// NON-CONFIDENTIAL and expects to be embedded in a distributed client.
//
//  * Google's device-code ("TV and limited input devices") client. Google
//    treats installed-app client secrets as non-confidential; extracting ours
//    buys quota abuse and consent-screen impersonation, never access to any
//    user's calendar, because every refresh token stays in that user's own
//    server.
//  * Klipy's app key, which rides in the URL path of every request and is
//    embedded in Klipy's own demo clients.
//
// A genuinely confidential secret does NOT belong here. Shipping a Slack
// `client_secret` (or any signing key) to every install would let whoever
// extracted it act as Control Center — which is precisely why the Slack bridge
// asks each workspace for its own app instead of sharing one.

/// The built-in Google OAuth **device-code** client id, or empty when this build
/// carries none (a dev build, or a build from the public repository).
const String builtinGoogleClientId = '';

/// The client secret paired with [builtinGoogleClientId]. Empty when this build
/// carries no built-in Google client.
const String builtinGoogleClientSecret = '';

/// The built-in Klipy GIF app key, or empty when this build carries none. Klipy
/// keys are not secrets: the key is part of every request path.
const String builtinKlipyAppKey = '';
