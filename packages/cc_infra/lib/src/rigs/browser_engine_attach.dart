// Opens the protocol client for whichever browser a rig booted.
//
// One function, so nothing above it knows which of three protocols is on the
// wire — the driver holds a [BrowserEngineClient] and every verb below it is
// the same. Split out of `RigService` so the smoke tool drives the identical
// path: a rig cannot be booted in CI, and a second copy of "how do I attach to
// Firefox" in the one tool that CAN boot one is a copy that would be wrong
// exactly when it mattered.
library;

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/bidi_client.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';
import 'package:cc_infra/src/rigs/cdp_client.dart';
import 'package:cc_infra/src/rigs/rig_browser_defaults.dart';
import 'package:cc_infra/src/rigs/webdriver_client.dart';

/// Attaches to [engine]'s automation endpoint on [host]:[port].
///
/// [guestPort] is the port that endpoint believes it serves, INSIDE the guest.
/// It differs from [port] whenever a relay sits between them, and it is not
/// cosmetic: Firefox refuses a WebSocket upgrade whose `Host` header names any
/// other port, with a bare 400 and no diagnostic.
///
/// [timeout] is generous by default. The backend's readiness probe has already
/// covered the cold-start image pull and the package install, but a slow launch
/// still has to finish coming up before the endpoint takes a session.
Future<BrowserEngineClient> attachBrowserEngine({
  required RigBrowserEngine engine,
  required String host,
  required int port,
  required int guestPort,
  Duration timeout = const Duration(seconds: 75),
}) async {
  switch (engine) {
    case RigBrowserEngine.chromium:
      final cdp = await CdpClient.attachToFirstPage(
        host: host,
        port: port,
        timeout: timeout,
      );
      await cdp.enableDomains();
      return cdp;
    case RigBrowserEngine.firefox:
      return BidiClient.attach(
        host: host,
        port: port,
        guestPort: guestPort,
        timeout: timeout,
      );
    case RigBrowserEngine.webkit:
      final webdriver = await WebDriverClient.attach(
        host: host,
        port: port,
        // Longer: classic WebDriver LAUNCHES the browser when the session is
        // created, so this call covers a MiniBrowser start rather than just a
        // connect.
        timeout: timeout + const Duration(seconds: 45),
      );
      // Which is also why a WebKit rig has no page until now — the welcome
      // page cannot be opened by the workload the way the other two engines
      // open it. Best effort: a rig that came up but failed to show its home
      // page is still a working rig, and the first real navigation fixes it.
      try {
        await webdriver.navigate(kBrowserRigHomeUrl);
      } on Object catch (e) {
        CcInfraLog.warning(
          'rig: the WebKit rig did not open its welcome page ($e)',
        );
      }
      return webdriver;
  }
}
