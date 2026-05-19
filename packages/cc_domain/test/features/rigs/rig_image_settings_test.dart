import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:test/test.dart';

void main() {
  group('isValidCustomRigImageRef', () {
    test('accepts ordinary registry references', () {
      const pinnedUbuntu =
          'ubuntu:24.04@sha256:d78ab76437b1afc5f01e223d6bf0172763f404bb166441'
          '328845adbef44518cb';
      const pinnedShell =
          'chromedp/headless-shell:stable@sha256:2d349b544a1ea6b5b5fd7c0fe992'
          '15ff662339c57407ee2e8c0a11af93516b04';
      for (final ref in [
        'ubuntu:24.04',
        'alpine',
        'acme/dev-shell:1.2.3',
        'ghcr.io/acme/dev-shell:v2',
        'registry.example.com:5000/team/img:latest',
        pinnedUbuntu,
        pinnedShell,
      ]) {
        expect(isValidCustomRigImageRef(ref), isTrue, reason: ref);
      }
    });

    test('refuses anything that could name a local source', () {
      // These are how the runtime would be talked into reading arbitrary
      // host files as an image: local archives, rootfs dirs, stdin, flags.
      for (final ref in [
        './image.tar',
        '../escape',
        '/etc/passwd',
        '-',
        '--image',
        'archive.tar',
        'archive.tar.gz',
        'archive.tgz',
        'a b',
        '',
      ]) {
        expect(isValidCustomRigImageRef(ref), isFalse, reason: '"$ref"');
      }
    });

    test('normalize collapses blank to null (meaning: use the default)', () {
      expect(normalizeCustomRigImageRef(null), isNull);
      expect(normalizeCustomRigImageRef('   '), isNull);
      expect(normalizeCustomRigImageRef(' alpine '), 'alpine');
    });
  });

  group('registryHostsForImageRef', () {
    test('bare and Hub references pull through Docker Hub + its CDN', () {
      for (final ref in ['ubuntu:24.04', 'acme/dev-shell:1.2']) {
        expect(
          registryHostsForImageRef(ref),
          containsAll(['docker.io', 'production.cloudflare.docker.com']),
          reason: ref,
        );
      }
    });

    test('known registries carry their blob CDNs alongside the API host', () {
      expect(
        registryHostsForImageRef('ghcr.io/acme/x:1'),
        containsAll(['ghcr.io', 'pkg-containers.githubusercontent.com']),
      );
      expect(
        registryHostsForImageRef('quay.io/acme/x'),
        contains('quay.io'),
      );
    });

    test('an unknown registry gets its own host admitted', () {
      expect(
        registryHostsForImageRef('registry.example.com:5000/team/img'),
        ['registry.example.com'],
      );
    });
  });
}
