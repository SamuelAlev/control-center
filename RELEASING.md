# Releasing Control Center

Desktop release binaries are built by [`.github/workflows/release.yml`](.github/workflows/release.yml):
**macOS** (drag-and-drop DMG, Apple Silicon), **Windows** (Inno Setup `.exe`), and **Linux** (AppImage + tarball). The workflow attaches the artifacts, `SHA256SUMS.txt`, and a signed SLSA build-provenance attestation per binary to a **draft** GitHub Release.

## Cut a release

1. Optionally bump `version:` in `pubspec.yaml` (the in-app version is overridden by the tag at build time, so this is just bookkeeping).
2. Tag and push:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```
   (Or run the workflow manually from **Actions → Release → Run workflow** and enter a version.)
3. Watch the run in the **Actions** tab. The three build jobs run in parallel, then a `release` job creates a **draft** release.
4. Open **Releases**, review the attached files and notes, then click **Publish**.

## What gets built

> [!IMPORTANT]
> **Windows has not been through a real release yet.** The job
> (`build-windows` in [release.yml](.github/workflows/release.yml)) is enabled
> and `windows` is in `RELEASE_PLATFORMS`, but it has never produced a shipped
> artifact — treat the first Windows release as a validation run and check the
> installer, the portable zip and the standalone `cc_server` zip by hand before
> publishing.
>
> Two Windows-specific things worth knowing while reviewing it:
> `scripts/release/windows_natives.sh` builds every native with MSVC (there is
> no `rift` there — plain `git worktree` is the backend), and `cc_inference`
> links the static-CRT (`-MT-`) sherpa archive, so its cargo build sets
> `RUSTFLAGS=-Ctarget-feature=+crt-static` to match. Builds are unsigned unless
> `WINDOWS_CERT` / `WINDOWS_CERT_PWD` are set.

| Platform | Artifact | Notes |
|---|---|---|
| macOS (arm64) | `Control-Center-<v>-arm64.dmg` | Developer ID signed + notarized + stapled; embeds the full native set. |
| Windows (x64) | `Control-Center-<v>-x64-setup.exe` | Per-user installer; bundles the full native DLL set except `rift`. |
| Windows (x64) | `Control-Center-<v>-windows-x64.zip` | Portable zip of the app layout — the WinSparkle in-app updater's payload. |
| Linux (x86_64) | `Control-Center-<v>-x86_64.AppImage` (+ `.tar.gz`) | Bundles the full native `.so` set under `lib/`. |
| All | `appcast.xml` + `appcast-windows.xml` | The signed updater feeds the desktop app checks (see "In-app updates"). |
| macOS (arm64) | `cc_server-<v>-macos-arm64.tar.gz` | Standalone self-hostable server; Developer ID signed + notarized. |
| Linux (x64) | `cc_server-<v>-linux-x64.tar.gz` | Standalone self-hostable server. |
| Windows (x64) | `cc_server-<v>-windows-x64.zip` | Standalone self-hostable server (unsigned). |

Plus three GHCR images built by the `containers` job — `cc-server`,
`control-center-web` and `control-center-remote` — each carrying its own SLSA
attestation. Every name above comes from
[`scripts/lib/artifact_names.sh`](scripts/lib/artifact_names.sh); the set is
asserted complete by `make_release.sh` before a draft is created, so a build job
that produced nothing fails the release instead of shipping a short one.

Native FFI libraries are built from source — `rift` ← `anomalyco/rift`, `fff` ← `dmtrKovalenko/fff`, `tree-sitter` + the 5 grammars ← upstream, `aec` ← `pulseaudio/webrtc-audio-processing` (+ meson's abseil wrap), `lame` ← the pinned LAME 3.100 tarball (vcpkg's `mp3lame` port on Windows), `cc_watcher` and `cc_inference` ← in-repo Rust, `ccpty` ← the vendored `flutter_pty` C. `cc_inference` additionally links a **checksum-pinned** prebuilt sherpa-onnx static archive (`SHERPA_ONNX_*` in `scripts/lib/native_pins.env`), fetched by `build_inference.sh` rather than by cargo, so nothing unverified is linked into a signed artifact. Every source host must be in the Linux job's `harden-runner` allowlist (extend it via the `extra-endpoints` input of the [`setup-flutter`](.github/actions/setup-flutter/action.yml) composite), which is part of the build, not a nicety: that job blocks egress, so an unlisted host fails the release.

There is exactly ONE ONNX Runtime, statically linked inside `libcc_inference`, so nothing about it needs staging or version-qualifying. That matters most on Windows, where the loader matches an already-loaded module by base name and could only ever hold one `onnxruntime.dll`.

**Every native build is FATAL.** There is no degraded mode: `cc_server` refuses to boot when a required library cannot be loaded, and the packaging scripts refuse to produce an artifact without it — so tolerating a build failure would only move the crash from the runner to a user's machine. `scripts/release/verify_natives.sh` gates each packaged bundle, and `cc_server_package.sh`'s `require_native` gates the server archive.

`rift` is the single documented exception: it is not built on Windows (no MSVC copy-on-write backend), where plain `git worktree` is the *backend* rather than a degradation. The only other fallbacks left are environment-driven, never build-driven: a filesystem without copy-on-write support, and semantic search staying FTS-only until the on-device embedding **model** is downloaded (models are the only artifacts fetched at runtime).

## First-run trust

The macOS DMG is Developer ID signed + notarized + stapled, so it opens normally, no Gatekeeper warning. Windows and Linux are not code-signed:

- **Windows:** on the SmartScreen prompt, click **More info** → **Run anyway**.
- **Linux:** make the AppImage executable and run it:
  ```bash
  chmod +x Control-Center-<v>-x86_64.AppImage
  ./Control-Center-<v>-x86_64.AppImage
  ```

## Verify a download

Checksums live in `SHA256SUMS.txt`. Each binary also has a keyless build-provenance attestation tying it to this repo + commit + workflow run (`--repo`, not `--owner`: the latter accepts an artifact attested by any repository under the account):

```bash
gh attestation verify Control-Center-<v>-arm64.dmg --repo SamuelAlev/control-center
```

## In-app updates

Every release publishes a signed updater feed alongside the binaries; the desktop app checks it on launch (after the shell is ready), every 24h, from the macOS app menu (**Control Center → Check for Updates…**, right under About), and from **Settings → Advanced → About → Check for updates**. Updates always prompt — release notes + explicit confirm — never apply silently, and a check whose prompt would interrupt a meeting recording is deferred to the next cycle.

- **macOS** — Sparkle 2 (via `auto_updater`): the whole `.app` is replaced (UI + embedded `cc_server` + natives), Developer ID signature intact. Feed: `appcast.xml`, DMG enclosure signed `sparkle:edSignature`.
- **Windows** — WinSparkle: the enclosure is the Inno installer (`Control-Center-<v>-x64-setup.exe`), run unattended (`/SILENT /SP-`) — WinSparkle *launches* the enclosure, so it cannot be a zip. The portable zip stays a plain download. Feed: `appcast-windows.xml`, enclosures signed `sparkle:dsaSignature` (WinSparkle 0.8.x predates EdDSA). Updating the app IS updating its embedded `cc_server`; the two never update independently.
- **Linux** — notify-only: "Check for updates" opens the latest release page (no Sparkle backend; AppImageUpdate is a future option).
- **Standalone `cc_server`** — never auto-updates. `cc_server update` (check + download + SHA256/SLSA verify + stage, `--apply` to swap the whole tree with a one-deep `.bak`) is the explicit path; Docker installs are told to `docker pull`; the desktop-embedded binary refuses (`CC_EMBEDDED`). A published release **older** than the running binary is refused unless `--allow-downgrade`. On Windows the install directory cannot be renamed while the binary runs from it, so `--apply` parks the live `cc_server.exe` as `.old` and overlays the verified tree in place.
- **Web / `cc_remote`** — no updater: the origin IS the deployment. The clients poll `/deploy.json` (written by the deploy workflows) and offer a consent-driven Refresh banner. It is deliberately **not** `version.json`: `flutter build web` generates a file by that name, which would overwrite ours and leave the banner permanently dead.

Feed URLs point at `releases/latest/download/…`, so **draft releases are invisible to every updater** until published.

### Testing the updater locally (no release needed)

Two tiers, both dev-only:

**1. Simulate the outcome (30 seconds, no keys/server).** Run the app with
`--dart-define=CC_FAKE_UPDATE=available` (or `none` / `error`) and use the
app-menu item or the About button. The native updater is replaced by a stub
that fires the real controller events, so you exercise the menu item, the
check state machine, and the About row — just not Sparkle's own prompt.

**2. The real Sparkle flow (fake feed, real everything else).**
```bash
fvm dart run tool/fake_update_server.dart          # serves a signed fake appcast on 127.0.0.1:8642
# in another terminal:
fvm flutter run -d macos --dart-define=CC_APPCAST_URL=http://127.0.0.1:8642/appcast.xml
```
The harness zips the locally built `.app` with its version bumped to `999.0.0`,
signs it (detached Ed25519) with a throwaway dev key living in
`.dart_tool/sparkle-dev/`, and patches that key into the **built** bundle's
`SUPublicEDKey` (a build artifact — the committed plist placeholder is never
touched, so release verification is unaffected). Sparkle then downloads,
verifies, and installs "for real"; the relaunched app believes it is on
999.0.0 so the fake loop terminates. `CC_APPCAST_URL` is a dart-define/env
override with no effect on release builds.

(The web banner has an even cheaper fake: build the web app, then edit
`gitSha` in `build/web/deploy.json` and serve that directory — the origin then
reports a "newer deploy" than the running build and the Refresh banner
appears. Edit the built copy, not the committed `web/deploy.json`: only files
in `build/web` are what a browser actually fetches.)

### One-time setup (updater signing keys)

The release job signs the appcasts with two secrets that are NOT the Apple Developer ID cert:

**This has been done — both keys are configured.** What follows is how, so it can
be repeated on a key rotation or a fork.

Both keypairs are generated **on macOS**; neither needs a Windows machine.

- `SPARKLE_ED25519_KEY` (macOS updates) — generated with Sparkle's own tool,
  which stores the private key in your login keychain and prints the public half:
  ```bash
  macos/Pods/Sparkle/bin/generate_keys            # prints SUPublicEDKey
  macos/Pods/Sparkle/bin/generate_keys -x key.txt # exports the private seed
  gh secret set SPARKLE_ED25519_KEY < key.txt
  ```
  Paste the printed public key into `macos/Runner/Info.plist` → `SUPublicEDKey`.
  `gen_appcast.sh` accepts the 32-, 64- and 96-byte export forms and takes the
  leading 32 bytes as the seed, so no hand-trimming is needed. (`dart run
  auto_updater:generate_keys` runs this same binary, but only after `pod install`.)
- `SPARKLE_DSA_PRIVATE_KEY` (Windows updates) — WinSparkle's `generate_keys.bat`
  is nothing but three openssl calls, so run them directly:
  ```bash
  openssl dsaparam 4096 > dsaparam.pem
  openssl gendsa -out dsa_priv.pem dsaparam.pem && rm dsaparam.pem
  openssl dsa -in dsa_priv.pem -pubout -out dsa_pub.pem
  gh secret set SPARKLE_DSA_PRIVATE_KEY < dsa_priv.pem
  ```
  Commit the resulting `dsa_pub.pem` at the repo root (it is PUBLIC), which
  `windows/runner/Runner.rc` embeds as the `DSAPub` resource. Never commit
  `dsa_priv.pem`.

**Back both private keys up.** They are permanent: once a user installs a build
signed with a key, every future update must be signed with the SAME key or their
app will reject it. The Ed25519 key is recoverable from the login keychain
(`generate_keys -x`); the DSA key exists only where you put it, because a GitHub
secret cannot be read back.

`scripts/release/gen_appcast.sh` is covered by `test/tooling/appcast_generation_test.dart`, which runs the real script against fixture artifacts and throwaway keys and verifies the emitted signature — run it after touching the script (it needs `python3` with `cryptography`, and skips with a reason otherwise).

Without both secrets the release job fails at `gen_appcast.sh` — deliberately: an unsigned feed is one every client would reject anyway.

### If the in-app updater does nothing

Almost always one of the two public keys. Both fail closed — which is correct,
and also silent from the user's side: the app checks, finds an item, rejects the
signature, and reports no update.

- **macOS** — `macos/Runner/Info.plist` → `SUPublicEDKey` is empty, or does not
  match the key `SPARKLE_ED25519_KEY` signs with.
- **Windows** — `dsa_pub.pem` at the repo root is still the placeholder, or does
  not match `SPARKLE_DSA_PRIVATE_KEY`.

Fix both with the one-time ceremony above. `gen_appcast.sh` now derives the
public half of each signing key and compares it against these two files, so a
release whose secrets and committed public keys disagree fails the job with the
exact value to paste, instead of publishing a feed no client can verify.

### Homebrew

The cask lives in the external `control-center/tap` repo. **It must set `auto_updates true`** now that Sparkle ships — otherwise `brew upgrade` and the in-app updater fight over the same `.app`.

## Hardening built into the pipeline

- `permissions: {}` at the top; each job gets only what it needs (builds: `contents: read` + `id-token`/`attestations: write`; release: `contents: write`).
- All third-party actions are pinned to commit SHAs; the release is created with the first-party `gh` CLI.
- OIDC SLSA build-provenance attestation + `SHA256SUMS.txt` on every artifact.
- `step-security/harden-runner` is the FIRST step of every job that checks out
  the repo. `egress-policy: block` on the Linux jobs (`prepare`, `build-linux`,
  `release`); `audit` on `build-macos`, `build-windows` — harden-runner can only
  block on Linux — and on `containers`, whose Docker Hub / GHCR CDN hosts cannot
  be enumerated. The two signing jobs previously had no harden-runner at all.
  It stays inline rather than moving into
  [`setup-flutter`](.github/actions/setup-flutter/action.yml): a local action is
  read from the workspace, so `actions/checkout` must run before it, and
  harden-runner has to precede the checkout it would otherwise follow. Both
  orderings are pinned by `test/tooling/workflow_setup_test.dart`.
- **Renovate is the single dependency tool** ([`renovate.json`](renovate.json)). Its built-in managers keep the GitHub Actions SHA pins (digest-pinned, version comment kept current), the Dart/pub deps, and the `/docs` npm app up to date; custom regex managers track the **pinned native-source SHAs** (rift, fff, the tree-sitter runtime, and each grammar) in [`scripts/lib/native_pins.env`](scripts/lib/native_pins.env), which is now the ONLY place a pin lives — it used to be two copies, or three for `WAP_REF` — and group the tree-sitter runtime + grammars so the parser ABI stays consistent. Each ref keeps its `# vX.Y.Z` comment on the assignment line because that version is what Renovate compares against upstream tags. Everything runs monthly (native pins via release tags; dart tracks `master`); security advisories bypass the schedule. Enable the Renovate GitHub App on the repo for it to run.

