import 'dart:io';

import 'package:control_center/core/storage/app_support_path_provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempRoot;
  late _FakePathProvider fake;
  late PathProviderPlatform originalInstance;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('cc_app_support_test_');
    fake = _FakePathProvider(appSupportPath: tempRoot.path);
    originalInstance = PathProviderPlatform.instance;
    PathProviderPlatform.instance = fake;
    AppSupportPathProvider.resetForTesting();
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalInstance;
    AppSupportPathProvider.resetForTesting();
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('install captures real path and registers a wrapper', () async {
    expect(AppSupportPathProvider.isInstalled, isFalse);

    final realDir = await AppSupportPathProvider.install();

    expect(AppSupportPathProvider.isInstalled, isTrue);
    expect(realDir.path, tempRoot.path);
    expect(AppSupportPathProvider.realAppSupportDir.path, tempRoot.path);
    expect(
      PathProviderPlatform.instance,
      isA<AppSupportPathProvider>(),
      reason: 'install() should swap the platform instance',
    );
  });

  test('install is idempotent', () async {
    final first = await AppSupportPathProvider.install();
    final second = await AppSupportPathProvider.install();
    expect(first.path, second.path);
  });

  // The redirect outlived the font cache it was built for: plugins that resolve
  // app support (shared_preferences on Windows/Linux) have written under
  // `<real>/fonts/` for as long as it has existed, so dropping it would strip a
  // user's saved preferences.
  test(
    'getApplicationSupportPath returns <real>/fonts after install',
    () async {
      await AppSupportPathProvider.install();
      final supportPath = await PathProviderPlatform.instance
          .getApplicationSupportPath();
      expect(supportPath, p.join(tempRoot.path, 'fonts'));
    },
  );

  test('fonts subfolder is created on demand', () async {
    await AppSupportPathProvider.install();
    final fontsDir = Directory(p.join(tempRoot.path, 'fonts'));
    expect(fontsDir.existsSync(), isFalse, reason: 'not created until asked');

    await PathProviderPlatform.instance.getApplicationSupportPath();

    expect(fontsDir.existsSync(), isTrue);
  });

  test('other path methods delegate to the original instance', () async {
    await AppSupportPathProvider.install();
    final tmp = await PathProviderPlatform.instance.getTemporaryPath();
    final docs = await PathProviderPlatform.instance
        .getApplicationDocumentsPath();
    final cache = await PathProviderPlatform.instance.getApplicationCachePath();
    expect(tmp, fake.tempPath);
    expect(docs, fake.docsPath);
    expect(cache, fake.cachePath);
  });

  test(
    'controlCenterRootDir returns the real root, not the fonts subfolder',
    () async {
      await AppSupportPathProvider.install();
      final root = await controlCenterRootDir();
      expect(root.path, tempRoot.path);
      expect(
        root.path.endsWith('fonts'),
        isFalse,
        reason: 'app data should live at the real root, not in fonts/',
      );
    },
  );

  test('controlCenterRootDir throws before install', () async {
    expect(controlCenterRootDir, throwsA(isA<StateError>()));
  });
}

/// Minimal stand-in for the real platform implementation. Records what paths
/// it hands out so we can assert delegation.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider({required this.appSupportPath}) : super();

  final String appSupportPath;
  final String tempPath = '/tmp/fake-temp';
  final String docsPath = '/tmp/fake-docs';
  final String cachePath = '/tmp/fake-cache';

  @override
  Future<String?> getApplicationSupportPath() async => appSupportPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;

  @override
  Future<String?> getApplicationCachePath() async => cachePath;
}
