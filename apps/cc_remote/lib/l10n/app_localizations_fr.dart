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
  String get teammate => 'Collègue';

  @override
  String get systemSender => 'Système';

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
  String get permissionPrPublish =>
      'Mettre à jour ou fusionner des pull requests';

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
  String get permissionRemembered => 'Approbation temporaire';

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
  String permissionTools(String tools) {
    return 'Outils : $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Sans effet tant que cette action est sur Refuser';

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
  String mobileGoalFailures(String count) {
    return 'Exécutions échouées consécutives : $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Le superviseur s’est arrêté après plusieurs échecs. Consultez la conversation pour en savoir plus.';

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
  String get credentialsConnectCodePrompt => 'Code de confirmation';

  @override
  String get credentialsConnectCodeMalformed =>
      'Ce n\'est pas un code de connexion valide. Les codes comptent 8 lettres et chiffres.';

  @override
  String get credentialsSignInInvalidCode =>
      'Ce code ne correspond pas à cette connexion. Vérifiez-le et réessayez.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Trop de codes erronés. Relancez la connexion.';

  @override
  String get credentialsSignInRetryLater =>
      'Le service de connexion ne répond pas pour le moment. Patientez une minute, puis réessayez.';

  @override
  String get credentialsSignInRefused =>
      'La connexion a été refusée. Relancez-la et approuvez toutes les autorisations demandées.';

  @override
  String get credentialsSignInNotSaved =>
      'La connexion a réussi, mais le serveur n\'a pas pu l\'enregistrer. Réessayez.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'La connexion à $provider n\'est pas encore configurée sur ce serveur.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'L’adresse de retour de connexion de ce serveur n’est pas accessible de manière sécurisée depuis un téléphone. Connectez-vous depuis l’application de bureau, ou demandez au propriétaire du serveur de configurer une adresse HTTPS publique.';

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
  String get credentialsUpdateToken => 'Mettre à jour le jeton';

  @override
  String get credentialsAddToken => 'Ajouter un jeton';

  @override
  String get credentialsPersonalToken => 'Jeton d’accès personnel';

  @override
  String get credentialsPersonalTokenHint =>
      'Collez un jeton d’accès personnel';

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

  @override
  String get permissionHostExecution => 'Exécuter des commandes sur l\'hôte';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Votre connexion à $provider a expiré. Reconnectez-vous.';
  }

  @override
  String get credentialsSignInPaused =>
      'En pause : le service de connexion de cet espace de travail a changé. Elle fonctionnera de nouveau dès le retour du service.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'Impossible de joindre $provider pour le moment. Nouvelle tentative en cours.';
  }

  @override
  String get credentialsScopeWorkspace => 'Cet espace de travail uniquement';

  @override
  String get credentialsScopeAllWorkspaces => 'Tous les espaces de travail';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Supprimer vos identifiants enregistrés de cet espace de travail ? Les autres espaces de travail gardent les leurs.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Supprimer vos identifiants enregistrés de chaque espace de travail qui les partage ?';

  @override
  String get credentialsSignInServerRestarted =>
      'Le serveur a redémarré. Relancez la connexion.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Installez la GitHub App sur $owner pour que l\'automatisation atteigne $names. Touchez pour ouvrir GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'La GitHub App n\'est pas installée sur $owner, l\'automatisation ne peut donc pas atteindre $names. Demandez à un admin de l\'espace de travail de l\'installer.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Ajoutez $names aux dépôts de la GitHub App. Touchez pour ouvrir GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'La GitHub App ne voit pas encore $names. Demandez à un admin de l\'espace de travail de les ajouter à ses dépôts.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Installation de la GitHub App suspendue. L\'automatisation pour $names est en pause jusqu\'à ce qu\'un propriétaire du compte réactive l\'installation sur GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'La personne responsable de l\'automatisation de cet espace de travail ne voit plus $names, donc rien n\'y est exécuté en son nom.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'La personne responsable de l\'automatisation de cet espace de travail n\'est pas connectée à la forge, donc l\'automatisation pour $names attend qu\'elle se connecte.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Impossible de vérifier l\'accès à $names. Nouvelle tentative en cours.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Connectez-vous à $forge pour voir les pull requests de $count dépôts de plus',
      one:
          'Connectez-vous à $forge pour voir les pull requests d\'un dépôt de plus',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dépôts sont masqués, car votre compte $forge ne les voit pas',
      one: '1 dépôt est masqué, car votre compte $forge ne le voit pas',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dépôts sont masqués, car vous n\'y avez pas accès dans cet espace de travail',
      one:
          '1 dépôt est masqué, car vous n\'y avez pas accès dans cet espace de travail',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vérification de votre accès à $count dépôts de plus…',
      one: 'Vérification de votre accès à 1 dépôt de plus…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-mail du compte Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Saisissez l\'adresse e-mail de votre compte Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'Jeton d\'API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Aucun jeton d\'automatisation ne peut lire $names, le travail en arrière-plan y est donc en pause. Un admin peut en ajouter un dans Réglages → Dépôts.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Confirmez dans votre navigateur, puis saisissez le code qu’il affiche.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Ce compte est déjà connecté à une autre personne sur ce serveur. Connectez-vous avec un autre compte.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider est injoignable pour vérifier ce jeton. Réessayez dans un instant.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider refuse ce jeton. Vérifiez que vous l’avez copié en entier et qu’il n’a pas été révoqué.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Ce n’est pas un jeton personnel. Collez un jeton d’accès personnel de votre propre compte $provider, et non un jeton de projet, de groupe, d’espace de travail ou de bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Ce jeton n’a pas le périmètre $scope, nécessaire pour relire et commenter. Créez-en un qui l’a.';
  }

  @override
  String get credentialsTokenExpired =>
      'Ce jeton a expiré. Créez-en un nouveau et collez-le ici.';

  @override
  String get credentialsSignInRateLimited =>
      'Trop de requêtes pour le moment. Patientez un peu, puis réessayez.';

  @override
  String get credentialsSignInCancelled =>
      'La connexion a été annulée ou refusée. Relancez-la quand vous êtes prêt.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Cette connexion n’est plus ouverte : elle a été annulée, utilisée ou remplacée. Relancez-la.';

  @override
  String get noWorkspacesYetHint =>
      'Un administrateur d’espace de travail doit vous inviter, ou le propriétaire du serveur peut créer un espace de travail pour vous.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos désigne maintenant un autre dépôt sur $forge. Reliez-le depuis l’application de bureau ou web pour continuer à l’utiliser.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos désigne maintenant un autre dépôt sur $forge. Un administrateur d’espace de travail doit le relier avant de pouvoir de nouveau l’utiliser.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Les agents ont besoin d’un bac à sable sur ce serveur';

  @override
  String get runSandboxUnavailable =>
      'Ce serveur n’a pas de bac à sable : seul son propriétaire peut y lancer des agents. Le propriétaire peut installer le bac à sable ou le désactiver pour tout le monde.';

  @override
  String get scriptToolCalls => 'Appels d\'outils';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appels',
      one: '1 appel',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count en cours';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count OK';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count échec(s)';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count refusé(s)';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count annulé(s)';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count en file d\'attente';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count ignoré(s)';
  }

  @override
  String get scriptStepQueued => 'En file d\'attente';

  @override
  String get scriptStepSkipped => 'Ignoré';

  @override
  String get scriptGroupLoop => 'Boucle';

  @override
  String get scriptGroupEach => 'Pour chacun';

  @override
  String get scriptGroupParallel => 'En parallèle';

  @override
  String get scriptGroupFunction => 'Fonction';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count appels de plus',
      one: 'Afficher 1 appel de plus',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Appels non placés dans le script';

  @override
  String get scriptToolComputed => 'Outil';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Script';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes',
      one: '1 ligne',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'En cours';

  @override
  String get scriptStateCompleted => 'Terminé';

  @override
  String get scriptStateFailed => 'Échec';

  @override
  String get scriptStateTimedOut => 'Délai expiré';

  @override
  String get scriptStateCancelled => 'Annulé';

  @override
  String get scriptStateMemoryExceeded => 'Mémoire épuisée';

  @override
  String get scriptStateOutputExceeded => 'Sortie trop longue';

  @override
  String get scriptStateSandboxError => 'Erreur du bac à sable';

  @override
  String get scriptStateRefused => 'Refusé';

  @override
  String get scriptOriginLine => 'Depuis un script que l\'agent exécute';

  @override
  String get codeModeTitle => 'Mode code';

  @override
  String get codeModeAvailable => 'Disponible';

  @override
  String get codeModeUnavailable => 'Indisponible';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Ce serveur ne peut pas exécuter de scripts, donc les agents ici appellent leurs outils un par un. Le serveur indique : $reason';
  }

  @override
  String get codeModeNoReason => 'aucune raison n\'a été donnée.';

  @override
  String get workKindUnknown =>
      'Pour une raison que cette version ne nomme pas :';

  @override
  String get workRefusalUnknown => 'Le serveur a refusé ceci :';

  @override
  String workActionFailed(String error) {
    return 'Cela n\'a pas fonctionné : $error';
  }

  @override
  String get wakeKindStopped =>
      'Retenue, car une personne a arrêté l\'exécution.';

  @override
  String get wakeKindAttempts => 'La livraison a échoué trois fois.';

  @override
  String get wakeKindAgentDeleted => 'L\'agent n\'existe plus.';

  @override
  String get wakeKindAgentNotDispatchable => 'L\'agent est retiré.';

  @override
  String get wakeKindAgentPaused => 'L\'agent est en pause.';

  @override
  String get wakeKindPersonRemoved =>
      'La personne pour qui il agit a quitté l\'espace de travail.';

  @override
  String get wakeKindBudgetBlocked => 'Un budget bloque une exécution.';

  @override
  String get wakeKindTakeOver =>
      'Une personne a pris le relais sur le worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'Cette conversation a lancé 30 exécutions à partir de relances au cours de la dernière heure.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Cet espace de travail a lancé 300 exécutions à partir de relances au cours de la dernière heure.';

  @override
  String get wakeKindLiveRunNoInput =>
      'L\'exécution en cours de l\'agent ici ne prend aucune saisie.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'L\'exécution en cours de l\'agent ici fonctionne autrement, donc celle-ci démarre sa propre exécution après elle.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'L\'exécution en cours de l\'agent ici agit pour quelqu\'un d\'autre, donc celle-ci démarre sa propre exécution après elle.';

  @override
  String get wakeKindDispatchRefused => 'L\'exécution n\'a pas pu démarrer.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Aucun bac à sable n\'est disponible pour une exécution en lecture seule.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Le back-end de cet agent ne peut pas garder une exécution en lecture seule.';

  @override
  String get wakeKindServerStopped =>
      'Un redémarrage du serveur a arrêté l\'exécution.';

  @override
  String get wakeKindServerRestarted =>
      'Le serveur a redémarré pendant l\'exécution d\'une personne.';

  @override
  String get wakeKindGuardFailed =>
      'Une vérification avant livraison a échoué.';

  @override
  String get wakeKindLimit =>
      'En attente de la réinitialisation de la limite d\'utilisation du fournisseur.';

  @override
  String get wakeKindLimitRunLive =>
      'En attente de la fin de l\'exécution à la limite d\'utilisation.';

  @override
  String get wakeKindWakeMissed => 'Manquée pendant l\'arrêt du serveur.';

  @override
  String get wakeKindPipelineRunEnded =>
      'Son exécution de pipeline est terminée.';

  @override
  String get wakeKindGoalEnded => 'Son objectif est terminé.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Son objectif a épuisé son budget.';

  @override
  String get wakeKindGoalReviewStale =>
      'L\'objectif a changé depuis la demande de cette revue.';

  @override
  String get wakeKindGoalPaused => 'Son objectif est en pause.';

  @override
  String get wakeKindGoalHeld => 'Son objectif est retenu.';

  @override
  String get wakeKindGoalStopped => 'Son objectif a été arrêté.';

  @override
  String get wakeKindAskSettled =>
      'La question à laquelle elle répond a déjà été réglée.';

  @override
  String get wakeKindRuleEnded => 'Sa planification est terminée.';

  @override
  String get wakeRefusalNotYours =>
      'Cette relance agit pour une autre personne. Seule elle peut la livrer ou la reprendre.';

  @override
  String get wakeRefusalSettled => 'Cette relance est déjà réglée.';

  @override
  String get goalRefusalAlreadyActive => 'Cet agent a déjà un objectif actif.';

  @override
  String get goalRefusalNotInReview => 'Cet objectif n\'attend pas de revue.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Les preuves de l\'objectif sont incomplètes.';

  @override
  String get goalRefusalClaimPending =>
      'Une affirmation selon laquelle il est terminé est encore en cours de vérification.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Cet objectif n\'a aucun segment en cours.';

  @override
  String get goalRefusalNotYours =>
      'Seule la personne qui a lancé cet objectif peut faire cela.';

  @override
  String get goalRefusalNotPaused => 'Mettez d\'abord l\'objectif en pause.';

  @override
  String get goalRefusalContractInvalid =>
      'Le contrat de l\'objectif ne peut pas être lu.';

  @override
  String get goalRefusalCheckerUnknown => 'Aucun agent ne porte ce nom.';

  @override
  String get goalRefusalCheckerAmbiguous => 'Plusieurs agents portent ce nom.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Le vérificateur doit être un autre agent que celui qui fait le travail.';

  @override
  String get goalRefusalCommandInvalid => 'Cet objectif ne peut pas être lu :';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'L\'intervalle est trop court. Choisissez au moins une minute.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Cette heure est trop proche. Choisissez-en une plus tard.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Cette chaîne de relances a utilisé ses exécutions ou son temps.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Vous ne pouvez pas lire ce que cela surveillerait.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Indiquez une date de fin ou un nombre d\'exécutions.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Cette conversation ou cet agent a déjà autant de planifications que permis.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'L\'heure n\'a pas pu être lue.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'La note est trop longue.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'La fin est trop lointaine.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Une limite d\'exécutions, de jours ou de budget est hors plage.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Seule une boucle peut choisir sa prochaine heure.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Cela ne peut pas être surveillé.';

  @override
  String get wakeRuleRefusalRuleEnded =>
      'Cette planification est déjà terminée.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Cette planification appartient à quelqu\'un d\'autre.';

  @override
  String get wakeRuleEndFired => 'Elle a été exécutée une fois.';

  @override
  String get wakeRuleEndExpired => 'Elle a atteint sa date de fin.';

  @override
  String get wakeRuleEndRunCap => 'Elle a utilisé ses exécutions.';

  @override
  String get wakeRuleEndCostCap => 'Elle a atteint son plafond de coût.';

  @override
  String get wakeRuleEndGoalEnded => 'Son objectif est terminé.';

  @override
  String get wakeRuleEndCancelled => 'Elle a été annulée.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'La personne concernée a quitté l\'espace de travail.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Ses paramètres enregistrés n\'ont pas pu être lus.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Travail en cours sur le segment $segmentString. Personne n\'a besoin d\'agir.';
  }

  @override
  String get goalHoldWaiting =>
      'Il attend un travail qui lui est dû. Il continue de lui-même.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Il attend un travail qui lui est dû. Il continue de lui-même à $time au plus tard.';
  }

  @override
  String get goalHoldVerifying =>
      'Il affirme être terminé. Le serveur exécute ses vérifications, puis un relecteur décide.';

  @override
  String get goalHoldLimit =>
      'En pause à la limite d\'utilisation du fournisseur. Il reprend de lui-même après la réinitialisation.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'En pause à la limite d\'utilisation du fournisseur. Il reprend de lui-même à $time.';
  }

  @override
  String get goalHoldPerson =>
      'En attente d\'une réponse d\'une personne dans la conversation. Il continue dès qu\'une personne répond.';

  @override
  String get goalHoldByPerson =>
      'En pause par une personne. Il reste en pause jusqu\'à ce que quelqu\'un le reprenne.';

  @override
  String get goalHoldNeedsReview =>
      'En attente de revue : il ne peut pas continuer seul. Approuvez-le comme terminé, reprenez-le ou annulez-le.';

  @override
  String get goalHoldBudget =>
      'Il a épuisé son budget. Relevez le budget pour qu\'il puisse continuer.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Pauses à la limite d\'utilisation : $countString sur $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'Aucune progression dans ses derniers segments.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Il a attendu 24 heures sur le même travail sans progression.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'La dernière vérification a échoué.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Le vérificateur n\'a pas pu dire si c\'est terminé.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Aucun bac à sable n\'est disponible pour exécuter ses vérifications.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Son agent vérificateur est indisponible. Choisissez-en un autre, puis reprenez.';

  @override
  String get goalHoldDetailCheckBroken =>
      'Cette vérification ne peut pas être exécutée :';

  @override
  String get goalHoldDetailWakeSkipped => 'Sa relance n\'a pas été livrée.';

  @override
  String get goalHoldDetailClaimPending =>
      'Son affirmation qu\'il est terminé attend une vérification.';

  @override
  String get goalHoldDetailUnanswered =>
      'Une question ou une demande d\'approbation adressée à une personne est restée sans réponse.';

  @override
  String get goalHoldDetailLimitParks =>
      'Il a atteint les limites d\'utilisation trop souvent. Examinez-le, puis reprenez.';

  @override
  String get goalHoldDetailInput =>
      'En attente d\'une réponse dans la conversation.';

  @override
  String goalSegments(int run, int max) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Segment $runString sur $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segment $runString, sans plafond';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '$spent dépensés sur $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Échéance $time';
  }

  @override
  String get goalPipelineStep => 'Une étape de pipeline poursuit cet objectif.';

  @override
  String get goalSummaryHeading => 'Dernier résumé';

  @override
  String get goalDoneMeans => 'Critères d\'achèvement';

  @override
  String get goalChecks => 'Vérifications';

  @override
  String get goalBoundaries => 'Limites';

  @override
  String get goalStopWhen => 'Arrêter et demander quand';

  @override
  String get goalNoMachineCheck =>
      'Aucune vérification automatique. Un relecteur juge d\'après ce qu\'il peut lire.';

  @override
  String get goalCheckEnvironment => 'Tâche de l\'environnement';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Dernière vérification, tour $roundString, $time';
  }

  @override
  String get goalClaim => 'Ce qu\'il affirme';

  @override
  String get goalCheckPassed => 'Réussie';

  @override
  String goalCheckFailed(int code) {
    return 'Échec, code de sortie $code';
  }

  @override
  String get goalCheckTimedOut => 'Délai dépassé';

  @override
  String get goalCheckNotRerun => 'Non relancée : rien n\'a changé';

  @override
  String get goalCheckBroken => 'Impossible à exécuter';

  @override
  String get goalCriterionMet => 'Atteint';

  @override
  String get goalCriterionUnmet => 'Non atteint';

  @override
  String get goalCriterionCannotTell => 'Impossible à dire';

  @override
  String get goalVerdictPass => 'Verdict : terminé';

  @override
  String get goalVerdictFail => 'Verdict : pas terminé';

  @override
  String get goalVerdictCannotVerify => 'Verdict : impossible à dire';

  @override
  String get goalConcerns => 'Réserves';

  @override
  String goalVerifiedBy(String agent) {
    return 'Vérifié par $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Vérifié par lui-même (aucun vérificateur distinct)';

  @override
  String get goalClosedByPerson =>
      'Clos par une personne sans vérification réussie';

  @override
  String get goalApprove => 'Approuver l\'achèvement';

  @override
  String get goalApproveTitle => 'Clore cet objectif comme terminé ?';

  @override
  String get goalApproveBody =>
      'Aucune vérification ne l\'a confirmé. Vous le clôturez sur votre parole, et l\'objectif enregistre qu\'une personne l\'a clos sans vérification.';

  @override
  String get goalApproveConfirm => 'Clore comme terminé';

  @override
  String get goalResumeNotYours =>
      'La reprise ou la hausse de son budget revient à la personne qui l\'a lancé.';

  @override
  String get goalChooseChecker => 'Choisir un autre vérificateur';

  @override
  String goalCheckerSet(String agent) {
    return '$agent le vérifie désormais. Reprenez pour vérifier à nouveau.';
  }

  @override
  String get goalSchedules => 'Planifications';

  @override
  String get goalRepeat => 'Répéter';

  @override
  String get goalCreateChecks => 'Vérifications (facultatif)';

  @override
  String get goalCreateCheckHint =>
      'Une commande qui réussit quand le travail est fait';

  @override
  String get goalCreateAddCheck => 'Ajouter une vérification';

  @override
  String get goalCreateRemoveCheck => 'Supprimer la vérification';

  @override
  String get goalCreateSegmentCap => 'Plafond de segments (facultatif)';

  @override
  String get goalCreateSegmentInvalid =>
      'Le plafond de segments est un nombre entier, d\'au moins 1.';

  @override
  String get scheduleCreateTitle => 'Répéter une consigne';

  @override
  String get scheduleCadence => 'Fréquence';

  @override
  String get scheduleEveryMinutes => 'Toutes les N minutes';

  @override
  String get scheduleEveryHours => 'Toutes les N heures';

  @override
  String get scheduleSelfPaced => 'À rythme libre';

  @override
  String get scheduleSelfPacedHint =>
      'L\'agent choisit le délai après chaque exécution, entre 1 minute et 1 heure.';

  @override
  String get scheduleInterval => 'Intervalle';

  @override
  String get scheduleNote => 'Que doit faire chaque exécution ?';

  @override
  String get scheduleCostCap => 'Plafond de coût en USD (facultatif)';

  @override
  String get scheduleExpiryDays => 'Se termine après N jours (facultatif)';

  @override
  String get scheduleCreateInvalid =>
      'Choisissez un espace et un agent, décrivez ce que chaque exécution doit faire, et indiquez des nombres entiers d\'au moins 1.';

  @override
  String get scheduleCreateButton => 'Démarrer la planification';

  @override
  String get scheduleCreateConfirmTitle => 'Démarrer cette planification ?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Elle s\'exécute toutes les $countString minutes, à partir de maintenant.',
      one: 'Elle s\'exécute chaque minute, à partir de maintenant.',
    );
    return '$_temp0';
  }

  @override
  String scheduleCreateConfirmEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Elle s\'exécute toutes les $countString heures, à partir de maintenant.',
      one: 'Elle s\'exécute chaque heure, à partir de maintenant.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Elle s\'exécute maintenant, puis l\'agent choisit quand relancer.';

  @override
  String get scheduleCreated =>
      'Planification démarrée. Elle figure sous Planifications.';

  @override
  String get schedulesTitle => 'Planifications';

  @override
  String get schedulesLoadFailed => 'Impossible de charger les planifications';

  @override
  String get schedulesEmpty => 'Aucune planification ni surveillance';

  @override
  String get schedulesEmptyDescription =>
      'Répétez une consigne depuis l\'écran des objectifs, ou envoyez /loop ou /schedule dans une conversation.';

  @override
  String get scheduleMissing =>
      'Cette planification n\'est plus disponible dans cet espace de travail.';

  @override
  String scheduleEvery(String interval) {
    return 'Toutes les $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Boucle à rythme libre';

  @override
  String get scheduleCron => 'Planification cron';

  @override
  String scheduleOnce(String time) {
    return 'Une fois à $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Surveillance : $event';
  }

  @override
  String get scheduleWatchPrChecks => 'vérifications de pull request';

  @override
  String get scheduleWatchPrReview => 'revues de pull request';

  @override
  String get scheduleWatchPrMerged => 'fusion de pull request';

  @override
  String get scheduleWatchEnvironment => 'environnement';

  @override
  String get scheduleWatchTicket => 'ticket';

  @override
  String get scheduleWatchPipelineRun => 'exécution de pipeline';

  @override
  String get scheduleStatusActive => 'Active';

  @override
  String get scheduleStatusPaused => 'En pause';

  @override
  String get scheduleStatusEnded => 'Terminée';

  @override
  String scheduleWakes(String agent) {
    return 'Relance $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Prochaine exécution $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Dernière exécution $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString exécutions',
      one: '1 exécution',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString sur $maxString exécutions';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ignorées',
      one: '1 ignorée',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Se termine $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Partie d\'une chaîne : $countString exécutions restantes, se termine $time';
  }

  @override
  String get scheduleNoteAgent => 'Note de l\'agent, dans ses mots :';

  @override
  String get scheduleNotePerson => 'Note d\'une personne :';

  @override
  String scheduleActsFor(String name) {
    return 'Agit pour $name';
  }

  @override
  String get scheduleActsForBot => 'N\'agit pour personne';

  @override
  String get scheduleGoalBound => 'Elle se termine avec son objectif.';

  @override
  String get schedulePause => 'Pause';

  @override
  String get scheduleResume => 'Reprendre';

  @override
  String get scheduleDelete => 'Supprimer';

  @override
  String get scheduleRemove => 'Supprimer';

  @override
  String get scheduleDeleteTitle => 'Supprimer cette planification ?';

  @override
  String get scheduleDeleteBody =>
      'Elle s\'arrête définitivement. Ce qu\'elle a déjà fait n\'est pas annulé.';

  @override
  String get scheduleRemoveTitle => 'Supprimer cette planification terminée ?';

  @override
  String get scheduleRemoveBody => 'Elle disparaît de la liste.';

  @override
  String get scheduleResumeNotYours =>
      'Seule la personne pour qui cette planification agit peut la reprendre.';

  @override
  String get scheduleResumeAdminOnly =>
      'Seul un admin de l\'espace de travail peut reprendre une planification qui n\'appartient à personne.';

  @override
  String get scheduleOpenConversation => 'Ouvrir la conversation';

  @override
  String get progressWaiting => 'En attente';

  @override
  String get progressNothingWaiting => 'Rien n\'attend.';

  @override
  String get wakeOriginGoal => 'Objectif';

  @override
  String get wakeOriginGoalCheck => 'Vérification de l\'objectif';

  @override
  String get wakeOriginGoalReview => 'Revue de l\'objectif';

  @override
  String get wakeOriginSchedule => 'Planification';

  @override
  String get wakeOriginWatch => 'Surveillance';

  @override
  String get wakeOriginReply => 'Réponse';

  @override
  String get wakeOriginMessage => 'Message';

  @override
  String get wakeOriginWorkFinished => 'Travail terminé';

  @override
  String get wakeOriginLimitReset => 'Limite réinitialisée';

  @override
  String get wakeOriginRecovery => 'Reprise';

  @override
  String get wakeOriginAssignment => 'Attribution';

  @override
  String get wakeOriginPipelineStep => 'Étape de pipeline';

  @override
  String get wakeOriginImprovementReview => 'Revue d\'amélioration';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Réponse de $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Message de $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Travail terminé par $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Pour $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Prévue à $time';
  }

  @override
  String get wakeDueNow => 'Prévue maintenant';

  @override
  String get wakeHeld => 'Retenue';

  @override
  String wakeExpires(String time) {
    return 'Expire $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Tentative $attemptString';
  }

  @override
  String get wakeCancel => 'Annuler';

  @override
  String get wakeDeliverNow => 'Livrer maintenant';

  @override
  String get wakeResume => 'Reprendre';

  @override
  String get wakeDismiss => 'Ignorer';

  @override
  String get wakeResumeOnlyTheirs =>
      'Seule la personne dont c\'est l\'exécution peut la reprendre.';

  @override
  String get wakeRecovery =>
      'Le serveur a redémarré pendant cette exécution. Reprenez-la pour la poursuivre, ou ignorez-la.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'En pause à la limite d\'utilisation de $provider, qui se réinitialise à $time. L\'exécution attend Reprendre, jusqu\'à 7 jours après la réinitialisation.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'En pause à la limite d\'utilisation du fournisseur, qui se réinitialise à $time. L\'exécution attend Reprendre, jusqu\'à 7 jours après la réinitialisation.';
  }

  @override
  String get limitParkResumeNow => 'Reprendre maintenant';

  @override
  String get limitParkCancel => 'Annuler';

  @override
  String limitParkResumed(String provider) {
    return 'Repris après la limite d\'utilisation de $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'N\'attend plus à la limite d\'utilisation de $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'le fournisseur';

  @override
  String get mobileHeldMessages => 'Messages retenus';

  @override
  String get heldSteeringTitle =>
      'Retenus parce que l\'exécution s\'est terminée avant de pouvoir les prendre. Envoyez les vôtres maintenant ou supprimez-les.';

  @override
  String get heldSteeringRelease => 'Envoyer les messages retenus';

  @override
  String get notifGoalCompleted => 'Objectif terminé';

  @override
  String get notifGoalFailed => 'Échec de l\'objectif';

  @override
  String get notifGoalCancelled => 'Objectif annulé';

  @override
  String get notifGoalBudgetExhausted => 'L\'objectif a épuisé son budget';

  @override
  String get notifGoalNeedsReview => 'Un objectif attend votre revue';

  @override
  String get notifGoalNeedsPerson => 'Un objectif a besoin de vous';

  @override
  String get notifGoalOnHold => 'Un objectif est retenu';

  @override
  String get notifWakeRuleEnded => 'Une planification est terminée';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString éléments vous attendent',
      one: '1 élément vous attend',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString améliorations ont été proposées',
      one: 'Une amélioration a été proposée',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Une exécution de pipeline est retenue à son budget';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Dépensé : $spent sur $cap';
  }

  @override
  String get notifNeedsYou => 'Vous attend';

  @override
  String get notifDigestGoalReview => 'Objectif en attente de revue';

  @override
  String get notifDigestGoalPerson => 'Objectif qui attend une personne';

  @override
  String get notifDigestHeldWake => 'Relance retenue';

  @override
  String get notifDigestImprovement => 'Amélioration proposée';

  @override
  String get wakeKindRulePaused => 'Sa planification a été mise en pause.';

  @override
  String get wakeKindRuleBusy =>
      'L\'agent était occupé, et cette planification ignore les moments où il l\'est.';

  @override
  String get wakeKindRuleFolded =>
      'Un événement plus récent de la même surveillance a pris sa place.';

  @override
  String get wakeKindRuleSuperseded =>
      'Une heure plus récente de sa planification l\'a remplacée.';

  @override
  String get wakeKindRuleNotified =>
      'Sa planification envoie seulement une notification, donc aucune exécution n\'a démarré.';

  @override
  String get wakeKindRuleLimitParked =>
      'Sa planification attend la réinitialisation de la limite d\'utilisation du fournisseur.';

  @override
  String get improvementRefusalCooldown =>
      'Une revue d\'amélioration a été lancée dans cette conversation il y a peu. Réessayez plus tard.';

  @override
  String get improvementRefusalQueued =>
      'Une revue d\'amélioration de cette conversation attend déjà d\'être lancée.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Cet agent ne fait pas partie de cet espace de travail.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Les messages retenus à la limite d\'utilisation ne peuvent pas être envoyés à la main. Ils attendent la reprise de l\'exécution en pause.';

  @override
  String limitParkCancelled(String provider) {
    return 'L\'attente à la limite d\'utilisation de $provider a été annulée.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'L\'attente à la limite d\'utilisation de $provider a expiré avant la reprise de l\'exécution.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'L\'exécution n\'a pas repris après la limite d\'utilisation de $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Retenus pendant que l\'exécution attend la réinitialisation de la limite d\'utilisation. Ils sont envoyés lorsque la personne pour qui elle s\'exécute la reprend.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Retenus jusqu\'à la réinitialisation de la limite d\'utilisation à $time. Ils sont envoyés lorsque la personne pour qui elle s\'exécute la reprend.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Retenus par le serveur. Vous pouvez les supprimer.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$agent a été relancé pour $countString éléments en attente',
      one: '$agent a été relancé',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Une relance pour $agent a été manquée pendant l\'arrêt du serveur.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Une relance pour $agent n\'a pas été livrée.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Planification définie pour $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'La planification de $agent est terminée.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Note de planification de $agent :';
  }

  @override
  String get workRowNoteFromPerson => 'Note de planification d\'une personne :';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'La commande $command a été refusée.';
  }

  @override
  String get workRowCommandRefused => 'Une commande a été refusée.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person a relevé le plafond de dépenses du pipeline de $from à $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person a relevé le plafond de dépenses du pipeline.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Une modification acceptée de cette compétence n\'a pas pu être terminée, car la compétence a changé entre-temps. La proposition a été annulée.';

  @override
  String get workRowOpenSchedule => 'Ouvrir la planification';

  @override
  String get heldSteeringOthersTitle =>
      'Retenus parce que l\'exécution s\'est terminée avant de pouvoir les prendre. Seule la personne qui a écrit un message peut l\'envoyer.';

  @override
  String get heldSteeringOnlyYours =>
      'N\'envoie que vos messages. Les autres attendent leurs auteurs.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Écrit par $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Seule la personne qui a écrit un message retenu peut l\'envoyer, et aucun de ceux-ci n\'est le vôtre.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Vous avez besoin d\'un accès en écriture aux dépôts de cet espace pour diriger une exécution qui agit pour quelqu\'un d\'autre.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name a mis en pause la planification de $agent.';
  }

  @override
  String get goalVerdictObjective => 'L\'objectif dans son ensemble';

  @override
  String get notifDigestRequest => 'En attente de votre réponse';
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

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Connectez-vous à $forge pour voir les demandes de tirage de $count dépôts de plus',
      one:
          'Connectez-vous à $forge pour voir les demandes de tirage d\'un dépôt de plus',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Courriel du compte Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Saisissez l\'adresse courriel de votre compte Atlassian.';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Aucun jeton d\'automatisation ne peut lire $names, le travail en arrière-plan y est donc en pause. Un admin peut en ajouter un dans Paramètres → Dépôts.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Ce jeton n’a pas la portée $scope, nécessaire pour relire et commenter. Créez-en un qui l’a.';
  }

  @override
  String get wakeKindGoalReviewStale =>
      'L\'objectif a changé depuis la demande de cette révision.';

  @override
  String get goalRefusalNotInReview =>
      'Cet objectif n\'attend pas de révision.';

  @override
  String get goalHoldNeedsReview =>
      'En attente de révision : il ne peut pas continuer seul. Approuvez-le comme terminé, reprenez-le ou annulez-le.';

  @override
  String get scheduleWatchPrChecks => 'vérifications de demande de tirage';

  @override
  String get scheduleWatchPrReview => 'révisions de demande de tirage';

  @override
  String get scheduleWatchPrMerged => 'fusion de demande de tirage';

  @override
  String get wakeOriginGoalReview => 'Révision de l\'objectif';

  @override
  String get wakeOriginImprovementReview => 'Révision d\'amélioration';

  @override
  String get notifGoalNeedsReview => 'Un objectif attend votre révision';

  @override
  String get notifDigestGoalReview => 'Objectif en attente de révision';

  @override
  String get improvementRefusalCooldown =>
      'Une révision d\'amélioration a été lancée dans cette conversation il y a peu. Réessayez plus tard.';

  @override
  String get improvementRefusalQueued =>
      'Une révision d\'amélioration de cette conversation attend déjà d\'être lancée.';
}