## Code signing

**macOS (Developer ID + notarization), required.** The release signs with Developer ID + hardened runtime, notarizes the DMG, and staples it; [`macos_package.sh`](scripts/release/macos_package.sh) **fails** if the secrets are missing (no unsigned fallback). Set these repo secrets:

| Secret | What |
|---|---|
| `MACOS_CERTIFICATE` | base64 of the **Developer ID Application** `.p12` (cert + private key) |
| `MACOS_CERTIFICATE_PWD` | password for that `.p12` |
| `APPLE_ID` | the Apple ID email used for notarization |
| `APPLE_TEAM_ID` | your 10-char Team ID (developer.apple.com → Membership) |
| `APPLE_APP_PASSWORD` | an app-specific password (appleid.apple.com) for `notarytool` |

```bash
# In Keychain Access, export your "Developer ID Application" identity (with its
# private key) as a password-protected .p12, then:
base64 -i DeveloperID.p12 | gh secret set MACOS_CERTIFICATE
gh secret set MACOS_CERTIFICATE_PWD     # the .p12 password
gh secret set APPLE_ID                  # your Apple ID email
gh secret set APPLE_TEAM_ID             # e.g. L3C7R68G6X
gh secret set APPLE_APP_PASSWORD        # app-specific password
```

The macOS app stores secrets in the **data-protection keychain**, scoped to the team-prefixed access group `<TeamID>.com.alev.control-center` (entitlement in `macos/Runner/*.entitlements`). That Team ID is baked into the two entitlements files **and** `lib/core/providers/storage_providers.dart`. Update all three together if the team changes.

