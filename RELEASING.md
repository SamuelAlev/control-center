# Releasing Control Center

[`.github/workflows/release.yml`](.github/workflows/release.yml) builds macOS (Apple Silicon), Windows (x64) and Linux (x86_64) in parallel, then creates a **draft** GitHub Release. Review it before publishing; draft assets are invisible to the updater feeds.

## Cut a release

1. Optionally update `version:` in `pubspec.yaml` (the build overrides the in-app version from the tag).
2. Run `git tag v1.2.3 && git push origin v1.2.3`, or use **Actions → Release → Run workflow** with a version.
3. Check all build jobs, artifacts, `SHA256SUMS.txt`, provenance attestations and release notes in the draft. Publish only after review.

## What gets built

| Platform | Desktop artifact | Standalone server |
| --- | --- | --- |
| macOS arm64 | `Control-Center-<v>-arm64.dmg` (Developer ID signed, notarized, stapled) | `cc_server-<v>-macos-arm64.tar.gz` (signed, notarized) |
| Windows x64 | `Control-Center-<v>-x64-setup.exe` (per-user installer); `Control-Center-<v>-windows-x64.zip` (portable) | `cc_server-<v>-windows-x64.zip` (unsigned) |
| Linux x86_64 | `Control-Center-<v>-x86_64.AppImage` (with its `.zsync`) and `.tar.gz` | `cc_server-<v>-linux-x64.tar.gz` |

`appcast.xml` and `appcast-windows.xml` are signed update feeds. The `containers` job publishes GHCR `cc-server`, `cc-webapp` and `cc-remote` images with SLSA attestations. [`scripts/lib/artifact_names.sh`](scripts/lib/artifact_names.sh) defines the exact artifact set; `make_release.sh` refuses to draft a partial set.

**First Windows release:** `build-windows` is enabled but has not produced a shipped artifact. Validate the installer, portable zip and standalone server zip manually before publishing. `scripts/release/windows_natives.sh` uses MSVC: `rift` is absent, so Windows uses `git worktree` as its backend. `cc_inference` links a static-CRT sherpa archive and builds with `RUSTFLAGS=-Ctarget-feature=+crt-static`. Windows is unsigned unless `WINDOWS_CERT` and `WINDOWS_CERT_PWD` are set.

**Native builds are mandatory.** All required FFI binaries are built/staged for both the desktop and server; `scripts/release/verify_natives.sh` and `cc_server_package.sh` reject incomplete artifacts, and `cc_server` refuses to boot without required libraries. macOS/Linux use copy-on-write `rift`; provision fails with `cow_unavailable` where CoW is unavailable, rather than writing to the source checkout via a fallback. Windows uses plain `git worktree`. `cc_inference` statically links one ONNX Runtime, avoiding a separately staged `onnxruntime.dll`; its sherpa-onnx archive is checksum-pinned under `scripts/lib/native_pins.env` and downloaded by `scripts/natives/build_inference.sh`, not Cargo. All external native source hosts must be allowed through the Linux build's blocking `harden-runner` policy (`extra-endpoints` on `.github/actions/setup-flutter/action.yml`). Only on-device models are fetched at runtime; semantic search remains FTS-only until its embedding model is available.

**Linux runs on the host's glibc.** The AppImage and tarball are built on `ubuntu-22.04`, the oldest supported Ubuntu LTS, because [AppImageHub](https://appimage.github.io) only lists an AppImage that starts there with stock packages (its test runs it offline under Xvfb on that runner). `scripts/lib/linux_desktop.sh` records that floor (glibc 2.35, `GLIBCXX_3.4.30`) and what the host provides: GTK 3 and its closure, libcurl (a bundled copy would carry Debian's CA path) and libpulse. `bundle_linux_deps.sh` copies only the libraries listed there (today libnotify and libsecret), with their Debian copyright notices, and refuses anything else a new plugin links until it is reviewed. `lint_appdir.sh` fails the release on any ELF past the floor or with an unresolvable library. `natives.yml` and the `e2e` job run on the same runner, and the natives cache key carries the runner image, so a release never restores natives linked against a newer glibc. Media playback uses the system's libmpv, which a stock desktop lacks, so without it the desktop starts with playback hidden rather than failing to boot.

