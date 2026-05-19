import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/deployment_preview.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_deployment_previews_use_case.dart';
import 'package:test/test.dart';

// The real Netlify bot comment from a PR. Deliberately kept
// verbatim (custom domain, table layout, decoy log/QR/config links) so the
// detector is pinned against a real-world payload, not a sanitized one.
const _netlifyComment = '''
### <span aria-hidden="true">✅</span> Deploy Preview for *use-ctrl* ready!


|  Name | Link |
|:-:|------------------------|
|<span aria-hidden="true">🔨</span> Latest commit | e6321ac9be3ea9fd6fe92343a7a7dd915f02ad5c |
|<span aria-hidden="true">🔍</span> Latest deploy log | https://app.netlify.com/projects/use-ctrl/deploys/6a5e2cc64e6c7a000844d5d8 |
|<span aria-hidden="true">😎</span> Deploy Preview | [https://deploy-preview-2803.usectrl.dev](https://deploy-preview-2803.usectrl.dev) |
|<span aria-hidden="true">📱</span> Preview on mobile | <details><summary> Toggle QR Code... </summary><br /><br />![QR Code](https://app.netlify.com/qr-code/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.abc)<br /><br />_Use your smartphone camera to open QR code link._</details> |
---
<!-- [use-ctrl Preview](https://deploy-preview-2803.usectrl.dev) -->
_To edit notification comments on pull requests, go to your [Netlify project configuration](https://app.netlify.com/projects/use-ctrl/configuration/notifications#deploy-notifications)._
''';

void main() {
  const detector = DetectDeploymentPreviewsUseCase();

  group('commit statuses (primary source)', () {
    test('picks target_url from a netlify deploy-preview context', () {
      final previews = detector.detect(
        statuses: [
          const CommitStatus(
            context: 'netlify/test-web-app/deploy-preview',
            state: CommitStatusState.success,
            targetUrl: 'https://deploy-preview-2803.usectrl.dev',
          ),
          const CommitStatus(
            context: 'netlify/test-backend/deploy-preview',
            state: CommitStatusState.success,
            targetUrl: 'https://deploy-preview-2803.test-backend.usectrl.dev',
          ),
        ],
      );

      expect(previews, hasLength(2));
      expect(
        previews.map((p) => p.siteName),
        containsAll(['test-web-app', 'test-backend']),
      );
      expect(
        previews.every((p) => p.source == DeploymentPreviewSource.commitStatus),
        isTrue,
      );
      expect(previews.first.state, DeploymentPreviewState.ready);
    });

    test('a pending status is surfaced as building', () {
      final previews = detector.detect(
        statuses: [
          const CommitStatus(
            context: 'netlify/site/deploy-preview',
            state: CommitStatusState.pending,
            targetUrl: 'https://deploy-preview-1--site.netlify.app',
          ),
        ],
      );
      expect(previews.single.state, DeploymentPreviewState.building);
    });

    test('ignores non-preview status contexts', () {
      final previews = detector.detect(
        statuses: [
          const CommitStatus(
            context: 'ci/circleci: build',
            state: CommitStatusState.success,
            targetUrl: 'https://circleci.com/gh/acme/app/123',
          ),
        ],
      );
      expect(previews, isEmpty);
    });
  });

  group('comment fallback', () {
    test('detects the netlify preview URL on a custom domain', () {
      final previews = detector.detect(texts: [_netlifyComment]);

      expect(previews, hasLength(1));
      final preview = previews.single;
      expect(preview.url, 'https://deploy-preview-2803.usectrl.dev');
      expect(preview.source, DeploymentPreviewSource.comment);
      // A comment has no structured context, so the site is derived from the
      // preview host — `deploy-preview-2803.usectrl.dev` -> `usectrl`.
      expect(preview.siteName, 'usectrl');
    });

    test('never picks the deploy-log, QR-code, or config decoy links', () {
      final previews = detector.detect(texts: [_netlifyComment]);
      final urls = previews.map((p) => p.url).join('\n');
      expect(urls, isNot(contains('app.netlify.com')));
    });

    test('detects a md style [Visit Preview](url) link', () {
      final previews = detector.detect(
        texts: [
          'Check it out: [Visit Preview](https://acme-app.example.com/x)',
        ],
      );
      expect(previews.single.url, 'https://acme-app.example.com/x');
    });

    test('detects a bare Vercel preview URL by host suffix', () {
      final previews = detector.detect(
        texts: ['Deployed to https://acme-git-feat-team.vercel.app somewhere'],
      );
      expect(previews.single.url, 'https://acme-git-feat-team.vercel.app');
    });

    test('ignores unrelated links', () {
      final previews = detector.detect(
        texts: [
          'See [the docs](https://example.com/docs) and https://github.com/a/b',
        ],
      );
      expect(previews, isEmpty);
    });

    test('never treats the SonarCloud quality-gate badge as a preview', () {
      // The SonarCloud bot embeds its badge as an image on `sonarsource.github.io`.
      // The host ends in `.github.io` (a GitHub Pages preview suffix), so it used
      // to slip through as a bare-URL preview — but it points at a `.png`, so it
      // is an asset, not a browsable preview page.
      const sonarComment =
          '## [![Quality Gate Passed](https://sonarsource.github.io/'
          'sonarcloud-github-static-resources/v2/checks/QualityGateBadge/'
          "qg-passed-20px.png 'Quality Gate Passed')]"
          '(https://sonarcloud.io/dashboard?id=SamuelAlev_control-center&pullRequest=15770)'
          ' **Quality Gate passed**';
      expect(detector.detect(texts: [sonarComment]), isEmpty);
    });

    test('rejects image-asset URLs on preview-looking hosts', () {
      final previews = detector.detect(
        texts: [
          'Deploy preview badge: https://acme.github.io/badges/status.svg',
        ],
      );
      expect(previews, isEmpty);
    });
  });

  group('merge & dedupe', () {
    test('status source wins; comment for the same site is dropped', () {
      final previews = detector.detect(
        statuses: [
          const CommitStatus(
            context: 'netlify/test-web-app/deploy-preview',
            state: CommitStatusState.success,
            targetUrl: 'https://deploy-preview-2803.usectrl.dev',
          ),
        ],
        texts: [_netlifyComment],
      );
      // Same URL from both sources collapses to the status-sourced one.
      expect(previews, hasLength(1));
      expect(previews.single.source, DeploymentPreviewSource.commitStatus);
    });

    test('combines distinct sites across sources', () {
      final previews = detector.detect(
        statuses: [
          const CommitStatus(
            context: 'netlify/test-backend/deploy-preview',
            state: CommitStatusState.success,
            targetUrl: 'https://deploy-preview-2803.test-backend.usectrl.dev',
          ),
        ],
        texts: [_netlifyComment], // contributes the `usectrl` site
      );
      expect(previews, hasLength(2));
      expect(
        previews.map((p) => p.siteName),
        containsAll(['test-backend', 'usectrl']),
      );
    });

    test('is stable / deterministic across calls', () {
      List<String> run() => detector
          .detect(texts: [_netlifyComment])
          .map((p) => '${p.siteName}:${p.url}')
          .toList();
      expect(run(), run());
    });
  });
}