### What Xcode signs, and what it does not

`flutter build macos --release` builds the app **ad-hoc signed and without
entitlements**; [`macos_package.sh`](scripts/release/macos_package.sh) then signs the
bundle inside-out with Developer ID, embeds the provisioning profile, applies
`Runner/Release.entitlements`, notarizes and staples. Xcode's signature is replaced
wholesale, so it must not try to produce a real one.

The Runner target's **Release** configuration therefore sets
`CODE_SIGN_IDENTITY[sdk=macosx*] = "-"` and `CODE_SIGN_STYLE = Manual`, and carries no
`CODE_SIGN_ENTITLEMENTS`. Both halves are load-bearing on CI, and each one failed the
release separately before it was right:

- an `"Apple Development"` identity plus `DEVELOPMENT_TEAM` made Xcode look for a Mac
  Development provisioning profile no runner has — *"No profiles for
  'com.alev.control-center' were found"*;
- `CODE_SIGN_ENTITLEMENTS` pulled in `keychain-access-groups`, a **restricted**
  entitlement, which requires a provisioning profile even under manual signing —
  *"Runner requires a provisioning profile"*.

Ad-hoc rather than unsigned matters: an unsigned arm64 binary will not execute at all, so
`--skip-sign` dry runs and `scripts/run_desktop.sh MODE=release` would produce something
that cannot be launched. Debug and Profile keep automatic signing and the debug
entitlements, so local development is unaffected. `test/tooling/macos_signing_test.dart`
pins all of this.