## First-run trust

macOS DMGs are signed, notarized and stapled. Windows installers are unsigned unless the optional Authenticode secrets are supplied; SmartScreen users may need **More info → Run anyway**. For Linux:

```bash
chmod +x Control-Center-<v>-x86_64.AppImage
./Control-Center-<v>-x86_64.AppImage
```

## Verify a download

Check `SHA256SUMS.txt`. Each binary also has keyless provenance tied to this repository, commit and workflow run:

```bash
gh attestation verify Control-Center-<v>-arm64.dmg --repo SamuelAlev/control-center
```

Use `--repo`, not `--owner`, which accepts attestations from other repositories under the same account.

## In-app updates

Updates ask for confirmation and release notes; checks run after startup, every 24 hours and on demand. A prompt is deferred during meeting recording. Draft feeds cannot update clients.

- **macOS:** Sparkle 2 replaces the entire `.app` (including embedded `cc_server` and natives). `appcast.xml` DMG enclosures use `sparkle:edSignature`. Stable feed items **must be untagged**: the bundled plugin does not opt in to `<sparkle:channel>stable</sparkle:channel>`.
- **Windows:** WinSparkle launches the Inno `-x64-setup.exe` silently (`/SILENT /SP-`), not the portable zip. `appcast-windows.xml` uses `sparkle:dsaSignature` for WinSparkle 0.8.x. Its embedded server updates with the app.
- **Linux:** check opens the latest release page; no automatic install. The AppImage embeds `gh-releases-zsync` update information, so AppImageUpdate and appimaged update it in place from the latest release's `.zsync`, downloading only the changed blocks.
- **Standalone `cc_server`:** never auto-updates. `cc_server update` checks, downloads, SHA256/SLSA-verifies and stages; `--apply` swaps the tree with a one-deep `.bak`. It rejects downgrades without `--allow-downgrade`, refuses when `CC_EMBEDDED`, and on Windows parks the running executable as `.old` before overlaying the verified tree. Docker users pull a new image.
- **Hosted web and `cc_remote`:** `/deploy.json` prompts a consent-driven refresh. Do not rename it `version.json`: `fvm flutter build web` generates that file itself.

### Testing the updater locally (no release needed)

For controller/menu/About behavior, run the app with `--dart-define=CC_FAKE_UPDATE=available` (also `none` or `error`). This does not exercise Sparkle's own prompt. For the real macOS download/verify/install flow:

```bash
fvm dart run tool/fake_update_server.dart
# in another terminal:
fvm flutter run -d macos --dart-define=CC_APPCAST_URL=http://127.0.0.1:8642/appcast.xml
```

The harness creates a signed fake appcast and patches a throwaway public key into the **built** bundle only. Its private key lives in `.dart_tool/sparkle-dev/`; the committed plist is untouched. The installed app reports version `999.0.0` so the loop ends. For web, edit `gitSha` in **`build/web/deploy.json`** and serve that build directory; editing committed `web/deploy.json` cannot affect the served build.

### One-time setup (updater signing keys)

Both signing secrets are already configured. Repeat on forks or rotation; generate both keypairs on macOS. Back up both private keys: installed clients reject future updates signed by a different key. The Ed25519 seed can be re-exported from the keychain; a GitHub secret cannot be read back, so keep the DSA private key separately.

```bash
macos/Pods/Sparkle/bin/generate_keys            # prints SUPublicEDKey; stores seed in login keychain
macos/Pods/Sparkle/bin/generate_keys -x key.txt # exports private seed
gh secret set SPARKLE_ED25519_KEY < key.txt
```

Put the printed public key in `macos/Runner/Info.plist` (`SUPublicEDKey`). `gen_appcast.sh` accepts Sparkle's 32/64/96-byte export forms; do not hand-trim. The second keypair is for WinSparkle:

