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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Option(
          value: ConnectModeSetting.hosted,
          selected: selected,
          enabled: enabled,
          title: l10n.connectModeHosted,
          hint: l10n.connectModeHostedDisclosure,
          onSelected: onSelected,
        ),
        _Option(
          value: ConnectModeSetting.off,
          selected: selected,
          enabled: enabled,
          title: l10n.connectModeOwn,
          hint: l10n.connectModeOwnHint,
          onSelected: onSelected,
        ),
        _Option(
          value: ConnectModeSetting.custom,
          selected: selected,
          enabled: enabled,
          title: l10n.connectModeCustom,
          hint: l10n.connectModeCustomHint,
          onSelected: onSelected,
        ),
        if (selected == ConnectModeSetting.custom)
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
                  enabled: enabled,
                  label: l10n.connectCustomUrlLabel,
                  hintText: 'https://connect.example.com',
                  keyboardType: TextInputType.url,
                  errorText: urlError,
                  helperText: isLoopbackConnectUrl(value.text)
                      ? l10n.connectCustomUrlLoopbackHint
                      : null,
                  onSubmitted: onUrlSubmitted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.title,
    required this.hint,
    required this.onSelected,
  });

  final ConnectModeSetting value;
  final ConnectModeSetting? selected;
  final bool enabled;
  final String title;
  final String hint;
  final ValueChanged<ConnectModeSetting> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final select = enabled ? () => onSelected(value) : null;
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
              CcRadio<ConnectModeSetting>(
                value: value,
                groupValue: selected,
                onChanged: enabled ? onSelected : null,
                semanticLabel: title,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CcTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled ? t.textPrimary : t.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      hint,
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