### The standalone server archive signs itself separately

[`cc_server_package.sh`](scripts/release/cc_server_package.sh) signs and notarizes the
`cc_server-<v>-macos-arm64` archive on its own, after `macos_package.sh` has left the
Developer ID keychain on the search list. Two things about it are load-bearing, and both
shipped broken in v0.0.1:

- **It signs every Mach-O it can find under the dist dir, not a fixed list of
  directories.** The archive vendors code-server, which is a complete Node runtime plus
  compiled `*.node` addons and helper binaries, and it is staged *before* signing. While
  the signing pass was a `Frameworks/*.dylib` + `lib/*.dylib` glob, several dozen unsigned
  Mach-Os went into the submission. code-server's *executables* additionally get
  [`scripts/release/entitlements/code_server.entitlements`](scripts/release/entitlements/code_server.entitlements):
  under the hardened runtime V8 cannot allocate executable memory, so a node signed bare
  is notarizable and unrunnable. A per-file adhoc/hardened-runtime check runs before
  submission, because it names the offending path and the notary service does not.
- **`notarytool submit --wait` exits 0 on `status: Invalid`.** It reports that the
  submission completed, not that it passed. Unchecked, the script printed
  `Current status: Invalid.............Processing complete`, then archived, checksummed
  and reported `==> Done` — a rejected build shipped as a release asset with a green CI
  run. Both this script and `macos_package.sh` now grep for `status: Accepted` and dump
  `notarytool log` on anything else.

