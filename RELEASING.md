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

| Platform | Artifact | Notes |
|---|---|---|
| macOS (arm64) | `Control-Center-<v>-arm64.dmg` | Developer ID signed + notarized + stapled; embeds `rift` + `fff` + `tree-sitter` dylibs. |
| Windows (x64) | `Control-Center-<v>-x64-setup.exe` | Per-user installer; bundles `fff` (+ `tree-sitter`, best-effort) DLLs. No `rift`. |
| Linux (x86_64) | `Control-Center-<v>-x86_64.AppImage` (+ `.tar.gz`) | Bundles all three `.so`s under `lib/`. |

Native FFI libraries are built from source (`rift` ← `anomalyco/rift`, `fff` ← `dmtrKovalenko/fff`, `tree-sitter` ← upstream) and bundled. **Every native build is non-fatal** — if one fails the release still ships and that feature degrades gracefully at runtime (rift → plain `git worktree`, fff → Dart file search, tree-sitter → no code graph).

## First-run trust

The macOS DMG is Developer ID signed + notarized + stapled, so it opens normally — no Gatekeeper warning. Windows and Linux are not code-signed:

- **Windows:** on the SmartScreen prompt, click **More info** → **Run anyway**.
- **Linux:** make the AppImage executable and run it:
  ```bash
  chmod +x Control-Center-<v>-x86_64.AppImage
  ./Control-Center-<v>-x86_64.AppImage
  ```

## Verify a download

Checksums live in `SHA256SUMS.txt`. Each binary also has a keyless build-provenance attestation tying it to this repo + commit + workflow run:

```bash
gh attestation verify Control-Center-<v>-arm64.dmg --owner SamuelAlev
```

## Hardening built into the pipeline

- `permissions: {}` at the top; each job gets only what it needs (builds: `contents: read` + `id-token`/`attestations: write`; release: `contents: write`).
- All third-party actions are pinned to commit SHAs; the release is created with the first-party `gh` CLI.
- OIDC SLSA build-provenance attestation + `SHA256SUMS.txt` on every artifact.
- `step-security/harden-runner` (egress audit) on the Linux build + release jobs.
- **Renovate is the single dependency tool** ([`renovate.json`](renovate.json)). Its built-in managers keep the GitHub Actions SHA pins (digest-pinned, version comment kept current), the Dart/pub deps, and the `/docs` npm app up to date; custom regex managers track the **pinned native-source SHAs** — rift, fff, the tree-sitter runtime, and each grammar — updating both copies of each pin (the `scripts/natives/build_*.sh` default **and** the `release.yml` Windows `env:`) in one PR, and grouping the tree-sitter runtime + grammars so the parser ABI stays consistent. Everything runs monthly (native pins via release tags; dart tracks `master`); security advisories bypass the schedule. Enable the Renovate GitHub App on the repo for it to run.

## Code signing

**macOS (Developer ID + notarization) — required.** The release signs with Developer ID + hardened runtime, notarizes the DMG, and staples it; [`macos_package.sh`](scripts/release/macos_package.sh) **fails** if the secrets are missing (no unsigned fallback). Set these repo secrets:

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

The macOS app stores secrets in the **data-protection keychain**, scoped to the team-prefixed access group `<TeamID>.com.alev.control-center` (entitlement in `macos/Runner/*.entitlements`). That Team ID is baked into the two entitlements files **and** `lib/core/providers/storage_providers.dart` — update all three together if the team changes.

For local-dev signing (so the keychain doesn't prompt while developing), run `bash macos/scripts/create_local_signing_cert.sh` once.

**Windows (Authenticode) — optional.** Set `WINDOWS_CERT` (base64 of the `.pfx`) and `WINDOWS_CERT_PWD`; the installer is then signed, reducing SmartScreen friction. Without them it ships unsigned.

## Scripts

The workflow stays thin by delegating to scripts (each runnable locally):

| Script | Does |
|---|---|
| `scripts/natives/build_natives.sh [dest]` | Build rift + fff + tree-sitter (macOS/Linux), best-effort |
| `scripts/release/windows_natives.sh` | Build fff + tree-sitter DLLs (Windows; reads the `*_REF` env pins) |
| `scripts/release/macos_package.sh [version]` | Embed dylibs + sign + DMG + notarize + checksum |
| `scripts/release/linux_package.sh [version]` | Bundle `.so`s + AppImage + tarball + checksums |
| `scripts/release/make_release.sh` | Assemble artifacts + checksums + notes + draft release |

## Local dry run

```bash
# macOS — signing + notarization are required; export the same values as the
# CI secrets (MACOS_CERTIFICATE is the base64 of your Developer ID .p12).
bash scripts/natives/build_natives.sh build/natives
flutter build macos --release
export MACOS_CERTIFICATE="$(base64 -i DeveloperID.p12)" MACOS_CERTIFICATE_PWD=… \
       APPLE_ID=… APPLE_TEAM_ID=L3C7R68G6X APPLE_APP_PASSWORD=…
VERSION=1.2.3 bash scripts/release/macos_package.sh

# Linux
bash scripts/natives/build_natives.sh build/natives
flutter build linux --release
VERSION=1.2.3 bash scripts/release/linux_package.sh

# Windows (Git Bash + cargo/cmake/clang on PATH)
FFF_REF=... TREE_SITTER_REF=... TS_DART_REF=... TS_JAVASCRIPT_REF=... TS_TYPESCRIPT_REF=... TS_PHP_REF=... \
  bash scripts/release/windows_natives.sh
flutter build windows --release
# copy build/natives/*.dll next to control_center.exe, then:
#   ISCC.exe /DAppVersion=1.2.3 windows/installer/control_center.iss
```
