import 'package:cc_connect_core/cc_connect_core.dart'
    show canonicalConnectOrigin, isLoopbackOrigin;
import 'package:cc_data/cc_data.dart' show ConnectModeSetting;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Whether [url] is a shape a custom Connect may have: an absolute HTTPS URL
/// with a host, or plain HTTP to a loopback address (a Connect running on
/// this machine) — the same rule the server applies.
bool isConnectServerUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return false;
  }
  return uri.scheme == 'https' ||
      (uri.scheme == 'http' && isLoopbackConnectUrl(url));
}

/// Whether [url] is plain HTTP to this machine's loopback.
bool isLoopbackConnectUrl(String url) {
  try {
    return Uri.parse(url.trim()).scheme == 'http' &&
        isLoopbackOrigin(canonicalConnectOrigin(url));
  } on FormatException {
    return false;
  }
}

/// Whether [url] is an absolute HTTPS URL with a host and nothing a Connect
/// base URL cannot carry: the shape a WORKSPACE's custom Connect must have.
/// Plain HTTP to loopback is a server owner's privilege, never a workspace's.
bool isHttpsConnectUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;
}

/// The three ways a server can sign people in to providers, as radio rows:
/// Control Center's apps (hosted Connect), the operator's own apps (Connect
/// off), or a Connect server at an HTTPS URL.
///
/// Shared by onboarding and Settings so the disclosure under "Use Control
/// Center's apps" is word for word the same in both. Nothing is preselected
/// when [selected] is null or [ConnectModeSetting.unset].
class ConnectModeOptions extends StatelessWidget {
  /// Creates the options.
  const ConnectModeOptions({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.urlController,
    this.enabled = true,
    this.urlError,
    this.onUrlSubmitted,
  });

  /// The chosen mode, or null for none.
  final ConnectModeSetting? selected;

  /// Picks a mode.
  final ValueChanged<ConnectModeSetting> onSelected;

  /// The custom Connect URL being typed.
  final TextEditingController urlController;

  /// False when `CC_CONNECT_URL` pins the configuration.
  final bool enabled;

  /// Why the typed URL is not acceptable, if it is not.
  final String? urlError;

  /// Called when the URL field is submitted.
  final ValueChanged<String>? onUrlSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConnectChoiceList<ConnectModeSetting>(
      selected: selected,
      onSelected: onSelected,
      urlChoice: ConnectModeSetting.custom,
      urlController: urlController,
      urlError: urlError,
      urlHelper: (url) =>
          isLoopbackConnectUrl(url) ? l10n.connectCustomUrlLoopbackHint : null,
      onUrlSubmitted: onUrlSubmitted,
      choices: [
        ConnectChoice(
          value: ConnectModeSetting.hosted,
          title: l10n.connectModeHosted,
          hint: l10n.connectModeHostedDisclosure,
          enabled: enabled,
        ),
        ConnectChoice(
          value: ConnectModeSetting.off,
          title: l10n.connectModeOwn,
          hint: l10n.connectModeOwnHint,
          enabled: enabled,
        ),
        ConnectChoice(
          value: ConnectModeSetting.custom,
          title: l10n.connectModeCustom,
          hint: l10n.connectModeCustomHint,
          enabled: enabled,
        ),
      ],
    );
  }
}

/// One radio row of a [ConnectChoiceList].
@immutable
class ConnectChoice<T> {
  /// Creates a choice.
  const ConnectChoice({
    required this.value,
    required this.title,
    required this.hint,
    this.enabled = true,
  });

  /// What picking it selects.
  final T value;

  /// The row's title.
  final String title;

  /// What it means, under the title.
  final String hint;

  /// False greys the row out and ignores taps.
  final bool enabled;
}

/// Radio rows for "whose apps sign people in", with the Connect URL field
/// under [urlChoice] while it is selected.
///
/// The server's card ([ConnectModeOptions]) and a workspace's card share it,
/// so the two choices look and read the same.
class ConnectChoiceList<T> extends StatelessWidget {
  /// Creates the list.
  const ConnectChoiceList({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
    required this.urlChoice,
    required this.urlController,
    this.urlError,
    this.urlHelper,
    this.onUrlSubmitted,
  });

  /// The rows, in display order.
  final List<ConnectChoice<T>> choices;

  /// The chosen value, or null for none.
  final T? selected;

  /// Picks a value.
  final ValueChanged<T> onSelected;

  /// The value that needs a Connect URL.
  final T urlChoice;

  /// The custom Connect URL being typed.
  final TextEditingController urlController;

  /// Why the typed URL is not acceptable, if it is not.
  final String? urlError;

  /// Helper text for what is typed, or null for none.
  final String? Function(String url)? urlHelper;

  /// Called when the URL field is submitted.
  final ValueChanged<String>? onUrlSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final urlEnabled = choices.any((c) => c.value == urlChoice && c.enabled);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final choice in choices) ...[
          _Option<T>(
            choice: choice,
            selected: selected,
            onSelected: onSelected,
          ),
          if (choice.value == urlChoice && selected == urlChoice)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 28,
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              // RTL carve-out: a URL reads left to right in every locale.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: urlController,
                  builder: (context, value, _) => CcTextField(
                    controller: urlController,
                    enabled: urlEnabled,
                    label: l10n.connectCustomUrlLabel,
                    hintText: 'https://connect.example.com',
                    keyboardType: TextInputType.url,
                    errorText: urlError,
                    helperText: urlHelper?.call(value.text),
                    onSubmitted: onUrlSubmitted,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Option<T> extends StatelessWidget {
  const _Option({
    required this.choice,
    required this.selected,
    required this.onSelected,
  });

  final ConnectChoice<T> choice;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final enabled = choice.enabled;
    final select = enabled ? () => onSelected(choice.value) : null;
    return MergeSemantics(
      child: GestureDetector(
        // The whole row is the target, not just the dot.
        onTap: select,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CcRadio<T>(
                value: choice.value,
                groupValue: selected,
                onChanged: enabled ? onSelected : null,
                semanticLabel: choice.title,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: CcTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled ? t.textPrimary : t.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      choice.hint,
                      style: CcTypography.caption.copyWith(
                        height: 1.45,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
