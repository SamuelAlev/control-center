// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Retour';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get settings => 'Réglages';

  @override
  String get refresh => 'Actualiser';

  @override
  String get approve => 'Approuver';

  @override
  String get deny => 'Refuser';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get agentQuestionHeader => 'Question pour vous';

  @override
  String get agentQuestionAnsweredLabel => 'Répondu';

  @override
  String get agentQuestionSkip => 'Ignorer';

  @override
  String get agentQuestionSkippedLabel => 'Ignorée';

  @override
  String get agentQuestionFreeformHint => 'Saisissez votre réponse…';

  @override
  String get agentApprovalRequired => 'Approbation requise';

  @override
  String get copyCommand => 'Copier la commande';

  @override
  String get approveAndRemember => 'Approuver pendant 8 heures';

  @override
  String get decline => 'Refuser';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Envoyer';

  @override
  String get close => 'Fermer';

  @override
  String get expand => 'Développer';

  @override
  String get zoomIn => 'Zoom avant';

  @override
  String get zoomOut => 'Zoom arrière';

  @override
  String get resetZoom => 'Réinitialiser le zoom';

  @override
  String get scanQrPrompt =>
      'Scannez le QR code de Control Center pour associer ce téléphone.';

  @override
  String get scanQrHelp =>
      'Ouvrez l’appareil photo et pointez-le vers le QR affiché dans Control Center. Ce téléphone se connecte directement via un lien privé.';

  @override
  String get connectingToMac => 'Connexion à Control Center…';

  @override
  String get connectingDetail =>
      'Établissement d’une liaison directe et sécurisée.';

  @override
  String get identityChangedTitle => 'Identité du serveur modifiée';

  @override
  String get identityChangedBody =>
      'Ce serveur ne correspond plus à l’identité enregistrée lors de l’association. Cela peut indiquer une réinstallation du serveur — ou qu’une tierce partie intercepte la connexion. Par sécurité, cet appareil ne se connectera pas. Supprimez l’association, puis scannez un nouveau QR code depuis Control Center pour réassocier.';

  @override
  String get removePairing => 'Supprimer l’association';

  @override
  String get couldntConnect => 'Connexion impossible';

  @override
  String get pendingPairingTitle => 'Se connecter à ce serveur ?';

  @override
  String get pendingPairingBody =>
      'Un lien a demandé à Control Center d’associer ce serveur. Poursuivez uniquement si c’est vous qui l’avez initié.';

  @override
  String get connect => 'Connecter';

  @override
  String get failureNotPaired =>
      'Non associé — scannez le QR code depuis Control Center';

  @override
  String get failureUnreachable =>
      'Impossible d’atteindre le serveur par aucun chemin — vérifiez qu’il est lancé, ou essayez le même réseau';

  @override
  String get failureIdentityChanged =>
      'L’identité du serveur a changé — s’il a été réinstallé, réassociez cet appareil';

  @override
  String get failureAuthRejected =>
      'Le serveur a refusé cet appareil — réassociez-le depuis Control Center';

  @override
  String get failureUnknown => 'Connexion impossible — appuyez pour réessayer';

  @override
  String get statusConnected => 'Connecté';

  @override
  String get statusConnecting => 'Connexion';

  @override
  String get statusOffline => 'Hors ligne';

  @override
  String get statusIdentityMismatch => 'Identité différente';

  @override
  String get statusNotPaired => 'Non associé';

  @override
  String get statusConfirmPairing => 'Confirmer l’association';

  @override
  String get connectionFailed => 'Échec de la connexion';

  @override
  String get identityMismatchBanner =>
      'Identité du serveur modifiée — connexion interrompue. Réassociez cet appareil pour continuer.';

  @override
  String get tabInbox => 'Boîte de réception';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Discussion';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Calendrier';

  @override
  String get tabNews => 'Actualités';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count en attente';
  }

  @override
  String get updateAvailable =>
      'Une nouvelle version de Control Center est disponible';

  @override
  String get appearance => 'Apparence';

  @override
  String get language => 'Langue';

  @override
  String get device => 'Appareil';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get languageSystem => 'Système';

  @override
  String get disconnectTapAgain =>
      'Appuyez de nouveau pour déconnecter cet appareil de Control Center';

  @override
  String get disconnectDevice => 'Déconnecter cet appareil';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get chooseWorkspace => 'Choisir un espace de travail';

  @override
  String get workspaces => 'Espaces de travail';

  @override
  String get workspacesLoadFailed =>
      'Impossible de charger les espaces de travail';

  @override
  String get noWorkspacesYet => 'Aucun espace de travail';

  @override
  String selectWorkspace(String name) {
    return 'Sélectionner $name';
  }

  @override
  String get inboxLoadFailed => 'Impossible de charger la boîte de réception';

  @override
  String get allCaughtUp => 'Vous êtes à jour';

  @override
  String get inboxNoForgeAccount =>
      'Aucun compte forge n’est connecté sur le serveur, les pull requests ne peuvent donc pas encore vous être attribuées.';

  @override
  String get inboxNothingWaiting =>
      'Rien n’est bloqué et aucune pull request n’attend votre action.';

  @override
  String get blocked => 'Bloqué';

  @override
  String get sectionNeedsYourReview => 'En attente de votre revue';

  @override
  String get sectionReturnedToYou => 'Renvoyées vers vous';

  @override
  String get sectionApprovedAndReady => 'Approuvées et prêtes';

  @override
  String get sectionYourDrafts => 'Vos brouillons';

  @override
  String get sectionWaitingForReviewers => 'En attente de relecteurs';

  @override
  String get sectionMergingAndMerged => 'En fusion et récemment fusionnées';

  @override
  String get sectionWaitingForAuthor => 'En attente de l’auteur';

  @override
  String waitingAgo(String ago) {
    return 'en attente $ago';
  }

  @override
  String get openConversation => 'Ouvrir la conversation';

  @override
  String get calendarLoadFailed => 'Impossible de charger le calendrier';

  @override
  String get nothingScheduled => 'Rien de prévu';

  @override
  String get calendarEmptyDescription =>
      'Les événements de vos calendriers connectés s’affichent ici.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Synchroniser les calendriers maintenant';

  @override
  String get event => 'Événement';

  @override
  String get eventNotFound => 'Événement introuvable';

  @override
  String get eventNotFoundDescription =>
      'Il est peut-être hors de la fenêtre d’agenda, ou a été supprimé en amont.';

  @override
  String get joinMeeting => 'Rejoindre la réunion';

  @override
  String get join => 'Rejoindre';

  @override
  String attendeesCount(int count) {
    return 'Participants ($count)';
  }

  @override
  String get details => 'Détails';

  @override
  String get allDay => 'Toute la journée';

  @override
  String get happeningNow => 'En cours';

  @override
  String inDuration(String duration) {
    return 'Dans $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead : $title';
  }

  @override
  String get attendeeAccepted => 'accepté';

  @override
  String get attendeeDeclined => 'refusé';

  @override
  String get attendeeMaybe => 'peut-être';

  @override
  String get attendeeNoReply => 'sans réponse';

  @override
  String get organizer => 'organisateur';

  @override
  String get calendarNoAccounts =>
      'Aucun calendrier n’est connecté pour cet espace de travail. Connectez-en un depuis l’application de bureau — la connexion stocke son jeton sur le serveur.';

  @override
  String get calendarReauthNeeded =>
      'Un compte calendrier doit être reconnecté — ce que vous voyez ci-dessous peut être obsolète. Reconnectez-le depuis l’application de bureau.';

  @override
  String get spacesLoadFailed => 'Impossible de charger les espaces';

  @override
  String get noSpaces => 'Aucun espace';

  @override
  String get spacesEmptyDescription =>
      'Les espaces de cet espace de travail s’affichent ici.';

  @override
  String get newSpaceFolder => 'Nouveau dossier';

  @override
  String get folderName => 'Nom du dossier';

  @override
  String get renameSpaceFolder => 'Renommer le dossier';

  @override
  String get deleteSpaceFolder => 'Supprimer le dossier';

  @override
  String get moveSpaceToFolder => 'Déplacer vers un dossier';

  @override
  String get removeSpaceFromFolder => 'Retirer du dossier';

  @override
  String get spaceFolderActions => 'Actions du dossier';

  @override
  String get deleteFolderWithSpacesWarning =>
      'La suppression définitive des espaces efface leurs messages et leurs répertoires de travail pour tout le monde. Cette action est irréversible.';

  @override
  String get deleteSpacesInFolder =>
      'Supprimer définitivement les espaces de ce dossier';

  @override
  String get deleteFolderAndSpaces => 'Supprimer le dossier et les espaces';

  @override
  String get keepSpacesInFolder =>
      'Sinon, les espaces resteront hors de tout dossier.';

  @override
  String get create => 'Créer';

  @override
  String get otherSpaces => 'Autres espaces';

  @override
  String get folderUpdateFailed => 'Impossible de mettre à jour les dossiers';

  @override
  String get thread => 'Fil';

  @override
  String get agentWorking => 'L’agent travaille';

  @override
  String get messagesLoadFailed => 'Impossible de charger les messages';

  @override
  String get noMessagesYet => 'Aucun message pour l\'instant';

  @override
  String get noMessagesDescription =>
      'Envoyez un message pour démarrer la conversation.';

  @override
  String get agentResponding => 'Agent en cours';

  @override
  String get agentFinished => 'Agent terminé';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sont trop volumineux pour être envoyés d’ici.',
      one: '$names est trop volumineux pour être envoyé d’ici.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$names sont trop volumineux pour être envoyés via le relais d’ici.',
      one: '$names est trop volumineux pour être envoyé via le relais d’ici.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Impossible d’envoyer la pièce jointe. Réessayez.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pièces jointes n’ont pas pu être envoyées et ont été omises.',
      one: '1 pièce jointe n’a pas pu être envoyée et a été omise.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Collègue';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Joindre un fichier';

  @override
  String get messageHint => 'Message';

  @override
  String removeAttachment(String name) {
    return 'Supprimer $name';
  }

  @override
  String get articlesLoadFailed => 'Impossible de charger les articles';

  @override
  String get noArticles => 'Aucun article';

  @override
  String get articlesEmptyDescription =>
      'Les nouveaux articles apparaissent ici au fil des mises à jour.';

  @override
  String get unread => 'Non lus';

  @override
  String get allFeeds => 'Tous les flux';

  @override
  String get save => 'Enregistrer';

  @override
  String get unsave => 'Retirer';

  @override
  String get readFullArticle => 'Lire l’article complet';

  @override
  String get ticketsLoadFailed => 'Impossible de charger les tickets';

  @override
  String get noTickets => 'Aucun ticket';

  @override
  String get ticketsEmptyDescription =>
      'Les tickets de cet espace de travail apparaissent ici.';

  @override
  String get all => 'Tout';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Impossible de charger le ticket';

  @override
  String assignedTo(String name) {
    return 'Assigné à $name';
  }

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get status => 'Statut';

  @override
  String get assign => 'Assigner';

  @override
  String get reassign => 'Réassigner';

  @override
  String get noAgents => 'Aucun agent';

  @override
  String get noAgentsDescription =>
      'Assignez un agent de cet espace de travail.';

  @override
  String get statusOpen => 'Ouvert';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusBlocked => 'Bloqué';

  @override
  String get statusInReview => 'En revue';

  @override
  String get statusDone => 'Terminé';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Pour moi';

  @override
  String get lensMine => 'Les miens';

  @override
  String get prsLoadFailed => 'Impossible de charger les pull requests';

  @override
  String get noOpenPullRequests => 'Aucune pull request ouverte';

  @override
  String get nothingWaitingOnReview => 'Rien n’attend votre relecture';

  @override
  String get noOwnOpenPullRequests => 'Vous n’avez aucune pull request ouverte';

  @override
  String get nothingBlocked => 'Rien de bloqué';

  @override
  String get prsEmptyDescription =>
      'Les pull requests des dépôts de cet espace de travail apparaissent ici.';

  @override
  String get refreshPullRequests => 'Actualiser les pull requests';

  @override
  String get noForgeConnected =>
      'Aucune forge n’est connectée au serveur, les pull requests ne peuvent pas être récupérées. Connectez-en une depuis l’application de bureau.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépôts n’ont pas pu être lus.',
      one: '1 dépôt n’a pas pu être lu.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Illisibles : $names';
  }

  @override
  String get installationSuspendedTitle => 'Installation GitHub App suspendue';

  @override
  String installationSuspendedBody(String names) {
    return 'Affichage des dernières données connues pour $names. Reprenez l\'installation sur GitHub, ou connectez un jeton qui y a accès.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Installation GitHub App suspendue. Affichage des dernières données connues pour $names. Reprenez l\'installation sur GitHub, ou connectez un jeton qui y a accès.';
  }

  @override
  String get draft => 'Brouillon';

  @override
  String get merged => 'Fusionné';

  @override
  String get closed => 'Fermé';

  @override
  String get open => 'Ouverte';

  @override
  String get approved => 'Approuvé';

  @override
  String get changesRequested => 'Modifications demandées';

  @override
  String get reviewRequired => 'Relecture requise';

  @override
  String get checksPassing => 'Vérifications réussies';

  @override
  String get checksFailing => 'Échec des vérifications';

  @override
  String get checksRunning => 'Vérifications en cours';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Impossible de charger cette pull request';

  @override
  String get openOnForge => 'Ouvrir sur la forge';

  @override
  String get requestChangesNeedsComment =>
      'Ajoutez un commentaire expliquant les changements nécessaires.';

  @override
  String get conversation => 'Conversation';

  @override
  String get files => 'Fichiers';

  @override
  String get checks => 'Vérifications';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Conflits';

  @override
  String get reviewers => 'RELECTEURS';

  @override
  String get noDescriptionNoComments =>
      'Pas encore de description ni de commentaires.';

  @override
  String get noChangedFiles => 'Aucun fichier modifié.';

  @override
  String get noChecksReported =>
      'Aucun contrôle signalé pour le commit de tête.';

  @override
  String get reviewCommentHint => 'Laisser un commentaire de relecture…';

  @override
  String get comment => 'Commentaire';

  @override
  String get commentPosted => 'Commentaire publié';

  @override
  String get request => 'Demander';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — aucune action disponible.';
  }

  @override
  String get reviewApproved => 'approuvée';

  @override
  String get reviewRequestedChanges => 'changements demandés';

  @override
  String get reviewCommented => 'commentée';

  @override
  String get reviewPending => 'en attente';

  @override
  String get unknownAuthor => 'inconnu';

  @override
  String hideDiffFor(String file) {
    return 'Masquer le diff de $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Afficher le diff de $file';
  }

  @override
  String get checkRunning => 'en cours';

  @override
  String get checkPassed => 'réussi';

  @override
  String get checkFailed => 'échoué';

  @override
  String get checkCancelled => 'annulé';

  @override
  String get checkSkipped => 'ignoré';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'Aucun diff texte pour ce fichier — il est binaire, ou trop volumineux pour que la forge en renvoie un.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher les $count lignes restantes',
      one: 'Afficher la ligne restante',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes inchangées',
      one: '1 ligne inchangée',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Aller au plus récent';

  @override
  String get streaming => 'En cours';

  @override
  String get working => 'En cours';

  @override
  String get input => 'Entrée';

  @override
  String get output => 'Sortie';

  @override
  String get now => 'à l’instant';

  @override
  String agoMinutes(int count) {
    return '$count min';
  }

  @override
  String agoHours(int count) {
    return '$count h';
  }

  @override
  String agoDays(int count) {
    return '$count j';
  }

  @override
  String get today => 'Aujourd’hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get yesterday => 'hier';

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String durationHours(int count) {
    return '$count h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get mobileConversations => 'Conversations';

  @override
  String get mobileNewConversation => 'Nouvelle conversation';

  @override
  String get mobileConversationName => 'Nom de la conversation';

  @override
  String get mobileRename => 'Renommer';

  @override
  String get mobileManageSpace => 'Gérer l’espace';

  @override
  String get mobileArchived => 'Archivé';

  @override
  String get mobileSearchMessages =>
      'Rechercher dans tous les messages de cet espace';

  @override
  String get mobileSearch => 'Rechercher';

  @override
  String get mobileNoResults => 'Aucun résultat';

  @override
  String get mobileReopen => 'Rouvrir';

  @override
  String get mobileArchive => 'Archiver';

  @override
  String get mobileProgress => 'Progression et contexte';

  @override
  String get mobileReadFailed =>
      'Impossible de marquer cette conversation comme lue';

  @override
  String get mobileSendFailed =>
      'Message non envoyé. Votre brouillon est conservé.';

  @override
  String get sentAttachmentUnavailable => 'Pièce jointe indisponible';

  @override
  String get sentAttachmentLoadFailed =>
      'Impossible de charger la pièce jointe';

  @override
  String get mobileActionFailed => 'Échec de l\'action';

  @override
  String get mobileRemove => 'Retirer';

  @override
  String get mobileLinkedMessage => 'Message lié';

  @override
  String get mobileOlderMessages => 'Messages précédents';

  @override
  String get mobileMessageActions => 'Actions sur le message';

  @override
  String get mobileOpenThread => 'Ouvrir le fil';

  @override
  String get mobileCopyLink => 'Copier le lien';

  @override
  String get mobileStopRun => 'Arrêter l\'exécution';

  @override
  String get mobileStopRunConfirm =>
      'Arrêter cette exécution de l’agent ? Le travail déjà effectué sera conservé.';

  @override
  String get mobileControlUnsupported =>
      'Cette exécution est terminée ou ne prend pas en charge cette commande.';

  @override
  String get mobilePauseRequested => 'Pause demandée à la fin du prochain tour';

  @override
  String get mobileResumed => 'Exécution reprise';

  @override
  String get mobileStopRequested => 'Arrêt demandé';

  @override
  String get mobileQueuedMessages => 'Messages en attente';

  @override
  String get mobilePauseRun => 'Mettre en pause au prochain tour';

  @override
  String get mobileResumeRun => 'Reprendre';

  @override
  String get mobileEditQueued => 'Modifier le message en attente';

  @override
  String get mobileSteerNow => 'Rediriger maintenant';

  @override
  String get mobileMoveUp => 'Monter';

  @override
  String get mobileMoveDown => 'Descendre';

  @override
  String get mobileQueueChanged =>
      'La file d’attente a changé ou cette exécution ne permet pas d’intervenir en direct. Actualisez et réessayez.';

  @override
  String get mobileActivity => 'Activité';

  @override
  String get mobilePermissions => 'Autorisations et historique';

  @override
  String get mobilePlans => 'Plans';

  @override
  String get mobileGoals => 'Objectifs supervisés';

  @override
  String get mobileCredentials => 'Connexions et identifiants';

  @override
  String get mobileWorkspaceUnavailable =>
      'Cet espace de travail est indisponible ou vous n’y avez plus accès.';

  @override
  String get mobilePrReviewThreads => 'Fils de revue';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Impossible de charger les fils de revue';

  @override
  String get mobilePrNoReviewThreads =>
      'Aucun fil de revue dans le code pour le moment';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Vous n’êtes pas autorisé à commenter ce dépôt.';

  @override
  String get mobilePrPermissionChecking =>
      'Vérification des autorisations de commentaire…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Impossible de vérifier les autorisations de commentaire. Réessayez pour commenter.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, ligne $line';
  }

  @override
  String get mobilePrOriginalSide => 'Original';

  @override
  String get mobilePrSelectCommentLine => 'Choisissez une ligne à commenter';

  @override
  String get mobilePrUpdatedSide => 'Mis à jour';

  @override
  String get mobilePrThreadResolved => 'Résolu';

  @override
  String get mobilePrReplyHint => 'Écrire une réponse…';

  @override
  String get mobilePrCommentRequired =>
      'Rédigez un commentaire avant de publier.';

  @override
  String get mobilePrReply => 'Répondre';

  @override
  String get mobilePrReopenThread => 'Rouvrir le fil';

  @override
  String get mobilePrResolveThread => 'Résoudre le fil';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Seuls l’auteur de la pull request ou une personne ayant accès en écriture peuvent résoudre ce fil.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Commenter $side, ligne $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Écrire un commentaire dans le code…';

  @override
  String get mobilePrPostInlineComment => 'Publier le commentaire';

  @override
  String get mobilePrCommentUnavailable =>
      'Les commentaires dans le code ne sont pas disponibles pour cette pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'La forge n’a pas fourni de patch texte pour ce fichier.';

  @override
  String get mobilePrNoPatchForFile =>
      'Le patch de ce fichier n’est pas disponible.';

  @override
  String get mobileTicketNew => 'Nouveau ticket';

  @override
  String get mobileTicketCreate => 'Créer un ticket';

  @override
  String get mobileTicketEdit => 'Modifier le ticket';

  @override
  String get mobileTicketTitle => 'Titre';

  @override
  String get mobileTicketTitleRequired =>
      'Saisissez un titre pour enregistrer ce ticket.';

  @override
  String get mobileTicketDescription => 'Description';

  @override
  String get mobileTicketMarkdownHint => 'Ajouter des détails en Markdown';

  @override
  String get mobileTicketPriority => 'Priorité';

  @override
  String get mobileTicketPriorityNone => 'Aucune priorité';

  @override
  String get mobileTicketPriorityUrgent => 'Urgent';

  @override
  String get mobileTicketPriorityHigh => 'Élevé';

  @override
  String get mobileTicketPriorityMedium => 'Moyen';

  @override
  String get mobileTicketPriorityLow => 'Faible';

  @override
  String get mobileTicketLabels => 'Étiquettes';

  @override
  String get mobileTicketLabelsHint => 'Une étiquette par ligne';

  @override
  String get mobileTicketLabelsHelp =>
      'Saisissez chaque étiquette sur une ligne distincte.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Créé dans $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Non assigné';

  @override
  String get mobileTicketAssignedFilter => 'Assignés';

  @override
  String get mobileTicketAgentsLoadFailed => 'Impossible de charger les agents';

  @override
  String get mobileTicketSearch => 'Rechercher des tickets';

  @override
  String get mobileTicketSearchHint =>
      'Titre, clé, description, étiquette ou personne assignée';

  @override
  String get mobileTicketClearSearch => 'Effacer la recherche de tickets';

  @override
  String get mobileTicketNoMatches => 'Aucun ticket correspondant';

  @override
  String get mobileTicketAdjustFilters =>
      'Essayez une autre recherche ou modifiez les filtres.';

  @override
  String get mobileTicketClearFilters => 'Effacer les filtres';

  @override
  String get mobileTicketNotFound => 'Ticket introuvable';

  @override
  String get mobileTicketNotFoundDescription =>
      'Ce ticket a peut-être été supprimé ou déplacé hors de cet espace de travail.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'L’espace de travail a changé. Revenez à l’espace de travail actuel avant d’enregistrer.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Ouvrir l’espace lié';

  @override
  String get mobileTicketReadOnly =>
      'Vous devez être membre de l’espace de travail pour modifier les tickets.';

  @override
  String get permissionTitle => 'Autorisations';

  @override
  String get permissionWorkspaceFailed =>
      'Impossible de charger l’espace de travail';

  @override
  String get permissionNoWorkspace =>
      'Sélectionnez un espace de travail pour examiner les autorisations.';

  @override
  String get permissionLoading => 'Chargement des autorisations…';

  @override
  String get permissionScopeDescription =>
      'Examinez comment chaque action est autorisée à cette portée. Les agents et les espaces peuvent hériter des règles de l’espace de travail.';

  @override
  String get permissionScope => 'Portée des règles';

  @override
  String get permissionWorkspaceScope => 'Espace de travail';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Espace';

  @override
  String get permissionAgentContext => 'Agent agissant dans cet espace';

  @override
  String get permissionNoAgentContext => 'Aucun agent sélectionné';

  @override
  String get permissionTargetsFailed =>
      'Impossible de charger les cibles de cette portée';

  @override
  String get permissionNoTargets => 'Aucune cible disponible à cette portée.';

  @override
  String get permissionRoleFailed =>
      'Impossible de confirmer votre rôle dans l’espace de travail';

  @override
  String get permissionMemberRequired =>
      'Vous devez être membre de l’espace de travail pour consulter les règles.';

  @override
  String get permissionRulesFailed => 'Impossible de charger les règles';

  @override
  String get permissionAuditAdminOnly =>
      'L’historique des autorisations est réservé aux administrateurs de l’espace de travail.';

  @override
  String get permissionAllow => 'Autoriser';

  @override
  String get permissionAsk => 'Demander d\'abord';

  @override
  String get permissionDeny => 'Refuser';

  @override
  String get permissionFileDelete => 'Supprimer des fichiers';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Écrire hors de l’arbre de travail';

  @override
  String get permissionGitCommit => 'Créer un commit';

  @override
  String get permissionGitPush => 'Pousser des commits';

  @override
  String get permissionPrCreate => 'Créer des pull requests';

  @override
  String get permissionPrPublish => 'Publier des pull requests';

  @override
  String get permissionVendorSyncWrite =>
      'Écrire dans la synchronisation fournisseur';

  @override
  String get permissionNetworkEgress => 'Accéder au réseau';

  @override
  String get permissionSecretAccess => 'Accéder aux secrets';

  @override
  String get permissionPackageInstall => 'Installer des paquets';

  @override
  String get permissionProcessSpawn => 'Lancer des processus';

  @override
  String get permissionWorkspaceMutation => 'Modifier l’espace de travail';

  @override
  String get permissionEnclosureControl => 'Contrôler l’enceinte';

  @override
  String get permissionChangeFailed => 'Impossible de modifier la règle';

  @override
  String get permissionEffectiveDescription =>
      'Décision applicable à cette portée sans arguments d’action. Les autorisations conditionnelles ci-dessous ne valent que pour les requêtes correspondantes ; le serveur prend la décision finale.';

  @override
  String get permissionSpaceAgentNote =>
      'Aucun agent sélectionné. Choisissez-en un ci-dessus pour voir ses règles spécifiques.';

  @override
  String get permissionScopedGrants => 'Règles à cette portée';

  @override
  String get permissionModePreset => 'Préréglage du mode';

  @override
  String get permissionBuiltInDefault => 'Valeur par défaut';

  @override
  String get permissionRemembered => 'Autorisation mémorisée';

  @override
  String get permissionSource => 'Source';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · définie ici';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · héritée';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Expire le $date';
  }

  @override
  String get permissionSetHere => 'Définir une règle ici';

  @override
  String get permissionRevokeBeforeEdit =>
      'Révoquez la règle de cette portée ou l’autorisation mémorisée avant de définir une règle générale pour cette action.';

  @override
  String get permissionConfirmRevoke => 'Confirmer la révocation';

  @override
  String get permissionRevokeRule => 'Révoquer la règle';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Préfixe de commande : $prefix';
  }

  @override
  String get permissionNoExpiry => 'Sans expiration';

  @override
  String get permissionExpired => 'Expirée';

  @override
  String get permissionExplicitRule => 'Règle explicite';

  @override
  String get permissionEnforcementAdvisory =>
      'Consultatif : les règles « demander d’abord » sont consignées sans solliciter d’approbation';

  @override
  String get permissionEnforcementSoft =>
      'Application souple : toute dérogation nécessite une autorisation';

  @override
  String get permissionEnforcementHard =>
      'Application stricte : aucune dérogation possible';

  @override
  String permissionPaths(String paths) {
    return 'Chemins : $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Références Git : $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hôtes : $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Commandes : $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Nombre maximal : $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Nombre maximal de centimes : $cents';
  }

  @override
  String get permissionAuditHeading => 'Historique des autorisations';

  @override
  String get permissionAuditDescription =>
      'Décisions récentes enregistrées par le serveur. Seuls les administrateurs peuvent consulter le journal ou vérifier sa chaîne de hachage.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'au nom de $user';
  }

  @override
  String get permissionPrompted => 'Approbation humaine demandée';

  @override
  String get permissionVerifyChain => 'Vérifier la chaîne d’audit';

  @override
  String get permissionVerifyFailed =>
      'Impossible de vérifier la chaîne d’audit';

  @override
  String permissionChainIntact(String count) {
    return 'Chaîne intacte · $count entrées vérifiées';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Chaîne rompue à l’entrée $sequence : $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Aucune décision d’autorisation enregistrée pour le moment.';

  @override
  String get permissionAuditFailed =>
      'Impossible de charger l’historique des autorisations';

  @override
  String get mobilePlansLoadFailed => 'Impossible de charger les plans';

  @override
  String get mobilePlansEmpty => 'Aucun plan pour le moment';

  @override
  String get mobilePlansEmptyDescription =>
      'Les plans soumis par les agents apparaîtront ici pour revue.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Ce plan n’est plus disponible dans cet espace de travail.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count étapes';
  }

  @override
  String get mobilePlanDraft => 'Brouillon';

  @override
  String get mobilePlanProposed => 'En attente de revue';

  @override
  String get mobilePlanApproved => 'Approuvé';

  @override
  String get mobilePlanRejected => 'Rejeté';

  @override
  String get mobilePlanSuperseded => 'Remplacé';

  @override
  String get mobilePlanExecuting => 'En cours';

  @override
  String get mobilePlanSynthesizing => 'Synthèse';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Échec';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Révision $revision';
  }

  @override
  String get mobilePlanSteps => 'Étapes';

  @override
  String get mobilePlanNoSteps => 'Aucune étape n’a été soumise pour ce plan.';

  @override
  String get mobilePlanAssumptions => 'Précisions';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Dépend de $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Coût estimé jusqu’à $cost';
  }

  @override
  String get mobilePlanSelect => 'Sélectionner';

  @override
  String get mobilePlanSelected => 'Sélectionné';

  @override
  String get mobilePlanEstimate => 'Estimer le coût';

  @override
  String get mobilePlanEstimateRequired =>
      'Estimez le plan avant d’approuver son exécution.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Coût estimé : $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'indisponible';

  @override
  String get mobilePlanNoHardCap => 'sans plafond fixe';

  @override
  String get mobilePlanExceedsBudget =>
      'L’estimation dépasse le budget défini. Vérifiez-la avant d’approuver.';

  @override
  String get mobilePlanPartialEstimate =>
      'Cette estimation couvre le plan entier ; les étapes sélectionnées peuvent coûter moins cher.';

  @override
  String get mobilePlanConfirmAll => 'Lancer le plan entier ?';

  @override
  String get mobilePlanConfirmSelected => 'Lancer les étapes sélectionnées ?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'L’approbation lance l’exécution et peut entraîner des frais. Coût maximal estimé : $cost. Plafond budgétaire : $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Tout approuver et lancer';

  @override
  String get mobilePlanApproveSelected => 'Approuver la sélection et lancer';

  @override
  String get mobilePlanWiden => 'Approuver d’autres étapes';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Autoriser l’exécution de $count étapes supplémentaires ? Elles peuvent entraîner des frais. Plafond de coût actuel : $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Le plan a changé pendant la revue. Ouvrez la dernière révision et estimez-la à nouveau.';

  @override
  String get mobilePlanReject => 'Rejeter le plan';

  @override
  String get mobilePlanRejectConfirm =>
      'Rejeter ce plan ? Il ne sera pas exécuté.';

  @override
  String get mobilePlanStop => 'Arrêter l’exécution';

  @override
  String get mobilePlanStopConfirm =>
      'Arrêter l’exécution de ce plan ? Le travail déjà effectué ne sera pas annulé.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Exécution : $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Approbation acceptée. En attente du suivi de l’exécution…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed étapes d’exécution terminées sur $total';
  }

  @override
  String get mobilePlanOpenConversation => 'Ouvrir la conversation';

  @override
  String get mobileGoalsTitle => 'Objectifs supervisés';

  @override
  String get mobileGoalsLoadFailed =>
      'Impossible de charger les objectifs supervisés';

  @override
  String get mobileGoalsEmpty => 'Aucun objectif supervisé pour le moment';

  @override
  String get mobileGoalsEmptyDescription =>
      'Lancez-en un dans un espace, ou envoyez /goal dans une conversation.';

  @override
  String get mobileGoalMissing =>
      'Cet objectif n’est plus disponible dans cet espace de travail.';

  @override
  String get mobileGoalActive => 'Actif';

  @override
  String get mobileGoalPaused => 'En pause';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Échec';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Budget atteint';

  @override
  String get mobileGoalGoal => 'Objectif';

  @override
  String get mobileGoalLoop => 'Boucle';

  @override
  String mobileGoalKind(String kind) {
    return 'Type : $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count exécutions';
  }

  @override
  String get mobileGoalNoRunLimit => 'illimité';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Exécutions : $runs / $maxRuns · Dépenses : $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Échéance : $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Exécutions échouées consécutives : $count';
  }

  @override
  String get mobileGoalSummary => 'Résumé d’achèvement';

  @override
  String get mobileGoalFailedDescription =>
      'Le superviseur s’est arrêté après plusieurs échecs. Consultez la conversation pour en savoir plus.';

  @override
  String get mobileGoalBudgetWall =>
      'L’échéance ou la limite d’exécutions a été atteinte. Augmenter le plafond de coût ne permettra pas de reprendre cet objectif.';

  @override
  String get mobileGoalPause => 'Mettre l\'objectif en pause';

  @override
  String get mobileGoalResume => 'Reprendre l\'objectif';

  @override
  String get mobileGoalStop => 'Annuler l’objectif';

  @override
  String get mobileGoalStopConfirm =>
      'Annuler définitivement cet objectif supervisé ? Il ne pourra pas être repris.';

  @override
  String get mobileGoalRaiseBudget => 'Augmenter le budget et reprendre';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Porter le budget à $amount et reprendre';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Augmenter le plafond de coût de cet objectif de $oldCap à $newCap et reprendre les dépenses ?';
  }

  @override
  String get mobileGoalOpenConversation =>
      'Ouvrir la conversation de l’objectif';

  @override
  String get mobileGoalCreate => 'Lancer un objectif supervisé';

  @override
  String get mobileGoalChooseSpace => 'Exécuter dans l’espace';

  @override
  String get mobileGoalNoSpaces =>
      'Créez un espace avant de lancer un objectif.';

  @override
  String get mobileGoalChooseAgent => 'Exécuter avec l’agent';

  @override
  String get mobileGoalNoAgents =>
      'Ajoutez un agent actif avant de lancer un objectif.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name sélectionné';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Quel résultat l’agent doit-il atteindre ?';

  @override
  String get mobileGoalBudgetUsd => 'Plafond de coût (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Choisissez un espace et un agent, saisissez un objectif et définissez un plafond de coût positif en USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Lancer un objectif supervisé avec un coût maximal de $cap ? L’agent peut commencer immédiatement.';
  }

  @override
  String get mobileGoalUnavailable =>
      'La connexion au serveur n’est pas prête. Réessayez une fois reconnecté.';

  @override
  String get mobileGoalConversationMissing =>
      'La conversation sélectionnée n’est plus disponible dans cet espace de travail.';

  @override
  String get mobileGoalCreateSent =>
      'Objectif lancé. Son suivi apparaîtra dans cette liste.';

  @override
  String get mobileGoalStartRefused =>
      'Aucune exécution d’objectif lancée. Consultez la conversation pour connaître la raison donnée par le superviseur.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name sélectionné';
  }

  @override
  String get requestUnavailable =>
      'Cette demande n’est plus disponible dans l’espace de travail actif.';

  @override
  String get requestAlreadyResolved => 'Cette demande a déjà été traitée.';

  @override
  String get inboxCredentialsBlocked => 'Identifiants bloquant des exécutions';

  @override
  String get inboxSyncFailures => 'Échecs de synchronisation fournisseur';

  @override
  String get inboxConfigureCredentials => 'Configurer les identifiants';

  @override
  String get openTicket => 'Ouvrir le ticket';

  @override
  String get activityTitle => 'Activité';

  @override
  String get activityClearAll => 'Effacer l’activité';

  @override
  String get activityClearConfirm =>
      'Cela masquera toute l’activité enregistrée jusqu’ici pour vous sur tous vos appareils. Les nouvelles activités resteront visibles.';

  @override
  String get activityMarkAllRead => 'Tout marquer comme lu';

  @override
  String get activityMarkAllConfirm =>
      'Marquer toutes les activités de cet espace de travail comme lues sur tous vos appareils ?';

  @override
  String get activityMarkRead => 'Marquer comme lu';

  @override
  String get activityMarkUnread => 'Marquer comme non lu';

  @override
  String get activityDismiss => 'Ignorer';

  @override
  String get activityResolved => 'Résolu';

  @override
  String get activityOpen => 'Ouvert';

  @override
  String get activityEmpty => 'Aucune activité pour le moment';

  @override
  String get activityLoadFailed => 'Impossible de charger l’activité';

  @override
  String get activityAgentWaiting => 'L’agent attend une réponse';

  @override
  String get activityAgentBlocked => 'Action de l’agent bloquée';

  @override
  String get activityMessage => 'Nouveau message';

  @override
  String get activityPullRequest => 'Mise à jour de la pull request';

  @override
  String get activityTicket => 'Mise à jour du ticket';

  @override
  String get activityMeeting => 'Mise à jour de la réunion';

  @override
  String get activityCalendar => 'Connexion au calendrier';

  @override
  String get activityRig => 'Mise à jour de l’enceinte';

  @override
  String get activityEvent => 'Mettre à jour';

  @override
  String get activityPrReady => 'Pull request prête à fusionner';

  @override
  String get activityPrBlocked => 'Fusion de la pull request bloquée';

  @override
  String get activityPrApproved => 'Pull request approuvée';

  @override
  String get activityPrChanges => 'Modifications demandées';

  @override
  String get activityPrChecksFailed =>
      'Échec des vérifications de la pull request';

  @override
  String get activityPrChecksRecovered =>
      'Vérifications de la pull request rétablies';

  @override
  String get activityPrComment => 'Commentaire sur la pull request';

  @override
  String get activityPrPublished => 'Pull request publiée';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Mention dans une pull request';

  @override
  String get activityPrReviewRequested => 'Revue demandée';

  @override
  String get activityPrReviewStale => 'Revue à actualiser';

  @override
  String get activityTicketAssigned => 'Ticket assigné';

  @override
  String get activityTicketChanged => 'Statut du ticket modifié';

  @override
  String get activityMeetingSoon => 'Réunion imminente';

  @override
  String get activityCalendarExpired => 'Connexion au calendrier expirée';

  @override
  String get activityRigControl => 'Contrôle de l’enceinte modifié';

  @override
  String get activityRigClosed => 'Enceinte arrêtée';

  @override
  String get mobileSpacesSearch => 'Rechercher des espaces';

  @override
  String get mobileSpacesArchived => 'Archivé';

  @override
  String get mobileSpacesActive => 'Actif';

  @override
  String get mobileSpacesNew => 'Nouveau espace';

  @override
  String get mobileSpacesManage => 'Gérer l’espace';

  @override
  String get mobileSpacesName => 'Nom de l\'espace';

  @override
  String get mobileSpacesAgents => 'Agents';

  @override
  String get mobileSpacesMembers => 'Personnes';

  @override
  String get mobileSpacesRepos => 'Dépôts';

  @override
  String get mobileSpacesAllRepos => 'Tous les dépôts liés';

  @override
  String get mobileSpacesNoRepos => 'Aucun dépôt';

  @override
  String get mobileSpacesBaseBranch => 'Branche de base (facultatif)';

  @override
  String get mobileSpacesDefaultBranch => 'Branche par défaut';

  @override
  String get mobileSpacesMode => 'Mode';

  @override
  String get mobileSpacesModeChat => 'Discussion';

  @override
  String get mobileSpacesModeReview => 'Revue (lecture seule)';

  @override
  String get mobileSpacesModePlan => 'Planification (lecture seule)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestrer';

  @override
  String get mobileSpacesAutonomy => 'Dérogation au niveau d’autonomie';

  @override
  String get mobileSpacesAutonomyInherited => 'Hérité';

  @override
  String get mobileSpacesAutonomyPropose => 'Proposer uniquement';

  @override
  String get mobileSpacesAutonomyApproval => 'Agir avec approbation';

  @override
  String get mobileSpacesAutonomyFreely => 'Agir librement';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Une dérogation ne peut contourner ni les demandes d’approbation ni les refus des règles d’action. Seuls les administrateurs de l’espace de travail peuvent la modifier.';

  @override
  String get mobileSpacesArchive => 'Archiver l\'espace';

  @override
  String get mobileSpacesReopen => 'Rouvrir l’espace';

  @override
  String get mobileSpacesSave => 'Enregistrer les modifications';

  @override
  String get mobileSpacesCreate => 'Créer un espace';

  @override
  String get mobileSpacesOperationFailed =>
      'Impossible de mettre à jour l’espace';

  @override
  String get mobileSpacesMissing =>
      'Espace introuvable dans cet espace de travail';

  @override
  String get mobileSpacesEmptyName => 'Saisissez un nom d’espace';

  @override
  String get mobileSpacesNoMatches => 'Aucun espace correspondant';

  @override
  String get mobileSpacesUnread => 'Réponse d’agent non lue';

  @override
  String get mobileSpacesNeedsInput => 'Votre réponse est attendue';

  @override
  String get mobileSpacesRunning => 'Agent en cours d’exécution';

  @override
  String get mobileSpacesNoAgents => 'Aucun agent dans cet espace de travail';

  @override
  String get mobileSpacesNoMembers =>
      'Aucun autre membre dans cet espace de travail';

  @override
  String get mobileSpacesRepoError => 'Impossible de charger les dépôts';

  @override
  String get mobileSpacesRetry => 'Réessayer';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Choisissez ou saisissez une branche de base lors de la création d’un espace ; celle d’un espace existant ne peut pas être modifiée.';

  @override
  String get mobileSpacesArchivedEmpty => 'Aucun espace archivé';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Les dépôts ajoutés ultérieurement à l’espace de travail seront aussi inclus dans cet espace.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Espace créé. Réessayez d’ajouter des personnes ou ouvrez sa page de gestion.';

  @override
  String get progressTitle => 'Progression';

  @override
  String get progressConversation => 'Conversation';

  @override
  String get progressLoadFailed => 'Impossible de charger la progression';

  @override
  String get progressUnavailable => 'Conversation indisponible';

  @override
  String get progressUnavailableDescription =>
      'Cette conversation n’appartient pas à l’espace de travail ni à l’espace actifs. Revenez à son espace pour continuer.';

  @override
  String get progressSaveFailed => 'Impossible de mettre à jour la progression';

  @override
  String get progressGoal => 'Objectif';

  @override
  String get progressNoGoal => 'Aucun objectif de travail défini';

  @override
  String get progressSetGoal => 'Définir l\'objectif';

  @override
  String get progressEditGoal => 'Modifier l’objectif';

  @override
  String get progressClearGoal => 'Effacer l\'objectif';

  @override
  String get progressGoalRequired =>
      'Saisissez un objectif avant d’enregistrer.';

  @override
  String get progressTodos => 'Tâches';

  @override
  String get transcriptToolTodos => 'Tâches';

  @override
  String get transcriptToolSearchMemory => 'Rechercher dans la mémoire';

  @override
  String get transcriptToolRenderMedia => 'Afficher les médias';

  @override
  String get progressNoTodos => 'Aucune tâche pour le moment';

  @override
  String get progressNewTodo => 'Nouvelle tâche';

  @override
  String get progressAddTodo => 'Ajouter une tâche';

  @override
  String get progressEditTodo => 'Modifier la tâche';

  @override
  String get progressTodoRequired => 'Saisissez une tâche avant d’enregistrer.';

  @override
  String get progressTodoNoLongerExists =>
      'Cette tâche a été supprimée. Rechargez la liste et réessayez.';

  @override
  String get progressWorkspaceChanged =>
      'L’espace de travail actif a changé. Revenez à cette conversation et réessayez.';

  @override
  String progressRemoveTodo(String name) {
    return 'Supprimer la tâche $name';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'En cours';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Monter la tâche';

  @override
  String get progressMoveDown => 'Descendre la tâche';

  @override
  String get progressRunTree => 'Exécutions des agents';

  @override
  String get progressNoRuns =>
      'Aucune exécution dans cette conversation pour le moment';

  @override
  String get progressRunning => 'En cours';

  @override
  String get progressFailed => 'Échec';

  @override
  String get progressUnknown => 'Inconnu';

  @override
  String get progressHealthy => 'Actif';

  @override
  String get progressBlocked => 'Bloqué';

  @override
  String get progressLooping => 'En boucle';

  @override
  String get progressStalled => 'Bloqué';

  @override
  String get progressDead => 'Arrêt inattendu';

  @override
  String get progressQuiet => 'Aucune sortie pour le moment';

  @override
  String get progressCostReported => 'Coût déclaré par le fournisseur';

  @override
  String get progressCostNotional =>
      'Prix catalogue indicatif de l’abonnement ; ce n’est pas une facture';

  @override
  String get progressCostMixed => 'Sources de coût mixtes';

  @override
  String get progressCostEstimated => 'Coût estimé';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modèle : $model · Durée : $duration · Coût : $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Démarré $time';
  }

  @override
  String progressLiveness(String state) {
    return 'État : $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Entrée : $input · Sortie : $output jetons';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Seuls les 6 000 premiers caractères de la sortie structurée sont affichés.';

  @override
  String progressRetryOf(String runId) {
    return 'Nouvelle tentative de l’exécution $runId';
  }

  @override
  String get progressContext => 'Contexte et limites';

  @override
  String get progressNoAgent => 'Aucun agent à examiner';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window jetons';
  }

  @override
  String get progressMeasured =>
      'Contexte déclaré par le fournisseur lors du dernier appel';

  @override
  String get progressEstimated =>
      'Estimation fondée sur la conversation enregistrée et le contexte persistant';

  @override
  String get progressContextUnknown =>
      'Utilisation du contexte non encore communiquée';

  @override
  String progressContextPercent(String percent) {
    return '$percent % de la fenêtre de contexte';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Limite mensuelle configurée pour l’agent : $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Conversation active enregistrée : environ $tokens jetons';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Contexte persistant pour $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt système';

  @override
  String get progressContextRules => 'Règles';

  @override
  String get progressContextSkills => 'Compétences';

  @override
  String get progressContextTools => 'Définitions d\'outils';

  @override
  String get progressContextMcp => 'Outils MCP';

  @override
  String get progressContextDeferred => 'Outils différés';

  @override
  String get progressContextSubagents => 'Sous-agents';

  @override
  String get progressContextRunner => 'Exécuteur externe';

  @override
  String get progressContextMemory => 'Mémoire';

  @override
  String get progressContextHistory => 'Historique de la conversation';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens jetons';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens jetons';
  }

  @override
  String get progressOutputs => 'Sorties récentes';

  @override
  String get progressNoOutputs => 'Aucune sortie récente de l’agent';

  @override
  String get progressStructuredOutputsAbove =>
      'Les sorties structurées des exécutions figurent ci-dessus.';

  @override
  String get progressRecentOutputsOnly =>
      'Seuls les messages récents sont affichés. Ouvrez la conversation pour voir les travaux antérieurs.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artéfact';

  @override
  String get progressResult => 'Résultat';

  @override
  String get progressHideArtifact => 'Masquer l’artéfact';

  @override
  String get progressReadArtifact => 'Lire l’artéfact';

  @override
  String get progressArtifactUnavailable => 'Artéfact indisponible';

  @override
  String get progressArtifactPreviewLimited => 'Aperçu limité de cet artéfact.';

  @override
  String get progressDiagramSource => 'Source du diagramme';

  @override
  String progressOpenAttachment(String name) {
    return 'Ouvrir $name';
  }

  @override
  String get progressOpenPlan => 'Ouvrir le plan';

  @override
  String progressOpenDiff(String label) {
    return 'Examiner les fichiers modifiés : $label';
  }

  @override
  String get progressViewMessage => 'Voir le message';

  @override
  String get pushTitle => 'Notifications en arrière-plan';

  @override
  String get pushIntro =>
      'Recevez une alerte privée quand quelque chose demande votre attention, même si l’application est fermée. Les détails restent dans votre connexion chiffrée.';

  @override
  String get pushLoading => 'Vérification des paramètres de notification…';

  @override
  String get pushError =>
      'Impossible de modifier les notifications. Vérifiez votre connexion et réessayez.';

  @override
  String get pushEnable => 'Activer les notifications';

  @override
  String get pushDisable => 'Désactiver les notifications';

  @override
  String get pushQuiet => 'Suspendre les alertes sur cet appareil';

  @override
  String get pushCategories => 'Me notifier pour';

  @override
  String get pushCategoryAgents => 'Agents';

  @override
  String get pushCategoryMessages => 'Messages';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Tickets';

  @override
  String get pushCategoryCalendar => 'Calendrier';

  @override
  String get pushCategoryMachines => 'Machines';

  @override
  String get pushSecureOrigin => 'Les notifications nécessitent HTTPS.';

  @override
  String get pushInstallIos =>
      'Sur iPhone ou iPad, ajoutez cette application à l’écran d’accueil et ouvrez-la depuis cet écran pour activer les notifications.';

  @override
  String get pushUnsupported =>
      'Ce navigateur ne prend pas en charge les notifications en arrière-plan.';

  @override
  String get pushDenied =>
      'Le navigateur indique que les notifications sont bloquées. Vérifiez l’autorisation de ce site et les réglages de notification du navigateur ou de l’appareil, puis actualisez.';

  @override
  String get pushOsHint =>
      'Votre navigateur doit aussi être autorisé à afficher des notifications dans les réglages système de votre appareil.';

  @override
  String get pushServiceUnavailable =>
      'Le service push du navigateur a refusé l’abonnement. Certains navigateurs, comme Brave, le désactivent par défaut : cherchez une option de messages push dans les réglages de confidentialité du navigateur, puis réessayez.';

  @override
  String get pushWorkerUnavailable =>
      'Le service de notifications n’a pas pu démarrer dans ce navigateur. Rechargez la page et réessayez.';

  @override
  String get pushResubscribe => 'Reconnecter les notifications';

  @override
  String get pushStatusEnabled =>
      'Les notifications sont activées sur cet appareil.';

  @override
  String get pushStatusDisabled =>
      'Les notifications sont désactivées sur cet appareil.';

  @override
  String get credentialsTitle => 'Connexions et identifiants';

  @override
  String get credentialsIntro =>
      'Connectez les comptes utilisés par vos exécutions et vos intégrations. Les secrets sont stockés sur votre serveur, pas sur ce téléphone.';

  @override
  String get credentialsModelProviders => 'Fournisseurs de modèles';

  @override
  String get credentialsOwnerOnly =>
      'Seul le propriétaire du serveur peut ajouter, connecter ou supprimer les identifiants des fournisseurs de modèles. Ces clés sont partagées entre les espaces de travail.';

  @override
  String get credentialsContactOwner =>
      'Demandez au propriétaire du serveur de connecter le fournisseur requis par votre exécution bloquée.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code se connecte via la CLI de l’hôte. Demandez au propriétaire du serveur de terminer ou renouveler la connexion au compte dans le terminal de l’hôte ; ce téléphone ne peut pas le faire.';

  @override
  String get credentialsYourForgeAccounts => 'Vos comptes de forge';

  @override
  String get credentialsYourTicketingAccount =>
      'Votre compte de gestion des tickets';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Les tickets locaux ne nécessitent aucune connexion. Connectez Linear ici si votre espace de travail l’utilise.';

  @override
  String get credentialsMembershipRequired =>
      'Rejoignez un espace de travail pour gérer vos identifiants de forge ou de gestion des tickets. Demandez l’accès à un administrateur de l’espace de travail.';

  @override
  String get credentialsSwitchWorkspace =>
      'Ce lien mène à un autre espace de travail. Passez à cet espace avant de modifier les identifiants.';

  @override
  String get credentialsReturnToInbox =>
      'Revenez à la boîte de réception pour réessayer une exécution bloquée une fois ses identifiants connectés. L’hôte vérifie aussi automatiquement les exécutions en attente.';

  @override
  String get credentialsLoadFailed =>
      'Impossible de charger les connexions. Vérifiez la liaison au serveur et réessayez.';

  @override
  String get credentialsOperationFailed =>
      'Impossible de modifier cette connexion. Vérifiez la liaison au serveur, vos droits d’accès et les identifiants, puis réessayez.';

  @override
  String get credentialsConnected => 'Connecté';

  @override
  String get credentialsNotConnected => 'Non connecté';

  @override
  String credentialsSignedInAs(String username) {
    return 'Connecté en tant que $username';
  }

  @override
  String get credentialsAccount => 'Compte connecté';

  @override
  String get credentialsStoredKey => 'Clé enregistrée';

  @override
  String get credentialsActive => 'Actif';

  @override
  String get credentialsRemove => 'Retirer';

  @override
  String get credentialsRemoveConfirm =>
      'Supprimer vos identifiants enregistrés ? Vous devrez peut-être vous reconnecter.';

  @override
  String get credentialsApiKey => 'Clé API';

  @override
  String get credentialsApiKeyHint => 'Collez une clé API du fournisseur';

  @override
  String get credentialsBrowserLogin => 'Se connecter avec le navigateur';

  @override
  String get credentialsSignInAgain => 'Reconnectez-vous';

  @override
  String get credentialsWaitingForLogin =>
      'En attente d’autorisation dans votre navigateur…';

  @override
  String get credentialsLoginTimedOut =>
      'La connexion a expiré. Relancez la procédure.';

  @override
  String get credentialsCopyCode => 'Copier le code';

  @override
  String get credentialsDeviceCodeHint =>
      'Confirmez ce code sur la page du fournisseur. Gardez cet écran ouvert pendant que le serveur termine la connexion.';

  @override
  String get credentialsPasteRedirect =>
      'Code d’autorisation ou URL de redirection';

  @override
  String get credentialsPasteRedirectHint =>
      'Collez le code ou l’URL de redirection complète du fournisseur';

  @override
  String get credentialsCompleteLogin => 'Terminer la connexion';

  @override
  String get credentialsRedirectUnavailable =>
      'Le rappel du navigateur de ce serveur n’est pas accessible de manière sécurisée depuis un téléphone. Demandez au propriétaire du serveur de configurer un rappel HTTPS public, ou ajoutez plutôt un jeton.';

  @override
  String get credentialsUpdateToken => 'Mettre à jour le jeton';

  @override
  String get credentialsAddToken => 'Ajouter un jeton';

  @override
  String get credentialsPersonalToken => 'Jeton d’accès personnel';

  @override
  String get credentialsPersonalTokenHint =>
      'Collez un jeton d’accès personnel';

  @override
  String get credentialsHostManaged =>
      'Cette connexion provient de l’application serveur ou de son environnement. Seul le propriétaire du serveur peut la modifier là-bas ; vous pouvez toutefois ajouter votre propre jeton.';

  @override
  String get credentialsStopWatching => 'Arrêter la surveillance';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Connexion à Claude Code expirée';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'L\'exécution s\'est arrêtée car son compte ne s\'authentifie plus. Reconnectez-vous, puis relancez le tour.';

  @override
  String get transcriptSignInExpiredTitle => 'Connexion au fournisseur expirée';

  @override
  String get transcriptSignInExpiredBody =>
      'L\'exécution s\'est arrêtée car les identifiants de son fournisseur ne fonctionnent plus. Reconnectez-le dans Paramètres → Fournisseurs, puis relancez le tour.';
}

/// The translations for French, as used in Canada (`fr_CA`).
class AppLocalizationsFrCa extends AppLocalizationsFr {
  AppLocalizationsFrCa() : super('fr_CA');

  @override
  String get scanQrPrompt =>
      'Scannez le code QR de Control Center pour associer ce téléphone.';

  @override
  String get identityChangedBody =>
      'Ce serveur ne correspond plus à l’identité enregistrée lors de l’association. Cela peut indiquer une réinstallation du serveur — ou qu’une tierce partie intercepte la connexion. Par sécurité, cet appareil ne se connectera pas. Supprimez l’association, puis scannez un nouveau code QR depuis Control Center pour réassocier.';

  @override
  String get failureNotPaired =>
      'Non associé — scannez le code QR depuis Control Center';

  @override
  String get tabNews => 'Fil de nouvelles';
}
