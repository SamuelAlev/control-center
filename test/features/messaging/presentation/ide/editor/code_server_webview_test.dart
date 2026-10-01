import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_webview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

/// `flutter test` has no web view platform. This one renders nothing and keeps
/// the creation params so a test can fire the callbacks the native side would.
class _FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  PlatformInAppWebViewWidgetCreationParams? params;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    this.params = params;
    return _FakeInAppWebViewWidget(params);
  }
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

class _FakeController extends PlatformInAppWebViewController {
  _FakeController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 0),
      );
}

const _coverKey = Key('cover');

void main() {
  late _FakeInAppWebViewPlatform platform;
  final controller = InAppWebViewController.fromPlatform(
    platform: _FakeController(),
  );

  setUp(() {
    platform = _FakeInAppWebViewPlatform();
    InAppWebViewPlatform.instance = platform;
  });

  Future<void> pumpWebView(WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CodeServerWebView(
          url: 'http://127.0.0.1:1/proxy/vscode/sid/',
          cover: SizedBox(key: _coverKey),
        ),
      ),
    );
  }

  void log(String message) => platform.params!.onConsoleMessage!(
    controller,
    ConsoleMessage(message: message),
  );

  void failLoad({required bool mainFrame}) => platform.params!.onReceivedError!(
    controller,
    WebResourceRequest(
      url: WebUri('http://127.0.0.1:1/proxy/vscode/sid/'),
      isForMainFrame: mainFrame,
    ),
    WebResourceError(
      type: WebResourceErrorType.CANNOT_CONNECT_TO_HOST,
      description: 'refused',
    ),
  );

  testWidgets('stays covered until the bridge reports chrome hidden', (
    tester,
  ) async {
    await pumpWebView(tester);
    expect(find.byKey(_coverKey), findsOneWidget);

    log('%c[Extension Host] %cDart activated color: blue color: ');
    await tester.pump();
    expect(find.byKey(_coverKey), findsOneWidget);

    log(
      '%c[Extension Host] %c$codeServerChromeHiddenMarker '
      'color: blue color: ',
    );
    await tester.pump();
    expect(find.byKey(_coverKey), findsNothing);
  });

  testWidgets('a failed main-frame load uncovers its error page', (
    tester,
  ) async {
    await pumpWebView(tester);

    failLoad(mainFrame: false);
    await tester.pump();
    expect(find.byKey(_coverKey), findsOneWidget);

    failLoad(mainFrame: true);
    await tester.pump();
    expect(find.byKey(_coverKey), findsNothing);
  });

  testWidgets('uncovers after the timeout when no marker arrives', (
    tester,
  ) async {
    await pumpWebView(tester);

    await tester.pump(const Duration(seconds: 9));
    expect(find.byKey(_coverKey), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(_coverKey), findsNothing);
  });
}
