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
| macOS (arm64) | `Control-Center-<v>-arm64.dmg` | Ad-hoc signed; embeds `rift` + `fff` + `tree-sitter` dylibs. |
| Windows (x64) | `Control-Center-<v>-x64-setup.exe` | Per-user installer; bundles `fff` (+ `tree-sitter`, best-effort) DLLs. No `rift`. |
| Linux (x86_64) | `Control-Center-<v>-x86_64.AppImage` (+ `.tar.gz`) | Bundles all three `.so`s under `lib/`. |

Native FFI libraries are built from source (`rift` ← `anomalyco/rift`, `fff` ← `dmtrKovalenko/fff`, `tree-sitter` ← upstream) and bundled. **Every native build is non-fatal** — if one fails the release still ships and that feature degrades gracefully at runtime (rift → plain `git worktree`, fff → Dart file search, tree-sitter → no code graph).

## First-run trust (unsigned builds)

These builds are **not** signed by a paid developer certificate, so the OS warns on first launch. This is expected.

- **macOS:** right-click the app → **Open** (or System Settings → Privacy & Security → **Open Anyway**). If macOS reports the app is "damaged", clear the quarantine flag:
  ```bash
  xattr -dr com.apple.quarantine "/Applications/Control Center.app"
  ```
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
- **Renovate is the single dependency tool** ([`renovate.json`](renovate.json)). Its built-in managers keep the GitHub Actions SHA pins (digest-pinned, version comment kept current), the Dart/pub deps, and the `/docs` npm app up to date; custom regex managers track the **pinned native-source SHAs** — rift, fff, the tree-sitter runtime, and each grammar — updating both copies of each pin (the `scripts/build_*.sh` default **and** the `release.yml` Windows `env:`) in one PR, and grouping the tree-sitter runtime + grammars so the parser ABI stays consistent. Everything runs monthly (native pins via release tags; dart tracks `master`); security advisories bypass the schedule. Enable the Renovate GitHub App on the repo for it to run.

## Enabling real code signing later

Signing/notarization is already wired but dormant — it activates automatically when the secrets exist:

- **macOS (Developer ID + notarization):** set repo secrets `MACOS_CERTIFICATE` (base64 of the `.p12`), `MACOS_CERTIFICATE_PWD`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD` (an app-specific password). The macOS job then signs with hardened runtime, notarizes the DMG, and staples it — removing the Gatekeeper warning.
- **Windows (Authenticode):** set `WINDOWS_CERT` (base64 of the `.pfx`) and `WINDOWS_CERT_PWD`. The installer is then signed, reducing SmartScreen friction.

## Scripts

The workflow stays thin by delegating to scripts (each runnable locally):

| Script | Does |
|---|---|
| `scripts/build_natives.sh [dest]` | Build rift + fff + tree-sitter (macOS/Linux), best-effort |
| `scripts/release/windows_natives.sh` | Build fff + tree-sitter DLLs (Windows; reads the `*_REF` env pins) |
| `scripts/release/macos_package.sh [version]` | Embed dylibs + sign + DMG + notarize + checksum |
| `scripts/release/linux_package.sh [version]` | Bundle `.so`s + AppImage + tarball + checksums |
| `scripts/release/make_release.sh` | Assemble artifacts + checksums + notes + draft release |

## Local dry run

```bash
# macOS
bash scripts/build_natives.sh build/natives
flutter build macos --release
VERSION=1.2.3 bash scripts/release/macos_package.sh

# Linux
bash scripts/build_natives.sh build/natives
flutter build linux --release
VERSION=1.2.3 bash scripts/release/linux_package.sh

# Windows (Git Bash + cargo/cmake/clang on PATH)
FFF_REF=... TREE_SITTER_REF=... TS_DART_REF=... TS_JAVASCRIPT_REF=... TS_TYPESCRIPT_REF=... TS_PHP_REF=... \
  bash scripts/release/windows_natives.sh
flutter build windows --release
# copy build/natives/*.dll next to control_center.exe, then:
#   ISCC.exe /DAppVersion=1.2.3 windows/installer/control_center.iss
```
