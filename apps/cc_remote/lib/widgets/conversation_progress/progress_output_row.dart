import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_artifact.dart';
import 'package:cc_remote/widgets/messaging/sent_attachments.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProgressOutputRow extends ConsumerWidget {
  const ProgressOutputRow({
    required this.scope,
    required this.message,
    required this.openedArtifactId,
    required this.onToggleArtifact,
    super.key,
  });

  final ProgressScope scope;
  final MessageDto message;
  final String? openedArtifactId;
  final ValueChanged<String> onToggleArtifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final raw = message.metadata;
    final meta = raw is Map ? raw.cast<String, dynamic>() : null;
    final attachments = MessageAttachment.attachmentsFromMetadata(meta);
    final planId = meta?['planId'];
    final artifactId = meta?['workProductId'];
    final references = <EntityRef>[
      for (final value in (meta?['entityRefs'] as List? ?? const []))
        if (value is Map) ?EntityRef.tryFromJson(value.cast<String, dynamic>()),
    ];
    final repos = references.isEmpty
        ? null
        : ref.watch(workspaceReposProvider).value;
    final text = message.content.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgPrimary,
          border: Border.all(color: t.borderSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planId is String
                    ? l.progressPlan
                    : artifactId is String
                    ? l.progressArtifact
                    : l.progressResult,
                style: CcTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              if (text.isNotEmpty)
                Text(
                  text.length > 320 ? '${text.substring(0, 320)}…' : text,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
              if (artifactId is String && artifactId.isNotEmpty) ...[
                CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.secondary,
                  onPressed: () => onToggleArtifact(artifactId),
                  child: Text(
                    openedArtifactId == artifactId
                        ? l.progressHideArtifact
                        : l.progressReadArtifact,
                  ),
                ),
                if (openedArtifactId == artifactId)
                  ProgressArtifact(scope: scope, artifactId: artifactId),
              ],
              if (attachments.isNotEmpty) ...[
                SentAttachments(
                  attachments: attachments,
                  workspaceId: scope.workspaceId,
                  alignEnd: false,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (planId is String && planId.isNotEmpty)
                    CcButton(
                      size: CcButtonSize.lg,
                      variant: CcButtonVariant.secondary,
                      onPressed: () => context.push(
                        remoteWorkspaceLocation(
                          '/plans/${Uri.encodeComponent(planId)}',
                          scope.workspaceId,
                        ),
                      ),
                      child: Text(l.progressOpenPlan),
                    ),
                  for (final reference in references)
                    if (reference.type == EntityRefType.pullRequest &&
                        int.tryParse(reference.id) != null)
                      for (final repo in repos ?? const <Repo>[])
                        if (repo.fullName == reference.repoFullName)
                          CcButton(
                            size: CcButtonSize.lg,
                            variant: CcButtonVariant.secondary,
                            onPressed: () => context.push(
                              remoteWorkspaceLocation(
                                '/pr/${Uri.encodeComponent(repo.id)}/${Uri.encodeComponent(reference.id)}',
                                scope.workspaceId,
                              ),
                            ),
                            child: Text(
                              l.progressOpenDiff(
                                reference.label ?? reference.id,
                              ),
                            ),
                          ),
                  CcButton(
                    size: CcButtonSize.lg,
                    variant: CcButtonVariant.secondary,
                    onPressed: () => context.push(
                      remoteSpaceLocation(
                        workspaceId: scope.workspaceId,
                        spaceId: scope.spaceId,
                        conversationId: scope.conversationId,
                        messageId: message.id,
                      ),
                    ),
                    child: Text(l.progressViewMessage),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
