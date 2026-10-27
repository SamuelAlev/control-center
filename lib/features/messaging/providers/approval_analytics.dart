import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Records the user's answer to an agent approval request.
///
/// [surface] names where it was answered (`overlay`, `conversation`). Only
/// the request's IDs, severity and action classes are reported; its title,
/// detail and shell command are free text and never leave the client.
void trackApprovalDecision(
  WidgetRef ref,
  ConfirmationRequestDto request, {
  required bool approved,
  required bool remembered,
  required String surface,
}) => ref.track(
  AnalyticsEvents.approvalDecided(
    approved: approved,
    remembered: remembered,
    surface: surface,
    actionClasses: request.actionClasses,
    severity: request.severity,
    workspaceId: request.workspaceId,
    spaceId: request.spaceId,
    conversationId: request.conversationId,
  ),
);