The archive itself cannot be stapled (`stapler` only handles `.app`/`.dmg`/`.pkg`), so the
ticket is checked online at first launch.

### Local development signing (macOS)

Only needed to work on the app itself, and only on macOS. Credentials live in the macOS
*data-protection keychain*, which requires the app to be signed by an Apple Developer team
— a **free** Apple ID works. Without it the app still launches; secure storage
(GitHub/Linear/Google sign-in) is simply unavailable. Windows and Linux need no signing to
run locally.

The debug entitlement uses `$(DEVELOPMENT_TEAM)`, so no source edit is required. Add your
Apple ID in Xcode → Settings → Accounts, then run once:

```bash
bash macos/scripts/create_local_signing_cert.sh
```

It writes a git-ignored `Signing.local.xcconfig` configured for **automatic signing** under
your team. Because the app uses the Keychain Sharing capability, mint the development
provisioning profile once — `flutter run` cannot, as it does not pass
`-allowProvisioningUpdates`:

```bash
flutter build macos --config-only
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Debug -allowProvisioningUpdates build
```

Then `flutter run -d macos` works. The script prints these commands too.


**Windows (Authenticode), optional.** Set `WINDOWS_CERT` (base64 of the `.pfx`) and `WINDOWS_CERT_PWD`; the installer is then signed, reducing SmartScreen friction. Without them it ships unsigned.

