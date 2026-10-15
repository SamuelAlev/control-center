import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_webview.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_pool.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_view.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:control_center/shared/editor/host/editor_body_host.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

/// `flutter test` has no web view platform; this one renders nothing.
class _FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _FakeInAppWebViewWidget(params);
}

class _FakeInAppWebViewWidget extends PlatformInAppWebViewWidget {
  _FakeInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError();

  @override
  void dispose() {}
}

const _kind = 'codeServer';

EditorTab _file(String path) =>
    EditorTab(kind: _kind, label: path, args: {'spaceId': 's1', 'path': path});

void main() {
  late EditorLayoutController layout;
  late CodeServerWindowPool pool;
  final opens = <String>[];
  var resolutions = 0;

  setUp(() {
    InAppWebViewPlatform.instance = _FakeInAppWebViewPlatform();
    opens.clear();
    resolutions = 0;
  });

  Future<void> pumpWorkbench(WidgetTester tester, List<EditorTab> tabs) async {
    final group = EditorTabGroupController();
    for (final t in tabs) {
      group.insert(group.tabs.length, t);
    }
    group.selectedIndex = 0;
    layout = EditorLayoutController.single(controller: group);
    pool = CodeServerWindowPool(
      targetOf: (tab) => tab.kind == _kind
          ? CodeServerTarget(spaceId: 's1', path: tab.args['path'] as String?)
          : null,
      openFile: (worktree, windowId, path, line) async =>
          opens.add('$windowId:$path'),
      closeFile: (worktree, path) async {},
    )..attach(layout);
    addTearDown(() {
      pool.dispose();
      layout.dispose();
    });
    final bodyHost = EditorBodyHost(isWebviewKind: (_) => false);
    await tester.pumpWidget(
      testWrap(
        MediaProxyScope(
          config: MediaProxyConfig(
            httpBase: Uri.parse('http://127.0.0.1:4100/_cc_resource/cap/'),
            deviceId: 'desktop',
            psk: 'test-key',
          ),
          child: ProviderScope(
            overrides: [
              codeServerSessionProvider.overrideWith((ref, request) async {
                resolutions++;
                return const CodeServerSessionResult(
                  sessionId: 'sid',
                  url: '/proxy/vscode/sid/',
                  status: CodeServerStatus.ready,
                );
              }),
            ],
            child: Stack(
              fit: StackFit.expand,
              children: [
                CodeServerWindowParking(pool: pool),
                EditorWorkspace(
                  layout: layout,
                  chrome: const EditorChrome(),
                  buildBody: (tab, {required isVisible}) => bodyHost.wrap(
                    tab,
                    isVisible: isVisible,
                    background: const Color(0xFFFFFFFF),
                    buildContent: () => tab.kind == _kind
                        ? CodeServerPane(
                            spaceId: 's1',
                            path: tab.args['path'] as String?,
                            tab: tab,
                            pool: pool,
                          )
                        : Text(tab.label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Session resolves, then the webview mounts a frame later.
    await tester.pump();
    await tester.pump();
  }

  /// The one live webview state, wherever it currently is.
  State webviewState(WidgetTester tester) =>
      tester.state(find.byType(CodeServerWebView, skipOffstage: false));

  void select(EditorTab tab) => layout.focusOrOpenInLeaf(
    layout.leafIdContaining(tab)!,
    (t) => identical(t, tab),
    () => tab,
  );

  testWidgets('switching code-server tabs moves one live webview', (
    tester,
  ) async {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    const chat = EditorTab(kind: 'chat', label: 'chat');
    await pumpWorkbench(tester, [a, b, chat]);
    final webview = webviewState(tester);
    pool.bridgeReady(pool.windowOf(a)!, 'w1');
    pool.windowReady(pool.windowOf(a)!);

    select(b);
    await tester.pump();
    expect(webviewState(tester), same(webview));
    expect(opens, ['w1:lib/b.dart']);
    expect(find.byType(CodeServerWebView), findsOneWidget);

    // A non-editor tab parks the window offstage, still alive.
    select(chat);
    await tester.pump();
    expect(find.byType(CodeServerWebView), findsNothing);
    expect(webviewState(tester), same(webview));

    select(a);
    await tester.pump();
    expect(find.byType(CodeServerWebView), findsOneWidget);
    expect(webviewState(tester), same(webview));
    expect(opens, ['w1:lib/b.dart', 'w1:lib/a.dart']);

    // Closing the tab that shows the window hands it to the next editor tab.
    layout.closeTabByIdentity(a);
    select(b);
    await tester.pump();
    expect(webviewState(tester), same(webview));
    expect(tester.takeException(), isNull);

    // Unmount so the webview's cover timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'preloaded webview paints behind chat, moves into first file unchanged, then parks offstage',
    (tester) async {
      const chat = EditorTab(kind: 'chat', label: 'chat');
      await pumpWorkbench(tester, [chat]);
      const target = CodeServerTarget(spaceId: 's1');
      pool.setPreloadTarget(target);

      bool webviewIsOffstage() => tester
          .widgetList<Offstage>(
            find.ancestor(
              of: find.byType(CodeServerWebView, skipOffstage: false),
              matching: find.byType(Offstage, skipOffstage: false),
            ),
          )
          .any((slot) => slot.offstage);
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.byType(CodeServerWebView, skipOffstage: false), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      await tester.pump();
      final window = pool.parked.single;
      expect(window.boot.path, isNull);
      expect(window.isBooting, isTrue);
      expect(find.text('chat'), findsWidgets);
      expect(find.byType(CodeServerWebView), findsOneWidget);
      expect(tester.getSize(find.byType(CodeServerWebView)).isEmpty, isFalse);
      expect(webviewIsOffstage(), isFalse);
      final webview = webviewState(tester);
      expect(resolutions, 1);

      final first = _file('lib/first.dart');
      layout.focusOrOpenInLeaf(layout.activeLeafId, (_) => false, () => first);
      await tester.pump();
      expect(pool.windowOf(first), same(window));
      expect(pool.parked, isEmpty);
      expect(webviewState(tester), same(webview));
      expect(
        resolutions,
        1,
        reason: 'adoption must not request a second session',
      );
      expect(
        opens,
        isEmpty,
        reason: 'the first file waits for bridge readiness',
      );
      pool.bridgeReady(window, 'w1');
      expect(opens, ['w1:lib/first.dart']);

      pool.windowReady(window);
      select(chat);
      await tester.pump();
      expect(pool.parked, [window]);
      expect(window.isBooting, isFalse);
      expect(find.byType(CodeServerWebView), findsNothing);
      expect(webviewState(tester), same(webview));
      expect(webviewIsOffstage(), isTrue);
      expect(resolutions, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('side-by-side panes of one worktree show two windows', (
    tester,
  ) async {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    await pumpWorkbench(tester, [a]);
    layout.openInSplit(layout.activeLeafId, b, DropEdge.right);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CodeServerWebView), findsNWidgets(2));
    expect(find.byType(CodeServerWindowView), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('the boot payload follows the window host, not the placeholder', () {
    final url = codeServerEmbedUrl(
      '/proxy/vscode/sid/?folder=%2Fw&payload='
      '${Uri.encodeQueryComponent('[["openFile","vscode-remote://remote/w/a.ts:3"]]')}',
      Uri.parse('http://localhost:4100/_cc_resource/cap/'),
    )!;
    final parsed = Uri.parse(url);
    expect(parsed.host, '127.0.0.1');
    expect(
      parsed.queryParameters['payload'],
      '[["openFile","vscode-remote://127.0.0.1:4100/w/a.ts:3"]]',
    );
    expect(parsed.path, '/_cc_resource/cap/proxy/vscode/sid/');
    expect(parsed.queryParameters['folder'], '/w');
  });

  test('a URL without a payload is left as is', () {
    expect(
      codeServerEmbedUrl(
        '/proxy/vscode/sid/?folder=%2Fw',
        Uri.parse('http://127.0.0.1:4100/_cc_resource/cap/'),
      ),
      'http://127.0.0.1:4100/_cc_resource/cap/proxy/vscode/sid/?folder=%2Fw',
    );
  });

  test('rejects absolute and missing-facade iframe URLs', () {
    final local = Uri.parse('http://127.0.0.1:4100/_cc_resource/cap/');
    expect(
      codeServerEmbedUrl('http://remote.example/proxy/vscode/sid/', local),
      isNull,
    );
    expect(codeServerEmbedUrl('/proxy/vscode/sid/', null), isNull);
    expect(
      codeServerEmbedUrl('//remote.example/proxy/vscode/sid/', local),
      isNull,
    );
  });
}
