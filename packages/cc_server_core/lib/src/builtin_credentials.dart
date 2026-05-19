// Built-in third-party app credentials, injected at RELEASE BUILD TIME.
//
// Empty in the repository ON PURPOSE. This file exists instead of
// `String.fromEnvironment` because `dart build cli` — unlike
// `dart compile exe` — has no `-D` flag, so a compile-time define cannot reach
// the server binary at all. The release scripts rewrite these constants from CI
// secrets, build and restore the file; see
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
//  * The GitHub App's CLIENT ID, used for the device-flow sign-in. A device
//    flow authenticates with the client id alone — GitHub sends no secret in
//    either leg — so the id is public by design, exactly like the one the `gh`
//    CLI ships with. It buys nothing on its own: a code still has to be
//    approved by a human on github.com, and the token that comes back is
//    theirs, minted against their account. An extracted copy mints nothing.
//
// The GitHub App's CLIENT SECRET is deliberately NOT here, even though the
// sign-in would technically work with it: GitHub does not document it as
// public, and it is only ever needed to REFRESH a token. The shipped app
// therefore leaves "Expire user authorization tokens" off, so nothing ever
// needs refreshing and no secret has to travel. An operator running their own
// app with expiry on pastes their secret in Settings, where it stays on their
// server.
//
// A genuinely confidential secret does NOT belong here. Shipping a Slack
// `client_secret` (or any signing key) to every install would let whoever
// extracted it act as Control Center — which is precisely why the Slack bridge
// asks each workspace for its own app instead of sharing one. The GitHub App's
// PRIVATE KEY is the same category and is deliberately absent: it is what mints
// installation tokens, so an extracted copy would read every repository the app
// is installed on. The server binary is the distributed artifact, so "in the
// release build" and "on every user's disk" are the same place. Only the client
// id ships.

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
