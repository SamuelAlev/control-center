// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Πίσω';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get retry => 'Επανάληψη';

  @override
  String get tryAgain => 'Δοκιμάστε ξανά';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get refresh => 'Ανανέωση';

  @override
  String get approve => 'Έγκριση';

  @override
  String get deny => 'Απόρριψη';

  @override
  String get continueLabel => 'Συνέχεια';

  @override
  String get agentQuestionHeader => 'Ερώτηση για εσάς';

  @override
  String get agentQuestionAnsweredLabel => 'Απαντήθηκε';

  @override
  String get agentQuestionSkip => 'Παράλειψη';

  @override
  String get agentQuestionSkippedLabel => 'Παραλείφθηκε';

  @override
  String get agentQuestionFreeformHint => 'Πληκτρολογήστε την απάντησή σας…';

  @override
  String get agentApprovalRequired => 'Απαιτείται έγκριση';

  @override
  String get copyCommand => 'Αντιγραφή εντολής';

  @override
  String get approveAndRemember => 'Έγκριση για 8 ώρες';

  @override
  String get decline => 'Άρνηση';

  @override
  String get confirm => 'Επιβεβαίωση';

  @override
  String get send => 'Αποστολή';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get expand => 'Ανάπτυξη';

  @override
  String get zoomIn => 'Μεγέθυνση';

  @override
  String get zoomOut => 'Σμίκρυνση';

  @override
  String get resetZoom => 'Επαναφορά μεγέθυνσης';

  @override
  String get scanQrPrompt =>
      'Σαρώστε τον κωδικό QR από το Control Center για να συζεύξετε αυτό το τηλέφωνο.';

  @override
  String get scanQrHelp =>
      'Ανοίξτε την κάμερα και στρέψτε την στον QR που εμφανίζεται στο Control Center. Αυτό το τηλέφωνο συνδέεται απευθείας μέσω ιδιωτικής σύνδεσης.';

  @override
  String get connectingToMac => 'Σύνδεση με το Control Center…';

  @override
  String get connectingDetail => 'Δημιουργία ασφαλούς, άμεσης σύνδεσης.';

  @override
  String get identityChangedTitle => 'Η ταυτότητα του διακομιστή άλλαξε';

  @override
  String get identityChangedBody =>
      'Αυτός ο διακομιστής δεν ταιριάζει πλέον με την ταυτότητα που αποθηκεύτηκε κατά τη σύζευξη. Μπορεί να σημαίνει ότι ο διακομιστής επανεγκαταστάθηκε — ή ότι κάτι παρεμβαίνει στη σύνδεση. Για ασφάλεια, αυτή η συσκευή δεν θα συνδεθεί. Αφαιρέστε τη σύζευξη και σαρώστε έναν νέο κωδικό QR από το Control Center για να συζεύξετε ξανά.';

  @override
  String get removePairing => 'Αφαίρεση σύζευξης';

  @override
  String get couldntConnect => 'Δεν ήταν δυνατή η σύνδεση';

  @override
  String get pendingPairingTitle => 'Σύνδεση σε αυτόν τον διακομιστή;';

  @override
  String get pendingPairingBody =>
      'Ένας σύνδεσμος ζήτησε από το Control Center να συζευχθεί με αυτόν τον διακομιστή. Συνεχίστε μόνο αν το ξεκινήσατε εσείς.';

  @override
  String get connect => 'Σύνδεση';

  @override
  String get failureNotPaired =>
      'Χωρίς σύζευξη — σαρώστε τον κωδικό QR από το Control Center';

  @override
  String get failureUnreachable =>
      'Δεν ήταν δυνατή η πρόσβαση στον διακομιστή από καμία διαδρομή — ελέγξτε ότι εκτελείται ή δοκιμάστε το ίδιο δίκτυο';

  @override
  String get failureIdentityChanged =>
      'Η ταυτότητα του διακομιστή άλλαξε — αν επανεγκαταστάθηκε, συζεύξτε ξανά αυτή τη συσκευή';

  @override
  String get failureAuthRejected =>
      'Ο διακομιστής απέρριψε αυτή τη συσκευή — συζεύξτε την ξανά από το Control Center';

  @override
  String get failureUnknown =>
      'Δεν ήταν δυνατή η σύνδεση — πατήστε για επανάληψη';

  @override
  String get statusConnected => 'Συνδεδεμένο';

  @override
  String get statusConnecting => 'Σύνδεση';

  @override
  String get statusOffline => 'Εκτός σύνδεσης';

  @override
  String get statusIdentityMismatch => 'Ασυμφωνία ταυτότητας';

  @override
  String get statusNotPaired => 'Χωρίς σύζευξη';

  @override
  String get statusConfirmPairing => 'Επιβεβαίωση σύζευξης';

  @override
  String get connectionFailed => 'Η σύνδεση απέτυχε';

  @override
  String get identityMismatchBanner =>
      'Η ταυτότητα του διακομιστή άλλαξε — η σύνδεση σταμάτησε. Συζεύξτε ξανά αυτή τη συσκευή για να συνεχίσετε.';

  @override
  String get tabInbox => 'Εισερχόμενα';

  @override
  String get tabTickets => 'Εισιτήρια';

  @override
  String get tabChat => 'Συνομιλία';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Ημερολόγιο';

  @override
  String get tabNews => 'Ειδήσεις';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count σε αναμονή';
  }

  @override
  String get updateAvailable => 'Ένα νέο Control Center είναι διαθέσιμο';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get language => 'Γλώσσα';

  @override
  String get device => 'Συσκευή';

  @override
  String get themeSystem => 'Σύστημα';

  @override
  String get themeLight => 'Φωτεινό';

  @override
  String get themeDark => 'Σκοτεινό';

  @override
  String get languageSystem => 'Σύστημα';

  @override
  String get disconnectTapAgain =>
      'Πατήστε ξανά για να αποσυνδέσετε αυτή τη συσκευή από το Control Center';

  @override
  String get disconnectDevice => 'Αποσύνδεση αυτής της συσκευής';

  @override
  String get disconnect => 'Αποσύνδεση';

  @override
  String get chooseWorkspace => 'Επιλογή χώρου εργασίας';

  @override
  String get workspaces => 'Χώροι εργασίας';

  @override
  String get workspacesLoadFailed => 'Αποτυχία φόρτωσης χώρων εργασίας';

  @override
  String get noWorkspacesYet => 'Δεν υπάρχουν ακόμη χώροι εργασίας';

  @override
  String selectWorkspace(String name) {
    return 'Επιλογή $name';
  }

  @override
  String get inboxLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των εισερχομένων';

  @override
  String get allCaughtUp => 'Είστε ενήμεροι';

  @override
  String get inboxNoForgeAccount =>
      'Δεν είναι συνδεδεμένος λογαριασμός forge στον διακομιστή, επομένως τα pull requests δεν μπορούν ακόμη να αποδοθούν σε εσάς.';

  @override
  String get inboxNothingWaiting =>
      'Τίποτα δεν είναι αποκλεισμένο και κανένα pull request δεν σας περιμένει.';

  @override
  String get blocked => 'Αποκλεισμένος';

  @override
  String get sectionNeedsYourReview => 'Χρειάζεται την ανασκόπησή σας';

  @override
  String get sectionReturnedToYou => 'Επιστράφηκε σε εσάς';

  @override
  String get sectionApprovedAndReady => 'Εγκεκριμένα και έτοιμα';

  @override
  String get sectionYourDrafts => 'Τα πρόχειρά σας';

  @override
  String get sectionWaitingForReviewers => 'Αναμονή κριτών';

  @override
  String get sectionMergingAndMerged => 'Συγχώνευση και πρόσφατα συγχωνευμένα';

  @override
  String get sectionWaitingForAuthor => 'Αναμονή συντάκτη';

  @override
  String waitingAgo(String ago) {
    return 'αναμονή $ago';
  }

  @override
  String get openConversation => 'Άνοιγμα της συνομιλίας';

  @override
  String get calendarLoadFailed => 'Δεν ήταν δυνατή η φόρτωση του ημερολογίου';

  @override
  String get nothingScheduled => 'Τίποτα προγραμματισμένο';

  @override
  String get calendarEmptyDescription =>
      'Τα γεγονότα από τα συνδεδεμένα ημερολόγιά σας εμφανίζονται εδώ.';

  @override
  String get agenda => 'Ατζέντα';

  @override
  String get syncCalendarsNow => 'Συγχρονισμός ημερολογίων τώρα';

  @override
  String get event => 'Γεγονός';

  @override
  String get eventNotFound => 'Το γεγονός δεν βρέθηκε';

  @override
  String get eventNotFoundDescription =>
      'Μπορεί να είναι εκτός του παραθύρου ατζέντας ή να αφαιρέθηκε στην πηγή.';

  @override
  String get joinMeeting => 'Συμμετοχή στη σύσκεψη';

  @override
  String get join => 'Συμμετοχή';

  @override
  String attendeesCount(int count) {
    return 'Παρευρισκόμενοι ($count)';
  }

  @override
  String get details => 'Λεπτομέρειες';

  @override
  String get allDay => 'Ολοήμερο';

  @override
  String get happeningNow => 'Συμβαίνει τώρα';

  @override
  String inDuration(String duration) {
    return 'Σε $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead: $title';
  }

  @override
  String get attendeeAccepted => 'αποδεκτό';

  @override
  String get attendeeDeclined => 'απορρίφθηκε';

  @override
  String get attendeeMaybe => 'ίσως';

  @override
  String get attendeeNoReply => 'χωρίς απάντηση';

  @override
  String get organizer => 'διοργανωτής';

  @override
  String get calendarNoAccounts =>
      'Δεν είναι συνδεδεμένο ημερολόγιο για αυτόν τον χώρο εργασίας. Συνδέστε ένα από την εφαρμογή υπολογιστή — η είσοδος αποθηκεύει το token στον διακομιστή.';

  @override
  String get calendarReauthNeeded =>
      'Ένας λογαριασμός ημερολογίου χρειάζεται επανασύνδεση — ό,τι βλέπετε παρακάτω μπορεί να είναι παλιό. Επανασυνδέστε τον από την εφαρμογή υπολογιστή.';

  @override
  String get spacesLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των χώρων';

  @override
  String get noSpaces => 'Κανένας χώρος';

  @override
  String get spacesEmptyDescription =>
      'Οι χώροι σε αυτόν τον χώρο εργασίας εμφανίζονται εδώ.';

  @override
  String get newSpaceFolder => 'Νέος φάκελος';

  @override
  String get folderName => 'Όνομα φακέλου';

  @override
  String get renameSpaceFolder => 'Μετονομασία φακέλου';

  @override
  String get deleteSpaceFolder => 'Διαγραφή φακέλου';

  @override
  String get moveSpaceToFolder => 'Μετακίνηση χώρου σε φάκελο';

  @override
  String get removeSpaceFromFolder => 'Αφαίρεση χώρου από φάκελο';

  @override
  String get spaceFolderActions => 'Ενέργειες φακέλου';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Η οριστική διαγραφή των χώρων αφαιρεί τα μηνύματα και τους καταλόγους εργασίας τους για όλους. Δεν είναι δυνατή η αναίρεση.';

  @override
  String get deleteSpacesInFolder =>
      'Οριστική διαγραφή των χώρων σε αυτόν τον φάκελο';

  @override
  String get deleteFolderAndSpaces => 'Διαγραφή φακέλου και χώρων';

  @override
  String get keepSpacesInFolder =>
      'Διαφορετικά, οι χώροι θα παραμείνουν εκτός φακέλου.';

  @override
  String get create => 'Δημιουργία';

  @override
  String get otherSpaces => 'Άλλοι χώροι';

  @override
  String get folderUpdateFailed => 'Δεν ήταν δυνατή η ενημέρωση των φακέλων';

  @override
  String get thread => 'Νήμα';

  @override
  String get agentWorking => 'Ο πράκτορας εργάζεται';

  @override
  String get messagesLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των μηνυμάτων';

  @override
  String get noMessagesYet => 'Δεν υπάρχουν ακόμη μηνύματα';

  @override
  String get noMessagesDescription =>
      'Στείλτε ένα μήνυμα για να ξεκινήσει η συνομιλία.';

  @override
  String get agentResponding => 'Ο πράκτορας απαντά';

  @override
  String get agentFinished => 'Ο πράκτορας ολοκλήρωσε';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names είναι πολύ μεγάλα για αποστολή από εδώ.',
      one: '$names είναι πολύ μεγάλο για αποστολή από εδώ.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names είναι πολύ μεγάλα για αποστολή μέσω του relay από εδώ.',
      one: '$names είναι πολύ μεγάλο για αποστολή μέσω του relay από εδώ.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Δεν ήταν δυνατή η μεταφόρτωση του συνημμένου. Δοκιμάστε ξανά.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συνημμένα δεν μεταφορτώθηκαν και παραλείφθηκαν.',
      one: '1 συνημμένο δεν μεταφορτώθηκε και παραλείφθηκε.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Συνάδελφος';

  @override
  String get agent => 'Πράκτορας';

  @override
  String get attachFile => 'Επισύναψη αρχείου';

  @override
  String get messageHint => 'Μήνυμα';

  @override
  String removeAttachment(String name) {
    return 'Αφαίρεση $name';
  }

  @override
  String get articlesLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των άρθρων';

  @override
  String get noArticles => 'Κανένα άρθρο';

  @override
  String get articlesEmptyDescription =>
      'Νέα άρθρα εμφανίζονται εδώ καθώς ενημερώνονται οι ροές.';

  @override
  String get unread => 'Μη αναγνωσμένα';

  @override
  String get allFeeds => 'Όλες οι ροές';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get unsave => 'Αναίρεση αποθήκευσης';

  @override
  String get readFullArticle => 'Ανάγνωση πλήρους άρθρου';

  @override
  String get ticketsLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των εισιτηρίων';

  @override
  String get noTickets => 'Κανένα εισιτήριο';

  @override
  String get ticketsEmptyDescription =>
      'Τα εισιτήρια σε αυτόν τον χώρο εργασίας εμφανίζονται εδώ.';

  @override
  String get all => 'Όλα';

  @override
  String get ticket => 'Εισιτήριο';

  @override
  String get ticketLoadFailed => 'Δεν ήταν δυνατή η φόρτωση του εισιτηρίου';

  @override
  String assignedTo(String name) {
    return 'Ανατέθηκε στον/στην $name';
  }

  @override
  String get openInBrowser => 'Άνοιγμα στο πρόγραμμα περιήγησης';

  @override
  String get status => 'Κατάσταση';

  @override
  String get assign => 'Ανάθεση';

  @override
  String get reassign => 'Επανάθεση';

  @override
  String get noAgents => 'Κανένας πράκτορας';

  @override
  String get noAgentsDescription =>
      'Αναθέστε έναν πράκτορα από αυτόν τον χώρο εργασίας.';

  @override
  String get statusOpen => 'Ανοιχτό';

  @override
  String get statusInProgress => 'Σε εξέλιξη';

  @override
  String get statusBlocked => 'Αποκλεισμένος';

  @override
  String get statusInReview => 'Σε ανασκόπηση';

  @override
  String get statusDone => 'Ολοκληρώθηκε';

  @override
  String get statusBacklog => 'Ανεκτέλεστα';

  @override
  String get lensNeedsMe => 'Με χρειάζεται';

  @override
  String get lensMine => 'Δικά μου';

  @override
  String get prsLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των pull requests';

  @override
  String get noOpenPullRequests => 'Δεν υπάρχουν ανοιχτά pull requests';

  @override
  String get nothingWaitingOnReview =>
      'Τίποτα δεν περιμένει την ανασκόπησή σας';

  @override
  String get noOwnOpenPullRequests => 'Δεν έχετε ανοιχτά pull requests';

  @override
  String get nothingBlocked => 'Τίποτα δεν είναι αποκλεισμένο';

  @override
  String get prsEmptyDescription =>
      'Τα pull requests από τα repo αυτού του χώρου εργασίας εμφανίζονται εδώ.';

  @override
  String get refreshPullRequests => 'Ανανέωση pull requests';

  @override
  String get noForgeConnected =>
      'Δεν είναι συνδεδεμένο forge στον διακομιστή, επομένως δεν μπορούν να ανακτηθούν pull requests. Συνδέστε ένα από την εφαρμογή υπολογιστή.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repo δεν ήταν αναγνώσιμα.',
      one: '1 repo δεν ήταν αναγνώσιμο.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Μη αναγνώσιμα: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Η εγκατάσταση του GitHub App έχει ανασταλεί';

  @override
  String installationSuspendedBody(String names) {
    return 'Εμφανίζονται τα τελευταία γνωστά δεδομένα για τα ⁨$names⁩. Συνεχίστε την εγκατάσταση στο GitHub ή συνδέστε token με πρόσβαση.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Η εγκατάσταση του GitHub App έχει ανασταλεί. Εμφανίζονται τα τελευταία γνωστά δεδομένα για τα ⁨$names⁩. Συνεχίστε την εγκατάσταση στο GitHub ή συνδέστε token με πρόσβαση.';
  }

  @override
  String get draft => 'Πρόχειρο';

  @override
  String get merged => 'Συγχωνεύθηκε';

  @override
  String get closed => 'Κλειστό';

  @override
  String get open => 'Ανοιχτό';

  @override
  String get approved => 'Εγκρίθηκε';

  @override
  String get changesRequested => 'Ζητήθηκαν αλλαγές';

  @override
  String get reviewRequired => 'Απαιτείται ανασκόπηση';

  @override
  String get checksPassing => 'Οι έλεγχοι περνούν';

  @override
  String get checksFailing => 'Οι έλεγχοι αποτυγχάνουν';

  @override
  String get checksRunning => 'Οι έλεγχοι εκτελούνται';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Δεν ήταν δυνατή η φόρτωση αυτού του pull request';

  @override
  String get openOnForge => 'Άνοιγμα στο forge';

  @override
  String get requestChangesNeedsComment =>
      'Προσθέστε ένα σχόλιο που εξηγεί τι πρέπει να αλλάξει.';

  @override
  String get conversation => 'Συνομιλία';

  @override
  String get files => 'Αρχεία';

  @override
  String get checks => 'Έλεγχοι';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχεία',
      one: '1 αρχείο',
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
  String get conflicts => 'Συγκρούσεις';

  @override
  String get reviewers => 'Κριτές';

  @override
  String get noDescriptionNoComments =>
      'Δεν υπάρχει ακόμη περιγραφή ούτε σχόλια.';

  @override
  String get noChangedFiles => 'Κανένα αλλαγμένο αρχείο.';

  @override
  String get noChecksReported => 'Δεν αναφέρθηκαν έλεγχοι για το head commit.';

  @override
  String get reviewCommentHint => 'Αφήστε ένα σχόλιο ανασκόπησης…';

  @override
  String get comment => 'Σχόλιο';

  @override
  String get commentPosted => 'Το σχόλιο δημοσιεύτηκε';

  @override
  String get request => 'Αίτημα';

  @override
  String get squashAndMerge => 'Squash και συγχώνευση';

  @override
  String noActionsAvailable(String status) {
    return '$status — δεν υπάρχουν διαθέσιμες ενέργειες.';
  }

  @override
  String get reviewApproved => 'ενέκρινε';

  @override
  String get reviewRequestedChanges => 'ζήτησε αλλαγές';

  @override
  String get reviewCommented => 'ανασκόπησε';

  @override
  String get reviewPending => 'εκκρεμεί';

  @override
  String get unknownAuthor => 'άγνωστος';

  @override
  String hideDiffFor(String file) {
    return 'Απόκρυψη του diff για το $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Εμφάνιση του diff για το $file';
  }

  @override
  String get checkRunning => 'σε εκτέλεση';

  @override
  String get checkPassed => 'πέρασε';

  @override
  String get checkFailed => 'απέτυχε';

  @override
  String get checkCancelled => 'ακυρώθηκε';

  @override
  String get checkSkipped => 'παραλείφθηκε';

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
      'Δεν υπάρχει κειμενικό diff για αυτό το αρχείο — είναι δυαδικό ή πολύ μεγάλο για να επιστρέψει ένα το forge.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εμφάνιση των υπόλοιπων $count γραμμών',
      one: 'Εμφάνιση της υπόλοιπης γραμμής',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αμετάβλητες γραμμές',
      one: '1 αμετάβλητη γραμμή',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Μετάβαση στα πιο πρόσφατα';

  @override
  String get streaming => 'Ροή';

  @override
  String get working => 'Εργάζεται';

  @override
  String get input => 'Είσοδος';

  @override
  String get output => 'Έξοδος';

  @override
  String get now => 'τώρα';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Σήμερα';

  @override
  String get tomorrow => 'Αύριο';

  @override
  String get yesterday => 'Χθες';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get mobileConversations => 'Συνομιλίες';

  @override
  String get mobileNewConversation => 'Νέα συνομιλία';

  @override
  String get mobileConversationName => 'Όνομα συνομιλίας';

  @override
  String get mobileRename => 'Μετονομασία';

  @override
  String get mobileManageSpace => 'Διαχείριση χώρου';

  @override
  String get mobileArchived => 'Αρχειοθετημένο';

  @override
  String get mobileSearchMessages => 'Αναζήτηση σε όλα τα μηνύματα του χώρου';

  @override
  String get mobileSearch => 'Αναζήτηση';

  @override
  String get mobileNoResults => 'Δεν βρέθηκαν αποτελέσματα';

  @override
  String get mobileReopen => 'Επανάνοιγμα';

  @override
  String get mobileArchive => 'Αρχειοθέτηση';

  @override
  String get mobileProgress => 'Πρόοδος και πλαίσιο';

  @override
  String get mobileReadFailed =>
      'Δεν ήταν δυνατή η επισήμανση της συνομιλίας ως αναγνωσμένης';

  @override
  String get mobileSendFailed =>
      'Το μήνυμα δεν στάλθηκε. Το πρόχειρο παραμένει εδώ.';

  @override
  String get mobileActionFailed => 'Η ενέργεια απέτυχε';

  @override
  String get mobileRemove => 'Αφαίρεση';

  @override
  String get mobileLinkedMessage => 'Συνδεδεμένο μήνυμα';

  @override
  String get mobileOlderMessages => 'Παλαιότερα μηνύματα';

  @override
  String get mobileMessageActions => 'Ενέργειες μηνύματος';

  @override
  String get mobileOpenThread => 'Άνοιγμα νήματος';

  @override
  String get mobileCopyLink => 'Αντιγραφή συνδέσμου';

  @override
  String get mobileStopRun => 'Διακοπή εκτέλεσης';

  @override
  String get mobileStopRunConfirm =>
      'Να διακοπεί η εκτέλεση του πράκτορα; Η εργασία που έχει ήδη ολοκληρωθεί θα διατηρηθεί.';

  @override
  String get mobileControlUnsupported =>
      'Η εκτέλεση έχει ολοκληρωθεί ή δεν υποστηρίζει αυτή την ενέργεια.';

  @override
  String get mobilePauseRequested => 'Ζητήθηκε παύση πριν από τον επόμενο γύρο';

  @override
  String get mobileResumed => 'Η εκτέλεση συνεχίστηκε';

  @override
  String get mobileStopRequested => 'Ζητήθηκε διακοπή';

  @override
  String get mobileQueuedMessages => 'Μηνύματα σε ουρά';

  @override
  String get mobilePauseRun => 'Παύση πριν από τον επόμενο γύρο';

  @override
  String get mobileResumeRun => 'Συνέχεια';

  @override
  String get mobileEditQueued => 'Επεξεργασία μηνύματος ουράς';

  @override
  String get mobileSteerNow => 'Καθοδήγηση τώρα';

  @override
  String get mobileMoveUp => 'Μετακίνηση πάνω';

  @override
  String get mobileMoveDown => 'Μετακίνηση κάτω';

  @override
  String get mobileQueueChanged =>
      'Η ουρά άλλαξε ή η εκτέλεση δεν δέχεται καθοδήγηση σε πραγματικό χρόνο. Απαιτείται ανανέωση και νέα προσπάθεια.';

  @override
  String get mobileActivity => 'Δραστηριότητα';

  @override
  String get mobilePermissions => 'Δικαιώματα και ιστορικό ελέγχου';

  @override
  String get mobilePlans => 'Σχέδια';

  @override
  String get mobileGoals => 'Εποπτευόμενοι στόχοι';

  @override
  String get mobileCredentials => 'Συνδέσεις και διαπιστευτήρια';

  @override
  String get mobileWorkspaceUnavailable =>
      'Ο χώρος εργασίας δεν είναι διαθέσιμος ή δεν υπάρχει πλέον πρόσβαση.';

  @override
  String get mobilePrReviewThreads => 'Νήματα ανασκόπησης';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των νημάτων ανασκόπησης';

  @override
  String get mobilePrNoReviewThreads =>
      'Δεν υπάρχουν ακόμη νήματα ανασκόπησης σε γραμμές κώδικα';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Δεν υπάρχει δικαίωμα σχολιασμού σε αυτό το αποθετήριο.';

  @override
  String get mobilePrPermissionChecking => 'Έλεγχος δικαιωμάτων σχολιασμού…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Δεν ήταν δυνατός ο έλεγχος δικαιωμάτων σχολιασμού. Απαιτείται νέα προσπάθεια για σχολιασμό.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return 'Γραμμή $line ($side)';
  }

  @override
  String get mobilePrOriginalSide => 'Αρχική έκδοση';

  @override
  String get mobilePrUpdatedSide => 'Ενημερώθηκε';

  @override
  String get mobilePrThreadResolved => 'Επιλύθηκε';

  @override
  String get mobilePrReplyHint => 'Σύνταξη απάντησης…';

  @override
  String get mobilePrCommentRequired =>
      'Απαιτείται σχόλιο πριν από τη δημοσίευση.';

  @override
  String get mobilePrReply => 'Απάντηση';

  @override
  String get mobilePrReopenThread => 'Επαναφορά νήματος';

  @override
  String get mobilePrResolveThread => 'Επίλυση νήματος';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Μόνο ο συντάκτης του pull request ή κάποιος με δικαίωμα εγγραφής μπορεί να επιλύσει αυτό το νήμα.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Σχόλιο στη γραμμή $line ($side)';
  }

  @override
  String get mobilePrInlineCommentHint => 'Σύνταξη σχολίου στη γραμμή…';

  @override
  String get mobilePrPostInlineComment => 'Δημοσίευση σχολίου';

  @override
  String get mobilePrCommentUnavailable =>
      'Τα σχόλια σε γραμμές κώδικα δεν είναι διαθέσιμα για αυτό το pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'Η πλατφόρμα φιλοξενίας δεν παρείχε τις διαφορές αυτού του αρχείου σε μορφή κειμένου.';

  @override
  String get mobilePrNoPatchForFile =>
      'Οι διαφορές αυτού του αρχείου δεν είναι διαθέσιμες.';

  @override
  String get mobileTicketNew => 'Νέο εισιτήριο';

  @override
  String get mobileTicketCreate => 'Δημιουργία εισιτηρίου';

  @override
  String get mobileTicketEdit => 'Επεξεργασία εισιτηρίου';

  @override
  String get mobileTicketTitle => 'Τίτλος';

  @override
  String get mobileTicketTitleRequired =>
      'Απαιτείται τίτλος για την αποθήκευση του εισιτηρίου.';

  @override
  String get mobileTicketDescription => 'Περιγραφή';

  @override
  String get mobileTicketMarkdownHint => 'Προσθήκη λεπτομερειών σε Markdown';

  @override
  String get mobileTicketPriority => 'Προτεραιότητα';

  @override
  String get mobileTicketPriorityNone => 'Χωρίς προτεραιότητα';

  @override
  String get mobileTicketPriorityUrgent => 'Επείγον';

  @override
  String get mobileTicketPriorityHigh => 'Υψηλό';

  @override
  String get mobileTicketPriorityMedium => 'Μεσαίο';

  @override
  String get mobileTicketPriorityLow => 'Χαμηλό';

  @override
  String get mobileTicketLabels => 'Ετικέτες';

  @override
  String get mobileTicketLabelsHint => 'Μία ετικέτα ανά γραμμή';

  @override
  String get mobileTicketLabelsHelp =>
      'Εισαγωγή κάθε ετικέτας σε ξεχωριστή γραμμή.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Καταχωρίστηκε στο $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Χωρίς ανάθεση';

  @override
  String get mobileTicketAssignedFilter => 'Με ανάθεση';

  @override
  String get mobileTicketAgentsLoadFailed => 'Αποτυχία φόρτωσης πρακτόρων';

  @override
  String get mobileTicketSearch => 'Αναζήτηση εισιτηρίων';

  @override
  String get mobileTicketSearchHint =>
      'Τίτλος, κλειδί, περιγραφή, ετικέτα ή υπεύθυνος';

  @override
  String get mobileTicketClearSearch => 'Καθαρισμός αναζήτησης εισιτηρίων';

  @override
  String get mobileTicketNoMatches =>
      'Δεν βρέθηκαν εισιτήρια που να ταιριάζουν';

  @override
  String get mobileTicketAdjustFilters =>
      'Δοκιμάστε άλλη αναζήτηση ή αλλάξτε τα φίλτρα.';

  @override
  String get mobileTicketClearFilters => 'Καθαρισμός φίλτρων';

  @override
  String get mobileTicketNotFound => 'Το εισιτήριο δεν βρέθηκε';

  @override
  String get mobileTicketNotFoundDescription =>
      'Αυτό το εισιτήριο ενδέχεται να έχει διαγραφεί ή μετακινηθεί εκτός αυτού του χώρου εργασίας.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Ο χώρος εργασίας άλλαξε. Απαιτείται επιστροφή στον τρέχοντα χώρο εργασίας πριν από την αποθήκευση.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Άνοιγμα συνδεδεμένου χώρου';

  @override
  String get mobileTicketReadOnly =>
      'Απαιτείται ρόλος μέλους στον χώρο εργασίας για την αλλαγή εισιτηρίων.';

  @override
  String get permissionTitle => 'Δικαιώματα';

  @override
  String get permissionWorkspaceFailed =>
      'Αποτυχία φόρτωσης του χώρου εργασίας';

  @override
  String get permissionNoWorkspace =>
      'Επιλέξτε χώρο εργασίας για προβολή των δικαιωμάτων.';

  @override
  String get permissionLoading => 'Φόρτωση δικαιωμάτων…';

  @override
  String get permissionScopeDescription =>
      'Προβολή του τρόπου λήψης αποφάσεων για κάθε ενέργεια σε αυτό το πεδίο εφαρμογής. Οι κανόνες του χώρου εργασίας μπορούν να κληρονομούνται από πράκτορες και χώρους.';

  @override
  String get permissionScope => 'Πεδίο εφαρμογής πολιτικής';

  @override
  String get permissionWorkspaceScope => 'Χώρος εργασίας';

  @override
  String get permissionAgentScope => 'Πράκτορας';

  @override
  String get permissionSpaceScope => 'Χώρος';

  @override
  String get permissionAgentContext =>
      'Πράκτορας που ενεργεί σε αυτόν τον χώρο';

  @override
  String get permissionNoAgentContext => 'Δεν έχει επιλεγεί πράκτορας';

  @override
  String get permissionTargetsFailed =>
      'Αποτυχία φόρτωσης στόχων του πεδίου εφαρμογής';

  @override
  String get permissionNoTargets =>
      'Δεν υπάρχουν διαθέσιμοι στόχοι σε αυτό το πεδίο εφαρμογής.';

  @override
  String get permissionRoleFailed =>
      'Αποτυχία επιβεβαίωσης του ρόλου στον χώρο εργασίας';

  @override
  String get permissionMemberRequired =>
      'Απαιτείται ρόλος μέλους στον χώρο εργασίας για την προβολή κανόνων πολιτικής.';

  @override
  String get permissionRulesFailed => 'Αποτυχία φόρτωσης κανόνων πολιτικής';

  @override
  String get permissionAuditAdminOnly =>
      'Το ιστορικό εξουσιοδοτήσεων είναι διαθέσιμο μόνο στους διαχειριστές του χώρου εργασίας.';

  @override
  String get permissionAllow => 'Αποδοχή';

  @override
  String get permissionAsk => 'Ερώτηση πρώτα';

  @override
  String get permissionDeny => 'Απόρριψη';

  @override
  String get permissionFileDelete => 'Διαγραφή αρχείων';

  @override
  String get permissionFileWriteOutsideWorktree => 'Εγγραφή εκτός worktree';

  @override
  String get permissionGitCommit => 'Καταχώριση αλλαγών';

  @override
  String get permissionGitPush => 'Αποστολή commit';

  @override
  String get permissionPrCreate => 'Δημιουργία pull request';

  @override
  String get permissionPrPublish => 'Δημοσίευση pull request';

  @override
  String get permissionVendorSyncWrite => 'Εγγραφή συγχρονισμού παρόχου';

  @override
  String get permissionNetworkEgress => 'Πρόσβαση στο δίκτυο';

  @override
  String get permissionSecretAccess => 'Πρόσβαση σε απόρρητα στοιχεία';

  @override
  String get permissionPackageInstall => 'Εγκατάσταση πακέτων';

  @override
  String get permissionProcessSpawn => 'Εκκίνηση διεργασιών';

  @override
  String get permissionWorkspaceMutation => 'Αλλαγή χώρου εργασίας';

  @override
  String get permissionEnclosureControl => 'Έλεγχος περιβάλλοντος απομόνωσης';

  @override
  String get permissionChangeFailed => 'Αποτυχία αλλαγής του κανόνα';

  @override
  String get permissionEffectiveDescription =>
      'Ισχύει σε αυτό το πεδίο εφαρμογής χωρίς ορίσματα ενέργειας. Οι παρακάτω εξουσιοδοτήσεις υπό όρους ισχύουν μόνο για αιτήματα που πληρούν τις προϋποθέσεις· η τελική απόφαση λαμβάνεται από τον διακομιστή.';

  @override
  String get permissionSpaceAgentNote =>
      'Δεν έχει επιλεγεί πράκτορας. Οι κανόνες για συγκεκριμένο πράκτορα παραλείπονται μέχρι να επιλεγεί κάποιος παραπάνω.';

  @override
  String get permissionScopedGrants => 'Κανόνες σε αυτό το πεδίο εφαρμογής';

  @override
  String get permissionModePreset => 'Προκαθορισμένο λειτουργίας';

  @override
  String get permissionBuiltInDefault => 'Ενσωματωμένη προεπιλογή';

  @override
  String get permissionRemembered => 'Αποθηκευμένη έγκριση';

  @override
  String get permissionSource => 'Πηγή';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · ορίστηκε εδώ';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · κληρονομήθηκε';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Λήγει $date';
  }

  @override
  String get permissionSetHere => 'Ορισμός κανόνα εδώ';

  @override
  String get permissionRevokeBeforeEdit =>
      'Απαιτείται ανάκληση του κανόνα με συγκεκριμένο πεδίο εφαρμογής ή του αποθηκευμένου κανόνα πριν οριστεί γενικός κανόνας για αυτή την ενέργεια.';

  @override
  String get permissionConfirmRevoke => 'Επιβεβαίωση ανάκλησης';

  @override
  String get permissionRevokeRule => 'Ανάκληση κανόνα';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Πρόθεμα εντολής: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Χωρίς λήξη';

  @override
  String get permissionExpired => 'Έληξε';

  @override
  String get permissionExplicitRule => 'Ρητός κανόνας';

  @override
  String get permissionEnforcementAdvisory =>
      'Συμβουλευτική λειτουργία: οι κανόνες «Ερώτηση πρώτα» καταγράφονται χωρίς αίτημα έγκρισης';

  @override
  String get permissionEnforcementSoft =>
      'Ήπια επιβολή: η παράκαμψη απαιτεί εξουσιοδότηση';

  @override
  String get permissionEnforcementHard =>
      'Αυστηρή επιβολή: δεν επιτρέπεται παράκαμψη';

  @override
  String permissionPaths(String paths) {
    return 'Διαδρομές: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Αναφορές Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Κεντρικοί υπολογιστές: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Εντολές: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Μέγιστο πλήθος: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Μέγιστο ποσό σε σεντ: $cents';
  }

  @override
  String get permissionAuditHeading => 'Ιστορικό εξουσιοδοτήσεων';

  @override
  String get permissionAuditDescription =>
      'Πρόσφατες αποφάσεις που καταγράφηκαν από τον διακομιστή. Μόνο οι διαχειριστές μπορούν να εξετάσουν το αρχείο καταγραφής ή να επαληθεύσουν την αλυσίδα κατακερματισμού του.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'εκ μέρους του χρήστη $user';
  }

  @override
  String get permissionPrompted => 'Ζητήθηκε ανθρώπινη έγκριση';

  @override
  String get permissionVerifyChain => 'Επαλήθευση αλυσίδας καταγραφής';

  @override
  String get permissionVerifyFailed =>
      'Δεν ήταν δυνατή η επαλήθευση της αλυσίδας καταγραφής';

  @override
  String permissionChainIntact(String count) {
    return 'Άθικτη αλυσίδα · ελέγχθηκαν $count εγγραφές';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Η αλυσίδα διακόπηκε στην εγγραφή $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Δεν έχουν καταγραφεί ακόμη αποφάσεις εξουσιοδότησης.';

  @override
  String get permissionAuditFailed =>
      'Δεν ήταν δυνατή η φόρτωση του ιστορικού εξουσιοδοτήσεων';

  @override
  String get mobilePlansLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των σχεδίων';

  @override
  String get mobilePlansEmpty => 'Δεν υπάρχουν ακόμη σχέδια';

  @override
  String get mobilePlansEmptyDescription =>
      'Τα σχέδια που υποβάλλουν οι πράκτορες θα εμφανίζονται εδώ για ανασκόπηση.';

  @override
  String get mobilePlanTitle => 'Σχέδιο';

  @override
  String get mobilePlanMissing =>
      'Αυτό το σχέδιο δεν είναι πλέον διαθέσιμο σε αυτόν τον χώρο εργασίας.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count βήματα';
  }

  @override
  String get mobilePlanDraft => 'Πρόχειρο';

  @override
  String get mobilePlanProposed => 'Αναμονή ανασκόπησης';

  @override
  String get mobilePlanApproved => 'Εγκρίθηκε';

  @override
  String get mobilePlanRejected => 'Απορρίφθηκε';

  @override
  String get mobilePlanSuperseded => 'Αντικαταστάθηκε';

  @override
  String get mobilePlanExecuting => 'Εκτέλεση';

  @override
  String get mobilePlanSynthesizing => 'Σύνθεση';

  @override
  String get mobilePlanCompleted => 'Ολοκληρώθηκε';

  @override
  String get mobilePlanFailed => 'Αποτυχία';

  @override
  String get mobilePlanCancelled => 'Ακυρώθηκε';

  @override
  String mobilePlanRevision(String revision) {
    return 'Αναθεώρηση $revision';
  }

  @override
  String get mobilePlanSteps => 'Βήματα';

  @override
  String get mobilePlanNoSteps => 'Δεν υποβλήθηκαν βήματα για αυτό το σχέδιο.';

  @override
  String get mobilePlanAssumptions => 'Διευκρινίσεις';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Εξαρτάται από $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Εκτιμώμενο κόστος έως $cost';
  }

  @override
  String get mobilePlanSelect => 'Επιλογή';

  @override
  String get mobilePlanSelected => 'Επιλεγμένο';

  @override
  String get mobilePlanEstimate => 'Εκτίμηση κόστους';

  @override
  String get mobilePlanEstimateRequired =>
      'Απαιτείται εκτίμηση κόστους του σχεδίου πριν από την έγκριση εκτέλεσης.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Εκτιμώμενο κόστος: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'μη διαθέσιμο';

  @override
  String get mobilePlanNoHardCap => 'χωρίς αυστηρό ανώτατο όριο';

  @override
  String get mobilePlanExceedsBudget =>
      'Η εκτίμηση υπερβαίνει τον καθορισμένο προϋπολογισμό. Απαιτείται έλεγχος πριν από την έγκριση.';

  @override
  String get mobilePlanPartialEstimate =>
      'Η εκτίμηση καλύπτει ολόκληρο το σχέδιο· τα επιλεγμένα βήματα ενδέχεται να κοστίσουν λιγότερο.';

  @override
  String get mobilePlanConfirmAll => 'Να ξεκινήσει ολόκληρο το σχέδιο;';

  @override
  String get mobilePlanConfirmSelected => 'Να ξεκινήσουν τα επιλεγμένα βήματα;';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Η έγκριση ξεκινά την εκτέλεση και ενδέχεται να επιφέρει χρεώσεις. Εκτιμώμενο ανώτατο κόστος: $cost. Όριο προϋπολογισμού: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Έγκριση όλων και εκτέλεση';

  @override
  String get mobilePlanApproveSelected => 'Έγκριση επιλεγμένων και εκτέλεση';

  @override
  String get mobilePlanWiden => 'Έγκριση επιπλέον βημάτων';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Να επιτραπεί η εκτέλεση $count επιπλέον βημάτων; Ενδέχεται να επιφέρουν χρεώσεις. Τρέχον όριο κόστους εκτέλεσης: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Το σχέδιο άλλαξε κατά την ανασκόπηση. Απαιτείται επανάνοιγμα της τελευταίας αναθεώρησης και νέα εκτίμηση.';

  @override
  String get mobilePlanReject => 'Απόρριψη σχεδίου';

  @override
  String get mobilePlanRejectConfirm =>
      'Να απορριφθεί αυτό το σχέδιο; Δεν θα εκτελεστεί.';

  @override
  String get mobilePlanStop => 'Διακοπή εκτέλεσης';

  @override
  String get mobilePlanStopConfirm =>
      'Να διακοπεί η εκτέλεση αυτού του σχεδίου; Η εργασία που έχει ήδη ολοκληρωθεί δεν θα αναιρεθεί.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Εκτέλεση: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Η έγκριση έγινε δεκτή. Αναμονή για την εγγραφή εκτέλεσης…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed από $total βήματα εκτέλεσης ολοκληρώθηκαν';
  }

  @override
  String get mobilePlanOpenConversation => 'Άνοιγμα συνομιλίας';

  @override
  String get mobileGoalsTitle => 'Εποπτευόμενοι στόχοι';

  @override
  String get mobileGoalsLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των εποπτευόμενων στόχων';

  @override
  String get mobileGoalsEmpty => 'Δεν υπάρχουν ακόμη εποπτευόμενοι στόχοι';

  @override
  String get mobileGoalsEmptyDescription =>
      'Η έναρξη γίνεται από έναν χώρο ή με αποστολή της εντολής /goal σε μια συνομιλία.';

  @override
  String get mobileGoalMissing =>
      'Αυτός ο στόχος δεν είναι πλέον διαθέσιμος σε αυτόν τον χώρο εργασίας.';

  @override
  String get mobileGoalActive => 'Ενεργός';

  @override
  String get mobileGoalPaused => 'Σε παύση';

  @override
  String get mobileGoalCompleted => 'Ολοκληρώθηκε';

  @override
  String get mobileGoalFailed => 'Αποτυχία';

  @override
  String get mobileGoalCancelled => 'Ακυρώθηκε';

  @override
  String get mobileGoalBudgetExhausted => 'Εξαντλήθηκε ο προϋπολογισμός';

  @override
  String get mobileGoalGoal => 'Στόχος';

  @override
  String get mobileGoalLoop => 'Βρόχος';

  @override
  String mobileGoalKind(String kind) {
    return 'Τύπος: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count εκτελέσεις';
  }

  @override
  String get mobileGoalNoRunLimit => 'χωρίς όριο';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Εκτελέσεις: $runs / $maxRuns · Δαπάνη: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Προθεσμία: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Διαδοχικές αποτυχημένες εκτελέσεις: $count';
  }

  @override
  String get mobileGoalSummary => 'Σύνοψη ολοκλήρωσης';

  @override
  String get mobileGoalFailedDescription =>
      'Ο επόπτης σταμάτησε μετά από επανειλημμένες αποτυχημένες εκτελέσεις. Οι λεπτομέρειες είναι διαθέσιμες στη συνομιλία.';

  @override
  String get mobileGoalBudgetWall =>
      'Έληξε η προθεσμία ή συμπληρώθηκε το όριο εκτελέσεων. Η αύξηση του ανώτατου ορίου κόστους δεν επιτρέπει τη συνέχιση αυτού του στόχου.';

  @override
  String get mobileGoalPause => 'Παύση στόχου';

  @override
  String get mobileGoalResume => 'Συνέχεια στόχου';

  @override
  String get mobileGoalStop => 'Ακύρωση στόχου';

  @override
  String get mobileGoalStopConfirm =>
      'Να ακυρωθεί οριστικά αυτός ο εποπτευόμενος στόχος; Δεν θα είναι δυνατή η συνέχισή του.';

  @override
  String get mobileGoalRaiseBudget => 'Αύξηση προϋπολογισμού και συνέχεια';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Αύξηση προϋπολογισμού σε $amount και συνέχεια';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Να αυξηθεί το ανώτατο όριο κόστους αυτού του στόχου από $oldCap σε $newCap και να συνεχιστούν οι δαπάνες;';
  }

  @override
  String get mobileGoalOpenConversation => 'Άνοιγμα συνομιλίας στόχου';

  @override
  String get mobileGoalCreate => 'Έναρξη εποπτευόμενου στόχου';

  @override
  String get mobileGoalChooseSpace => 'Εκτέλεση σε χώρο';

  @override
  String get mobileGoalNoSpaces =>
      'Απαιτείται δημιουργία χώρου πριν από την έναρξη στόχου.';

  @override
  String get mobileGoalChooseAgent => 'Εκτέλεση με πράκτορα';

  @override
  String get mobileGoalNoAgents =>
      'Απαιτείται προσθήκη ενεργού πράκτορα πριν από την έναρξη στόχου.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Επιλέχθηκε: $name';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Ποιο αποτέλεσμα πρέπει να επιδιώξει ο πράκτορας;';

  @override
  String get mobileGoalBudgetUsd => 'Όριο κόστους (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Απαιτούνται επιλογή χώρου και πράκτορα, περιγραφή του επιδιωκόμενου αποτελέσματος και θετικό όριο κόστους σε USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Να ξεκινήσει στόχος υπό εποπτεία με μέγιστο κόστος $cap; Ο πράκτορας ενδέχεται να ξεκινήσει αμέσως.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Η σύνδεση με τον διακομιστή δεν είναι έτοιμη. Απαιτείται νέα προσπάθεια μετά την επανασύνδεση.';

  @override
  String get mobileGoalConversationMissing =>
      'Η επιλεγμένη συνομιλία δεν είναι πλέον διαθέσιμη σε αυτόν τον χώρο εργασίας.';

  @override
  String get mobileGoalCreateSent =>
      'Ο στόχος ξεκίνησε. Η κατάσταση του επόπτη θα εμφανιστεί σε αυτή τη λίστα.';

  @override
  String get mobileGoalStartRefused =>
      'Δεν ξεκίνησε καμία εκτέλεση στόχου. Η αιτιολόγηση του επόπτη βρίσκεται στη συνομιλία.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Επιλέχθηκε: $name';
  }

  @override
  String get requestUnavailable =>
      'Αυτό το αίτημα δεν είναι πλέον διαθέσιμο στον ενεργό χώρο εργασίας.';

  @override
  String get requestAlreadyResolved => 'Αυτό το αίτημα έχει ήδη επιλυθεί.';

  @override
  String get inboxCredentialsBlocked =>
      'Διαπιστευτήρια που εμποδίζουν εκτελέσεις';

  @override
  String get inboxSyncFailures => 'Αποτυχημένοι συγχρονισμοί παρόχων';

  @override
  String get inboxConfigureCredentials => 'Ρύθμιση διαπιστευτηρίων';

  @override
  String get openTicket => 'Άνοιγμα εισιτηρίου';

  @override
  String get activityTitle => 'Δραστηριότητα';

  @override
  String get activityClearAll => 'Καθαρισμός δραστηριότητας';

  @override
  String get activityClearConfirm =>
      'Αποκρύπτεται όλη η δραστηριότητα που έχει καταγραφεί έως τώρα για εσάς, σε όλες τις συσκευές σας. Η νέα δραστηριότητα θα συνεχίσει να εμφανίζεται.';

  @override
  String get activityMarkAllRead => 'Σήμανση όλων ως αναγνωσμένων';

  @override
  String get activityMarkAllConfirm =>
      'Να σημειωθούν όλα τα στοιχεία δραστηριότητας σε αυτόν τον χώρο εργασίας ως αναγνωσμένα σε όλες τις συσκευές σας;';

  @override
  String get activityMarkRead => 'Σήμανση ως αναγνωσμένου';

  @override
  String get activityMarkUnread => 'Σήμανση ως μη αναγνωσμένου';

  @override
  String get activityDismiss => 'Απόρριψη';

  @override
  String get activityResolved => 'Επιλύθηκε';

  @override
  String get activityOpen => 'Ανοιχτό';

  @override
  String get activityEmpty => 'Δεν υπάρχει ακόμη δραστηριότητα';

  @override
  String get activityLoadFailed => 'Αποτυχία φόρτωσης δραστηριότητας';

  @override
  String get activityAgentWaiting => 'Ο πράκτορας χρειάζεται πληροφορίες';

  @override
  String get activityAgentBlocked => 'Η ενέργεια του πράκτορα αποκλείστηκε';

  @override
  String get activityMessage => 'Νέο μήνυμα';

  @override
  String get activityPullRequest => 'Ενημέρωση pull request';

  @override
  String get activityTicket => 'Ενημέρωση εισιτηρίου';

  @override
  String get activityMeeting => 'Ενημέρωση σύσκεψης';

  @override
  String get activityCalendar => 'Σύνδεση ημερολογίου';

  @override
  String get activityRig => 'Ενημέρωση περιβλήματος';

  @override
  String get activityEvent => 'Ενημέρωση';

  @override
  String get activityPrReady => 'Το pull request είναι έτοιμο για συγχώνευση';

  @override
  String get activityPrBlocked => 'Η συγχώνευση του pull request αποκλείστηκε';

  @override
  String get activityPrApproved => 'Το pull request εγκρίθηκε';

  @override
  String get activityPrChanges => 'Ζητήθηκαν αλλαγές';

  @override
  String get activityPrChecksFailed => 'Οι έλεγχοι του pull request απέτυχαν';

  @override
  String get activityPrChecksRecovered =>
      'Οι έλεγχοι του pull request είναι ξανά επιτυχείς';

  @override
  String get activityPrComment => 'Σχόλιο σε pull request';

  @override
  String get activityPrPublished => 'Το pull request δημοσιεύτηκε';

  @override
  String get activityPrMerged => 'Το pull request συγχωνεύθηκε';

  @override
  String get activityPrMentioned => 'Αναφορά σε εσάς σε pull request';

  @override
  String get activityPrReviewRequested => 'Ζητήθηκε ανασκόπηση';

  @override
  String get activityPrReviewStale => 'Απαιτείται ανανέωση ανασκόπησης';

  @override
  String get activityTicketAssigned => 'Ανατέθηκε εισιτήριο';

  @override
  String get activityTicketChanged => 'Άλλαξε η κατάσταση εισιτηρίου';

  @override
  String get activityMeetingSoon => 'Η σύσκεψη ξεκινά σύντομα';

  @override
  String get activityCalendarExpired => 'Η σύνδεση ημερολογίου έληξε';

  @override
  String get activityRigControl => 'Ο έλεγχος του περιβλήματος άλλαξε';

  @override
  String get activityRigClosed => 'Το περιβάλλον απομόνωσης σταμάτησε';

  @override
  String get mobileSpacesSearch => 'Αναζήτηση χώρων';

  @override
  String get mobileSpacesArchived => 'Αρχειοθετημένο';

  @override
  String get mobileSpacesActive => 'Ενεργός';

  @override
  String get mobileSpacesNew => 'Νέος χώρος';

  @override
  String get mobileSpacesManage => 'Διαχείριση χώρου';

  @override
  String get mobileSpacesName => 'Όνομα χώρου';

  @override
  String get mobileSpacesAgents => 'Πράκτορες';

  @override
  String get mobileSpacesMembers => 'Άτομα';

  @override
  String get mobileSpacesRepos => 'Αποθετήρια';

  @override
  String get mobileSpacesAllRepos => 'Όλα τα συνδεδεμένα αποθετήρια';

  @override
  String get mobileSpacesNoRepos => 'Δεν υπάρχουν αποθετήρια';

  @override
  String get mobileSpacesBaseBranch => 'Κλάδος βάσης (προαιρετικό)';

  @override
  String get mobileSpacesDefaultBranch => 'Προεπιλεγμένος κλάδος';

  @override
  String get mobileSpacesMode => 'Λειτουργία';

  @override
  String get mobileSpacesModeChat => 'Συνομιλία';

  @override
  String get mobileSpacesModeReview => 'Ανασκόπηση (μόνο για ανάγνωση)';

  @override
  String get mobileSpacesModePlan => 'Σχέδιο (μόνο για ανάγνωση)';

  @override
  String get mobileSpacesModeOrchestrate => 'Ενορχήστρωση';

  @override
  String get mobileSpacesAutonomy => 'Ειδική ρύθμιση αυτονομίας';

  @override
  String get mobileSpacesAutonomyInherited => 'Κληρονομημένο';

  @override
  String get mobileSpacesAutonomyPropose => 'Μόνο πρόταση';

  @override
  String get mobileSpacesAutonomyApproval => 'Ενέργεια με έγκριση';

  @override
  String get mobileSpacesAutonomyFreely => 'Ελεύθερη ενέργεια';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Η ειδική ρύθμιση δεν παρακάμπτει αιτήματα έγκρισης ή απαγορεύσεις της πολιτικής ενεργειών. Μόνο οι διαχειριστές του χώρου εργασίας μπορούν να την αλλάξουν.';

  @override
  String get mobileSpacesArchive => 'Αρχειοθέτηση χώρου';

  @override
  String get mobileSpacesReopen => 'Επανάνοιγμα χώρου';

  @override
  String get mobileSpacesSave => 'Αποθήκευση αλλαγών';

  @override
  String get mobileSpacesCreate => 'Δημιουργία χώρου';

  @override
  String get mobileSpacesOperationFailed =>
      'Δεν ήταν δυνατή η ενημέρωση του χώρου';

  @override
  String get mobileSpacesMissing =>
      'Ο χώρος δεν βρέθηκε σε αυτόν τον χώρο εργασίας';

  @override
  String get mobileSpacesEmptyName => 'Απαιτείται όνομα χώρου';

  @override
  String get mobileSpacesNoMatches => 'Δεν βρέθηκαν χώροι που να ταιριάζουν';

  @override
  String get mobileSpacesUnread => 'Μη αναγνωσμένη απάντηση πράκτορα';

  @override
  String get mobileSpacesNeedsInput => 'Απαιτείται παρέμβαση';

  @override
  String get mobileSpacesRunning => 'Πράκτορας σε εκτέλεση';

  @override
  String get mobileSpacesNoAgents =>
      'Δεν υπάρχουν πράκτορες σε αυτόν τον χώρο εργασίας';

  @override
  String get mobileSpacesNoMembers =>
      'Δεν υπάρχουν άλλα μέλη στον χώρο εργασίας';

  @override
  String get mobileSpacesRepoError =>
      'Δεν ήταν δυνατή η φόρτωση των αποθετηρίων';

  @override
  String get mobileSpacesRetry => 'Επανάληψη';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Επιλέξτε ή πληκτρολογήστε έναν κλάδο βάσης κατά τη δημιουργία του χώρου. Ο κλάδος βάσης δεν μπορεί να αλλάξει σε υπάρχοντες χώρους.';

  @override
  String get mobileSpacesArchivedEmpty => 'Δεν υπάρχουν αρχειοθετημένοι χώροι';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Τα αποθετήρια που θα συνδεθούν μελλοντικά στον χώρο εργασίας θα συμπεριληφθούν επίσης σε αυτόν τον χώρο.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Ο χώρος δημιουργήθηκε. Δοκιμάστε ξανά την προσθήκη ατόμων ή ανοίξτε τη σελίδα διαχείρισής του.';

  @override
  String get progressTitle => 'Πρόοδος';

  @override
  String get progressConversation => 'Συνομιλία';

  @override
  String get progressLoadFailed => 'Δεν ήταν δυνατή η φόρτωση της προόδου';

  @override
  String get progressUnavailable => 'Η συνομιλία δεν είναι διαθέσιμη';

  @override
  String get progressUnavailableDescription =>
      'Αυτή η συνομιλία δεν ανήκει στον ενεργό χώρο εργασίας και στον ενεργό χώρο. Επιστρέψτε στον χώρο της για να συνεχίσετε.';

  @override
  String get progressSaveFailed => 'Δεν ήταν δυνατή η ενημέρωση της προόδου';

  @override
  String get progressGoal => 'Στόχος';

  @override
  String get progressNoGoal => 'Δεν έχει οριστεί στόχος εργασίας';

  @override
  String get progressSetGoal => 'Ορισμός στόχου';

  @override
  String get progressEditGoal => 'Επεξεργασία στόχου';

  @override
  String get progressClearGoal => 'Καθαρισμός στόχου';

  @override
  String get progressGoalRequired =>
      'Απαιτείται στόχος πριν από την αποθήκευση.';

  @override
  String get progressTodos => 'Εργασίες';

  @override
  String get progressNoTodos => 'Δεν υπάρχουν ακόμη εργασίες';

  @override
  String get progressNewTodo => 'Νέα εργασία';

  @override
  String get progressAddTodo => 'Προσθήκη εργασίας';

  @override
  String get progressEditTodo => 'Επεξεργασία εργασίας';

  @override
  String get progressTodoRequired =>
      'Απαιτείται εργασία πριν από την αποθήκευση.';

  @override
  String get progressTodoNoLongerExists =>
      'Η εργασία αφαιρέθηκε. Φορτώστε ξανά τη λίστα και δοκιμάστε ξανά.';

  @override
  String get progressWorkspaceChanged =>
      'Ο ενεργός χώρος εργασίας άλλαξε. Επιστρέψτε σε αυτή τη συνομιλία και δοκιμάστε ξανά.';

  @override
  String progressRemoveTodo(String name) {
    return 'Αφαίρεση εργασίας $name';
  }

  @override
  String get progressPending => 'Εκκρεμεί';

  @override
  String get progressInProgress => 'Σε εξέλιξη';

  @override
  String get progressCompleted => 'Ολοκληρώθηκε';

  @override
  String get progressMoveUp => 'Μετακίνηση εργασίας πάνω';

  @override
  String get progressMoveDown => 'Μετακίνηση εργασίας κάτω';

  @override
  String get progressRunTree => 'Εκτελέσεις πρακτόρων';

  @override
  String get progressNoRuns =>
      'Δεν υπάρχουν ακόμη εκτελέσεις σε αυτή τη συνομιλία';

  @override
  String get progressRunning => 'Σε εκτέλεση';

  @override
  String get progressFailed => 'Αποτυχία';

  @override
  String get progressUnknown => 'Άγνωστο';

  @override
  String get progressHealthy => 'Ενεργός';

  @override
  String get progressBlocked => 'Αποκλεισμένος';

  @override
  String get progressLooping => 'Σε βρόχο';

  @override
  String get progressStalled => 'Σε στασιμότητα';

  @override
  String get progressDead => 'Διακόπηκε απροσδόκητα';

  @override
  String get progressQuiet => 'Δεν υπάρχει ακόμη έξοδος';

  @override
  String get progressCostReported => 'Χρέωση που αναφέρει ο πάροχος';

  @override
  String get progressCostNotional =>
      'Ενδεικτική τιμή καταλόγου συνδρομής· δεν αποτελεί χρέωση';

  @override
  String get progressCostMixed => 'Μικτές πηγές κόστους';

  @override
  String get progressCostEstimated => 'Εκτιμώμενο κόστος';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds δ.';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Μοντέλο: $model · Χρόνος: $duration · Κόστος: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Ξεκίνησε $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Κατάσταση λειτουργίας: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Είσοδος: $input · Έξοδος: $output διακριτικά';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Εμφανίζονται μόνο οι πρώτοι 6.000 χαρακτήρες της δομημένης εξόδου.';

  @override
  String progressRetryOf(String runId) {
    return 'Επανάληψη της εκτέλεσης $runId';
  }

  @override
  String get progressContext => 'Πλαίσιο και όρια';

  @override
  String get progressNoAgent => 'Δεν υπάρχει πράκτορας για έλεγχο';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window διακριτικά';
  }

  @override
  String get progressMeasured =>
      'Πλαίσιο που ανέφερε ο πάροχος στην τελευταία κλήση';

  @override
  String get progressEstimated =>
      'Εκτίμηση βάσει της αποθηκευμένης συνομιλίας και του μόνιμου πλαισίου';

  @override
  String get progressContextUnknown =>
      'Δεν έχει αναφερθεί ακόμη η χρήση πλαισίου';

  @override
  String progressContextPercent(String percent) {
    return '$percent% του παραθύρου πλαισίου';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Ορισμένο μηνιαίο όριο πράκτορα: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Αποθηκευμένη ενεργή συνομιλία: περίπου $tokens διακριτικά';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Μόνιμο πλαίσιο για $agent · $model';
  }

  @override
  String get progressContextSystem => 'Προτροπή συστήματος';

  @override
  String get progressContextRules => 'Κανόνες';

  @override
  String get progressContextSkills => 'Δεξιότητες';

  @override
  String get progressContextTools => 'Ορισμοί εργαλείων';

  @override
  String get progressContextMcp => 'Εργαλεία MCP';

  @override
  String get progressContextDeferred => 'Εργαλεία σε αναβολή';

  @override
  String get progressContextSubagents => 'Υποπράκτορες';

  @override
  String get progressContextRunner => 'Εξωτερικό περιβάλλον εκτέλεσης';

  @override
  String get progressContextMemory => 'Μνήμη';

  @override
  String get progressContextHistory => 'Ιστορικό συνομιλίας';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens διακριτικά';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens διακριτικά';
  }

  @override
  String get progressOutputs => 'Πρόσφατα αποτελέσματα';

  @override
  String get progressNoOutputs =>
      'Δεν υπάρχουν πρόσφατα αποτελέσματα πρακτόρων';

  @override
  String get progressStructuredOutputsAbove =>
      'Τα δομημένα αποτελέσματα εμφανίζονται στις εκτελέσεις πρακτόρων παραπάνω.';

  @override
  String get progressRecentOutputsOnly =>
      'Εμφανίζονται μόνο πρόσφατα μηνύματα. Οι παλαιότερες εργασίες είναι διαθέσιμες στη συνομιλία.';

  @override
  String get progressPlan => 'Σχέδιο';

  @override
  String get progressArtifact => 'Τεχνούργημα';

  @override
  String get progressResult => 'Αποτέλεσμα';

  @override
  String get progressHideArtifact => 'Απόκρυψη τεχνουργήματος';

  @override
  String get progressReadArtifact => 'Ανάγνωση τεχνουργήματος';

  @override
  String get progressArtifactUnavailable =>
      'Το τεχνούργημα δεν είναι πλέον διαθέσιμο';

  @override
  String get progressArtifactPreviewLimited =>
      'Εμφανίζεται περιορισμένη προεπισκόπηση του τεχνουργήματος.';

  @override
  String get progressDiagramSource => 'Πηγαίος κώδικας διαγράμματος';

  @override
  String progressOpenAttachment(String name) {
    return 'Άνοιγμα $name';
  }

  @override
  String get progressOpenPlan => 'Άνοιγμα σχεδίου';

  @override
  String progressOpenDiff(String label) {
    return 'Ανασκόπηση τροποποιημένων αρχείων: $label';
  }

  @override
  String get progressViewMessage => 'Προβολή μηνύματος';

  @override
  String get pushTitle => 'Ειδοποιήσεις παρασκηνίου';

  @override
  String get pushIntro =>
      'Ιδιωτικές ειδοποιήσεις όταν κάτι χρειάζεται προσοχή, ακόμη κι όταν η εφαρμογή είναι κλειστή. Οι λεπτομέρειες παραμένουν εντός της κρυπτογραφημένης σύνδεσης.';

  @override
  String get pushLoading => 'Έλεγχος ρυθμίσεων ειδοποιήσεων…';

  @override
  String get pushError =>
      'Δεν ήταν δυνατή η ενημέρωση των ειδοποιήσεων. Ελέγξτε τη σύνδεση και δοκιμάστε ξανά.';

  @override
  String get pushEnable => 'Ενεργοποίηση ειδοποιήσεων';

  @override
  String get pushDisable => 'Απενεργοποίηση ειδοποιήσεων';

  @override
  String get pushQuiet => 'Παύση ειδοποιήσεων σε αυτή τη συσκευή';

  @override
  String get pushCategories => 'Ειδοποιήσεις για';

  @override
  String get pushCategoryAgents => 'Πράκτορες';

  @override
  String get pushCategoryMessages => 'Μηνύματα';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Εισιτήρια';

  @override
  String get pushCategoryCalendar => 'Ημερολόγιο';

  @override
  String get pushCategoryMachines => 'Μηχανήματα';

  @override
  String get pushSecureOrigin => 'Οι ειδοποιήσεις απαιτούν HTTPS.';

  @override
  String get pushInstallIos =>
      'Σε iPhone ή iPad, προσθέστε την εφαρμογή στην οθόνη Αφετηρίας και ανοίξτε την από εκεί για να ενεργοποιηθούν οι ειδοποιήσεις.';

  @override
  String get pushUnsupported =>
      'Αυτό το πρόγραμμα περιήγησης δεν υποστηρίζει ειδοποιήσεις παρασκηνίου.';

  @override
  String get pushDenied =>
      'Οι ειδοποιήσεις έχουν αποκλειστεί στις ρυθμίσεις του προγράμματος περιήγησης. Επιτρέψτε τις από εκεί για να συνεχίσετε.';

  @override
  String get pushResubscribe => 'Επανασύνδεση ειδοποιήσεων';

  @override
  String get pushStatusEnabled =>
      'Οι ειδοποιήσεις είναι ενεργοποιημένες σε αυτή τη συσκευή.';

  @override
  String get pushStatusDisabled =>
      'Οι ειδοποιήσεις είναι απενεργοποιημένες σε αυτή τη συσκευή.';

  @override
  String get credentialsTitle => 'Συνδέσεις και διαπιστευτήρια';

  @override
  String get credentialsIntro =>
      'Συνδέστε τους λογαριασμούς που χρησιμοποιούν οι εκτελέσεις και οι ενσωματώσεις σας. Τα απόρρητα στοιχεία αποθηκεύονται στον διακομιστή σας, όχι σε αυτό το τηλέφωνο.';

  @override
  String get credentialsModelProviders => 'Πάροχοι μοντέλων';

  @override
  String get credentialsOwnerOnly =>
      'Μόνο ο ιδιοκτήτης του διακομιστή μπορεί να προσθέσει ή να αφαιρέσει διαπιστευτήρια παρόχων μοντέλων ή να συνδεθεί με αυτά. Αυτά τα κλειδιά χρησιμοποιούνται από κοινού σε όλους τους χώρους εργασίας.';

  @override
  String get credentialsContactOwner =>
      'Ζητήστε από τον ιδιοκτήτη του διακομιστή να συνδέσει τον πάροχο που χρειάζεται η αποκλεισμένη εκτέλεσή σας.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Η σύνδεση στο Claude Code γίνεται μέσω του CLI στον κεντρικό υπολογιστή. Ζητήστε από τον ιδιοκτήτη του διακομιστή να ολοκληρώσει ή να ανανεώσει τη σύνδεση του λογαριασμού από το τερματικό του. Αυτό δεν μπορεί να γίνει από το τηλέφωνο.';

  @override
  String get credentialsYourForgeAccounts =>
      'Οι λογαριασμοί σας σε πλατφόρμες κώδικα';

  @override
  String get credentialsYourTicketingAccount =>
      'Ο λογαριασμός σας στην υπηρεσία εισιτηρίων';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Τα τοπικά εισιτήρια δεν απαιτούν σύνδεση. Συνδέστε εδώ το Linear, αν το χρησιμοποιεί ο χώρος εργασίας σας.';

  @override
  String get credentialsMembershipRequired =>
      'Για να διαχειριστείτε τα διαπιστευτήρια πλατφορμών κώδικα ή υπηρεσιών εισιτηρίων, πρέπει να ανήκετε σε έναν χώρο εργασίας. Ζητήστε πρόσβαση από έναν διαχειριστή.';

  @override
  String get credentialsSwitchWorkspace =>
      'Αυτός ο σύνδεσμος οδηγεί σε άλλον χώρο εργασίας. Μεταβείτε σε εκείνον πριν αλλάξετε διαπιστευτήρια.';

  @override
  String get credentialsReturnToInbox =>
      'Επιστρέψτε στα Εισερχόμενα για να επαναλάβετε μια αποκλεισμένη εκτέλεση μόλις συνδεθούν τα διαπιστευτήριά της. Ο κεντρικός υπολογιστής ελέγχει αυτόματα και τις εκτελέσεις σε αναμονή.';

  @override
  String get credentialsLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των συνδέσεων. Ελέγξτε τη σύνδεση με τον διακομιστή και δοκιμάστε ξανά.';

  @override
  String get credentialsOperationFailed =>
      'Δεν ήταν δυνατή η αλλαγή αυτής της σύνδεσης. Ελέγξτε τη σύνδεση με τον διακομιστή, τα δικαιώματά σας και τα διαπιστευτήρια και δοκιμάστε ξανά.';

  @override
  String get credentialsConnected => 'Συνδεδεμένο';

  @override
  String get credentialsNotConnected => 'Δεν είναι συνδεδεμένο';

  @override
  String credentialsSignedInAs(String username) {
    return 'Σύνδεση ως $username';
  }

  @override
  String get credentialsAccount => 'Συνδεδεμένος λογαριασμός';

  @override
  String get credentialsStoredKey => 'Αποθηκευμένο κλειδί';

  @override
  String get credentialsActive => 'Ενεργός';

  @override
  String get credentialsRemove => 'Αφαίρεση';

  @override
  String get credentialsRemoveConfirm =>
      'Να αφαιρεθούν τα αποθηκευμένα διαπιστευτήριά σας; Ενδέχεται να χρειαστεί να συνδεθείτε ξανά.';

  @override
  String get credentialsApiKey => 'Κλειδί API';

  @override
  String get credentialsApiKeyHint => 'Επικολλήστε ένα κλειδί API παρόχου';

  @override
  String get credentialsBrowserLogin => 'Σύνδεση μέσω προγράμματος περιήγησης';

  @override
  String get credentialsSignInAgain => 'Συνδεθείτε ξανά';

  @override
  String get credentialsWaitingForLogin =>
      'Αναμονή έγκρισης στο πρόγραμμα περιήγησης…';

  @override
  String get credentialsLoginTimedOut =>
      'Η διαδικασία σύνδεσης έληξε. Ξεκινήστε νέα προσπάθεια σύνδεσης.';

  @override
  String get credentialsCopyCode => 'Αντιγραφή κωδικού';

  @override
  String get credentialsDeviceCodeHint =>
      'Επιβεβαιώστε αυτόν τον κωδικό στη σελίδα του παρόχου. Αφήστε αυτή την οθόνη ανοιχτή όσο ο διακομιστής ολοκληρώνει τη σύνδεση.';

  @override
  String get credentialsPasteRedirect =>
      'Κωδικός εξουσιοδότησης ή URL ανακατεύθυνσης';

  @override
  String get credentialsPasteRedirectHint =>
      'Επικολλήστε τον κωδικό ή το πλήρες URL ανακατεύθυνσης από τον πάροχο';

  @override
  String get credentialsCompleteLogin => 'Ολοκλήρωση σύνδεσης';

  @override
  String get credentialsRedirectUnavailable =>
      'Η διεύθυνση επιστροφής του διακομιστή για το πρόγραμμα περιήγησης δεν είναι ασφαλώς προσβάσιμη από τηλέφωνο. Ζητήστε από τον ιδιοκτήτη του διακομιστή να ρυθμίσει μια δημόσια διεύθυνση επιστροφής HTTPS ή προσθέστε ένα token.';

  @override
  String get credentialsUpdateToken => 'Ενημέρωση token';

  @override
  String get credentialsAddToken => 'Προσθήκη token';

  @override
  String get credentialsPersonalToken => 'Προσωπικό token πρόσβασης';

  @override
  String get credentialsPersonalTokenHint =>
      'Επικολλήστε ένα προσωπικό token πρόσβασης';

  @override
  String get credentialsHostManaged =>
      'Αυτή η σύνδεση προέρχεται από την εφαρμογή ή το περιβάλλον του διακομιστή. Μόνο ο ιδιοκτήτης του διακομιστή μπορεί να την αλλάξει εκεί. Μπορείτε πάντως να προσθέσετε το δικό σας token.';

  @override
  String get credentialsStopWatching => 'Διακοπή παρακολούθησης';
}