```bash
openssl dsaparam 4096 > dsaparam.pem
openssl gendsa -out dsa_priv.pem dsaparam.pem && rm dsaparam.pem
openssl dsa -in dsa_priv.pem -pubout -out dsa_pub.pem
gh secret set SPARKLE_DSA_PRIVATE_KEY < dsa_priv.pem
```

Commit **only** public `dsa_pub.pem` at the repo root (`windows/runner/Runner.rc` embeds it). Never commit `dsa_priv.pem`. `gen_appcast.sh` compares both secret-derived public keys against the committed keys and fails the release if either secret is missing or mismatched. After changing it, run `fvm flutter test --concurrency=1 test/tooling/appcast_generation_test.dart` (requires Python `cryptography`; otherwise that test skips).

### If the in-app updater says there is no update

Inspect the **published** `releases/latest/download/appcast.xml`, not just the version: macOS stable items must be untagged. A prior tagged feed was filtered by Sparkle; fix only the feed asset on the published release or publish a corrected release. If an item is present but verification fails, check `SUPublicEDKey` against `SPARKLE_ED25519_KEY` and root `dsa_pub.pem` against `SPARKLE_DSA_PRIVATE_KEY`; follow the setup above. Signing/key mismatch fails closed.

## Hardening built into the pipeline

Workflow default `permissions: {}`; each job grants only what it needs. Third-party actions are SHA-pinned, `gh` creates the release, and assets carry SHA256 checksums and OIDC SLSA build provenance. `step-security/harden-runner` must run **before checkout**, inline in each job: `egress-policy: block` for Linux `prepare`, `build-linux`, `release`; `audit` for macOS, Windows and containers (the latter has non-enumerable Docker Hub/GHCR CDN hosts). Do not move harden-runner into `setup-flutter`: a local action requires checkout first. `test/tooling/workflow_setup_test.dart` protects that ordering.

[`renovate.json`](renovate.json) is the sole dependency update tool. Its built-in managers cover actions, pub, Cargo, `/docs` npm and Docker; custom managers cover pinned native sources/archives in `scripts/lib/native_pins.env`, code-server, WebDriverAgent, vendored fonts/flutter_pty, the `.fvmrc` Flutter commit, smolvm images and signaling-server SDK. Keep native git ref `# vX.Y.Z` comments for tag comparisons. Group tree-sitter runtime with grammars and sherpa-onnx with `sherpa-onnx-sys`; preserve checksum pins and intentional freezes (LAME 3.100, Manrope 4.505, Sarabun 1.000, Rubik 2.300). Enable the Renovate GitHub App; monthly updates do not delay security advisories. `test/tooling/native_pins_test.dart` and `renovate_config_test.dart` check pin-manager coverage and datasource names (`dart` for pub.dev, not `pub`).

## Code signing

macOS Developer ID signing and notarization are **required**; missing secrets fail packaging rather than shipping unsigned. Set:

| Secret | Value |
| --- | --- |
| `MACOS_CERTIFICATE` | base64 password-protected **Developer ID Application** `.p12`, including private key |
| `MACOS_CERTIFICATE_PWD` | `.p12` password |
| `APPLE_ID` | Apple ID email for notarization |
| `APPLE_TEAM_ID` | 10-character developer Team ID |
| `APPLE_APP_PASSWORD` | Apple app-specific password for `notarytool` |

```bash
base64 -i DeveloperID.p12 | gh secret set MACOS_CERTIFICATE
gh secret set MACOS_CERTIFICATE_PWD
gh secret set APPLE_ID
gh secret set APPLE_TEAM_ID
gh secret set APPLE_APP_PASSWORD
```

The app's data-protection keychain access group `<TeamID>.com.alev.control-center` embeds the Team ID in **both** `macos/Runner/*.entitlements` and `lib/core/providers/storage_providers.dart`; change all three together.

### What Xcode signs and what it does not

