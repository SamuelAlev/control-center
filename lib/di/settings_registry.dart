import 'package:control_center/features/agents/presentation/settings_contributions.dart';
import 'package:control_center/features/calendar/presentation/settings_contributions.dart';
import 'package:control_center/features/chat_bridges/presentation/settings_contributions.dart';
import 'package:control_center/features/forge/presentation/settings_contributions.dart';
import 'package:control_center/features/memory/presentation/settings_contributions.dart';
import 'package:control_center/features/messaging/presentation/settings_contributions.dart';
import 'package:control_center/features/newsfeed/presentation/settings_contributions.dart';
import 'package:control_center/features/remote_control/presentation/settings_contributions.dart';
import 'package:control_center/features/repos/presentation/settings_contributions.dart';
import 'package:control_center/features/rigs/presentation/settings_contributions.dart';
import 'package:control_center/features/sandboxing/presentation/settings_contributions.dart';
import 'package:control_center/features/settings/presentation/settings_contributions.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/teams/presentation/settings_contributions.dart';
import 'package:control_center/features/ticketing/presentation/settings_contributions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The composition root for the settings surface.
///
/// This is the ONE file that knows every feature contributing to settings, and
/// knowing every module is precisely its job — the same role `di/providers.dart`
/// plays for repository ports. Concentrating it here is the point of the
/// inversion: before, a dozen files under `settings/presentation/` each named
/// another feature's widgets, so the coupling was real but invisible, spread
/// across screens whose job was supposed to be layout.
///
/// It aggregates and nothing more. A feature decides WHAT it contributes, WHERE
/// it goes and what it is called, in its own `presentation/settings_contributions.dart`;
/// this file only concatenates those lists, so adding a section never means
/// editing a screen.
///
/// A provider rather than a top-level constant so a widget test can override it
/// — pumping the agent registry with `SettingsRegistry()` gives the bare screen
/// with no contributed tabs reaching for providers the test never stubbed.
final settingsRegistryProvider = Provider<SettingsRegistry>(
  (ref) => const SettingsRegistry(
    sections: [
      ...forgeSettingsSections,
      ...ticketingSettingsSections,
      ...calendarSettingsSections,
      ...chatBridgesSettingsSections,
      ...messagingSettingsSections,
    ],
    bodies: [
      ...agentsSettingsBodies,
      ...newsfeedSettingsBodies,
      ...remoteControlSettingsBodies,
      ...reposSettingsBodies,
      ...rigsSettingsBodies,
      ...sandboxingSettingsBodies,
    ],
    agentTabs: [...memoryAgentSettingsTabs, ...settingsAgentSettingsTabs],
    agentRegistryViews: [...agentsRegistryViews, ...teamsRegistryViews],
  ),
);
