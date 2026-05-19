import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen for managing GitHub and ticketing provider credentials.
class ApiKeysScreen extends ConsumerWidget {
  /// Creates the API keys screen.
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiKeys)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: ApiKeysPanel(),
      ),
    );
  }
}