## Built-in app credentials

Two conveniences depend on credentials that ship inside `cc_server`: "use Control Center's Google app" in the calendar connect dialog, and the GIF picker. Both are optional — without them the calendar dialog asks for a Google client id + secret and the picker stays hidden, which is what every fork and local build gets.

| Secret | What |
|---|---|
| `CC_BUILTIN_GOOGLE_CLIENT_ID` | Google OAuth client of type **TVs and limited input devices** (the device-code flow). Not the iOS-type client the older client-side flow used. |
| `CC_BUILTIN_GOOGLE_CLIENT_SECRET` | The secret paired with it. Both halves or neither — one alone **fails the build**, because it would advertise an option that cannot work. |
| `CC_BUILTIN_KLIPY_APP_KEY` | Klipy app key from the partner panel. Ask for production status; a test key caps at 100 calls/hour. |

[`builtin_credentials.sh`](scripts/release/builtin_credentials.sh) writes them into `packages/cc_server_core/lib/src/builtin_credentials.dart` — real source constants, because `dart build cli` has no `-D` flag and a `String.fromEnvironment` value can therefore never reach the server binary. The release runs `inject` once per job **before any build**; the committed file holds empty strings, so this public repository stays free of credentials.

Only credentials the vendor documents as non-confidential are eligible. Google treats installed-app secrets that way (extracting ours buys quota abuse and consent-screen impersonation, never anyone's calendar data — refresh tokens never leave the user's own server), and a Klipy key rides in the URL path of every request. A Slack `client_secret` is **not** eligible, which is why each workspace brings its own Slack app.

Both also need one-time setup outside this repo: a **published, verified** Google consent screen (`calendar.readonly` is a sensitive scope — unverified use warns the user, caps at 100 accounts, and expires refresh tokens after 7 days), and an accepted Klipy API agreement.

Injecting rewrites a tracked file. `restore` puts it back from the pristine copy it set aside, and the release runners are throwaway, but locally run it when you're done:

```bash
export CC_BUILTIN_GOOGLE_CLIENT_ID=… CC_BUILTIN_GOOGLE_CLIENT_SECRET=… CC_BUILTIN_KLIPY_APP_KEY=…
bash scripts/release/builtin_credentials.sh inject
# … build …
bash scripts/release/builtin_credentials.sh restore
```

## Scripts

The workflow stays thin by delegating to scripts (each runnable locally).
`test/tooling/release_docs_test.dart` fails if a script under `scripts/release/`
is missing from this table, so it cannot quietly fall out of date again.

**Shared libraries** (sourced, not executed):

| File | Is |
|---|---|
| `scripts/lib/common.sh` | Host-agnostic helpers: `log`/`warn`/`die`, `sha256_of`, `fetch_pinned`, `scratch_dir`, `stage_natives`, `ensure_cc_server_bundle`, `assert_asset_budget`, `load_native_pins`. Safe to source under Git Bash |
| `scripts/lib/natives.sh` | **The** required-native matrix, one row per library. Read by `verify_natives.sh` and `cc_server_package.sh`; pinned to the Dart runtime table by `test/tooling/native_matrix_test.dart` |
| `scripts/lib/native_pins.env` | **The** pinned third-party sources (git SHAs + the LAME/appimagetool checksums). The only Renovate target |
| `scripts/lib/artifact_names.sh` | **The** release artifact name table. Also runnable: `bash scripts/lib/artifact_names.sh 1.2.3` prints the full shipped set |
| `scripts/natives/lib/natives_common.sh` | macOS/Linux-only native-build helpers (`git_clone_pinned`, platform detection, ad-hoc signing). Sourcing it asserts a buildable host |

**Natives:**

