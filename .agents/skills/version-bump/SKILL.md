---
name: version-bump
description: Prepare a Control Center version bump or release. Use when asked to bump the version, prepare the next release, update release metadata, or provide release Git commands. Synchronize the app and shared build identity, update both web deployment defaults, and always add release notes to the docs changelog.
user-invocable: true
argument-hint: "[version]"
---

# Bump the version

Run commands from the repository root. Read `RELEASING.md` first; it owns packaging, signing, release gates and publication requirements.

## Choose the version

- Inspect the root `pubspec.yaml`, the latest release tags, published GitHub releases and commits since the last release. Preserve unrelated working-tree changes.
- Use the requested version. If none was specified, follow the existing release sequence and state the choice. Check local and remote tags before choosing an unused version; never overwrite a tag or release.
- Inspect the previous version-bump commit for conventions. Workspace package versions are independent; do not bump every `pubspec.yaml`.

## Update metadata

Keep these four committed values aligned:

| File | Update |
| --- | --- |
| `pubspec.yaml` | `version: X.Y.Z+<build>`; retain the existing build suffix unless a new one was requested |
| `packages/cc_domain/lib/src/build_info.dart` | `BuildInfo.buildVersion`, without the build suffix |
| `web/deploy.json` | `version`, without the build suffix |
| `apps/cc_remote/web/deploy.json` | `version`, without the build suffix |

Keep `BuildInfo.buildGitSha` and both manifest `gitSha` values as `dev`. Keep `BuildInfo.buildTime` and both manifest `builtAt` values empty. Do not run the stamping tools against tracked files: CI stamps the actual commit and timestamp when building.

Comments must describe invariants, not repeat the current release number. A routine bump should not require editing `tool/gen_build_info.dart` or explanatory comments.

## Update the docs changelog

**A version bump is incomplete without `docs/src/data/changelog.ts`.**

- Read the existing `Release` shape and prepend the new entry to `releases`.
- Use the release version with its `v` prefix, a unique matching fragment ID, the intended release date in both display and ISO formats, a short title and a factual lead.
- Group consumer-visible changes under the existing `new`, `improved` and `fixed` types. Base claims on the commit range and implementation, not commit titles alone. Mention removed behavior when users need to know about it.
- Mark only the newest entry `latest: true`; preserve historical entries.
- The `note` field renders with a Platform label; reserve it for platform information.
- The changelog page, jump navigation, RSS feed and machine-readable copies must consume the same release data. Do not hardcode a new version or month into a renderer.

## Verify and hand off

- Use `fvm` for all Dart/Flutter commands. Analyze changed Dart sources and run the relevant existing version-comparison, deployment-manifest and release-tooling tests with `--concurrency=1` for root Flutter tests. Never run test suites in parallel. Report skipped checks and missing prerequisites explicitly.
- Smoke-run the build-identity and deployment-manifest generators in a temporary directory. Check both the pubspec-derived version and the explicit release override, and ensure the generated manifest agrees with the generated identity. Leave tracked defaults unstamped.
- Preview the docs changelog. Check the new entry, its jump link and RSS item, and verify desktop and phone layouts. Do not launch the Flutter app; the user owns `fvm flutter run`.
- Report any unresolved release gates from `RELEASING.md`, CI or packaging. Resolve public-distribution prerequisites before triggering the release workflow: it pushes GHCR images even while the GitHub Release stays a draft. Local metadata checks do not prove signed multi-platform artifacts are ready to publish.
- Give exact Git commands using explicit changed paths: stage, commit, push the branch, then create and push the release tag after CI passes. Tag pushes trigger a draft GitHub Release; review builds, checksums, attestations, signing and required manual scenarios before publishing.
- Do not commit, tag, push or publish unless the user explicitly asked you to execute those actions. Never suggest `git add .` when unrelated files are present.
