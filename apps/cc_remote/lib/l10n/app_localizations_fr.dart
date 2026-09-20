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
