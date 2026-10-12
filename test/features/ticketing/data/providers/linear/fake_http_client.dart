import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';

/// Hand-written [TestHttpClient] fake for the Linear adapter tests.
///
/// The adapter talks to Linear's GraphQL endpoint through exactly one method —
/// `post('', body: HttpBody.json(…))` — so a settable responder covers every
/// case the suite needs. Every request it sends is recorded in [requests] by
/// the base [TestHttpClient], so a surprising call site is visible when a test
/// fails.
class FakeHttpClient extends TestHttpClient {
  /// Creates a fake with no stub installed. Call [stubPost] or [stubPostError]
  /// before the adapter sends anything.
  FakeHttpClient()
    : super(
        // Never reached: [send] installs the responder before delegating, but
        // the base class requires a handler.
        handler: (_) => throw StateError(
          'FakeHttpClient has no stub. Call stubPost() or stubPostError() '
          'first.',
        ),
      );

  Future<HttpResponse> Function()? _responder;

  /// Makes the next (and every subsequent) `post` return the responder's
  /// response.
  void stubPost(Future<HttpResponse> Function() responder) {
    _responder = responder;
  }

  /// Makes `post` fail with [error] — the adapter's error-mapping paths.
  void stubPostError(Object error) {
    _responder = () => Future<HttpResponse>.error(error);
  }

  @override
  Future<HttpResponse> send(BaseHttpRequest request) async {
    final responder = _responder;
    if (responder == null) {
      throw StateError(
        'FakeHttpClient was sent ${request.method.value} ${request.url} with '
        'no stub. Call stubPost() or stubPostError() first.',
      );
    }
    handler = (_) => responder();
    return super.send(request);
  }
}
