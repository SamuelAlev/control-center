import 'package:flutter/widgets.dart';

/// A Navigator for the connect dialogs, on surfaces that have none.
///
/// The web gate keeps routing out of its `WidgetsApp` so the connected app's
/// router is the only thing syncing with the URL. A bare Navigator reports
/// nothing to the engine, and sits under the gate alone, so `rootNavigator`
/// lookups in the connected app still find its own.
class ConnectDialogHost extends StatelessWidget {
  /// Creates a host that rebuilds [builder] whenever it is rebuilt.
  const ConnectDialogHost({super.key, required this.builder});

  /// Builds the surface beneath any dialog.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => builder(context),
      ),
    );
  }
}
