import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen for managing teams.
class TeamsSettingsScreen extends ConsumerWidget {
  const TeamsSettingsScreen({super.key, this.workspaceId});

  final String? workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamsTitle)),
      body: const Center(
        child: Text('Teams — coming soon'), // TODO: i18n - add l10n key
      ),
    );
  }
}