`fvm flutter build macos --release` leaves an ad-hoc signed app **without entitlements**. `scripts/release/macos_package.sh` replaces that signature inside-out with Developer ID, adds the provisioning profile and `Runner/Release.entitlements`, then notarizes and staples. Runner Release must keep `CODE_SIGN_IDENTITY[sdk=macosx*] = "-"`, `CODE_SIGN_STYLE = Manual` and **no** `CODE_SIGN_ENTITLEMENTS`. Xcode Developer signing demands an unavailable CI development profile; adding the restricted keychain entitlement also demands a profile even with manual signing. Do not use `--skip-sign` to produce an unsigned arm64 binary (it cannot execute). Debug/Profile retain automatic signing and debug entitlements; `test/tooling/macos_signing_test.dart` guards this split.

### The standalone server archive signs itself separately

`cc_server_package.sh` signs/notarizes the archive independently after the app packager leaves the Developer ID keychain available. Sign **every Mach-O** under dist, including vendored code-server's Node binaries and `.node` addons; its executables need `scripts/release/entitlements/code_server.entitlements` for V8 executable memory under hardened runtime. Check every file before submission. `notarytool submit --wait` can exit 0 with `status: Invalid`: both packagers must explicitly require `status: Accepted` and dump `notarytool log` otherwise. An archive cannot be stapled; its ticket is checked online on first launch.

### Local development signing (macOS)

Only macOS client device-pairing keys need Apple-team signing (a free Apple ID works) to persist in the data-protection keychain. Without it the app starts but secure client pairing storage is unavailable; forge credentials live on the server. Add your Apple ID in Xcode → Settings → Accounts, then:

```bash
bash macos/scripts/create_local_signing_cert.sh
fvm flutter build macos --config-only
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Debug -allowProvisioningUpdates build
fvm flutter run -d macos
```

The script writes git-ignored `Signing.local.xcconfig` for automatic signing. Xcode must create the Keychain Sharing development profile once with `-allowProvisioningUpdates`; `fvm flutter run` does not pass it. Windows/Linux local runs do not need signing.

**Windows Authenticode (optional):** `WINDOWS_CERT` (base64 `.pfx`) and `WINDOWS_CERT_PWD` sign the installer. Otherwise it ships unsigned and SmartScreen warns.

## Built-in app credentials

The release optionally injects `CC_BUILTIN_GOOGLE_CLIENT_ID` and `CC_BUILTIN_GOOGLE_CLIENT_SECRET` (both or neither; one fails the build) for the server's Google device-code OAuth option, plus `CC_BUILTIN_KLIPY_APP_KEY` for GIF search. Forks/local builds without them ask for the user's Google app or hide GIF search. Use a Google OAuth client of type **TVs and limited input devices**, a published verified consent screen (`calendar.readonly` is sensitive), and a production Klipy key/agreement (test keys cap at 100 calls/hour). Do **not** inject a Slack client secret. Google installed-app secrets and the Klipy URL-path app key are vendor-documented non-confidential; user refresh tokens remain on the server.

`scripts/release/builtin_credentials.sh inject` rewrites tracked `packages/cc_server_core/lib/src/builtin_credentials.dart` before **any** build because `dart build cli` cannot take `-D`. The committed constants are empty. Release runners are disposable; locally always restore the pristine source:

```bash
export CC_BUILTIN_GOOGLE_CLIENT_ID=… CC_BUILTIN_GOOGLE_CLIENT_SECRET=… CC_BUILTIN_KLIPY_APP_KEY=…
bash scripts/release/builtin_credentials.sh inject
# build
bash scripts/release/builtin_credentials.sh restore
```

## Third-party licenses

Every artifact must carry `LICENSE` and generated `THIRD-PARTY-LICENSES.txt`: macOS under `.app/Contents/Resources/` **before signing**, Linux at bundle root, Windows beside executable, standalone archives at root. [`scripts/lib/third_party.sh`](scripts/lib/third_party.sh) defines components; [`third_party/licenses/`](third_party/licenses/) holds checked-in texts; `scripts/release/gen_third_party_licenses.sh` assembles notices without network access.

`desktop` and `server` in that table are artifacts, not native-build roles: desktop embeds server natives. Only standalone archives vendor code-server. **Statically linked libmp3lame is LGPL-2.1**; the notice identifies pinned source/checksum/shim/build script so recipients can relink under section 6. If that ceases to be possible, link it dynamically. Bundled fonts (Manrope, Fira Code, Phosphor) need matching license texts when changed. Flutter engine `NOTICES` covers Dart/Flutter dependencies; shipped text is the third-party notice channel. `test/tooling/third_party_licenses_test.dart` guards matrix coverage and LGPL inclusion.

