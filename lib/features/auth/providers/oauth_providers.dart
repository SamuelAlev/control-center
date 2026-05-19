import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How a provider signs a user in.
enum SignInFlow {
  /// A short code the human types on the provider's own page while the SERVER
  /// polls for the result. Needs no callback URL registered anywhere, which is
  /// what makes it work for a server on `127.0.0.1`, behind NAT, or driven
  /// from a phone.
  device,

  /// A browser round-trip back to the server's `/oauth/<provider>/callback`.
  redirect,
}

/// One provider this server can run a sign-in for.
class SignInProvider {
  /// Creates a [SignInProvider].
  const SignInProvider({
    required this.id,
    required this.flow,
    this.redirectUri = '',
  });

  /// The wire id (`github`, `linear`).
  final String id;

  /// Which flow it uses.
  final SignInFlow flow;

  /// The callback URL the operator registered, for the redirect flow. Empty
  /// for a device flow, which has none.
  final String redirectUri;
}

/// The providers this SERVER can run a browser sign-in for, keyed by wire id.
///
/// A provider in this map offers "sign in with …"; one outside it offers
/// "paste a token", which is the honest affordance for a server whose operator
/// has registered no app. Never completes with an error — an unreachable
/// server resolves to paste-only rather than to a broken card.
final signInProvidersProvider = FutureProvider<Map<String, SignInProvider>>((
  ref,
) async {
  try {
    final data = await ref
        .watch(rpcClientProvider)
        .call('oauth.providers', const {});
    final raw = data['providers'];
    if (raw is! List) {
      return const {};
    }
    final parsed = <String, SignInProvider>{};
    for (final entry in raw.whereType<Map<String, dynamic>>()) {
      final id = entry['provider'] as String? ?? '';
      if (id.isEmpty) {
        continue;
      }
      parsed[id] = SignInProvider(
        id: id,
        flow: entry['flow'] == 'device'
            ? SignInFlow.device
            : SignInFlow.redirect,
        redirectUri: entry['redirect_uri'] as String? ?? '',
      );
    }
    return parsed;
  } on Object {
    return const {};
  }
});

/// What a started sign-in needs from the human next.
sealed class SignInStarted {
  const SignInStarted();
}

/// A device flow: show [userCode] and send them to [verificationUri].
class SignInDeviceCode extends SignInStarted {
  /// Creates a [SignInDeviceCode].
  const SignInDeviceCode({
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
  });

  /// The code the human types on the provider's page.
  final String userCode;

  /// Where they type it.
  final String verificationUri;

  /// How long the code stays valid.
  final Duration expiresIn;
}

/// A redirect flow: the browser has been opened at the provider.
class SignInBrowserOpened extends SignInStarted {
  /// Creates a [SignInBrowserOpened].
  const SignInBrowserOpened({required this.opened});

  /// False when no browser could be opened at all.
  final bool opened;
}

/// Starts [provider]'s sign-in.
///
/// The credential never comes back through the app: for a device flow the
/// SERVER polls and stores it; for a redirect flow the browser talks to the
/// server's own callback. Either way the app learns the outcome by re-reading
/// its connection list — which is what lets the same flow work from a phone,
/// or from a browser that is not on the server's machine.
Future<SignInStarted> startProviderSignIn(
  WidgetRef ref,
  String provider,
) async {
  final data = await ref.read(rpcClientProvider).call('oauth.begin', {
    'provider': provider,
  });
  if (data['mode'] == 'device') {
    final code = data['user_code'] as String? ?? '';
    final uri = data['verification_uri'] as String? ?? '';
    // Open the page for them, but the dialog stays up either way: on a headless
    // host or a locked-down browser they can still type the URL themselves.
    if (uri.isNotEmpty) {
      openExternalUrl(uri);
    }
    return SignInDeviceCode(
      userCode: code,
      verificationUri: uri,
      expiresIn: Duration(
        seconds: (data['expires_in'] as num?)?.toInt() ?? 900,
      ),
    );
  }
  final url = data['url'] as String? ?? '';
  return SignInBrowserOpened(opened: url.isNotEmpty && openExternalUrl(url));
}

/// How long a started sign-in is waited on before the UI stops watching. The
/// login itself stays valid server-side for its own window; this is only about
/// how long a spinner is allowed to spin.
const Duration kSignInTimeout = Duration(minutes: 10);

/// Polls [isConnected] every two seconds until it answers true or
/// [kSignInTimeout] elapses.
///
/// Polling — rather than a push — because the sign-in finishes on the SERVER,
/// and the page the human is looking at is not the app.
Future<bool> awaitSignIn(Future<bool> Function() isConnected) async {
  final deadline = DateTime.now().add(kSignInTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (await isConnected()) {
      return true;
    }
  }
  return false;
}
