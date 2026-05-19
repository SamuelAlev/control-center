// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get calendarViewMonth => 'Mois';

  @override
  String get calendarViewWeek => 'Semaine';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Connecter Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Synchronisez votre Google Calendar pour voir vos événements ici et être averti avant le début des réunions.';

  @override
  String get calendarDisconnect => 'Déconnecter';

  @override
  String get calendarReconnect => 'Reconnecter';

  @override
  String get calendarEmptyNoEvents => 'Aucun événement dans cette période';

  @override
  String get calendarStartRecording => 'Démarrer l\'enregistrement';

  @override
  String get calendarStartRecordingAndLink => 'Enregistrer et lier';

  @override
  String get calendarJoinMeet => 'Rejoindre la réunion';

  @override
  String get calendarFromCalendar => 'Depuis le calendrier';

  @override
  String get calendarLinkedMeeting => 'Réunion liée';

  @override
  String get calendarToday => 'Aujourd\'hui';

  @override
  String get calendarAllDay => 'Toute la journée';

  @override
  String calendarWeekNumber(int number) {
    return 'Semaine $number';
  }

  @override
  String get calendarPreviousPeriod => 'Précédent';

  @override
  String get calendarNextPeriod => 'Suivant';

  @override
  String calendarLastSynced(String time) {
    return 'Synchronisé $time';
  }

  @override
  String get calendarNeverSynced => 'Pas encore synchronisé';

  @override
  String get calendarSyncing => 'Synchronisation…';

  @override
  String get calendarViewDay => 'Jour';

  @override
  String get calendarSectionCalendars => 'Calendriers';

  @override
  String get calendarShow => 'Afficher';

  @override
  String get calendarHide => 'Masquer';

  @override
  String get calendarRsvpGoing => 'Présent ?';

  @override
  String get calendarRsvpYes => 'Oui';

  @override
  String get calendarRsvpNo => 'Non';

  @override
  String get calendarRsvpMaybe => 'Peut-être';

  @override
  String get calendarRsvpFailed => 'Impossible de mettre à jour votre réponse';

  @override
  String get calendarAddAccount => 'Ajouter un compte de calendrier';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Connectez un compte Google pour synchroniser les événements dans cet espace de travail.';

  @override
  String get calendarNotConnected => 'Aucun compte Google connecté';

  @override
  String get calendarConnecting => 'Connexion…';

  @override
  String get calendarSyncNow => 'Synchroniser';

  @override
  String get calendarNoWorkspace =>
      'Sélectionnez un espace de travail pour voir son calendrier';

  @override
  String get calendarConnectError => 'Impossible de connecter Google Calendar';

  @override
  String get notificationMeetingStartsSoon => 'Réunion imminente';

  @override
  String get notifyMeetingStartsSoon =>
      'Lorsqu\'une réunion du calendrier est sur le point de commencer';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Agenda déconnecté';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Reconnectez $email pour reprendre la synchronisation';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Reconnectez votre agenda pour reprendre la synchronisation';

  @override
  String get notifyCalendarAuthExpired =>
      'Lorsqu\'un compte d\'agenda doit être reconnecté';

  @override
  String get calendarAlertLeadTime => 'Délai d\'alerte';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Combien de temps avant une réunion vous prévenir';

  @override
  String calendarConnectedAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count participants';
  }

  @override
  String get calendarEventLabel => 'Événement';

  @override
  String get calendarRecurring => 'Événement récurrent';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisateur';

  @override
  String get calendarYou => 'Vous';

  @override
  String get calendarShowFewer => 'Afficher moins';

  @override
  String get calendarRsvpAwaiting => 'En attente';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Voir les $count participants';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count oui';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count non';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count peut-être';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count en attente';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutes';
  }

  @override
  String get openInEditorPrompt => 'Ouvrir dans quel éditeur ?';

  @override
  String get ideNotInstalled => 'Non installé';

  @override
  String openInIde(String editor) {
    return 'Ouvrir dans $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Impossible d\'ouvrir $editor : $error';
  }

  @override
  String get profileSearchHint => 'Rechercher des pull requests…';

  @override
  String get profileClickToLoad => 'Cliquer pour charger';

  @override
  String get profileStateOpenHint => 'Actuellement ouvertes';

  @override
  String get profileStateMergedHint => 'Historique fusionné';

  @override
  String get profileStateClosedHint => 'Fermées, non fusionnées';

  @override
  String get profileNoPrsForFilter =>
      'Aucune pull request pour les états sélectionnés';

  @override
  String get byAuthorPrefix => 'par';

  @override
  String get youLabel => 'vous';

  @override
  String get readyToMerge => 'Prêt à fusionner';

  @override
  String get laneReadyHint => 'Contrôles au vert';

  @override
  String get laneReviewHint => 'En attente de vous';

  @override
  String get inProgress => 'En cours';

  @override
  String get laneInProgressHint => 'Ouvert · en cours';

  @override
  String get needsAttention => 'Nécessite une attention';

  @override
  String get laneAttentionHint => 'En échec ou obsolète';

  @override
  String get drafts => 'Brouillons';

  @override
  String get laneDraftsHint => 'Pas encore ouvert';

  @override
  String get allOpenPrs => 'Toutes les PR ouvertes';

  @override
  String showAllCount(int count) {
    return 'Tout afficher ($count)';
  }

  @override
  String get sortOldest => 'Plus anciennes';

  @override
  String get sortLargest => 'Plus grandes';

  @override
  String get selectAction => 'Sélectionner';

  @override
  String mergeCountReady(int count) {
    return 'Fusionner $count prêtes';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '1 sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get mergeReadyAction => 'Fusionner prêtes';

  @override
  String get nothingInLane => 'Rien dans cette voie';

  @override
  String get nothingInLaneHint =>
      'Choisissez une autre voie ci-dessus, ou affichez toutes les PR ouvertes.';

  @override
  String get summary => 'Résumé';

  @override
  String get openFullDiff => 'Ouvrir le diff complet';

  @override
  String get viewFiles => 'Voir les fichiers';

  @override
  String get checksLabel => 'Contrôles';

  @override
  String get commentsLabel => 'Commentaires';

  @override
  String get mergeReadyConfirmTitle => 'Fusionner les PR prêtes ?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fusionner par squash $count PR prêtes ? Action irréversible.',
      one: 'Fusionner par squash 1 PR prête ? Action irréversible.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PR fusionnées',
      one: '1 PR fusionnée',
    );
    return '$_temp0';
  }

  @override
  String get keybindingSelectPr => 'Sélectionner la PR';

  @override
  String get keybindingMergePr => 'Fusionner la PR';

  @override
  String get keybindingPeekPr => 'Aperçu de la PR';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Basculer la sélection de la PR ciblée';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Fusionner la PR ciblée si elle est prête';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Développer ou réduire le panneau d\'aperçu de la PR ciblée';

  @override
  String get kbMove => 'déplacer';

  @override
  String get kbSelect => 'sélectionner';

  @override
  String get kbMerge => 'fusionner';

  @override
  String get kbOpen => 'ouvrir';

  @override
  String get kbPeek => 'aperçu';

  @override
  String get kbTabs => 'onglets';

  @override
  String get kbSearch => 'rechercher';

  @override
  String get kbViewed => 'vu';

  @override
  String get kbCollapse => 'réduire';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSettingsDescription => 'Thème, langue et typographie.';

  @override
  String get notificationsSettingsDescription =>
      'Choisissez les événements d\'agent et d\'espace de travail qui vous notifient.';

  @override
  String get integrationsSettingsDescription =>
      'Connectez GitHub, la billetterie et le serveur MCP.';

  @override
  String get advanced => 'Avancé';

  @override
  String get advancedSettingsDescription =>
      'Nommage des branches, voix, recherche sémantique, confidentialité et journalisation.';

  @override
  String get agentRegistry => 'Registre des agents';

  @override
  String get settingsGroupGeneral => 'Général';

  @override
  String get settingsGroupAgents => 'Agents';

  @override
  String get settingsGroupResources => 'Ressources';

  @override
  String get filterSettingsHint => 'Filtrer les paramètres';

  @override
  String get needsSetupLabel => 'Configuration requise';

  @override
  String noSettingsMatch(String query) {
    return 'Aucun paramètre ne correspond à « $query »';
  }

  @override
  String get privacy => 'Confidentialité';

  @override
  String get sendDiffContentTitle =>
      'Envoyer le contenu du diff à l\'adaptateur IA';

  @override
  String get diffSharingOnSubtitle =>
      'Les lignes de diff brutes sont incluses dans les invites des agents pour une revue approfondie.';

  @override
  String get diffSharingOffSubtitle =>
      'Les agents utilisent uniquement des métadonnées structurées (chemins de fichiers, numéros de ligne, description de la PR) ; aucun code brut ne quitte l\'application.';

  @override
  String get errorReportingTitle => 'Partager les rapports de plantage';

  @override
  String get errorReportingOnSubtitle =>
      'Les diagnostics de plantage, d\'erreur et de performance sont envoyés pour aider à corriger les bugs (versions de production uniquement).';

  @override
  String get errorReportingOffSubtitle =>
      'Les diagnostics sont désactivés. Aucun rapport de plantage ou d\'erreur n\'est envoyé.';

  @override
  String get onboardingDiagnosticsTitle => 'Aidez à améliorer Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Envoyez des diagnostics de plantage, d\'erreur et de performance pour nous aider à corriger les problèmes plus vite (versions de production uniquement). Vous pouvez modifier ce choix à tout moment dans Réglages → Confidentialité.';

  @override
  String get blocked => 'Bloqué';

  @override
  String get idle => 'Inactif';

  @override
  String get noRunsYet => 'Aucune exécution';

  @override
  String runsInLastSixMonths(String count) {
    return '$count exécutions au cours des 6 derniers mois';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Actif il y a $duration';
  }

  @override
  String get reportsToNobody => 'Aucun responsable';

  @override
  String get copyPath => 'Copier le chemin';

  @override
  String get pathCopied => 'Chemin copié dans le presse-papiers';

  @override
  String get editAgent => 'Modifier l\'agent';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get titleRequired => 'Le titre est requis';

  @override
  String get import => 'Importer';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count définitions d\'agent trouvées',
      one: '1 définition d\'agent trouvée',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'Aucun nouvel agent à importer';

  @override
  String get noAgentsToDiscoverHint =>
      'Les définitions d\'agent de cet espace de travail sont déjà importées.';

  @override
  String get sortByStatus => 'Statut';

  @override
  String get sortByName => 'Nom';

  @override
  String get noMatchingAgents => 'Aucun agent ne correspond à votre filtre';

  @override
  String get selectAnAgentHint =>
      'Choisissez un agent pour voir son statut, son activité et ses détails.';

  @override
  String watchVideoOn(String provider) {
    return 'Regarder la vidéo sur $provider';
  }

  @override
  String get branchTemplate => 'Modèle de nom de branche';

  @override
  String get branchTemplateDescription =>
      'Modèle de la branche créée au démarrage d\'un ticket dans un worktree isolé.';

  @override
  String branchTemplatePreview(String example) {
    return 'Exemple : $example';
  }

  @override
  String get deletePipelineRun => 'Supprimer l\'exécution du pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Supprimer cette exécution de « $template » ? Cette action est irréversible.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Erreur lors de la suppression de l\'exécution du pipeline : $error';
  }

  @override
  String get deleteTicket => 'Supprimer le ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Supprimer « $title » ? Cette action est irréversible.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Erreur lors de la suppression du ticket : $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Supprimer « $name » ? Les dépôts liés sur le disque ne sont pas affectés.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Erreur lors de la suppression de l\'espace de travail : $error';
  }

  @override
  String get indexCode => 'Indexer le code';

  @override
  String get indexing => 'Indexation…';

  @override
  String get indexNoGrammars => 'Grammaires de code non installées';

  @override
  String get indexFailed => 'Échec de l\'indexation';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symboles indexés';
  }

  @override
  String get nodeConfigAdvanced => 'Avancé';

  @override
  String get nodeConfigReducer => 'Réducteur';

  @override
  String get nodeConfigReducerHelp =>
      'Comment fusionner lorsque cette clé de sortie a déjà une valeur';

  @override
  String get nodeConfigTimeoutMs => 'Délai d\'expiration (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Tentatives de réessai';

  @override
  String get nodeConfigContinueOnFail => 'Continuer si cette étape échoue';

  @override
  String get nodeConfigTeamId => 'ID d\'équipe';

  @override
  String get nodeConfigDispatchMode => 'Mode de répartition';

  @override
  String get nodeConfigOutputSchema => 'Schéma de sortie (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Schéma JSON que la sortie de l\'étape doit respecter';

  @override
  String get diffLineDisplay => 'Lignes longues dans les diffs';

  @override
  String get diffLineDisplayDescription =>
      'Renvoyer les lignes longues à la ligne ou les faire défiler horizontalement';

  @override
  String get diffLineWrap => 'Renvoi à la ligne';

  @override
  String get diffLineScroll => 'Défilement horizontal';

  @override
  String get actions => 'Actions';

  @override
  String get activate => 'Activer';

  @override
  String get activity => 'Activité';

  @override
  String get activityLabel => 'ACTIVITÉ';

  @override
  String adRulesCount(int count) {
    return '$count règles de publicités';
  }

  @override
  String get adapter => 'Adaptateur';

  @override
  String get adapterLabel => 'Adaptateur';

  @override
  String get adapters => 'Adaptateurs';

  @override
  String get adaptersAutoDetected =>
      'Exécuteurs d\'agent auto-détectés disponibles sur cette machine. Installez les outils CLI manquants pour activer des exécuteurs supplémentaires.';

  @override
  String get add => 'Ajouter';

  @override
  String get addAComment => 'Ajouter un commentaire';

  @override
  String get addAReaction => 'Ajouter une réaction';

  @override
  String get addASuggestion => 'Ajouter une suggestion';

  @override
  String get addAgent => 'Ajouter un agent';

  @override
  String get addAgents => 'Ajouter des agents';

  @override
  String get addAgentsToEnable =>
      'Ajoutez des agents pour activer l\'orchestration multi-agents';

  @override
  String get addEmoji => 'Ajouter un émoji';

  @override
  String get addFeed => 'Ajouter un flux';

  @override
  String get addFromFile => 'Ajouter depuis un fichier';

  @override
  String get addGif => 'Ajouter un GIF';

  @override
  String get addGithubRepoPrompt =>
      'Ajoutez au moins un dépôt GitHub pour voir les demandes de tirage';

  @override
  String get addLocalCheckoutDescription =>
      'Ajoutez un checkout local pour commencer à le cibler depuis cet espace de travail.';

  @override
  String get addRepository => 'Ajouter un dépôt';

  @override
  String get addToken => 'Ajouter un jeton';

  @override
  String get addWorkspace => 'Ajouter un espace de travail';

  @override
  String get addWorkspaceEllipsis => 'Ajouter un espace de travail…';

  @override
  String get added => 'Ajouté';

  @override
  String get addingEllipsis => 'Ajout en cours...';

  @override
  String get advancedLabel => 'Avancé';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentMdPath => 'Chemin MD de l\'agent';

  @override
  String get agentName => 'Nom de l\'agent';

  @override
  String get agentTitle => 'Titre de l\'agent';

  @override
  String get agentUpdated => 'Agent mis à jour.';

  @override
  String get agents => 'Agents';

  @override
  String agentsCount(int count, num plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentsLabel => 'AGENTS';

  @override
  String get agentsMentionSection => 'Agents';

  @override
  String get aiReview => 'Revue IA';

  @override
  String get all => 'Tout';

  @override
  String get allAgentsAlreadyInChannel =>
      'Tous les agents sont déjà dans ce canal.';

  @override
  String allAgentsCount(int count) {
    return 'Tous les agents · $count';
  }

  @override
  String get allCommits => 'Tous les commits';

  @override
  String get allSessionsReset =>
      'Toutes les sessions du bac à sable ont été réinitialisées.';

  @override
  String get allSources => 'Toutes les sources';

  @override
  String get allStarBadge => 'Étoile';

  @override
  String get allTimeLabel => 'Tout';

  @override
  String get allow => 'Autoriser';

  @override
  String get allowGitPush => 'Autoriser git push';

  @override
  String get allowGithubApi => 'Autoriser les appels API GitHub';

  @override
  String get allowNetwork => 'Autoriser l\'accès réseau général';

  @override
  String get apiKeys => 'Clés API';

  @override
  String get appFont => 'Police de l\'app';

  @override
  String get appLogLevelDebugDescription =>
      'Ajoute les traces détaillées - pour le développement.';

  @override
  String get appLogLevelDebugLabel => 'Débogage';

  @override
  String get appLogLevelErrorDescription =>
      'Seulement les erreurs et exceptions inattendues.';

  @override
  String get appLogLevelErrorLabel => 'Erreur';

  @override
  String get appLogLevelInfoDescription =>
      'Ajoute les messages de cycle de vie et d\'état.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Aucune sortie console.';

  @override
  String get appLogLevelNoneLabel => 'Aucun';

  @override
  String get appLogLevelVerboseDescription =>
      'Tout. Extrêmement verbeux - à utiliser uniquement pour le débogage.';

  @override
  String get appLogLevelVerboseLabel => 'Verbeux';

  @override
  String get appLogLevelWarningDescription =>
      'Ajoute les avertissements et problèmes récupérables.';

  @override
  String get appLogLevelWarningLabel => 'Avertissement';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Apparence et langue';

  @override
  String get apply => 'Appliquer';

  @override
  String get approve => 'Approuver';

  @override
  String get approveAndCompact => 'Approuver et compacter le contexte';

  @override
  String get approveAndExecute => 'Approuver et exécuter';

  @override
  String get approveAndHire => 'Approuver et embaucher';

  @override
  String get approved => 'Approuvé';

  @override
  String get articlesSubscribed => 'Articles de vos flux abonnés.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'Demander une revue IA';

  @override
  String get askAiReviewDescription => 'Demander à l\'IA de relire cette PR';

  @override
  String get askAnything =>
      'Posez n\'importe quelle question… (@ pour mentionner des agents, / pour les commandes)';

  @override
  String get assignees => 'ASSIGNÉS';

  @override
  String get attachFiles => 'Joindre des fichiers';

  @override
  String get attachImage => 'Joindre une image';

  @override
  String get attachedAgents => 'Agents attachés';

  @override
  String get audioInput => 'Entrée audio';

  @override
  String get authentication => 'Authentification';

  @override
  String get authenticationToken => 'Jeton d\'authentification';

  @override
  String authoredByLabel(String role) {
    return 'Par : $role';
  }

  @override
  String get authorsLabel => 'Auteurs';

  @override
  String authorsWithCount(int count) {
    return 'Auteurs · $count';
  }

  @override
  String get autoRecommended => 'Auto (recommandé)';

  @override
  String get available => 'Disponible';

  @override
  String get avgDuration => 'Durée moyenne';

  @override
  String get awaitingYourApproval => 'En attente de votre approbation';

  @override
  String get awaitingYourReview => 'En attente de votre revue';

  @override
  String get back => 'Retour';

  @override
  String get backLabel => 'Retour';

  @override
  String get backend => 'Back-end';

  @override
  String get blockAdsDescription =>
      'Bloquer les publicités, les traqueurs et les bannières de cookies';

  @override
  String get blockAdsTrackers =>
      'Bloquer les publicités, traqueurs et bannières de cookies';

  @override
  String get blocking => 'Bloquant';

  @override
  String get blockingLabel => 'Bloquant';

  @override
  String get bookmarkLabel => 'Signet';

  @override
  String get briefDescription => 'Brève description';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Préchargé - jamais mis à jour';

  @override
  String get cached => 'En cache';

  @override
  String get cancel => 'Annuler';

  @override
  String get cancelEdit => 'Annuler l\'édition';

  @override
  String get categoryCreation => 'Création';

  @override
  String get categoryDeletion => 'Suppression';

  @override
  String get categoryEditing => 'Édition';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categorySystem => 'Système';

  @override
  String get categoryView => 'Vue';

  @override
  String get centurionBadge => 'Centurion';

  @override
  String get change => 'Modifier';

  @override
  String get changesRequested => 'Modifications demandées';

  @override
  String get changesSummary => 'Résumé des modifications';

  @override
  String get channelsMentionSection => 'Canaux';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get checking => 'Vérification';

  @override
  String get checkingEllipsis => 'Vérification…';

  @override
  String get checkingGhCli => 'Vérification de gh CLI…';

  @override
  String get chooseAppFont => 'Choisir la police de l\'application';

  @override
  String get chooseCodeFont => 'Choisir la police de code';

  @override
  String get chooseRunner => 'Choisissez votre exécuteur d\'agent.';

  @override
  String get clear => 'Effacer';

  @override
  String get clickToRetry => 'Cliquer pour réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get closeEsc => 'Fermer (Échap)';

  @override
  String get closeKeyboardHint => 'Fermer les raccourcis clavier';

  @override
  String get closePanel => 'Fermer le panneau';

  @override
  String get closeReader => 'Fermer le lecteur';

  @override
  String get closeThread => 'Fermer le fil';

  @override
  String get closed => 'Fermé';

  @override
  String get codeFont => 'Police de code';

  @override
  String get collapse => 'Réduire';

  @override
  String get commandPalette => 'Palette de commandes';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get commandsMentionSection => 'Commandes';

  @override
  String get comment => 'Commentaire';

  @override
  String get commentOnFile => 'Commenter ce fichier';

  @override
  String get commentOnThisFile => 'Commenter ce fichier';

  @override
  String get commentSelected => 'Commenter la sélection';

  @override
  String get commented => 'Commenté';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Affichage des $loaded derniers commits sur $total';
  }

  @override
  String get prCloneProgressCloningTitle => 'Clonage du dépôt';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Cette PR modifie $fileCount fichiers, dépassant la limite de l\'API GitHub. Clonage du dépôt en local…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Cette PR dépasse la limite de fichiers de l\'API GitHub. Clonage du dépôt en local…';

  @override
  String get prCloneProgressFetchingTitle => 'Récupération des refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Récupération de la branche de base et de la PR…';

  @override
  String get prCloneProgressComputingTitle => 'Calcul du diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Exécution de git diff en local…';

  @override
  String get prCloneProgressErrorTitle => 'Échec du chargement';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Une erreur est survenue lors du clonage ou du calcul du diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Toujours en cours… $elapsed écoulées';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confiance : $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configurer les identités, prompts, compétences des agents et voir les exécutions.';

  @override
  String get configureDefaultRunners =>
      'Configurez l\'adaptateur et le modèle utilisés pour les nouvelles conversations et la génération de titres.';

  @override
  String get configuredLabel => 'Configuré.';

  @override
  String get confirmedBy => 'Confirmé par';

  @override
  String get consensus => 'Consensus';

  @override
  String get contentBlockingDescription =>
      'Bloquer les publicités, traqueurs et bannières de cookies';

  @override
  String get contentHint => 'Ce qui doit être mémorisé';

  @override
  String get contentLabel => 'Contenu';

  @override
  String get contentMarkdown => 'Contenu (Markdown)';

  @override
  String get contextWindowSize => 'Taille de la fenêtre de contexte';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get conversationMode => 'Mode de conversation';

  @override
  String get convertToGroup => 'Convertir en groupe ?';

  @override
  String get convertToGroupBody =>
      'L\'ajout d\'un autre agent transforme cette conversation en conversation de groupe.';

  @override
  String cookieRulesCount(int count) {
    return '$count règles de cookies';
  }

  @override
  String get copied => 'Copié !';

  @override
  String get copy => 'Copier';

  @override
  String get copyBaseBranchTooltip => 'Copier le nom de la branche cible';

  @override
  String get copyHeadBranchTooltip => 'Copier le nom de la branche source';

  @override
  String get couldNotCheckGhCli => 'Impossible de vérifier gh CLI.';

  @override
  String couldNotListDevices(String error) {
    return 'Impossible de lister les périphériques : $error';
  }

  @override
  String get create => 'Créer';

  @override
  String get createFirstAgent => 'Créez votre premier agent pour commencer.';

  @override
  String get createOrSelectWorkspace =>
      'Créez ou sélectionnez un espace de travail avant d\'ajouter des dépôts.';

  @override
  String get createPr => 'Créer une PR';

  @override
  String get createPullRequest => 'Créer la pull request';

  @override
  String get createdByMe => 'Créées par moi';

  @override
  String createdLabel(String date) {
    return 'Créé : $date';
  }

  @override
  String get currentParticipants => 'Participants actuels';

  @override
  String get customCapabilitiesDescription =>
      'Capacités personnalisées pour cet agent';

  @override
  String get customSystemPrompt =>
      'Prompt système personnalisé pour cet agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Désactiver';

  @override
  String get defaultCapabilities =>
      'Capacités par défaut · nouvelles conversations';

  @override
  String get defaultChat => 'Chat par défaut';

  @override
  String defaultPort(int port) {
    return 'Par défaut : $port.';
  }

  @override
  String defaultPortHint(int port) {
    return 'Par défaut : $port.';
  }

  @override
  String get defaultRunners => 'Exécuteurs par défaut';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAgent => 'Supprimer l\'agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Supprimer « $name » ? Cette action est irréversible.';
  }

  @override
  String get deleteChannel => 'Supprimer le canal';

  @override
  String deleteConfirmName(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deleteConversation => 'Supprimer la conversation';

  @override
  String get deleteConversationConfirm =>
      'Supprimer cette conversation ? Tous les messages seront perdus.';

  @override
  String get deleteFact => 'Supprimer le fait';

  @override
  String get deleteFeedBody =>
      'Cela supprime le flux et tous ses articles en cache. Les articles mis en signet de ce flux seront également supprimés.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String deleteNamedConversation(String name) {
    return 'Supprimer \"$name\" ? Tous les messages seront perdus.';
  }

  @override
  String get deletePolicy => 'Supprimer la politique';

  @override
  String get deletePolicyConfirm =>
      'Supprimer cette politique ? Cette action est irréversible.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Supprimer \"$topic\" ? Cette action est irréversible.';
  }

  @override
  String get deleteWorkspace => 'Supprimer l\'espace de travail';

  @override
  String get deny => 'Refuser';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get detailsLabel => 'Détails';

  @override
  String detectedBackend(String label) {
    return 'Détecté : $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Exécuteurs détectés ($count)';
  }

  @override
  String get detectingAdapters => 'Détection des adaptateurs…';

  @override
  String get detectingGhCli => 'Détection de gh CLI…';

  @override
  String get detectingInputDevices => 'Détection des périphériques d\'entrée…';

  @override
  String detectionFailed(String error) {
    return 'Échec de la détection : $error';
  }

  @override
  String diffFailed(String message) {
    return 'Échec du diff : $message';
  }

  @override
  String get diffWorkerPool => 'Pool de travailleurs';

  @override
  String get directMessage => 'Message direct';

  @override
  String get directMessages => 'Messages directs';

  @override
  String get disabled => 'Désactivé';

  @override
  String get discover => 'Découvrir';

  @override
  String get discoverAgents => 'Découvrir les agents';

  @override
  String get discoverAgentsDescription =>
      'La découverte d\'agents recherche les fichiers AGENTS.md et TEAM.md dans les chemins de l\'espace de travail et les analyse dans le registre des agents.\n\nConfigurez d\'abord un espace de travail, puis utilisez cette fonctionnalité pour peupler automatiquement les agents.';

  @override
  String get dismissed => 'Rejeté';

  @override
  String get domainHint => 'ex : api-performance';

  @override
  String get domainLabel => 'Domaine';

  @override
  String get download => 'Télécharger';

  @override
  String get downloadingLabel => 'Téléchargement';

  @override
  String downloadingModel(int pct) {
    return 'Téléchargement du modèle… $pct %';
  }

  @override
  String get draft => 'Brouillon';

  @override
  String get draftLabel => 'Brouillon';

  @override
  String get earnTiersDescription =>
      'Gagnez des niveaux en utilisant le Control Center';

  @override
  String get edit => 'Modifier';

  @override
  String get editFact => 'Modifier le fait';

  @override
  String get editPolicy => 'Modifier la politique';

  @override
  String get editSuggestedCodeHint => 'Modifier le code suggéré...';

  @override
  String get editSuggestion => 'Modifier la suggestion';

  @override
  String get editTheSuggestedCodeHint => 'Modifier le code suggéré...';

  @override
  String get egArchitect => 'ex. architecte';

  @override
  String get egControlCenter => 'ex : control-center';

  @override
  String get egPlatform => 'ex : macOS';

  @override
  String get egSamuelAlev => 'ex : SamuelAlev';

  @override
  String get egSoftwareArchitect => 'ex. Architecte logiciel';

  @override
  String get egTheVerge => 'ex. The Verge';

  @override
  String get egTokenLimit => 'ex : 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get embeddingInstalled =>
      'Modèle d\'embedding local installé. La recherche hybride est activée.';

  @override
  String get embeddingModel => 'Modèle d\'embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Non installé. La recherche revient au mode mots-clés uniquement jusqu\'à l\'activation.';

  @override
  String get embeddingRedownloadBody =>
      'Les fichiers du modèle existant seront supprimés et téléchargés à nouveau. La recherche sémantique sera indisponible jusqu\'à la fin du téléchargement.';

  @override
  String get embeddingRemoveBody =>
      'La recherche sémantique sera désactivée jusqu\'à ce que vous la réinstalliez. Vous pouvez l\'installer à nouveau à tout moment.';

  @override
  String get speakerDiarization => 'Diarisation des locuteurs';

  @override
  String get diarizationModel => 'Modèle de diarisation';

  @override
  String get diarizationInstalled =>
      'Installé — nomme chaque locuteur dans les transcriptions de réunions';

  @override
  String get diarizationNotInstalled =>
      'Non installé — les locuteurs des réunions ne seront pas séparés';

  @override
  String diarizationInstallFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Re-télécharger le modèle de diarisation';

  @override
  String get diarizationRedownloadBody =>
      'Cela supprime les modèles de diarisation actuels et les télécharge à nouveau.';

  @override
  String get removeDiarizationModel => 'Supprimer le modèle de diarisation';

  @override
  String get diarizationRemoveBody =>
      'Cela supprime les modèles de diarisation sur l\'appareil. Les transcriptions de réunions déjà produites ne sont pas affectées.';

  @override
  String get onboardingDiarizationTitle =>
      'Diarisation des locuteurs (facultatif)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Téléchargez pour identifier chaque locuteur (Personne 1, Personne 2…) dans les notes de réunion. Vous pourrez l\'ajouter plus tard dans les paramètres.';

  @override
  String get enableMcpServer => 'Activer le serveur MCP';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get enableSandboxing => 'Activer le bac à sable';

  @override
  String get enabled => 'Activé';

  @override
  String enterToken(String name) {
    return 'Entrez le jeton $name';
  }

  @override
  String get enterTokenToAuth =>
      'Entrez un jeton pour exiger l\'authentification';

  @override
  String errorCreatingAgent(String error) {
    return 'Erreur lors de la création de l\'agent : $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Erreur lors de la suppression de l\'agent : $error';
  }

  @override
  String get errorLoadingAgents => 'Erreur lors du chargement des agents';

  @override
  String errorWithDetail(String error) {
    return 'Erreur : $error';
  }

  @override
  String get errored => 'En erreur';

  @override
  String get erroredLabel => 'En erreur';

  @override
  String get exitSelection => 'Quitter la sélection';

  @override
  String get expand => 'Développer';

  @override
  String get extractingLabel => 'Extraction';

  @override
  String extractingModel(int pct) {
    return 'Extraction du modèle… $pct %';
  }

  @override
  String get fact => 'Fait';

  @override
  String factCount(int count) {
    return '$count fait';
  }

  @override
  String factCountPlural(int count) {
    return '$count faits';
  }

  @override
  String get facts => 'Faits';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount faits · $policyCount politiques';
  }

  @override
  String get failed => 'Échoué';

  @override
  String failedToDispatch(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get failedToLoad => 'Échec du chargement';

  @override
  String failedToLoadAgents(String error) {
    return 'Échec du chargement des agents : $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Échec du chargement des flux : $error';
  }

  @override
  String get failedToLoadGifs => 'Échec du chargement des GIFs';

  @override
  String failedToLoadLogs(String error) {
    return 'Échec du chargement des journaux : $error';
  }

  @override
  String get failedToLoadRepos => 'Échec du chargement des dépôts';

  @override
  String get failedToLoadWorkspaces =>
      'Échec du chargement des espaces de travail';

  @override
  String failedToStartAiReview(String error) {
    return 'Échec du démarrage de la revue IA : $error';
  }

  @override
  String get failedToStartMicTest =>
      'Échec du démarrage du test du microphone.';

  @override
  String failedToSubmitReview(String error) {
    return 'Échec de la soumission de la revue : $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Échec du téléversement de $name : $error';
  }

  @override
  String failedWithError(String error) {
    return 'Échec : $error';
  }

  @override
  String get failure => 'Échec';

  @override
  String get feedAlreadyExists => 'Un flux avec cette URL existe déjà.';

  @override
  String get feedUrl => 'URL du flux';

  @override
  String get feedUrlExample => 'ex : https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Un flux avec cette URL existe déjà.';

  @override
  String get feedUrlLabel => 'URL du flux';

  @override
  String feedsCount(int count) {
    return 'Flux ($count)';
  }

  @override
  String get feedsLabel => 'Flux';

  @override
  String get filesChanged => 'Fichiers modifiés';

  @override
  String filesCount(int count) {
    return '$count fichier(s)';
  }

  @override
  String get filesMentionSection => 'Fichiers';

  @override
  String get filterAgents => 'Filtrer les agents...';

  @override
  String get filterAgentsPlaceholder => 'Filtrer les agents…';

  @override
  String get filterFilesHint => 'Filtrer les fichiers...';

  @override
  String get filterLists => 'Listes de filtrage';

  @override
  String get filterSkillsPlaceholder => 'Filtrer les compétences…';

  @override
  String get finish => 'Terminer';

  @override
  String get firstReviewBadge => 'Première revue';

  @override
  String get fix => 'Corriger';

  @override
  String get fixSelected => 'Corriger la sélection';

  @override
  String get flawlessBadge => 'Impeccable';

  @override
  String get forks => 'Forks';

  @override
  String get forward => 'Transférer';

  @override
  String get gatesGithubPatPush =>
      'Contrôle l\'injection du PAT GitHub. Requis pour que l\'agent puisse pousser.';

  @override
  String get general => 'Général';

  @override
  String get generalSettingsDescription =>
      'Apparence, typographie, intégrations et serveur MCP.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI est authentifié et prêt, mais un jeton d\'accès personnel est défini ci-dessous et sera utilisé à la place. Effacez le PAT pour utiliser l\'authentification gh CLI.';

  @override
  String get ghCliInstalledAuth =>
      'Installé. Exécutez `gh auth login`, puis appuyez sur Actualiser.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI n\'est pas installé — installez-le depuis cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI non installé';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'Intégration GitHub CLI';

  @override
  String get githubCliReady => 'GitHub CLI est authentifié et prêt.';

  @override
  String get githubLink => 'Lien GitHub';

  @override
  String get githubPersonalAccessToken => 'Jeton d\'accès personnel GitHub';

  @override
  String get githubStatusAllOperational => 'Tous les systèmes opérationnels';

  @override
  String get githubStatusComponents => 'Composants';

  @override
  String get githubStatusFetchFailed =>
      'Impossible de joindre githubstatus.com';

  @override
  String get githubStatusIncidents => 'Incidents actifs';

  @override
  String get githubStatusOpenInBrowser => 'Ouvrir githubstatus.com';

  @override
  String get githubStatusRefresh => 'Actualiser';

  @override
  String get githubStatusTitle => 'Statut de GitHub';

  @override
  String githubStatusUpdated(String time) {
    return 'Mis à jour $time';
  }

  @override
  String lastChecked(String time) {
    return 'Vérifié $time';
  }

  @override
  String get lastCheckedRecently => 'Vérifié récemment';

  @override
  String get githubToken => 'Jeton GitHub';

  @override
  String get giveAgentsAMemory => 'Donnez une mémoire aux agents.';

  @override
  String get giveYourWorkAHome => 'Donnez un foyer à votre travail.';

  @override
  String get goBack => 'Retourner en arrière';

  @override
  String get goForward => 'Avancer';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get groupLabel => 'Groupe';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get groups => 'Groupes';

  @override
  String get hideContainerTerminal => 'Masquer le terminal du conteneur';

  @override
  String get high => 'Élevé';

  @override
  String get hotStreakBadge => 'Série chaude';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String get idleStatus => 'Inactif';

  @override
  String get images => 'Images';

  @override
  String get inFlightLabel => 'En cours';

  @override
  String get inactive => 'Inactif';

  @override
  String get install => 'Installer';

  @override
  String get installGhCliBody =>
      'Installez gh depuis https://cli.github.com/ et exécutez `gh auth login`, puis appuyez sur Actualiser.';

  @override
  String get installRequired => 'Installation requise';

  @override
  String get installedNotSignedIn => 'Installé - non connecté';

  @override
  String installedVersion(String version) {
    return 'Installé $version';
  }

  @override
  String get integrations => 'Intégrations';

  @override
  String get invite => 'Inviter';

  @override
  String get inviteAgent => 'Inviter un agent';

  @override
  String get isolateAgentExecution => 'Isoler l\'exécution des agents.';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count tâche$_temp0';
  }

  @override
  String get justNow => 'à l\'instant';

  @override
  String get keepMessages => 'Conserver les messages';

  @override
  String get keepSandboxing => 'Conserver le bac à sable';

  @override
  String get keybindingAdapters => 'Adaptateurs';

  @override
  String get keybindingAddARepositoryDescription => 'Ajouter un dépôt';

  @override
  String get keybindingAddRepository => 'Ajouter un dépôt';

  @override
  String get keybindingAgents => 'Agents';

  @override
  String get keybindingApprove => 'Approuver';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Approuver la révision par les pairs';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Signet ou supprimer le signet de l\'article sélectionné';

  @override
  String get keybindingCommandPalette => 'Palette de commandes';

  @override
  String get keybindingConversationTab => 'Onglet conversation';

  @override
  String get keybindingCreateANewAgentDescription => 'Créer un nouvel agent';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Créer un nouveau canal de groupe';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Créer un nouvel espace de travail';

  @override
  String get keybindingDeleteAgent => 'Supprimer l\'agent';

  @override
  String get keybindingDeleteChannel => 'Supprimer le canal';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Supprimer l\'agent sélectionné';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Supprimer le canal sélectionné';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Supprimer l\'espace de travail sélectionné';

  @override
  String get keybindingDeleteWorkspace => 'Supprimer l\'espace de travail';

  @override
  String get keybindingFilesChangedTab => 'Onglet fichiers modifiés';

  @override
  String get keybindingFocusSearch => 'Aller à la recherche';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Activer le champ de recherche des pull requests';

  @override
  String get keybindingGeneral => 'Général';

  @override
  String get keybindingGoToAgents => 'Aller aux agents';

  @override
  String get keybindingGoToAnalytics => 'Aller à l\'analytique';

  @override
  String get keybindingGoToDashboard => 'Aller au tableau de bord';

  @override
  String get keybindingGoToMemory => 'Aller à la mémoire';

  @override
  String get keybindingGoToNewsfeed => 'Aller au fil d\'actualités';

  @override
  String get keybindingGoToPipelines => 'Aller aux pipelines';

  @override
  String get keybindingGoToPullRequests => 'Aller aux demandes de tirage';

  @override
  String get keybindingGoToTickets => 'Aller aux tickets';

  @override
  String get keybindingKeybindings => 'Raccourcis';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Naviguer vers le registre des agents';

  @override
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Naviguer vers le tableau de bord d\'analytique';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Naviguer vers le tableau de bord global';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Accéder à la base de connaissances mémoire';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Naviguer vers le fil d\'actualités';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Accéder à la liste des pipelines';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Naviguer vers la liste des demandes de tirage';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Accéder au tableau des tickets';

  @override
  String get keybindingNewAgent => 'Nouvel agent';

  @override
  String get keybindingNewDirectMessage => 'Nouveau message direct';

  @override
  String get keybindingNewGroup => 'Nouveau groupe';

  @override
  String get keybindingNewWorkspace => 'Nouvel espace de travail';

  @override
  String get keybindingNextArticle => 'Article suivant';

  @override
  String get keybindingNextChannel => 'Canal suivant';

  @override
  String get keybindingNextPr => 'PR suivante';

  @override
  String get keybindingNextWorkspace => 'Espace de travail suivant';

  @override
  String get keybindingOpenArticle => 'Ouvrir l\'article';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Ouvrir ou fermer le popup du sélecteur d\'espace dans la barre latérale';

  @override
  String get keybindingOpenPr => 'Ouvrir la PR';

  @override
  String get keybindingOpenSettings => 'Ouvrir les paramètres';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Ouvrir la page des paramètres des adaptateurs';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Ouvrir la page des paramètres des agents';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Ouvrir les paramètres de l\'application';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Ouvrir la palette de commandes';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Ouvrir la page des paramètres généraux';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Ouvrir la page des paramètres des raccourcis';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Ouvrir la page des paramètres des dépôts';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Ouvrir l\'article sélectionné';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Ouvrir la demande de tirage sélectionnée';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Ouvrir l\'espace de travail sélectionné';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Ouvrir la page des paramètres des compétences';

  @override
  String get keybindingOpenWorkspace => 'Ouvrir l\'espace de travail';

  @override
  String get keybindingPreviousArticle => 'Article précédent';

  @override
  String get keybindingPreviousChannel => 'Canal précédent';

  @override
  String get keybindingPreviousPr => 'PR précédente';

  @override
  String get keybindingPreviousWorkspace => 'Espace de travail précédent';

  @override
  String get keybindingRefresh => 'Actualiser';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Actualiser tous les flux';

  @override
  String get keybindingRefreshAnalyticsDataDescription =>
      'Actualiser les données d\'analytique';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Actualiser les données du tableau de bord';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Actualiser la liste des demandes de tirage';

  @override
  String get keybindingRemoveRepository => 'Retirer le dépôt';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Retirer le dépôt sélectionné';

  @override
  String get keybindingRepositories => 'Dépôts';

  @override
  String get keybindingRequestChanges => 'Demander des modifications';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Demander des modifications sur la révision par les pairs';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Rescanner les adaptateurs';

  @override
  String get keybindingSearchInDiff => 'Rechercher dans le diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Rechercher dans la vue du diff';

  @override
  String get keybindingToggleViewed => 'Basculer vu';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Marquer le fichier focalisé comme vu ou non vu';

  @override
  String get keybindingToggleCollapse => 'Basculer replier';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Replier ou développer le fichier focalisé';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Sélectionner l\'article suivant';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Sélectionner le canal suivant';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Sélectionner la demande de tirage suivante';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Sélectionner l\'article précédent';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Sélectionner le canal précédent';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Sélectionner la demande de tirage précédente';

  @override
  String get keybindingSendMessage => 'Envoyer le message';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Envoyer le message actuel';

  @override
  String get keybindingSkills => 'Compétences';

  @override
  String get keybindingStartANewDirectMessageDescription =>
      'Démarrer un nouveau message direct';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Basculer entre le mode clair et sombre';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Passer à l\'onglet de conversation';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Passer au huitième espace de travail';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Passer au cinquième espace de travail';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Passer à l\'onglet des fichiers modifiés';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Passer au premier espace de travail';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Passer au quatrième espace de travail';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Passer à l\'espace de travail suivant';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Passer au neuvième espace de travail';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Passer à l\'espace de travail précédent';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Passer au deuxième espace de travail';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Passer au septième espace de travail';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Passer au sixième espace de travail';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Passer au troisième espace de travail';

  @override
  String get keybindingToggleBookmark => 'Basculer le signet';

  @override
  String get keybindingToggleTheme => 'Basculer le thème';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Basculer le sélecteur d\'espace';

  @override
  String get keybindingWorkspace1 => 'Workspace1';

  @override
  String get keybindingWorkspace2 => 'Workspace2';

  @override
  String get keybindingWorkspace3 => 'Workspace3';

  @override
  String get keybindingWorkspace4 => 'Workspace4';

  @override
  String get keybindingWorkspace5 => 'Workspace5';

  @override
  String get keybindingWorkspace6 => 'Workspace6';

  @override
  String get keybindingWorkspace7 => 'Workspace7';

  @override
  String get keybindingWorkspace8 => 'Workspace8';

  @override
  String get keybindingWorkspace9 => 'Workspace9';

  @override
  String get keybindings => 'Raccourcis clavier';

  @override
  String get keybindingsDescription =>
      'Tous les raccourcis clavier. Les raccourcis sont fixes et ne peuvent pas être réassignés.';

  @override
  String get killRunning => 'Arrêter l\'exécution';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY non configurée';

  @override
  String get klipyNotConfiguredHint =>
      'Passez --dart-define=KLIPY_APP_KEY=...\nou définissez-la dans .env avant d\'exécuter.';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'Système';

  @override
  String lastMonths(int count) {
    return '$count derniers mois';
  }

  @override
  String get latestLabel => 'Récents';

  @override
  String get leaderboardLabel => 'CLASSEMENT';

  @override
  String get leaderboardLabelShort => 'Classement';

  @override
  String get leaveACommentEllipsis => 'Laisser un commentaire...';

  @override
  String get legendLabel => 'Légende';

  @override
  String get lessLabel => 'Moins';

  @override
  String get letsPluginTools => 'Connectons vos outils.';

  @override
  String get level => 'Niveau';

  @override
  String levelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String get liveDiff => 'Diff en direct';

  @override
  String get liveSync => 'Synchronisation en direct';

  @override
  String get loadingAgents => 'Chargement des agents…';

  @override
  String get loadingModels => 'Chargement des modèles…';

  @override
  String get lockedLabel => 'Verrouillé';

  @override
  String get logLevel => 'Niveau de journalisation';

  @override
  String get logs => 'Journaux';

  @override
  String get low => 'Faible';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get manageParticipants => 'Gérer les participants';

  @override
  String get manageWorkspaces => 'Gérer les espaces de travail';

  @override
  String get masterToggle => 'Interrupteur principal';

  @override
  String get matchOsAppearance =>
      'Adapter l\'apparence au système d\'exploitation ou choisir un mode fixe.';

  @override
  String get mcpActiveAccepting =>
      'Le serveur MCP est actif et accepte les connexions.';

  @override
  String get mcpAuthToken => 'Jeton d\'authentification MCP';

  @override
  String get mcpAuthentication => 'Authentification';

  @override
  String get mcpAutoStartDescription =>
      'Si désactivé, le serveur reste arrêté jusqu\'à ce que vous le démarriez.';

  @override
  String mcpDefaultPort(int port) {
    return 'Par défaut : $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Écoute sur 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Écoute sur 127.0.0.1:$port.';
  }

  @override
  String get mcpNotRunning =>
      'Le serveur n\'est pas en cours d\'exécution. Démarrez-le pour activer les connexions MCP.';

  @override
  String get mcpRestartPortChanges =>
      'Le serveur doit être redémarré pour appliquer les modifications de port.';

  @override
  String get mcpServer => 'Serveur MCP';

  @override
  String get mcpServerStopped => 'Le serveur est arrêté';

  @override
  String get mcpStatus => 'Statut';

  @override
  String get medium => 'Moyen';

  @override
  String get memoryDataHint =>
      'Les faits et les politiques apparaîtront ici au fur et à mesure que les agents travaillent.';

  @override
  String get memoryLabel => 'Mémoire';

  @override
  String get merge => 'Merge';

  @override
  String get mergeMasterBadge => 'Maître du merge';

  @override
  String get merged => 'Fusionné';

  @override
  String get messagePlaceholder =>
      'Message… (@ pour mentionner, / pour les commandes)';

  @override
  String get messagingLabel => 'Messagerie';

  @override
  String get microphonePermissionDenied =>
      'Autorisation du microphone refusée.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modèle';

  @override
  String get modified => 'Modifié';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count mois',
      one: 'il y a 1 mois',
    );
    return '$_temp0';
  }

  @override
  String get more => 'Plus';

  @override
  String get moreLabel => 'Plus';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nom';

  @override
  String get nameAndTitleRequired => 'Le nom et le titre sont requis.';

  @override
  String get nameAndUrlRequired => 'Le nom et l\'URL sont requis';

  @override
  String get nameLabel => 'Nom';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox natif disponible sur $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installation nécessaire pour le sandbox natif';

  @override
  String get navAnalytics => 'Analytique';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navSaved => 'Enregistrés';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navigateLabel => 'Naviguer';

  @override
  String networkBlockCount(int count) {
    return '$count blocages réseau';
  }

  @override
  String get neutral => 'Neutre';

  @override
  String get newAgent => 'Nouvel agent';

  @override
  String get newCommitsPushed =>
      'De nouveaux commits ont été poussés — cliquez pour recharger le diff';

  @override
  String get newFact => 'Nouveau fait';

  @override
  String get newGroup => 'Nouveau groupe';

  @override
  String get newLabel => 'Nouveau';

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get newPolicy => 'Nouvelle politique';

  @override
  String get newPrToReview => 'Nouvelle PR à relire';

  @override
  String get newsfeed => 'Fil d\'actualités';

  @override
  String get newsfeedLabel => 'Fil d\'actualités';

  @override
  String get newsfeedSettingsDescription =>
      'Gérez vos flux abonnés et vos préférences de lecteur.';

  @override
  String get newsfeedSettingsTitle => 'Paramètres du fil d\'actualités';

  @override
  String get nextMatch => 'Correspondance suivante (↵)';

  @override
  String get noAccessGrants => 'Aucune autorisation d\'accès configurée';

  @override
  String get noActiveWorkspace =>
      'Aucun espace de travail ou dépôt actif sélectionné.';

  @override
  String get noActiveWorkspaceCreate => 'Aucun espace de travail actif';

  @override
  String get noActiveWorkspaceGithub =>
      'Aucun espace de travail actif avec un dépôt GitHub.';

  @override
  String get noAgentAssigned => 'Aucun agent assigné';

  @override
  String get noAgentProcessesRunning =>
      'Aucun processus d\'agent en cours d\'exécution';

  @override
  String get noAgents => 'Aucun agent';

  @override
  String get noAgentsConfigured => 'Aucun agent configuré';

  @override
  String get noAgentsDiscovered => 'Aucun agent découvert';

  @override
  String get noAgentsDiscoveredHint =>
      'Cliquez sur \"Découvrir\" pour rechercher des fichiers AGENTS.md ou \"Ajouter un agent\" pour en configurer un manuellement';

  @override
  String get noAgentsMatchSearch =>
      'Aucun agent ne correspond à votre recherche';

  @override
  String get noAgentsRegisteredYet => 'Aucun agent enregistré pour l\'instant';

  @override
  String get noArticlesYet => 'Aucun article pour l\'instant';

  @override
  String get noArticlesYetBody => 'Les articles de vos flux apparaîtront ici.';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get noDirectMessagesYet => 'Aucun message direct pour l\'instant';

  @override
  String get noDomains => 'Aucun domaine pour l\'instant';

  @override
  String get noExecutionLogsYet => 'Aucun journal d\'exécution pour l\'instant';

  @override
  String get noFacts => 'Aucun fait pour l\'instant';

  @override
  String get noFeedsYet => 'Aucun flux pour l\'instant';

  @override
  String get noFileAnchor =>
      'Aucune ancre de fichier — impossible de publier un commentaire en ligne.';

  @override
  String get noFileChangesInScope =>
      'Aucune modification de fichier dans cette portée';

  @override
  String get noGifsFound => 'Aucun GIF trouvé';

  @override
  String get noGroupsYet => 'Aucun groupe pour l\'instant';

  @override
  String get noInputDevicesDetected =>
      'Aucun périphérique d\'entrée détecté — utilisation de la valeur par défaut du système.';

  @override
  String get noMatchingFiles => 'Aucun fichier correspondant';

  @override
  String get noMatchingGoogleFonts =>
      'Aucune correspondance dans Google Fonts.';

  @override
  String get noMemoryData => 'Aucune donnée de mémoire pour l\'instant';

  @override
  String get noMessagesYet => 'Aucun message pour l\'instant';

  @override
  String get noModelsAdvertised => 'Aucun modèle annoncé par cet adaptateur.';

  @override
  String get noOpenPullRequests => 'Aucune pull request ouverte';

  @override
  String get noPolicies => 'Aucune politique pour l\'instant';

  @override
  String get noReposInWorkspaceYet =>
      'Aucun dépôt dans cet espace de travail pour l\'instant';

  @override
  String get noRunnersDetected =>
      'Aucun exécuteur détecté pour l\'instant. Actualisez pour scanner à nouveau.';

  @override
  String get noSavedArticles => 'Aucun article enregistré';

  @override
  String get noSavedArticlesBody =>
      'Les articles que vous enregistrez apparaîtront ici.';

  @override
  String noShortcutsMatch(String query) {
    return 'Aucun raccourci ne correspond à « $query »';
  }

  @override
  String get noSystemFonts => 'Aucune police système détectée.';

  @override
  String get noTokenSet => 'Aucun jeton défini — l\'accès est illimité.';

  @override
  String get noTokenSetUnrestricted =>
      'Aucun jeton défini — l\'accès est non restreint.';

  @override
  String get noTokenUnrestricted => 'Aucun jeton — l\'accès est non restreint';

  @override
  String get noWorkingMemory =>
      'Aucune note de mémoire de travail pour l\'instant.';

  @override
  String get noneAllRoles => 'Aucun (tous les rôles)';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get notConfiguredLabel => 'Non configuré.';

  @override
  String get notDetected => 'Non détecté';

  @override
  String get notEarnedYet => 'Pas encore obtenu';

  @override
  String get notFoundLabel => 'Non trouvé';

  @override
  String get notYetSpawned => 'Pas encore lancé';

  @override
  String get notes => 'Notes';

  @override
  String get notificationAgentFinished => 'Agent terminé';

  @override
  String get notificationExternalPr => 'PR externes';

  @override
  String get notificationNewMessages => 'Nouveaux messages';

  @override
  String get notificationPrMerged => 'PR fusionnée';

  @override
  String get notificationPrPublished => 'PR publiée';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyAgentRunCompleted =>
      'Notifier lorsqu\'un agent termine une exécution.';

  @override
  String get notifyExternalPr =>
      'Notifier lorsqu\'une nouvelle PR est détectée par le sondage.';

  @override
  String get notifyNewMessages =>
      'Notifier pour les nouveaux messages d\'agent dans d\'autres canaux.';

  @override
  String get notifyPrMerged =>
      'Notifier lorsqu\'une demande de tirage est fusionnée.';

  @override
  String get notifyPrPublished =>
      'Notifier lorsqu\'un agent publie une demande de tirage.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center peut utiliser des conteneurs Linux pour isoler l\'exécution des agents.';

  @override
  String get onboardingMacosDescription =>
      'Control Center utilise le sandbox natif sur macOS pour isoler l\'exécution des agents.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox non disponible sur cette plateforme. L\'exécution des agents se fera sans isolation.';

  @override
  String get openAction => 'Ouvrir';

  @override
  String get openApplicationSettings =>
      'Ouvrir les paramètres de l\'application';

  @override
  String get openArticlesBrowserFallback =>
      'Ouvrir l\'article dans le navigateur';

  @override
  String get openArticlesInApp => 'Ouvrir les articles dans l\'application';

  @override
  String get openContainerTerminal => 'Ouvrir le terminal du conteneur';

  @override
  String get openFolder => 'Ouvrir le dossier';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get openLabel => 'Ouvert';

  @override
  String get openOnGithub => 'Ouvrir sur GitHub';

  @override
  String get openStatus => 'Ouvert';

  @override
  String get optionalPersonaDescription =>
      'Description de personnalité optionnelle';

  @override
  String get otherLabel => 'Autre';

  @override
  String get ownerOrganization => 'Propriétaire / Organisation';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Analyse du diff…';

  @override
  String get passed => 'Réussi';

  @override
  String get pasteTokenHere => 'Coller le jeton ici';

  @override
  String get pasteValueHere => 'Coller la valeur ici';

  @override
  String get patNotNeededGhCli => 'Non nécessaire — gh CLI est connecté.';

  @override
  String get patOverridesGhCli => 'Configuré — remplace gh CLI.';

  @override
  String get pathLabel => 'Chemin';

  @override
  String get pendingApproval => 'En attente de votre approbation';

  @override
  String get perfectionistBadge => 'Perfectionniste';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona :';

  @override
  String get personaOptional => 'Personnalité (optionnel)';

  @override
  String get personalAccessTokenOptional =>
      'Jeton d\'accès personnel (optionnel)';

  @override
  String get planLabel => 'Plan';

  @override
  String get policies => 'Politiques';

  @override
  String get policiesHint =>
      'Les politiques apparaîtront ici une fois que les agents auront promu des faits.';

  @override
  String get policy => 'Politique';

  @override
  String get popular => 'Populaire';

  @override
  String get port => 'Port';

  @override
  String get portLabel => 'Port';

  @override
  String get postingEllipsis => 'Publication...';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'Description de la PR en Markdown...';

  @override
  String get prDraftCreated => 'Brouillon de PR créé';

  @override
  String get prMachineBadge => 'Machine à PR';

  @override
  String get prMergedBody => 'Une demande de tirage a été fusionnée';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'Titre de la PR';

  @override
  String get previewLabel => 'Aperçu';

  @override
  String get previousArticle => 'Article précédent';

  @override
  String get previousChannel => 'Canal précédent';

  @override
  String get previousMatch => 'Correspondance précédente (⇧↵)';

  @override
  String get previousPr => 'PR précédente';

  @override
  String get previousWorkspace => 'Espace précédent';

  @override
  String get priorityReviews => 'Revues prioritaires';

  @override
  String get priorityReviewsDescription =>
      'Revues prioritaires et aperçu du dépôt.';

  @override
  String get progressLabel => 'Progression';

  @override
  String get proposeToCreateDomain =>
      'Proposez un fait ou une politique pour en créer un.';

  @override
  String get prsCreated => 'PRs créées';

  @override
  String get prsCreatedLabel => 'PRs créées';

  @override
  String get prsMerged => 'PRs fusionnées';

  @override
  String get publishToGithub => 'Publier sur GitHub';

  @override
  String get published => 'Publié';

  @override
  String get pullRequestApproved => 'Demande de tirage approuvée';

  @override
  String get pullRequests => 'Demandes de tirage';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get queued => 'En file d\'attente';

  @override
  String get react => 'Réagir';

  @override
  String get readPrsIssuesMetadata =>
      'Permet à l\'agent de lire les PR, les incidents et les métadonnées du dépôt.';

  @override
  String get readerPreferences => 'Préférences du lecteur';

  @override
  String get reasoningEffort => 'Effort de raisonnement';

  @override
  String get recommendLabel => 'RECOMMANDATION';

  @override
  String recordingFromDevice(String device) {
    return 'Enregistrement depuis $device.';
  }

  @override
  String get redownload => 'Retélécharger';

  @override
  String get redownloadEmbeddingModel =>
      'Télécharger à nouveau le modèle d\'intégration ?';

  @override
  String get redownloadVoiceModel => 'Télécharger à nouveau le modèle vocal ?';

  @override
  String get refinePlan => 'Affiner le plan';

  @override
  String get refiningPlan => 'Affinement du plan…';

  @override
  String get refresh => 'Actualiser';

  @override
  String get refreshAll => 'Tout actualiser';

  @override
  String get refreshAllFeeds => 'Actualiser tous les flux';

  @override
  String get refreshLabel => 'Actualiser';

  @override
  String get refreshPrData => 'Actualiser les données PR';

  @override
  String get reject => 'Rejeter';

  @override
  String get rejected => 'Rejeté';

  @override
  String get reload => 'Recharger';

  @override
  String get remove => 'Retirer';

  @override
  String get removeBookmark => 'Retirer le signet';

  @override
  String get removeEmbeddingModel => 'Supprimer le modèle d\'intégration ?';

  @override
  String get removeLogo => 'Supprimer le logo';

  @override
  String get removeRepoFromWorkspace =>
      'Retirer le dépôt de l\'espace de travail ?';

  @override
  String get removeRepository => 'Retirer le dépôt';

  @override
  String get removeRepositoryConfirm =>
      'Retirer le dépôt de l\'espace de travail ?';

  @override
  String get removeVoiceModel => 'Supprimer le modèle vocal ?';

  @override
  String get removed => 'Supprimé';

  @override
  String get renamed => 'Renommé';

  @override
  String get reopen => 'Rouvrir';

  @override
  String get replyEllipsis => 'Répondre…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name sera retiré de cet espace de travail. Les fichiers locaux sur le disque ne sont pas modifiés.';
  }

  @override
  String get reportsTo => 'Rapporte à';

  @override
  String get reportsToOptional => 'Rapporte à (facultatif)';

  @override
  String reposCount(int count) {
    return 'Dépôts ($count)';
  }

  @override
  String get reposDescription =>
      'Les checkouts locaux ciblés par cet espace de travail.';

  @override
  String get repositories => 'Dépôts';

  @override
  String get repositoriesSettings => 'Paramètres des dépôts';

  @override
  String get repositoryName => 'Nom du dépôt';

  @override
  String get requestChanges => 'Demander des modifications';

  @override
  String get requested => 'Demandé';

  @override
  String get requestedChanges => 'Modifications demandées';

  @override
  String get requiredIfGhCliUnavailable =>
      'Requis si gh CLI n\'est pas disponible';

  @override
  String requiredRoleLabel(String role) {
    return 'Rôle requis : $role';
  }

  @override
  String get requiredRoleOptional => 'Rôle requis (facultatif)';

  @override
  String get requirements => 'Exigences';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetAllSandboxes => 'Réinitialiser tous les bacs à sable';

  @override
  String get resolve => 'Résoudre';

  @override
  String get resolved => 'Résolu';

  @override
  String get restartServerToApply =>
      'Redémarrez le serveur pour appliquer les modifications.';

  @override
  String get restartShell => 'Redémarrer le shell';

  @override
  String get restartToApply =>
      'Redémarrez le serveur pour appliquer les modifications.';

  @override
  String get retry => 'Réessayer';

  @override
  String get review => 'Revue';

  @override
  String get reviewChanges => 'Examiner les modifications';

  @override
  String get reviewedByMe => 'Revues par moi';

  @override
  String get reviewers => 'RELECTEURS';

  @override
  String get reviewersActive => 'Relecteurs actifs';

  @override
  String get reviewsLabel => 'Revues';

  @override
  String get roleLabel => 'Rôle';

  @override
  String get ruleHint => 'La règle de la politique (markdown pris en charge)';

  @override
  String get ruleLabel => 'Règle';

  @override
  String get runCompleted => 'Exécution terminée';

  @override
  String get runGhAuthLoginBody =>
      'Exécutez `gh auth login` dans votre terminal, puis appuyez sur Actualiser.';

  @override
  String get running => 'En cours';

  @override
  String get runningLabel => 'en cours';

  @override
  String get runningStatus => 'En cours';

  @override
  String get runs => 'Exécutions';

  @override
  String get runsAcrossAllAgents => 'Exécutions sur tous les agents';

  @override
  String get runsLabel => 'Exécutions';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Le sandbox natif sur Linux/WSL2 utilise bubblewrap. Installez avec :\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Le sandbox natif est intégré à macOS — utilise Apple Seatbelt (`sandbox-exec`). Aucune installation requise.';

  @override
  String get sandboxPermissions => 'Permissions du sandbox';

  @override
  String get sandboxUnsupported =>
      'Le sandbox natif n\'est pas encore pris en charge sur cette plateforme. Revient à \"Pas d\'isolation\".';

  @override
  String get sandboxing => 'Bac à sable';

  @override
  String get sandboxingDescription =>
      'Exécutez les agents dans un sandbox au niveau du système d\'exploitation afin qu\'ils ne puissent pas toucher à votre dossier personnel, vos clés SSH ou vos tokens non accordés.';

  @override
  String get sandboxingDisabledDescription =>
      'Les agents s\'exécutent directement sur l\'hôte avec un environnement complet — non recommandé.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Toutes les invocations d\'agents sont acheminées via $backend.';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get savedArticlesDescription =>
      'Articles que vous avez mis en signet.';

  @override
  String get savedLabel => 'Enregistrés';

  @override
  String get savingChanges => 'Enregistrement des modifications...';

  @override
  String get savingEllipsis => 'Enregistrement…';

  @override
  String get scopeDiffToCommits =>
      'Limiter le diff aux commits — Shift+clic pour une plage';

  @override
  String get searchAgents => 'Rechercher des agents';

  @override
  String get searchAuthors => 'Rechercher des auteurs…';

  @override
  String get searchPullRequestsHint => 'Rechercher… p. ex. author:@user';

  @override
  String get noPrsMatchSearch => 'Aucune pull request correspondante';

  @override
  String get noPrsMatchSearchHint =>
      'Aucune PR ouverte ne correspond à votre recherche. Essayez d\'autres termes ou effacez la recherche.';

  @override
  String get searchAuthorsPlaceholder => 'Rechercher des auteurs…';

  @override
  String get searchFactsHint => 'Rechercher des faits...';

  @override
  String get searchFonts => 'Rechercher des polices…';

  @override
  String get searchGifs => 'Rechercher des GIFs';

  @override
  String get searchGifsHint => 'Rechercher des GIFs...';

  @override
  String get searchInDiff => 'Rechercher dans le diff';

  @override
  String get searchInDiffHint => 'Rechercher dans le diff...';

  @override
  String get searchOrTypeModel => 'Rechercher ou saisir un nom de modèle…';

  @override
  String get searchPlaceholder => 'Rechercher...';

  @override
  String get searchShortcuts => 'Rechercher des raccourcis…';

  @override
  String get searching => 'Recherche en cours...';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count secondes',
      one: 'il y a 1 seconde',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Sélectionner un adaptateur';

  @override
  String get selectAdapterFirst => 'Sélectionnez d\'abord un adaptateur';

  @override
  String get selectAgentToReportTo => 'Sélectionner l\'agent auquel rapporter…';

  @override
  String get selectAnAgent => 'Sélectionner un agent';

  @override
  String get selectConversation => 'Sélectionner une conversation';

  @override
  String get selectEffortLevel => 'Sélectionner le niveau d\'effort';

  @override
  String get selectLabel => 'Sélectionner';

  @override
  String get selectRunner => 'Sélectionner un exécuteur';

  @override
  String get semanticSearch => 'Recherche sémantique';

  @override
  String get send => 'Envoyer';

  @override
  String get sendFirstMessage => 'Envoyer le premier message';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String sentFindingsToAgent(int count) {
    return '$count résultat(s) envoyé(s) à l\'agent.';
  }

  @override
  String get serverRunning => 'Serveur en cours d\'exécution';

  @override
  String get serverStopped => 'Serveur arrêté';

  @override
  String setGithubLinkDescription(String name) {
    return 'Définissez le propriétaire GitHub et le nom du dépôt pour $name. Cela est utilisé pour résoudre les références de PR et d\'issues comme #123 dans le contenu markdown.';
  }

  @override
  String get setLabel => 'Définir';

  @override
  String get setToken => 'Définir le jeton';

  @override
  String get settingsGeneralDescription =>
      'Apparence, typographie, intégrations et serveur MCP.';

  @override
  String get settingsLabel => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageDescription =>
      'Choisir la langue de l\'application.';

  @override
  String get sharedSecretToken => 'Jeton secret partagé';

  @override
  String get sharpshooterBadge => 'Tireur d\'élite';

  @override
  String get shortTask => 'Tâche courte';

  @override
  String get showNativeNotifications =>
      'Afficher les notifications macOS natives pour les événements.';

  @override
  String get showSuperseded => 'Afficher remplacés';

  @override
  String get signInWithGhAuth =>
      'Connectez-vous avec gh auth login ou ajoutez un jeton dans Paramètres > Clés API';

  @override
  String get signedIn => 'Connecté.';

  @override
  String signedInAs(String username) {
    return 'Connecté en tant que $username.';
  }

  @override
  String get skillEditor => 'Éditeur de compétences';

  @override
  String get skillNameRequired => 'Le nom de la compétence est requis.';

  @override
  String skillSaved(String name) {
    return 'Compétence « $name » enregistrée.';
  }

  @override
  String get skills => 'Compétences';

  @override
  String get skillsColon => 'Compétences :';

  @override
  String get skillsCommaSeparated => 'Compétences (séparées par des virgules)';

  @override
  String get skillsLabel => 'COMPÉTENCES';

  @override
  String get skipAcceptRisk => 'Passer — J\'accepte le risque';

  @override
  String get skipForNow => 'Passer pour l\'instant';

  @override
  String get skipSandboxing => 'Passer le bac à sable';

  @override
  String get skipSandboxingDialogContent =>
      'Êtes-vous sûr de vouloir ignorer le sandbox ? Cela permet aux agents d\'exécuter du code sur votre système sans isolation.';

  @override
  String get somethingWentWrong => 'Une erreur est survenue';

  @override
  String sourceCount(int count) {
    return '$count source';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count sources';
  }

  @override
  String get sourceFacts => 'Faits source :';

  @override
  String get splitDiff => 'Diff côte à côte';

  @override
  String get startDmWithAgent => 'Démarrer une discussion avec un agent';

  @override
  String get startFresh => 'Recommencer';

  @override
  String get startLabel => 'Démarrer';

  @override
  String get startOnAppLaunch => 'Démarrer au lancement de l\'app';

  @override
  String get startServerToAccept =>
      'Démarrez le serveur pour accepter les connexions MCP.';

  @override
  String get stats => 'Statistiques';

  @override
  String get statusLabel => 'Statut';

  @override
  String stepConnect(int number) {
    return 'Étape $number · Connexion';
  }

  @override
  String get stop => 'Arrêter';

  @override
  String get stopped => 'Arrêté';

  @override
  String get streaks => 'Séries';

  @override
  String get streaksLabel => 'Séries';

  @override
  String get strictIdentityCheck => 'Vérification stricte d\'identité';

  @override
  String get success => 'Succès';

  @override
  String get successLabel => 'Succès';

  @override
  String get successLabelShort => 'Succès';

  @override
  String get successRate => 'Taux de réussite';

  @override
  String get suggestAChange => 'Suggérer une modification';

  @override
  String get suggestAChangeEllipsis => 'Suggérer une modification...';

  @override
  String get suggestLabel => 'SUGGESTION';

  @override
  String get superseded => 'Remplacé';

  @override
  String get synced => 'Synchronisé';

  @override
  String get systemDefault => 'Valeur par défaut du système';

  @override
  String get systemFonts => 'Polices système';

  @override
  String get systemPrompt => 'Prompt système';

  @override
  String get systemPromptLabel => 'Prompt système';

  @override
  String get talkToControlCenter => 'Parlez à Control Center.';

  @override
  String get tapBadgeDescription =>
      'Appuyez sur un badge pour voir comment progresser';

  @override
  String get tapBadgeToLevelUp =>
      'Appuyez sur un badge pour voir comment progresser';

  @override
  String get taskMentionSection => 'Tâche';

  @override
  String get testLabel => 'Tester';

  @override
  String get theme => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String get thisCannotBeUndone => 'Cette action est irréversible.';

  @override
  String get thisConversation => 'cette conversation';

  @override
  String get threadLabel => 'Fil de discussion';

  @override
  String get throughput => 'Débit';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return 'Niveau $tier';
  }

  @override
  String get titleDescription => 'Description';

  @override
  String get titleLabel => 'Titre';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get toggleBookmark => 'Basculer le signet';

  @override
  String get toggleTheme => 'Basculer le thème';

  @override
  String get toggleWorkspaceSwitcher => 'Basculer le sélecteur d\'espace';

  @override
  String get tokenConfigured =>
      'Configuré — les clients doivent présenter ce jeton.';

  @override
  String get tokenConfiguredClients =>
      'Configuré — les clients doivent présenter ce jeton.';

  @override
  String tokenName(String name) {
    return 'Jeton $name';
  }

  @override
  String get topPerformerLabel => 'MEILLEUR PERFORMEUR';

  @override
  String get topPerformersDescription =>
      'Meilleurs performeurs, débit et santé de l\'espace de travail.';

  @override
  String get topic => 'Sujet';

  @override
  String get topicHint => 'ex : Tech Stack, Design System';

  @override
  String get totalRuns => 'Exécutions totales';

  @override
  String get totalRunsLabel => 'Exécutions totales';

  @override
  String trackingParamsCount(int count) {
    return '$count paramètres de suivi';
  }

  @override
  String get typeCommandOrSearch => 'Tapez une commande ou recherchez…';

  @override
  String get typography => 'Typographie';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get unexpectedError => 'Une erreur inattendue s\'est produite.';

  @override
  String get unifiedDiff => 'Diff unifié';

  @override
  String get unknownAuthor => 'Inconnu';

  @override
  String get unnamedAgent => 'Agent sans nom';

  @override
  String get updateKey => 'Mettre à jour la clé';

  @override
  String get updateLabel => 'Mettre à jour';

  @override
  String get updateToken => 'Mettre à jour le jeton';

  @override
  String updatedDaysAgo(int count) {
    return 'Mis à jour il y a $count j';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Mis à jour il y a $count h';
  }

  @override
  String get updatedJustNow => 'Mis à jour à l\'instant';

  @override
  String updatedMinutesAgo(int count) {
    return 'Mis à jour il y a $count min';
  }

  @override
  String get useSandbox => 'Utiliser le sandbox';

  @override
  String get useWorkspaceDefault =>
      'Utiliser la valeur par défaut de l\'espace de travail';

  @override
  String get userAgent => 'Agent utilisateur';

  @override
  String get userAgentDescription =>
      'Laissez vide pour utiliser l\'agent utilisateur par défaut de l\'application. Certains sites bloquent les agents utilisateurs non-navigateurs.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Utilisation du microphone par défaut du système.';

  @override
  String get viewAll => 'Tout voir';

  @override
  String get viewLabel => 'Vue';

  @override
  String get viewLog => 'Voir le journal';

  @override
  String get viewLogs => 'Voir les journaux';

  @override
  String voiceInstallFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Non installé. Télécharge ~200 Mo une seule fois ; fonctionne entièrement sur l\'appareil.';

  @override
  String get voiceModelNotInstalledLabel => 'Modèle vocal non installé.';

  @override
  String get voiceRedownloadBody =>
      'Les fichiers du modèle existant seront supprimés et l\'archive de ~200 Mo sera téléchargée à nouveau. La transcription vocale sera indisponible jusqu\'à la fin du téléchargement.';

  @override
  String get voiceRemoveBody =>
      'La transcription vocale sera désactivée jusqu\'à ce que vous la réinstalliez. Vous pouvez la réinstaller à tout moment.';

  @override
  String get voiceTranscription => 'Transcription vocale';

  @override
  String get weakIsolationDescription =>
      'Isolation faible — limite de namespace uniquement, pas de limite de kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Si désactivé, le bac à sable démarre sans route par défaut.';

  @override
  String get whenOffServerStaysStopped =>
      'Si désactivé, le serveur reste arrêté jusqu\'à ce que vous le démarriez.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en installé. Utilisé par le bouton micro du composeur.';

  @override
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count workers';
  }

  @override
  String get workingMemory => 'Mémoire de travail';

  @override
  String get workspaceName => 'Nom de l\'espace de travail';

  @override
  String get workspaceNotFound => 'Espace de travail introuvable';

  @override
  String get workspaceNotesScratchpad =>
      'Notes et bloc-notes de l\'espace de travail';

  @override
  String get workspacePulse => 'POULSION DE L\'ESPACE';

  @override
  String get workspaceScopedSkills =>
      'Fichiers de compétences limités à l\'espace de travail, attachés aux agents.';

  @override
  String workspaceTitle(String name) {
    return 'Espace de travail : $name';
  }

  @override
  String get workspaces => 'Espaces de travail';

  @override
  String get writeLabel => 'Écrire';

  @override
  String get writePrivateNotes =>
      'Écrire des notes privées, observations, plans...';

  @override
  String get writeSkillContent =>
      'Écrivez le contenu de votre compétence ici (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count ans',
      one: 'il y a 1 an',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'hier';

  @override
  String get yourAchievements => 'VOS SUCCÈS';

  @override
  String get focusModeStart => 'Démarrer une session de concentration';

  @override
  String get focusModeConfigTitle => 'Démarrer une session de concentration';

  @override
  String get focusModeGoalLabel => 'Objectif';

  @override
  String get focusModeGoalHint => 'Sur quoi travaillez-vous ?';

  @override
  String get focusModeDurationLabel => 'Durée';

  @override
  String get focusModeBlockNotifications => 'Bloquer les notifications';

  @override
  String get focusModeStartButton => 'Démarrer';

  @override
  String get focusModeEndSession => 'Terminer la session';

  @override
  String get focusModeExpand => 'Développer l\'application';

  @override
  String get focusModeFloat => 'Réduire dans la barre';

  @override
  String get focusModeActiveTooltip =>
      'Mode concentration actif — appuyez pour terminer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get acceptAndResolve => 'Accepter et résoudre';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Il semble que vous fassiez beaucoup de révisions d\'affilée. Prenez une pause !';
  }

  @override
  String get notificationSound => 'Son de notification';

  @override
  String get notificationSoundDescription =>
      'Son joué quand une notification est affichée.';

  @override
  String get notificationSoundNone => 'Aucun';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Tester';

  @override
  String get notificationVolume => 'Volume';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get clearAllFilters => '× Tout effacer';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dans $countString dépôts',
      one: 'Dans 1 dépôt',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Aucune PR de @$login dans cet espace de travail';
  }

  @override
  String get usersLabel => 'Utilisateurs';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get checksFailing => 'Échec des vérifications';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Sites de confiance';

  @override
  String get trustedSitesEmpty =>
      'Aucun site de confiance. Ajoutez un domaine pour y désactiver le blocage.';

  @override
  String get addTrustedSite => 'Ajouter un site de confiance';

  @override
  String get removeTrustedSite => 'Supprimer';

  @override
  String get disableBlockingForThisSite => 'Désactiver le blocage sur ce site';

  @override
  String get enableBlockingForThisSite => 'Activer le blocage sur ce site';

  @override
  String get enterDomainHint => 'ex. exemple.com';

  @override
  String get invalidDomain => 'Saisissez un domaine valide (ex. exemple.com)';

  @override
  String get pageLoadTimedOut =>
      'Chargement de la page expiré. Rechargez ou ouvrez dans le navigateur.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Exécuter le pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Exécuter le pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Choisissez un pipeline et renseignez ses entrées pour lancer une exécution.';

  @override
  String get pipelineRunNoInputsBadge => 'Aucune entrée';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Ce pipeline ne nécessite aucune entrée.';

  @override
  String get pipelineRunSubmit => 'Exécuter le pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Impossible de démarrer l\'exécution.';

  @override
  String pipelineRunStarted(String name) {
    return '$name démarré';
  }

  @override
  String get pipelineRunEmptyTitle => 'Aucun pipeline prêt à être lancé';

  @override
  String get pipelineRunEmptyHint =>
      'Activez un pipeline et activez l\'exécution manuelle dans son éditeur pour le lancer ici.';

  @override
  String get pipelineRunManageTemplates => 'Gérer les pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Exécution manuelle';

  @override
  String get pipelineRunSettingsAllow => 'Autoriser l\'exécution manuelle';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Afficher ce pipeline sur la page d\'exécution pour pouvoir le lancer manuellement.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Entrées';

  @override
  String get pipelineRunSettingsAddInput => 'Ajouter une entrée';

  @override
  String get pipelineRunSettingsNoInputs => 'Aucune entrée pour l\'instant.';

  @override
  String get pipelineInputEditTitle => 'Champ d\'entrée';

  @override
  String get pipelineInputKeyLabel => 'Clé';

  @override
  String get pipelineInputKeyHelp =>
      'Clé d\'état sous laquelle la valeur est stockée (par ex. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Libellé';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Options (séparées par des virgules)';

  @override
  String get pipelineInputDefaultLabel => 'Valeur par défaut';

  @override
  String get pipelineInputPlaceholderLabel => 'Texte indicatif';

  @override
  String get pipelineInputHelpLabel => 'Texte d\'aide';

  @override
  String get pipelineInputRequiredLabel => 'Obligatoire';

  @override
  String get pipelineInputTypeText => 'Texte';

  @override
  String get pipelineInputTypeMultiline => 'Texte multiligne';

  @override
  String get pipelineInputTypeNumber => 'Nombre';

  @override
  String get pipelineInputTypeBoolean => 'Bascule';

  @override
  String get pipelineInputTypeSelect => 'Liste déroulante';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Cliquez sur « Exécuter le pipeline » pour en lancer un.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Sélectionnez un espace de travail pour voir ses pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Échec du chargement des pipelines : $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Échec du démarrage du pipeline : $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineStepDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed sur $total étapes';
  }

  @override
  String get pipelineStepStarted => 'Démarré';

  @override
  String get pipelineStepFinished => 'Terminé';

  @override
  String get pipelineStepDurationLabel => 'Durée';

  @override
  String get pipelineStepBranch => 'Branche';

  @override
  String get pipelineStepError => 'Erreur';

  @override
  String get pipelineStepInput => 'Entrée';

  @override
  String get pipelineStepOutput => 'Sortie';

  @override
  String get pipelineStepNotExecuted => 'Pas encore exécuté';

  @override
  String get pipelineRunViewTimeline => 'Chronologie';

  @override
  String get pipelineRunViewGraph => 'Graphe';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Échec à $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuel';

  @override
  String get pipelineRunTriggerAuto => 'Automatique';

  @override
  String get pipelineStepSkippedReason => 'Ignoré';

  @override
  String get pipelineRunFilterAll => 'Tous';

  @override
  String get pipelineRunFilterEmpty =>
      'Aucune exécution ne correspond à ce filtre';

  @override
  String get relativeJustNow => 'à l\'instant';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count min',
      one: 'il y a 1 min',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automatisations';

  @override
  String get automationsSubtitle =>
      'Démarrer automatiquement les pipelines lorsque des événements de domaine se produisent';

  @override
  String get automationsNoTriggers =>
      'Aucun déclencheur configuré pour cet événement.';

  @override
  String get automationsAddTrigger => 'Ajouter un déclencheur';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get tasksNoTasks => 'Aucun ticket';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsNoTeams => 'No teams configured';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get pipelineRunTitle => 'Pipeline run';

  @override
  String get pipelineNotFound => 'Pipeline run not found';

  @override
  String get pipelineTemplatesNav => 'Modèles de pipeline';

  @override
  String get pipelineTemplatesTitle => 'Modèles de pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Éditeur glisser-déposer pour les pipelines qui orchestrent vos agents.';

  @override
  String get pipelineTemplatesNew => 'Nouveau modèle';

  @override
  String get pipelineTemplatesEmpty =>
      'Aucun modèle de pipeline. Créez-en un pour commencer.';

  @override
  String get pipelineTemplateIdLabel => 'ID du modèle';

  @override
  String get pipelineTemplateBuiltInBadge => 'Intégré';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Supprimer le modèle ?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Supprimer le modèle de pipeline $name ? Cette action est irréversible.';
  }

  @override
  String get pipelineTemplateSaved => 'Modèle de pipeline enregistré';

  @override
  String get pipelineTemplateEditorTitle => 'Modifier le pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Faites glisser des types de nœuds depuis la barre latérale, puis connectez-les.';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get nodeLibraryTitle => 'Bibliothèque de nœuds';

  @override
  String get nodeLibraryHint =>
      'Glissez un élément sur le canevas pour ajouter un nœud.';

  @override
  String get editorDragHint =>
      'Glissez depuis la bibliothèque, cliquez sur un nœud pour le modifier';

  @override
  String get editorEmptyCanvas =>
      'Glissez un nœud depuis la bibliothèque pour commencer.';

  @override
  String get nodeConfigTitle => 'Configuration du nœud';

  @override
  String get nodeConfigKind => 'Type';

  @override
  String get nodeConfigLabel => 'Libellé';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Choisir un agent…';

  @override
  String get nodeConfigInputKeys =>
      'Clés d\'entrée (séparées par des virgules)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Clés d\'état consommées par ce nœud. Utilisées pour la substitution dans le prompt.';

  @override
  String get nodeConfigOutputKey => 'Clé de sortie';

  @override
  String get nodeConfigPrompt => 'Modèle de prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Utilisez des placeholders à double accolade pour insérer des valeurs depuis l\'état à l\'exécution.';

  @override
  String get nodeConfigScript => 'Script bash';

  @override
  String get nodeConfigScriptHelp =>
      'Exécuté avec bash -c. GITHUB_TOKEN est défini. Les placeholders sont substitués avant exécution.';

  @override
  String get nodeConfigTriggers => 'Déclenché par';

  @override
  String get nodeConfigNoUpstream => 'Aucun autre nœud à connecter en amont.';

  @override
  String get nodeConfigRouteKeys => 'Clés de route';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Clé de route depuis $source';
  }

  @override
  String get conditionSectionTitle => 'Condition';

  @override
  String get conditionMode => 'Mode';

  @override
  String get conditionModeFilesAny => 'Fichier(s) présent(s) — au moins un';

  @override
  String get conditionModeFilesAll => 'Fichiers présents — tous';

  @override
  String get conditionModeComparison => 'Comparaison';

  @override
  String get conditionModeSwitch => 'Aiguillage';

  @override
  String get conditionFilePaths => 'Chemins de fichiers';

  @override
  String get conditionFilePathsAnyHelp =>
      'Un chemin par ligne, relatif au répertoire de base. Renvoie true si au moins un existe.';

  @override
  String get conditionFilePathsAllHelp =>
      'Un chemin par ligne, relatif au répertoire de base. Renvoie true seulement si tous existent.';

  @override
  String get conditionBaseKey => 'Clé du répertoire de base';

  @override
  String get conditionBaseKeyHelp =>
      'Clé d\'état contenant le répertoire de résolution des chemins (par défaut repoLocalPath).';

  @override
  String get conditionRecursive => 'Chercher dans les sous-dossiers';

  @override
  String get conditionNegate => 'Inverser : route true si absent';

  @override
  String get conditionLeft => 'Valeur de gauche';

  @override
  String get conditionOperator => 'Opérateur';

  @override
  String get conditionRight => 'Valeur de droite';

  @override
  String get conditionSwitchKey => 'Aiguiller sur la clé d\'état';

  @override
  String get conditionCases => 'Cas (séparés par des virgules)';

  @override
  String get conditionCasesHelp =>
      'Clés de route à comparer à la valeur, dans l\'ordre.';

  @override
  String get conditionDefaultCase => 'Cas par défaut';

  @override
  String get triggerPanelTitle => 'Déclencheurs';

  @override
  String get triggerPanelHelp => 'Ce qui démarre ce pipeline.';

  @override
  String get triggerManualHelp =>
      'Afficher sur la page d\'exécution et lancer à la main.';

  @override
  String get triggerSectionAutomatic => 'Déclencheurs automatiques';

  @override
  String get triggerAddButton => 'Ajouter un déclencheur';

  @override
  String get triggerNoneYet => 'Aucun déclencheur automatique pour l\'instant.';

  @override
  String get triggerAddDialogTitle => 'Ajouter un déclencheur';

  @override
  String get triggerKindLabel => 'Type de déclencheur';

  @override
  String get triggerKindEvent => 'Sur un évènement';

  @override
  String get triggerKindSchedule => 'Selon un calendrier';

  @override
  String get triggerIntervalLabel => 'Exécuter toutes les (secondes)';

  @override
  String get triggerEventFieldLabel => 'Évènement';

  @override
  String get triggerNoMoreEvents =>
      'Tous les évènements disponibles sont déjà configurés.';

  @override
  String get triggerMatchStatusLabel => 'Uniquement quand le statut est';

  @override
  String get triggerSummaryNone => 'Aucun déclencheur';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Toutes les ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Exécution manuelle';

  @override
  String get triggerEventSchedule => 'Calendrier';

  @override
  String get triggerEventPrStatusChanged => 'Statut de la PR modifié';

  @override
  String get triggerEventExternalPr => 'PR externe ouverte';

  @override
  String get triggerEventPrPublished => 'PR publiée';

  @override
  String get triggerEventPrMerged => 'PR fusionnée';

  @override
  String get triggerEventRepoAdded => 'Dépôt ajouté';

  @override
  String get triggerEventMessageReceived => 'Message reçu';

  @override
  String get triggerEventTicketCompleted => 'Tâche terminée';

  @override
  String get triggerEventTicketFailed => 'Tâche échouée';

  @override
  String get triggerEventTicketCancelled => 'Tâche annulée';

  @override
  String get triggerEventBudgetCrossed => 'Seuil de budget dépassé';

  @override
  String get automationsManagedHint =>
      'Les déclencheurs se configurent par pipeline dans son éditeur. Activez-les ou désactivez-les ici.';

  @override
  String get automationsEditInPipeline => 'Modifier dans le pipeline';

  @override
  String get nodeLibrarySearchHint => 'Rechercher des nœuds';

  @override
  String get nodeLibraryNoMatches => 'Aucun nœud correspondant';

  @override
  String get nodeCategoryFlow => 'Flux et logique';

  @override
  String get nodeCategoryPr => 'Revue de PR';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Messagerie';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get nodeCategoryDemo => 'Démo';

  @override
  String get triggerDisabledTag => 'désactivé';

  @override
  String get pipelineInputTypeRepo => 'Dépôt';

  @override
  String get pipelineRunNoRepos => 'Aucun dépôt dans cet espace de travail.';

  @override
  String get allowTicketingApi => 'Autoriser les appels API de tickets';

  @override
  String get ticketingApiKey => 'Clé API de ticketing';

  @override
  String get ticketingApiKeySubtitle =>
      'Injecte la clé API du fournisseur de tickets dans le bac à sable.';

  @override
  String get ticketingProvider => 'Fournisseur de tickets';

  @override
  String get connectGitHubAndTicketing =>
      'Connectez GitHub pour que Control Center puisse lire vos pull requests, tickets et revues. Connectez éventuellement un fournisseur de tickets. Rien ne quitte cette machine.';

  @override
  String get triggerEventTicketAssigned => 'Ticket assigné';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Nouveau ticket';

  @override
  String get noTicketsYet => 'Aucun ticket pour le moment';

  @override
  String get assignTicket => 'Assigner le ticket';

  @override
  String get addCollaborator => 'Ajouter un collaborateur';

  @override
  String get noCollaborators => 'Aucun collaborateur pour l\'instant';

  @override
  String get linkedPullRequests => 'Pull requests liées';

  @override
  String get noLinkedPullRequests => 'Aucune pull request liée';

  @override
  String get ticketActivity => 'Activité';

  @override
  String get ticketDispatchHint => '@mentionnez un agent pour le déployer…';

  @override
  String get stopAgent => 'Arrêter l\'agent';

  @override
  String get removeQueuedMessage => 'Supprimer le message en file d\'attente';

  @override
  String get ticketProperties => 'Propriétés';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Activité';

  @override
  String get ticketTabChanges => 'Modifications';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt =>
      'Sélectionnez un ticket pour afficher ses détails';

  @override
  String get ticketNoChanges =>
      'Aucune modification dans les dépôts liés pour l’instant';

  @override
  String get ticketTerminalNoAgent =>
      'Assignez un agent pour ouvrir un terminal';

  @override
  String get unassigned => 'Non assigné';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'À faire';

  @override
  String get ticketStatusInProgress => 'En cours';

  @override
  String get ticketStatusInReview => 'En revue';

  @override
  String get ticketStatusDone => 'Terminé';

  @override
  String get ticketStatusBlocked => 'Bloqué';

  @override
  String get ticketStatusFailed => 'Échoué';

  @override
  String get ticketStatusCancelled => 'Annulé';

  @override
  String get notificationTicketAssigned => 'Ticket assigné';

  @override
  String get notificationTicketStatusChanged => 'Statut du ticket modifié';

  @override
  String get notificationTicketCollaboratorAdded => 'Collaborateur ajouté';

  @override
  String get priority => 'Priorité';

  @override
  String get status => 'Statut';

  @override
  String get assignee => 'Assigné à';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketPriorityNone => 'Aucune';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'Élevée';

  @override
  String get ticketPriorityMedium => 'Moyenne';

  @override
  String get ticketPriorityLow => 'Basse';

  @override
  String get ticketViewList => 'Liste';

  @override
  String get ticketViewBoard => 'Tableau';

  @override
  String get ticketTitlePlaceholder => 'Titre du ticket';

  @override
  String get ticketDescriptionPlaceholder => 'Ajouter une description…';

  @override
  String get createMore => 'En créer d\'autres';

  @override
  String selectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get bulkDeleteTitle => 'Supprimer les tickets';

  @override
  String bulkDeleteMessage(int count) {
    return 'Supprimer $count tickets sélectionnés ? Action irréversible.';
  }

  @override
  String get assignTo => 'Assigner à…';

  @override
  String get sectionMembers => 'Membres';

  @override
  String get sectionAgents => 'Agents';

  @override
  String get sidebarGroupWork => 'Travail';

  @override
  String get sidebarGroupTeam => 'Équipe';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsEmpty => 'Vous êtes à jour';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get toggleThemeLabel => 'Changer de thème';

  @override
  String get teamsNav => 'Équipes';

  @override
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle => 'Voici ce sur quoi vos agents travaillent.';

  @override
  String get recentActivityTitle => 'Activité récente';

  @override
  String get noRecentActivity => 'Aucune activité récente pour le moment';

  @override
  String get noRecentActivitySubtitle =>
      'Les exécutions d\'agents, les pull requests et les messages apparaîtront ici.';

  @override
  String get noWorkspace => 'Aucun espace de travail';

  @override
  String get allAgentsIdle => 'Tous les agents inactifs';

  @override
  String get statWorkspaces => 'Espaces de travail';

  @override
  String get statAgents => 'Agents';

  @override
  String get statRunning => 'En cours d\'exécution';

  @override
  String get activeAgentsTitle => 'Agents actifs';

  @override
  String get noAgentProcessesSubtitle =>
      'L\'activité des agents apparaîtra ici au démarrage d\'une exécution.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'En cours · $count';
  }

  @override
  String get noneLabel => 'Aucun';

  @override
  String get sidebarGroupKnowledge => 'Connaissances';

  @override
  String get navMemory => 'Mémoire';

  @override
  String get memoryTabFacts => 'Faits';

  @override
  String get memoryTabPolicies => 'Politiques';

  @override
  String get memoryTabGraph => 'Graphe de connaissances';

  @override
  String get memoryNoWorkspace =>
      'Sélectionnez un espace de travail pour voir sa mémoire.';

  @override
  String get topStory => 'À la une';

  @override
  String get searchArticles => 'Rechercher des articles';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterUnread => 'Non lus';

  @override
  String get filterSaved => 'Enregistrés';

  @override
  String get saveArticle => 'Enregistrer l\'article';

  @override
  String get removeFromSaved => 'Retirer des enregistrés';

  @override
  String get filterBySource => 'Filtrer par source';

  @override
  String get viewAsList => 'Vue liste';

  @override
  String get viewAsGrid => 'Vue grille';

  @override
  String get noMatchingArticles => 'Aucun article correspondant';

  @override
  String get noMatchingArticlesBody =>
      'Essayez une autre recherche ou un autre filtre de source.';

  @override
  String get allCaughtUp => 'Tout est à jour';

  @override
  String get allCaughtUpBody => 'Aucun article non lu — revenez plus tard.';

  @override
  String get openArticlesInAppDescription =>
      'Ouvrir les liens dans le lecteur intégré plutôt que dans votre navigateur par défaut.';

  @override
  String get blockAdsTrackersDescription =>
      'Supprimer les publicités, les traqueurs et les bannières de cookies des articles ouverts dans le lecteur.';

  @override
  String get agentQuestionHeader => 'Question pour vous';

  @override
  String get agentQuestionAnsweredLabel => 'Répondu';

  @override
  String get agentQuestionSubmit => 'Envoyer la réponse';

  @override
  String get agentQuestionFreeformHint => 'Saisissez votre réponse…';

  @override
  String get agentQuestionAnswerLabel => 'Votre réponse';

  @override
  String get reviewRequested => 'Révision demandée';

  @override
  String get loadMorePrs => 'Charger plus';

  @override
  String get loadingMorePrs => 'Chargement…';

  @override
  String get noPrsMatchFilters =>
      'Aucune pull request ne correspond aux filtres dans ce dépôt';

  @override
  String get connectGitHubToLoadPrs =>
      'Connectez GitHub pour charger les pull requests';

  @override
  String get noRepositoriesConfigured => 'Aucun dépôt configuré';

  @override
  String get noAuthors => 'Aucun auteur';

  @override
  String get noAuthorMatches => 'Aucun résultat';

  @override
  String openedAgo(String age) {
    return 'Ouvert $age';
  }

  @override
  String updatedAgo(String age) {
    return 'Mis à jour $age';
  }

  @override
  String get checksPassing => 'Vérifications réussies';

  @override
  String get checksRunning => 'Vérifications en cours';

  @override
  String get needsYourReview => 'Nécessite votre révision';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions lignes';
  }

  @override
  String get checks => 'Vérifications';

  @override
  String get noReviewersAssigned => 'Aucun relecteur assigné';

  @override
  String get noAssignees => 'Aucun responsable';

  @override
  String get noChecksYet => 'Aucune vérification exécutée';

  @override
  String checksFailingCount(int count) {
    return '$count en échec';
  }

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get backToPullRequests => 'Retour aux pull requests';

  @override
  String get pullRequestNotFound => 'Pull request introuvable';

  @override
  String get pullRequestNotFoundBody =>
      'Elle a peut-être été fusionnée, fermée ou déplacée.';

  @override
  String get couldntLoadPullRequest =>
      'Impossible de charger cette pull request';

  @override
  String get showDetails => 'Afficher les détails';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Chargement de la pull request #$number…';
  }

  @override
  String get noDescriptionProvided => 'Aucune description fournie.';

  @override
  String get factsHint =>
      'Les faits apparaîtront ici à mesure que vos agents apprennent.';

  @override
  String get noFactsMatch => 'Aucun fait ne correspond à votre recherche';

  @override
  String get memoryLoadError => 'Impossible de charger la mémoire';

  @override
  String get sortRecent => 'Récent';

  @override
  String get sortConfidence => 'Confiance';

  @override
  String get confidenceTooltip =>
      'À quel point les agents sont sûrs que ce fait est vrai, de 0 à 100 %.';

  @override
  String get supersededTooltip => 'Un fait plus récent a remplacé celui-ci.';

  @override
  String get domain => 'Domaine';

  @override
  String get fitToView => 'Ajuster à l\'écran';

  @override
  String get project => 'Projet';

  @override
  String get projects => 'Projets';

  @override
  String get newProject => 'Nouveau projet';

  @override
  String get editProject => 'Modifier le projet';

  @override
  String get deleteProject => 'Supprimer le projet';

  @override
  String get noProject => 'Aucun projet';

  @override
  String get allTickets => 'Tous les tickets';

  @override
  String get projectNamePlaceholder => 'Nom du projet';

  @override
  String get projectDescriptionPlaceholder => 'Description (facultative)';

  @override
  String get projectColorLabel => 'Couleur';

  @override
  String get noProjectsYet => 'Aucun projet pour l\'instant';

  @override
  String get projectTicketsEmpty =>
      'Aucun ticket dans ce projet pour l\'instant';

  @override
  String get createProject => 'Créer le projet';

  @override
  String projectProgress(int done, int total) {
    return '$done sur $total terminés';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Supprimer « $name » ? Ses tickets sont conservés et retirés du projet.';
  }

  @override
  String get projectStatusActive => 'Actif';

  @override
  String get projectStatusCompleted => 'Terminé';

  @override
  String get projectStatusArchived => 'Archivé';

  @override
  String get markProjectCompleted => 'Marquer comme terminé';

  @override
  String get markProjectActive => 'Marquer comme actif';

  @override
  String get archiveProject => 'Archiver';

  @override
  String get restoreProject => 'Restaurer';

  @override
  String get relations => 'Relations';

  @override
  String get relateTo => 'Lier à';

  @override
  String get relationSubIssueOf => 'Sous-tâche de…';

  @override
  String get relationParentOf => 'Parent de…';

  @override
  String get relationBlockedBy => 'Bloqué par…';

  @override
  String get relationBlocking => 'Bloque…';

  @override
  String get relationRelatedTo => 'Lié à…';

  @override
  String get relationDuplicateOf => 'Doublon de…';

  @override
  String get relationGroupParent => 'Parent';

  @override
  String get relationGroupSubIssues => 'Sous-tâches';

  @override
  String get relationGroupBlockedBy => 'Bloqué par';

  @override
  String get relationGroupBlocking => 'Bloque';

  @override
  String get relationGroupRelated => 'Lié';

  @override
  String get relationGroupDuplicateOf => 'Doublon de';

  @override
  String get relationGroupDuplicatedBy => 'Dupliqué par';

  @override
  String get copyId => 'Copier l\'ID';

  @override
  String get ticketIdCopied => 'ID du ticket copié';

  @override
  String get selectTicket => 'Sélectionner un ticket';

  @override
  String get searchTicketsHint => 'Rechercher des tickets…';

  @override
  String get noMatchingTickets => 'Aucun ticket correspondant';

  @override
  String get addToProject => 'Ajouter au projet';

  @override
  String get activeFleet => 'Flotte active';

  @override
  String agentsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get blockedStatus => 'Bloqué';

  @override
  String get failedStatus => 'Échoué';

  @override
  String get neverRunStatus => 'Jamais exécuté';

  @override
  String get noActiveRun => 'Aucune exécution active';

  @override
  String get allPullRequests => 'Toutes les pull requests';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get needsYouNow => 'Requiert votre attention';

  @override
  String get pipelinesSectionTitle => 'Pipelines';

  @override
  String get allRuns => 'Toutes les exécutions';

  @override
  String get triage => 'Trier';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents en cours',
      one: '1 agent en cours',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count bloqués';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count pour vous';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR en attente',
      one: '1 PR en attente',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos dépôts',
      one: '1 dépôt',
    );
    return '$_temp0 de votre revue sur $_temp1';
  }

  @override
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revues',
      one: '1 revue',
    );
    return '$_temp0 en attente';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depuis plus de 2 jours',
      one: '1 depuis plus de 2 jours',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name est bloqué';
  }

  @override
  String get agentBlockedSubtitle => 'En attente de votre confirmation';

  @override
  String get pipelineFailedTitle => 'Échec du pipeline';

  @override
  String prStaleTitle(String number) {
    return 'PR $number obsolète';
  }

  @override
  String get prStaleSubtitle => 'Aucune activité récente';

  @override
  String get reviewRequestedBadge => 'Revue demandée';

  @override
  String get draftBadge => 'Brouillon';

  @override
  String get staleLabel => 'Obsolète';

  @override
  String stepsProgress(int done, int total) {
    return '$done sur $total étapes';
  }

  @override
  String get allCaughtUpSubtitle =>
      'Aucune revue, blocage ou échec ne requiert votre attention pour l\'instant.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Espace $name';
  }

  @override
  String get pipelineTriggerNode => 'Déclencheur';

  @override
  String get priorityReviewsTooltip =>
      'PR ouvertes qui demandent votre revue et attendent depuis plus de 24 heures.';

  @override
  String get workspaceSettings => 'Paramètres de l\'espace de travail';

  @override
  String get manageWorkspacesSubtitle =>
      'Renommez un espace de travail et changez sa marque — sélectionnez-en un à gauche pour le modifier.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espaces de travail',
      one: '1 espace de travail',
      zero: 'Aucun espace de travail',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos dépôts',
      one: '1 dépôt',
      zero: 'Aucun dépôt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agents',
      one: '1 agent',
      zero: '0 agent',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identité';

  @override
  String get uploadImage => 'Téléverser une image';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG ou GIF jusqu\'à 2 Mo. Sinon, nous utiliserons l\'initiale de l\'espace de travail.';

  @override
  String get workspaceNameFieldHelp =>
      'Affiché dans le sélecteur, le fil d\'Ariane et sur chaque écran.';

  @override
  String get dangerZone => 'Zone sensible';

  @override
  String get deleteThisWorkspace => 'Supprimer cet espace de travail';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Supprime définitivement $name, ses connexions de dépôts, ses agents et sa mémoire. Cette action est irréversible.';
  }

  @override
  String get discard => 'Abandonner';

  @override
  String discardChangesQuestion(String name) {
    return 'Abandonner les modifications non enregistrées de $name ?';
  }

  @override
  String get workspaceUpdated => 'Espace de travail mis à jour';

  @override
  String get editTitle => 'Modifier le titre';

  @override
  String get editDescription => 'Modifier la description';

  @override
  String get addDescription => 'Ajouter une description';

  @override
  String get prTitlePlaceholder => 'Titre';

  @override
  String get prBodyPlaceholder => 'Ajoutez une description';

  @override
  String get write => 'Écrire';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Aperçu';

  @override
  String get prTemplateLabel => 'Modèle';

  @override
  String get prTemplateDefault => 'Par défaut';

  @override
  String get addReviewers => 'Ajouter des relecteurs';

  @override
  String get addAssignees => 'Ajouter des assignés';

  @override
  String get searchUsers => 'Rechercher des personnes…';

  @override
  String get searchReviewers => 'Rechercher des personnes et des équipes…';

  @override
  String get usersSectionLabel => 'Personnes';

  @override
  String get teamsSectionLabel => 'Équipes';

  @override
  String get noMatchingUsers => 'Aucune personne correspondante';

  @override
  String get noMatchingReviewers => 'Aucun résultat';

  @override
  String addCount(int count) {
    return 'Ajouter ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Requis par les propriétaires de code';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Équipe';

  @override
  String get markdownBold => 'Gras';

  @override
  String get markdownItalic => 'Italique';

  @override
  String get markdownHeading => 'Titre';

  @override
  String get markdownBulletList => 'Liste à puces';

  @override
  String get markdownChecklist => 'Liste de tâches';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Lien';

  @override
  String get markdownQuote => 'Citation';

  @override
  String failedToUpdateTitle(String error) {
    return 'Échec de la mise à jour du titre : $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Échec de la mise à jour de la description : $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Échec de la mise à jour des relecteurs : $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Échec de la mise à jour des assignés : $error';
  }

  @override
  String get discardChangesConfirm => 'Abandonner vos modifications ?';

  @override
  String get newPr => 'Nouvelle PR';

  @override
  String get openPullRequest => 'Ouvrir une pull request';

  @override
  String get composePrSubtitle =>
      'Depuis une branche que vous avez poussée — sans agents ni tickets';

  @override
  String get createAsDraft => 'Créer en brouillon';

  @override
  String get composePrNoRepo => 'Aucun dépôt GitHub sélectionné';

  @override
  String get composePrNoRepoHint =>
      'Sélectionnez un espace de travail avec un dépôt lié à GitHub pour ouvrir une pull request.';

  @override
  String get composePrPickBranches =>
      'Choisissez une branche de base et une branche à comparer pour prévisualiser les modifications.';

  @override
  String get composePrNothingToCompare =>
      'Il n\'y a aucune différence entre ces branches.';

  @override
  String get repository => 'Dépôt';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Comparer';

  @override
  String get selectBranch => 'Sélectionner une branche';

  @override
  String get navMeetings => 'Réunions';

  @override
  String get meetingsNoWorkspace =>
      'Sélectionnez un espace de travail pour voir les réunions.';

  @override
  String get meetingsEmpty =>
      'Aucune réunion pour l\'instant. Démarrez un enregistrement pour en capturer une.';

  @override
  String get meetingsStartRecording => 'Démarrer l\'enregistrement';

  @override
  String get meetingsStopRecording => 'Arrêter l\'enregistrement';

  @override
  String get meetingsProcessing => 'Résumé en cours…';

  @override
  String get meetingEnhancedNotes => 'Notes enrichies';

  @override
  String get meetingYourNotes => 'Vos notes';

  @override
  String get meetingNotesHint =>
      'Prenez des notes rapides — l\'agent les développera après la réunion.';

  @override
  String get meetingTranscriptTitle => 'Transcription';

  @override
  String get meetingNoTranscriptYet =>
      'La transcription apparaît ici au fur et à mesure que les gens parlent.';

  @override
  String get meetingSpeakerMe => 'Vous';

  @override
  String get meetingSpeakerThem => 'Eux';

  @override
  String get meetingStatusRecording => 'Enregistrement';

  @override
  String get meetingStatusProcessing => 'Traitement';

  @override
  String get meetingStatusDone => 'Terminé';

  @override
  String get meetingStatusFailed => 'Échec';

  @override
  String get keybindingGoToMeetings => 'Aller aux réunions';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Naviguer vers la liste des réunions';

  @override
  String get meetingsOverlineKnowledge => 'Connaissances';

  @override
  String get meetingsOverlineEngine => 'Sur l\'appareil · Whisper base.en';

  @override
  String get meetingsSubtitle =>
      'Capture locale de vos réunions. Nous captons l\'audio de la réunion et votre micro, transcrivons sur l\'appareil, et laissons un agent transformer vos notes éparses en décisions et tâches — aucun bot ne rejoint jamais l\'appel.';

  @override
  String get meetingsRecordMeeting => 'Enregistrer la réunion';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en cours de traitement',
      one: '1 en cours de traitement',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'Cette semaine';

  @override
  String get meetingsStatThisWeekUnit => 'réunions capturées';

  @override
  String get meetingsStatRecorded => 'Enregistré';

  @override
  String get meetingsStatRecordedUnit => 'transcrit localement';

  @override
  String get meetingsStatOpen => 'Ouvertes';

  @override
  String get meetingsStatOpenUnit => 'tâches en attente';

  @override
  String get meetingsStatLogged => 'Consignées';

  @override
  String get meetingsStatLoggedUnit => 'décisions extraites';

  @override
  String get meetingsCaptureTitle =>
      'La capture audio système sans pilote est armée.';

  @override
  String get meetingsCaptureBody =>
      'Control Center capte la sortie haut-parleur de l\'application où vous vous trouvez — Slack Huddle, Meet, Zoom, Tuple — ainsi que votre microphone, et décode les deux flux sur cet appareil.';

  @override
  String get meetingsCapturePermission => 'Autorisation accordée';

  @override
  String get meetingsCaptureOnDevice => '100 % sur l\'appareil';

  @override
  String get meetingsCaptureNoBot => 'Aucun bot ne rejoint';

  @override
  String get meetingsScopeAll => 'Toutes les réunions';

  @override
  String get meetingsFilterAll => 'Toutes';

  @override
  String get meetingsFilterDone => 'Terminées';

  @override
  String get meetingsFilterProcessing => 'En cours';

  @override
  String get meetingsSearchHint => 'Filtrer par titre, personne, application…';

  @override
  String get meetingsBucketToday => 'Aujourd\'hui';

  @override
  String get meetingsBucketYesterday => 'Hier';

  @override
  String get meetingsBucketEarlierThisWeek => 'Plus tôt cette semaine';

  @override
  String get meetingsBucketLastWeek => 'La semaine dernière';

  @override
  String get meetingsBucketOlder => 'Plus ancien';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count décisions',
      one: '1 décision',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total tâches';
  }

  @override
  String get meetingsEnhancedPill => 'enrichi';

  @override
  String get meetingsTranscribing => 'transcription et synthèse…';

  @override
  String get meetingsOpenAction => 'Ouvrir';

  @override
  String get meetingsStopProcessing => 'Arrêter';

  @override
  String get meetingsStillTranscribing =>
      'Transcription en cours — le résumé apparaîtra une fois terminé.';

  @override
  String get meetingsNoMatch => 'Aucune réunion ne correspond';

  @override
  String get meetingsNoMatchHint =>
      'Essayez un autre filtre ou terme de recherche.';

  @override
  String get meetingBackAllMeetings => 'Toutes les réunions';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Relancer le résumé';

  @override
  String get meetingExport => 'Exporter';

  @override
  String get meetingAugmentingBanner =>
      'Enrichissement de vos notes à partir de la transcription — extraction des décisions et des tâches…';

  @override
  String get meetingTabNotes => 'Notes';

  @override
  String get meetingTabTranscript => 'Transcription';

  @override
  String get meetingTabActionItems => 'Tâches';

  @override
  String get meetingTabDecisions => 'Décisions';

  @override
  String get meetingNotesEnhancedToggle => 'Enrichies';

  @override
  String get meetingNotesYoursToggle => 'Vos notes';

  @override
  String get meetingEnhancedByAgent =>
      'Enrichi par l\'agent · à partir de la transcription';

  @override
  String get meetingEnhancedPending =>
      'L\'agent travaille encore sur ce résumé.';

  @override
  String get meetingNotesEmpty => 'Pas encore de notes enrichies.';

  @override
  String get meetingNotesSavedLocally => 'Enregistré localement';

  @override
  String get meetingNotesSaving => 'Enregistrement…';

  @override
  String get meetingViewFullTranscript => 'Voir la transcription complète';

  @override
  String get meetingTranscriptSearchHint => 'Rechercher dans la transcription…';

  @override
  String get meetingSpeakerEveryone => 'Tout le monde';

  @override
  String get meetingSpeakerOthers => 'Autres';

  @override
  String get meetingTranscriptEmpty => 'Pas encore de transcription.';

  @override
  String get meetingActionItemsEmpty => 'Aucune tâche extraite.';

  @override
  String get meetingActionItemFrom => 'de cette réunion';

  @override
  String get meetingCreateTicket => 'Créer un ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key créé et envoyé.';
  }

  @override
  String get meetingTicketFailed => 'Impossible de créer le ticket.';

  @override
  String get meetingDecisionsEmpty => 'Aucune décision consignée.';

  @override
  String get meetingEditTitle => 'Modifier le titre';

  @override
  String get meetingTitleLabel => 'Titre';

  @override
  String get meetingAddActionItem => 'Ajouter une action';

  @override
  String get meetingEditActionItem => 'Modifier l\'action';

  @override
  String get meetingDeleteActionItem => 'Supprimer l\'action';

  @override
  String get meetingActionItemContentLabel => 'Action';

  @override
  String get meetingActionItemContentHint => 'Que faut-il faire ?';

  @override
  String get meetingActionItemOwnerLabel => 'Responsable';

  @override
  String get meetingActionItemOwnerHint => 'Qui s\'en charge ? (facultatif)';

  @override
  String get meetingAddDecision => 'Ajouter une décision';

  @override
  String get meetingEditDecision => 'Modifier la décision';

  @override
  String get meetingDeleteDecision => 'Supprimer la décision';

  @override
  String get meetingDecisionContentLabel => 'Décision';

  @override
  String get meetingDecisionContentHint => 'Qu\'a-t-on décidé ?';

  @override
  String get meetingReRunStarted =>
      'Relance de la synthèse sur la transcription…';

  @override
  String get meetingReRunDone => 'Résumé actualisé.';

  @override
  String get meetingReRunNoTranscript =>
      'Aucune transcription à résumer pour l\'instant.';

  @override
  String get meetingExportCopied =>
      'Notes copiées dans le presse-papiers au format Markdown.';

  @override
  String get meetingExportNothing => 'Rien à exporter pour l\'instant.';

  @override
  String get meetingsRecordingCrumb => 'Enregistrement…';

  @override
  String get meetingRecordTitleHint => 'Titre de la réunion';

  @override
  String get meetingRecordTappingLabel => 'Captation :';

  @override
  String get meetingRecordMic => 'Micro';

  @override
  String get meetingRecordSystemAudio => 'Audio système';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Reprendre';

  @override
  String get meetingRecordStop => 'Arrêter et résumer';

  @override
  String get meetingRecordYourNotes => 'Vos notes';

  @override
  String get meetingRecordNotesTagline =>
      'notez l\'essentiel — l\'agent complète le reste';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Écrivez pendant que vous écoutez. Quelques fragments suffisent — après l\'arrêt, l\'agent les développe à partir de la transcription.';

  @override
  String get meetingRecordLiveTranscript => 'Transcription en direct';

  @override
  String get meetingRecordDecoding => 'décodage sur l\'appareil';

  @override
  String get meetingRecordListening =>
      'Écoute… la parole apparaîtra ici dans une seconde ou deux, étiquetée Vous / Autres.';

  @override
  String get meetingRecordPausedHint =>
      'En pause — l\'audio est ignoré jusqu\'à la reprise.';

  @override
  String get meetingRecordNotActive => 'Aucun enregistrement actif.';

  @override
  String get meetingHudRecording => 'enregistrement';

  @override
  String get meetingHudPaused => 'en pause';

  @override
  String get meetingHudOpen => 'Ouvrir';

  @override
  String get meetingHudStop => 'Arrêter';

  @override
  String get orchestrate => 'Orchestrer';

  @override
  String get orchestrationUnavailable => 'Orchestration indisponible';

  @override
  String get orchestrationApprove => 'Approuver le plan';

  @override
  String get orchestrationReject => 'Rejeter';

  @override
  String get orchestrationCancel => 'Annuler l\'orchestration';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count rôles — $hires nouvelles recrues';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sous-tickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Coût estimé : $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sous-tickets terminés';
  }

  @override
  String get orchestrationStatusProposed => 'Proposé';

  @override
  String get orchestrationStatusApproved => 'Approuvé';

  @override
  String get orchestrationStatusExecuting => 'En cours';

  @override
  String get orchestrationStatusSynthesizing => 'Synthèse';

  @override
  String get orchestrationStatusCompleted => 'Terminé';

  @override
  String get orchestrationStatusFailed => 'Échoué';

  @override
  String get orchestrationStatusCancelled => 'Annulé';

  @override
  String get messageFailed => 'Échec du run';

  @override
  String get retried => 'Relancé';

  @override
  String replyingTo(String name) {
    return 'en réponse à $name';
  }

  @override
  String get recentRuns => 'Exécutions récentes';

  @override
  String get runIdCopied => 'Id d\'exécution copié';

  @override
  String get copyRunId => 'Copier l\'id d\'exécution';

  @override
  String get copyLogPath => 'Copier le chemin du journal';

  @override
  String get silenceTimeoutLabel => 'Délai de silence (minutes)';

  @override
  String get silenceTimeoutHint =>
      'p. ex. 15 — arrête un run après ce délai sans sortie';

  @override
  String get ticketOutput => 'Sortie';

  @override
  String missingRequiredField(String field) {
    return 'Champ requis manquant : $field';
  }

  @override
  String get capabilityJsonMode => 'Mode JSON';

  @override
  String get capabilityModelSelection => 'Choix du modèle';

  @override
  String get transcriptThinking => 'Réflexion…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'A réfléchi pendant $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Modifications en cours…';

  @override
  String get transcriptStatusReadingFiles => 'Lecture des fichiers…';

  @override
  String get transcriptStatusSearching => 'Recherche dans le code…';

  @override
  String get transcriptStatusRunningCommands => 'Exécution de commandes…';

  @override
  String get transcriptStatusResponding => 'Réponse…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Exécution de $tool…';
  }

  @override
  String get transcriptInput => 'Entrée';

  @override
  String get transcriptOutput => 'Sortie';

  @override
  String get transcriptShowMore => 'Afficher plus';

  @override
  String get transcriptShowLess => 'Afficher moins';

  @override
  String transcriptToolCalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appels d\'\'outils',
      one: '1 appel d\'\'outil',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorLabel => 'Erreur';

  @override
  String get transcriptInterrupted => 'Interrompu';

  @override
  String get transcriptSandboxBlocked => 'Le bac à sable a bloqué une action';

  @override
  String get transcriptOutputTruncated => 'Sortie tronquée';

  @override
  String transcriptDiffStats(int adds, int dels) {
    return '$adds ajouts, $dels suppressions';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Personne $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Renommer l\'\'intervenant';

  @override
  String get meetingRenameSpeakerTitle => 'Renommer l\'\'intervenant';

  @override
  String get meetingSpeakerNameLabel => 'Nom';

  @override
  String get meetingLinkEvent => 'Associer à un événement';

  @override
  String get meetingChangeEvent => 'Changer d\'\'événement';

  @override
  String get meetingLinkEventTitle => 'Associer à un événement du calendrier';

  @override
  String get meetingLinkEventSearchHint => 'Rechercher des événements';

  @override
  String get meetingLinkEventEmpty =>
      'Aucun événement de calendrier à proximité';

  @override
  String get meetingUnlinkEvent => 'Supprimer l\'\'association';

  @override
  String get calendarLinkExistingMeeting => 'Associer à une réunion existante';

  @override
  String get calendarLinkMeetingTitle => 'Associer une réunion';

  @override
  String get calendarLinkMeetingSearchHint => 'Rechercher des réunions';

  @override
  String get calendarLinkMeetingEmpty => 'Aucune réunion à associer';

  @override
  String get meetingRenameSpeakerFailed =>
      'Impossible de renommer l\'intervenant';

  @override
  String get calendarLinkUpdateFailed =>
      'Impossible de mettre à jour le lien avec le calendrier';
}
