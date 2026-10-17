import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_remote/credential_providers.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'harness_connection_flow.dart';
part 'harness_connection_forms.dart';
part 'harness_connection_view.dart';

/// Host-owned harness provider: keys are write-only; OAuth is completed by the
/// host and polled from this phone. No secrets survive a successful save.
class HarnessConnectionCard extends ConsumerStatefulWidget {
  const HarnessConnectionCard({
    required this.info,
    required this.workspaceId,
    required this.canManage,
    super.key,
  });

  final HarnessProviderInfo info;
  final String workspaceId;
  final bool canManage;

  @override
  ConsumerState<HarnessConnectionCard> createState() =>
      _HarnessConnectionCardState();
}

class _HarnessConnectionCardState extends ConsumerState<HarnessConnectionCard>
    with _HarnessConnectionFlow, _HarnessConnectionView {}