| Script | Does |
|---|---|
| `scripts/natives/build_natives.sh [dest]` | Build every native (macOS/Linux); aborts on the first failure |
| `scripts/natives/build_inference.sh [dest]` | Build `libcc_inference` (speech + embeddings) against the checksum-pinned sherpa-onnx static archive, and assert the built dylib exports the `cc_*` ABI and leaks no ONNX Runtime / sherpa symbols |
| `scripts/release/windows_natives.sh` | Build DLLs (Windows); loads its pins from `native_pins.env` |

**Release:**

| Script | Does |
|---|---|
| `scripts/release/dry_run.sh [--os …] [--version …]` | Run the WHOLE pipeline for one platform locally — see "Local dry run" |
| `scripts/release/verify_natives.sh [--dir D]… <os> <role>` | Assert a packaged dir carries the required native set (from `scripts/lib/natives.sh`) |
| `scripts/release/builtin_credentials.sh <inject\|restore>` | Bake the built-in Google/Klipy credentials into `cc_server`'s source constants; run **before** any build |
| `scripts/release/fetch_code_server.sh [version]` | Fetch + extract the pinned code-server into `build/code-server/<platform>/` |
| `scripts/release/macos_package.sh [version]` | Embed dylibs + verify + sign + DMG + notarize + checksum |
| `scripts/release/linux_package.sh [version]` | Bundle `.so`s + verify + AppImage + tarball + checksums |
| `scripts/release/windows_package.sh [version]` | Bundle DLLs + verify + Inno installer + Authenticode + portable zip |
| `scripts/release/cc_server_package.sh <version> [os]` | Package the standalone self-hostable `cc_server` archive |
| `scripts/release/gen_appcast.sh <version> <tag> <build-number>` | Sign + write the two Sparkle appcasts (refuses if the signing keys do not match the public keys shipped in the app) |
| `scripts/release/make_release.sh [--dry-run]` | Assemble the exact expected artifact set + checksums + notes + draft release |

**Tools:**

| Tool | Does |
|---|---|
| `tool/gen_build_info.dart [--version X.Y.Z]` | Stamp the shared build identity every artifact compiles in |
| `tool/gen_deploy_manifest.dart <dir>` | Write the `deploy.json` the hosted clients poll, derived from that stamp |
| `scripts/build_web.sh [--target client\|remote\|gallery]` | The canonical local web build: stamp → workers → Wasm build → manifest → asset budget |
| `scripts/run_desktop.sh` | Build + embed `cc_server` into a local desktop build the way a release does, then launch |

## Local dry run

One script runs the whole pipeline for a platform, in CI's order:

```bash
# The full thing (natives are the slow part; drop --skip-natives the first time).
bash scripts/release/dry_run.sh --os macos --version 1.2.3

# Iterate on packaging only, reusing what is already staged in build/natives.
bash scripts/release/dry_run.sh --os macos --version 1.2.3 --skip-natives

# No Developer ID handy? Package without signing/notarizing. LOCAL ONLY — the
# same flag is refused under GITHUB_ACTIONS, so a CI release can never be
# unsigned by accident.
bash scripts/release/dry_run.sh --os macos --version 1.2.3 --skip-sign
```

It runs natives → credential injection → the build-identity stamp →
`flutter build` → the platform packager → `cc_server_package.sh`, then diffs what
landed against `scripts/lib/artifact_names.sh`.

This replaced a hand-written command list that did not work: it omitted a native
staging step, so the native-verify gate inside the package scripts failed on a
missing library, and it omitted `gen_build_info.dart`, so the artifact
self-reported `0.0.1 (dev)`.

To sign for real, export the same values the CI secrets carry before running it:

```bash
export MACOS_CERTIFICATE="$(base64 -i DeveloperID.p12)" MACOS_CERTIFICATE_PWD=… \
       APPLE_ID=… APPLE_TEAM_ID=L3C7R68G6X APPLE_APP_PASSWORD=…
```

On Windows the dry run needs Git Bash plus cargo/cmake/clang and an MSVC dev
environment on PATH (vcpkg supplies `libmp3lame`, or set `LAME_PREFIX`). Without
Inno Setup installed, `SKIP_INSTALLER=1` still exercises staging, verification
and the portable zip.