## Scripts

The workflow delegates to locally runnable scripts. Keep **every** `scripts/release/*.sh` listed: `test/tooling/release_docs_test.dart` checks names. Header `Usage:` lines document their arguments.

| Script or library | Purpose |
| --- | --- |
| `scripts/lib/common.sh` | Common sourcing helpers |
| `scripts/lib/natives.sh` | Required-native matrix |
| `scripts/lib/native_pins.env` | Native source/archive pins and checksums |
| `scripts/lib/artifact_names.sh` | Exact artifact name set (`bash scripts/lib/artifact_names.sh 1.2.3`) |
| `scripts/lib/linux_desktop.sh` | Linux desktop host floor: glibc/libstdc++ maxima, host-provided and bundled libraries |
| `scripts/lib/third_party.sh` | Licensed-component table |
| `scripts/natives/lib/natives_common.sh` | macOS/Linux native build helpers |
| `scripts/natives/build_natives.sh`, `scripts/natives/build_inference.sh` | Native builds; pinned sherpa-onnx link/ABI verification |
| `scripts/release/windows_natives.sh` | Windows MSVC DLL builds |
| `scripts/release/dry_run.sh` | Full local pipeline for one platform |
| `scripts/release/verify_natives.sh` | Required-native bundle check |
| `scripts/release/builtin_credentials.sh` | Inject/restore optional built-in credentials |
| `scripts/release/fetch_code_server.sh` | Fetch pinned code-server |
| `scripts/release/macos_package.sh`, `scripts/release/linux_package.sh`, `scripts/release/windows_package.sh` | Desktop staging, validation and packaging |
| `scripts/release/bundle_linux_deps.sh`, `scripts/release/appimage_excludelist` | Copy the reviewed libraries a stock Linux desktop may lack, fix plugin RUNPATHs, append their licenses |
| `scripts/release/lint_appdir.sh` | AppImageHub's checks on the AppDir before `appimagetool`: layout, desktop entry, AppStream, ABI floor, library closure |
| `scripts/release/cc_server_package.sh`, `scripts/release/cc_demo_server_package.sh` | Standalone server/demo archives |
| `scripts/release/gen_third_party_licenses.sh` | Offline license notices |
| `scripts/release/gen_appcast.sh` | Sign both updater feeds, checking committed public keys |
| `scripts/release/make_release.sh` | Assemble/check assets and create draft |
| `tool/gen_build_info.dart`, `tool/gen_deploy_manifest.dart` | Shared build identity and hosted `/deploy.json` |
| `scripts/build_web.sh`, `scripts/run_desktop.sh` | Local web build and embedded-server desktop launch |

## Local dry run

`scripts/release/dry_run.sh` executes CI's order: build/stage natives → inject credentials → stamp build identity → `fvm flutter build` → package desktop and server → compare against `scripts/lib/artifact_names.sh`. Use the script, not a hand-copied partial recipe:

```bash
bash scripts/release/dry_run.sh --os macos --version 1.2.3
bash scripts/release/dry_run.sh --os macos --version 1.2.3 --skip-natives # reuse build/natives
bash scripts/release/dry_run.sh --os macos --version 1.2.3 --skip-sign    # local only
```

`--skip-sign` disables signing/notarization **only outside** `GITHUB_ACTIONS`; unsigned arm64 binaries cannot execute. To sign locally, export `MACOS_CERTIFICATE` (base64 `.p12`), `MACOS_CERTIFICATE_PWD`, `APPLE_ID`, `APPLE_TEAM_ID` and `APPLE_APP_PASSWORD` first. Windows dry runs require Git Bash, cargo/cmake/clang and an MSVC dev environment on `PATH`; vcpkg supplies `libmp3lame` unless `LAME_PREFIX` is set. If Inno Setup is unavailable, `SKIP_INSTALLER=1` still validates staging and creates the portable zip.
