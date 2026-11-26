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
  String get teammate => 'Συνάδελφος';

  @override
  String get systemSender => 'Σύστημα';

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
  String get sentAttachmentUnavailable => 'Το συνημμένο δεν είναι διαθέσιμο';

  @override
  String get sentAttachmentLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση του συνημμένου';

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
  String get mobilePrSelectCommentLine => 'Επιλέξτε γραμμή για σχολιασμό';

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
  String get permissionPrPublish => 'Ενημέρωση ή συγχώνευση pull requests';

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
  String get permissionRemembered => 'Προσωρινή έγκριση';

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
  String permissionTools(String tools) {
    return 'Εργαλεία: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Χωρίς ισχύ όσο αυτή η ενέργεια είναι σε Απόρριψη';

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
  String mobileGoalFailures(String count) {
    return 'Διαδοχικές αποτυχημένες εκτελέσεις: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Ο επόπτης σταμάτησε μετά από επανειλημμένες αποτυχημένες εκτελέσεις. Οι λεπτομέρειες είναι διαθέσιμες στη συνομιλία.';

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
  String get transcriptToolTodos => 'Εργασίες';

  @override
  String get transcriptToolSearchMemory => 'Αναζήτηση στη μνήμη';

  @override
  String get transcriptToolRenderMedia => 'Απόδοση πολυμέσων';

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
      'Το πρόγραμμα περιήγησης αναφέρει ότι οι ειδοποιήσεις αποκλείονται. Ελέγξτε την άδεια του ιστότοπου και τις ρυθμίσεις ειδοποιήσεων του προγράμματος περιήγησης ή της συσκευής και έπειτα ανανεώστε.';

  @override
  String get pushOsHint =>
      'Το πρόγραμμα περιήγησης χρειάζεται επίσης άδεια εμφάνισης ειδοποιήσεων από τις ρυθμίσεις συστήματος της συσκευής σας.';

  @override
  String get pushServiceUnavailable =>
      'Η υπηρεσία push του προγράμματος περιήγησης απέρριψε τη συνδρομή. Ορισμένα προγράμματα περιήγησης, όπως το Brave, την απενεργοποιούν από προεπιλογή: αναζητήστε μια επιλογή μηνυμάτων push στις ρυθμίσεις απορρήτου και δοκιμάστε ξανά.';

  @override
  String get pushWorkerUnavailable =>
      'Δεν ήταν δυνατή η εκκίνηση της υπηρεσίας ειδοποιήσεων σε αυτό το πρόγραμμα περιήγησης. Φορτώστε ξανά τη σελίδα και δοκιμάστε ξανά.';

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
  String get credentialsConnectCodePrompt => 'Κωδικός επιβεβαίωσης';

  @override
  String get credentialsConnectCodeMalformed =>
      'Αυτό δεν μοιάζει με κωδικό σύνδεσης. Οι κωδικοί έχουν 8 γράμματα και ψηφία.';

  @override
  String get credentialsSignInInvalidCode =>
      'Αυτός ο κωδικός δεν αντιστοιχεί σε αυτή τη σύνδεση. Ελέγξτε τον και δοκιμάστε ξανά.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Πάρα πολλοί λανθασμένοι κωδικοί. Ξεκινήστε ξανά τη σύνδεση.';

  @override
  String get credentialsSignInRetryLater =>
      'Η υπηρεσία σύνδεσης δεν αποκρίνεται αυτή τη στιγμή. Περιμένετε ένα λεπτό και δοκιμάστε ξανά.';

  @override
  String get credentialsSignInRefused =>
      'Η σύνδεση απορρίφθηκε. Ξεκινήστε την ξανά και εγκρίνετε όλα τα ζητούμενα δικαιώματα.';

  @override
  String get credentialsSignInNotSaved =>
      'Η σύνδεση πέτυχε, αλλά ο διακομιστής δεν μπόρεσε να την αποθηκεύσει. Δοκιμάστε ξανά.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Η σύνδεση στο $provider δεν έχει ρυθμιστεί ακόμη σε αυτόν τον διακομιστή.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Η διεύθυνση επιστροφής σύνδεσης αυτού του διακομιστή δεν είναι προσβάσιμη με ασφάλεια από τηλέφωνο. Συνδεθείτε από την εφαρμογή υπολογιστή ή ζητήστε από τον κάτοχο του διακομιστή να ρυθμίσει μια δημόσια διεύθυνση HTTPS.';

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
  String get credentialsUpdateToken => 'Ενημέρωση token';

  @override
  String get credentialsAddToken => 'Προσθήκη token';

  @override
  String get credentialsPersonalToken => 'Προσωπικό token πρόσβασης';

  @override
  String get credentialsPersonalTokenHint =>
      'Επικολλήστε ένα προσωπικό token πρόσβασης';

  @override
  String get credentialsStopWatching => 'Διακοπή παρακολούθησης';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Η σύνδεση στο Claude Code έληξε';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Η εκτέλεση σταμάτησε επειδή ο λογαριασμός της δεν πιστοποιείται πλέον. Συνδεθείτε ξανά και επαναλάβετε τον γύρο.';

  @override
  String get transcriptSignInExpiredTitle => 'Η σύνδεση στον πάροχο έληξε';

  @override
  String get transcriptSignInExpiredBody =>
      'Η εκτέλεση σταμάτησε επειδή τα διαπιστευτήρια του παρόχου δεν λειτουργούν πλέον. Συνδέστε τον ξανά στις Ρυθμίσεις → Πάροχοι και επαναλάβετε τον γύρο.';

  @override
  String get permissionHostExecution =>
      'Εκτέλεση εντολών στον κεντρικό υπολογιστή';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Η σύνδεσή σας στο $provider έληξε. Συνδεθείτε ξανά.';
  }

  @override
  String get credentialsSignInPaused =>
      'Σε παύση: η υπηρεσία σύνδεσης αυτού του χώρου εργασίας άλλαξε. Θα λειτουργήσει ξανά μόλις επιστρέψει η υπηρεσία.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'Δεν είναι δυνατή η επικοινωνία με το $provider αυτή τη στιγμή. Γίνεται νέα προσπάθεια.';
  }

  @override
  String get credentialsScopeWorkspace => 'Μόνο αυτός ο χώρος εργασίας';

  @override
  String get credentialsScopeAllWorkspaces => 'Όλοι οι χώροι εργασίας';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Αφαίρεση των αποθηκευμένων διαπιστευτηρίων σας από αυτόν τον χώρο εργασίας; Οι άλλοι κρατούν τα δικά τους.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Αφαίρεση των αποθηκευμένων διαπιστευτηρίων σας από κάθε χώρο εργασίας που τα μοιράζεται;';

  @override
  String get credentialsSignInServerRestarted =>
      'Ο διακομιστής επανεκκινήθηκε. Ξεκινήστε ξανά τη σύνδεση.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Εγκαταστήστε το GitHub App στο $owner ώστε ο αυτοματισμός να φτάνει στα $names. Πατήστε για άνοιγμα του GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'Το GitHub App δεν είναι εγκατεστημένο στο $owner, οπότε ο αυτοματισμός δεν φτάνει στα $names. Ζητήστε από έναν διαχειριστή του χώρου εργασίας να το εγκαταστήσει.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Προσθέστε τα $names στα αποθετήρια του GitHub App. Πατήστε για άνοιγμα του GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'Το GitHub App δεν βλέπει ακόμη τα $names. Ζητήστε από έναν διαχειριστή του χώρου εργασίας να τα προσθέσει στα αποθετήριά του.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Η εγκατάσταση του GitHub App έχει ανασταλεί. Ο αυτοματισμός για τα $names είναι σε παύση μέχρι ένας κάτοχος του λογαριασμού να συνεχίσει την εγκατάσταση στο GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Το άτομο που είναι υπεύθυνο για τον αυτοματισμό αυτού του χώρου εργασίας δεν βλέπει πια τα $names, οπότε τίποτα δεν εκτελείται εκεί για λογαριασμό του.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Το άτομο που είναι υπεύθυνο για τον αυτοματισμό αυτού του χώρου εργασίας δεν έχει συνδεθεί στο forge, οπότε ο αυτοματισμός για τα $names περιμένει μέχρι να συνδεθεί.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Δεν ήταν δυνατός ο έλεγχος πρόσβασης στα $names. Γίνεται νέα προσπάθεια.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Συνδεθείτε στο $forge για να δείτε pull requests από $count ακόμη αποθετήρια',
      one:
          'Συνδεθείτε στο $forge για να δείτε pull requests από 1 ακόμη αποθετήριο',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count αποθετήρια είναι κρυφά επειδή ο λογαριασμός σας στο $forge δεν τα βλέπει',
      one:
          '1 αποθετήριο είναι κρυφό επειδή ο λογαριασμός σας στο $forge δεν το βλέπει',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count αποθετήρια είναι κρυφά επειδή δεν έχετε πρόσβαση σε αυτά σε αυτόν τον χώρο εργασίας',
      one:
          '1 αποθετήριο είναι κρυφό επειδή δεν έχετε πρόσβαση σε αυτό σε αυτόν τον χώρο εργασίας',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ελέγχεται η πρόσβασή σας σε $count ακόμη αποθετήρια…',
      one: 'Ελέγχεται η πρόσβασή σας σε 1 ακόμη αποθετήριο…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Email λογαριασμού Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Εισαγάγετε τη διεύθυνση email του λογαριασμού σας Atlassian.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Κανένα διακριτικό αυτοματοποίησης δεν μπορεί να διαβάσει τα $names, οπότε η εργασία στο παρασκήνιο εκεί είναι σε παύση. Ένας διαχειριστής μπορεί να προσθέσει ένα στις Ρυθμίσεις → Αποθετήρια.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Επιβεβαιώστε στο πρόγραμμα περιήγησης, και μετά εισαγάγετε τον κωδικό που εμφανίζει στο πεδίο παρακάτω.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Αυτός ο λογαριασμός είναι ήδη συνδεδεμένος με άλλο άτομο σε αυτόν τον διακομιστή. Συνδεθείτε με διαφορετικό λογαριασμό.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return 'Δεν ήταν δυνατή η επικοινωνία με το $provider για τον έλεγχο αυτού του token. Δοκιμάστε ξανά σε λίγο.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return 'Το $provider δεν αποδέχεται αυτό το token. Ελέγξτε ότι το αντιγράψατε ολόκληρο και ότι δεν έχει ανακληθεί.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Αυτό δεν είναι προσωπικό token. Επικολλήστε ένα προσωπικό access token από τον δικό σας λογαριασμό στο $provider, όχι token έργου, ομάδας, χώρου εργασίας ή bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Στο token λείπει το δικαίωμα $scope, που χρειάζονται η αναθεώρηση και τα σχόλια. Δημιουργήστε ένα που το περιλαμβάνει.';
  }

  @override
  String get credentialsTokenExpired =>
      'Αυτό το token έχει λήξει. Δημιουργήστε ένα νέο και επικολλήστε το εδώ.';

  @override
  String get credentialsSignInRateLimited =>
      'Πάρα πολλά αιτήματα αυτή τη στιγμή. Περιμένετε λίγο και δοκιμάστε ξανά.';

  @override
  String get credentialsSignInCancelled =>
      'Η σύνδεση ακυρώθηκε ή απορρίφθηκε. Ξεκινήστε την ξανά όταν είστε έτοιμοι.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Αυτή η σύνδεση δεν είναι πλέον ανοιχτή: ακυρώθηκε, χρησιμοποιήθηκε ή αντικαταστάθηκε. Ξεκινήστε την ξανά.';

  @override
  String get noWorkspacesYetHint =>
      'Ένας διαχειριστής χώρου εργασίας πρέπει να σας προσκαλέσει, ή ο κάτοχος του διακομιστή μπορεί να δημιουργήσει χώρο εργασίας για εσάς.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return 'Το $repos δείχνει πλέον σε διαφορετικό αποθετήριο στο $forge. Επανασυνδέστε το από την επιφάνεια εργασίας ή την εφαρμογή ιστού για να συνεχίσετε να το χρησιμοποιείτε.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return 'Το $repos δείχνει πλέον σε διαφορετικό αποθετήριο στο $forge. Ένας διαχειριστής χώρου εργασίας πρέπει να το επανασυνδέσει πριν μπορέσει να χρησιμοποιηθεί ξανά.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Οι πράκτορες χρειάζονται sandbox σε αυτόν τον διακομιστή';

  @override
  String get runSandboxUnavailable =>
      'Αυτός ο διακομιστής δεν έχει sandbox, γι\' αυτό μόνο ο κάτοχός του μπορεί να εκτελεί εδώ πράκτορες. Ο κάτοχος μπορεί να εγκαταστήσει το sandbox ή να απενεργοποιήσει την απομόνωση για όλους.';

  @override
  String get scriptToolCalls => 'Κλήσεις εργαλείων';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count κλήσεις',
      one: '1 κλήση',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count σε εκτέλεση';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count επιτυχείς';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count με αποτυχία';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count απορρίφθηκαν';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count ακυρώθηκαν';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count σε ουρά';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count παραλείφθηκαν';
  }

  @override
  String get scriptStepQueued => 'Σε ουρά';

  @override
  String get scriptStepSkipped => 'Παραλείφθηκε';

  @override
  String get scriptGroupLoop => 'Βρόχος';

  @override
  String get scriptGroupEach => 'Για κάθε';

  @override
  String get scriptGroupParallel => 'Παράλληλα';

  @override
  String get scriptGroupFunction => 'Συνάρτηση';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εμφάνιση $count ακόμη κλήσεων',
      one: 'Εμφάνιση 1 ακόμη κλήσης',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Κλήσεις χωρίς θέση στο σενάριο';

  @override
  String get scriptToolComputed => 'Εργαλείο';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Σενάριο';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count γραμμές',
      one: '1 γραμμή',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Σε εκτέλεση';

  @override
  String get scriptStateCompleted => 'Ολοκληρώθηκε';

  @override
  String get scriptStateFailed => 'Απέτυχε';

  @override
  String get scriptStateTimedOut => 'Έληξε ο χρόνος';

  @override
  String get scriptStateCancelled => 'Ακυρώθηκε';

  @override
  String get scriptStateMemoryExceeded => 'Εξάντληση μνήμης';

  @override
  String get scriptStateOutputExceeded => 'Υπερβολική έξοδος';

  @override
  String get scriptStateSandboxError => 'Σφάλμα sandbox';

  @override
  String get scriptStateRefused => 'Απορρίπτεται';

  @override
  String get scriptOriginLine => 'Από ένα σενάριο που εκτελεί ο πράκτορας';

  @override
  String get codeModeTitle => 'Λειτουργία κώδικα';

  @override
  String get codeModeAvailable => 'Διαθέσιμο';

  @override
  String get codeModeUnavailable => 'Μη διαθέσιμο';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Αυτός ο διακομιστής δεν μπορεί να εκτελέσει σενάρια, οπότε οι πράκτορες εδώ καλούν τα εργαλεία τους ένα κάθε φορά. Ο διακομιστής λέει: $reason';
  }

  @override
  String get codeModeNoReason => 'δεν δόθηκε αιτιολογία.';

  @override
  String get workKindUnknown =>
      'Για έναν λόγο που αυτή η έκδοση δεν αναγνωρίζει:';

  @override
  String get workRefusalUnknown => 'Ο διακομιστής απέρριψε αυτό:';

  @override
  String workActionFailed(String error) {
    return 'Δεν λειτούργησε: $error';
  }

  @override
  String get wakeKindStopped =>
      'Κρατήθηκε επειδή ένα άτομο σταμάτησε την εκτέλεση.';

  @override
  String get wakeKindAttempts => 'Η παράδοση απέτυχε τρεις φορές.';

  @override
  String get wakeKindAgentDeleted => 'Ο πράκτορας δεν υπάρχει πια.';

  @override
  String get wakeKindAgentNotDispatchable => 'Ο πράκτορας έχει αποσυρθεί.';

  @override
  String get wakeKindAgentPaused => 'Ο πράκτορας είναι σε παύση.';

  @override
  String get wakeKindPersonRemoved =>
      'Το άτομο για το οποίο ενεργεί έφυγε από τον χώρο εργασίας.';

  @override
  String get wakeKindBudgetBlocked =>
      'Ένας προϋπολογισμός μπλοκάρει μια εκτέλεση.';

  @override
  String get wakeKindTakeOver => 'Ένα άτομο ανέλαβε το worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'Αυτή η συνομιλία ξεκίνησε 30 εκτελέσεις από αφυπνίσεις την τελευταία ώρα.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Αυτός ο χώρος εργασίας ξεκίνησε 300 εκτελέσεις από αφυπνίσεις την τελευταία ώρα.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Η ζωντανή εκτέλεση του πράκτορα εδώ δεν δέχεται είσοδο.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Η ζωντανή εκτέλεση του πράκτορα εδώ λειτουργεί διαφορετικά, γι\' αυτό αυτή ξεκινά τη δική της εκτέλεση μετά από εκείνη.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Η ζωντανή εκτέλεση του πράκτορα εδώ ενεργεί για άλλο άτομο, γι\' αυτό αυτή ξεκινά τη δική της εκτέλεση μετά από εκείνη.';

  @override
  String get wakeKindDispatchRefused => 'Η εκτέλεση δεν μπόρεσε να ξεκινήσει.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Δεν υπάρχει διαθέσιμο sandbox για εκτέλεση μόνο για ανάγνωση.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Το backend αυτού του πράκτορα δεν μπορεί να κρατήσει μια εκτέλεση μόνο για ανάγνωση.';

  @override
  String get wakeKindServerStopped =>
      'Μια επανεκκίνηση του διακομιστή σταμάτησε την εκτέλεση.';

  @override
  String get wakeKindServerRestarted =>
      'Ο διακομιστής επανεκκινήθηκε κατά τη διάρκεια εκτέλεσης ενός ατόμου.';

  @override
  String get wakeKindGuardFailed =>
      'Ένας έλεγχος πριν από την παράδοση απέτυχε.';

  @override
  String get wakeKindLimit =>
      'Αναμονή να επαναφερθεί το όριο χρήσης του παρόχου.';

  @override
  String get wakeKindLimitRunLive =>
      'Αναμονή να τελειώσει η εκτέλεση στο όριο χρήσης.';

  @override
  String get wakeKindWakeMissed =>
      'Χάθηκε όσο ο διακομιστής ήταν εκτός λειτουργίας.';

  @override
  String get wakeKindPipelineRunEnded =>
      'Η εκτέλεση του pipeline της τελείωσε.';

  @override
  String get wakeKindGoalEnded => 'Ο στόχος της τελείωσε.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Ο στόχος της εξάντλησε τον προϋπολογισμό του.';

  @override
  String get wakeKindGoalReviewStale =>
      'Ο στόχος άλλαξε από τότε που ζητήθηκε αυτή η ανασκόπηση.';

  @override
  String get wakeKindGoalPaused => 'Ο στόχος της είναι σε παύση.';

  @override
  String get wakeKindGoalHeld => 'Ο στόχος της είναι σε αναμονή.';

  @override
  String get wakeKindGoalStopped => 'Ο στόχος της διακόπηκε.';

  @override
  String get wakeKindAskSettled => 'Η ερώτηση που απαντά έχει ήδη κλείσει.';

  @override
  String get wakeKindRuleEnded => 'Το χρονοδιάγραμμά της τελείωσε.';

  @override
  String get wakeRefusalNotYours =>
      'Αυτή η αφύπνιση ενεργεί για άλλο άτομο. Μόνο εκείνο μπορεί να την παραδώσει ή να τη συνεχίσει.';

  @override
  String get wakeRefusalSettled => 'Αυτή η αφύπνιση έχει ήδη ολοκληρωθεί.';

  @override
  String get goalRefusalAlreadyActive =>
      'Αυτός ο πράκτορας έχει ήδη έναν ενεργό στόχο.';

  @override
  String get goalRefusalNotInReview =>
      'Αυτός ο στόχος δεν αναμένει ανασκόπηση.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Τα τεκμήρια του στόχου είναι ελλιπή.';

  @override
  String get goalRefusalClaimPending =>
      'Ο ισχυρισμός ότι ολοκληρώθηκε ελέγχεται ακόμα.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Αυτός ο στόχος δεν έχει τμήμα σε εκτέλεση.';

  @override
  String get goalRefusalNotYours =>
      'Μόνο το άτομο που ξεκίνησε αυτόν τον στόχο μπορεί να το κάνει αυτό.';

  @override
  String get goalRefusalNotPaused => 'Βάλτε πρώτα τον στόχο σε παύση.';

  @override
  String get goalRefusalContractInvalid =>
      'Το συμβόλαιο του στόχου δεν μπορεί να διαβαστεί.';

  @override
  String get goalRefusalCheckerUnknown =>
      'Δεν υπάρχει πράκτορας με αυτό το όνομα.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Περισσότεροι από ένας πράκτορες έχουν αυτό το όνομα.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Ο ελεγκτής πρέπει να είναι άλλος πράκτορας από αυτόν που κάνει τη δουλειά.';

  @override
  String get goalRefusalCommandInvalid =>
      'Αυτός ο στόχος δεν μπορεί να διαβαστεί:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Το διάστημα είναι πολύ σύντομο. Επιλέξτε τουλάχιστον ένα λεπτό.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Αυτή η ώρα είναι πολύ σύντομα. Επιλέξτε μεταγενέστερη.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Αυτή η αλυσίδα αφυπνίσεων εξάντλησε τις εκτελέσεις ή τον χρόνο της.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Δεν μπορείτε να διαβάσετε όσα θα παρακολουθούσε αυτό.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Ορίστε μια ημερομηνία λήξης ή έναν αριθμό εκτελέσεων.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Αυτή η συνομιλία ή ο πράκτορας έχει ήδη όσα χρονοδιαγράμματα επιτρέπονται.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Η ώρα δεν μπορεί να διαβαστεί.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Η σημείωση είναι πολύ μεγάλη.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Η λήξη είναι πολύ μακριά.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Ένα όριο εκτελέσεων, ημερών ή προϋπολογισμού είναι εκτός εύρους.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Μόνο ένας βρόχος μπορεί να επιλέξει τη δική του επόμενη ώρα.';

  @override
  String get wakeRuleRefusalWatchRefused =>
      'Αυτό δεν μπορεί να παρακολουθηθεί.';

  @override
  String get wakeRuleRefusalRuleEnded =>
      'Αυτό το χρονοδιάγραμμα έχει ήδη τελειώσει.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Αυτό το χρονοδιάγραμμα ανήκει σε άλλο άτομο.';

  @override
  String get wakeRuleEndFired => 'Εκτελέστηκε η μία φορά της.';

  @override
  String get wakeRuleEndExpired => 'Έφτασε την ημερομηνία λήξης της.';

  @override
  String get wakeRuleEndRunCap => 'Εξάντλησε τις εκτελέσεις της.';

  @override
  String get wakeRuleEndCostCap => 'Έφτασε το όριο κόστους της.';

  @override
  String get wakeRuleEndGoalEnded => 'Ο στόχος της τελείωσε.';

  @override
  String get wakeRuleEndCancelled => 'Ακυρώθηκε.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Το άτομό της έφυγε από τον χώρο εργασίας.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Οι αποθηκευμένες ρυθμίσεις της δεν μπορούσαν να διαβαστούν.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Δουλεύει στο τμήμα $segmentString. Κανείς δεν χρειάζεται να κάνει κάτι.';
  }

  @override
  String get goalHoldWaiting =>
      'Περιμένει δουλειά που της οφείλεται. Συνεχίζει μόνος του.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Περιμένει δουλειά που της οφείλεται. Θα συνεχίσει μόνος του το αργότερο στις $time.';
  }

  @override
  String get goalHoldVerifying =>
      'Δηλώνει ότι τελείωσε. Ο διακομιστής εκτελεί τους ελέγχους του, μετά αποφασίζει ένας ανασκοπητής.';

  @override
  String get goalHoldLimit =>
      'Σε παύση στο όριο χρήσης του παρόχου. Συνεχίζει μόνος του μετά την επαναφορά.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Σε παύση στο όριο χρήσης του παρόχου. Θα συνεχίσει μόνος του στις $time.';
  }

  @override
  String get goalHoldPerson =>
      'Περιμένει να απαντήσει ένα άτομο στη συνομιλία. Συνεχίζει όταν απαντήσει κάποιος.';

  @override
  String get goalHoldByPerson =>
      'Σε παύση από άτομο. Μένει σε παύση μέχρι να τον συνεχίσει κάποιος.';

  @override
  String get goalHoldNeedsReview =>
      'Αναμονή ανασκόπησης: δεν μπορεί να συνεχίσει μόνος του. Εγκρίνετέ τον ως ολοκληρωμένο, συνεχίστε τον ή ακυρώστε τον.';

  @override
  String get goalHoldBudget =>
      'Εξάντλησε τον προϋπολογισμό του. Αυξήστε τον προϋπολογισμό για να συνεχίσει.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Παύσεις λόγω ορίου χρήσης: $countString από $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'Καμία πρόοδος στα τελευταία του τμήματα.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Περίμενε 24 ώρες για την ίδια δουλειά χωρίς πρόοδο.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Ο τελευταίος έλεγχος απέτυχε.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Ο ελεγκτής δεν μπόρεσε να κρίνει αν έχει ολοκληρωθεί.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Δεν υπάρχει διαθέσιμο sandbox για την εκτέλεση των ελέγχων του.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Ο πράκτορας ελεγκτής του δεν είναι διαθέσιμος. Επιλέξτε άλλον ελεγκτή και μετά συνεχίστε.';

  @override
  String get goalHoldDetailCheckBroken =>
      'Αυτός ο έλεγχος δεν μπορεί να εκτελεστεί:';

  @override
  String get goalHoldDetailWakeSkipped => 'Η αφύπνισή του δεν παραδόθηκε.';

  @override
  String get goalHoldDetailClaimPending =>
      'Ο ισχυρισμός ότι ολοκληρώθηκε περιμένει έλεγχο.';

  @override
  String get goalHoldDetailUnanswered =>
      'Μια ερώτηση ή ένα αίτημα έγκρισης προς άτομο έμεινε αναπάντητο.';

  @override
  String get goalHoldDetailLimitParks =>
      'Έφτασε τα όρια χρήσης πολύ συχνά. Ελέγξτε τον και μετά συνεχίστε.';

  @override
  String get goalHoldDetailInput => 'Αναμονή για απάντηση στη συνομιλία.';

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

    return 'Τμήμα $runString από $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Τμήμα $runString, χωρίς όριο';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Δαπάνη $spent από $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Προθεσμία $time';
  }

  @override
  String get goalPipelineStep => 'Ένα βήμα pipeline επιδιώκει αυτόν τον στόχο.';

  @override
  String get goalSummaryHeading => 'Τελευταία σύνοψη';

  @override
  String get goalDoneMeans => 'Ολοκλήρωση σημαίνει';

  @override
  String get goalChecks => 'Έλεγχοι';

  @override
  String get goalBoundaries => 'Όρια';

  @override
  String get goalStopWhen => 'Σταμάτα και ρώτα όταν';

  @override
  String get goalNoMachineCheck =>
      'Χωρίς αυτόματο έλεγχο. Ένας ανασκοπητής κρίνει από όσα μπορεί να διαβάσει.';

  @override
  String get goalCheckEnvironment => 'Εργασία περιβάλλοντος';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Τελευταίος έλεγχος, γύρος $roundString, $time';
  }

  @override
  String get goalClaim => 'Τι ισχυρίστηκε';

  @override
  String get goalCheckPassed => 'Επιτυχής';

  @override
  String goalCheckFailed(int code) {
    return 'Απέτυχε, κωδικός εξόδου $code';
  }

  @override
  String get goalCheckTimedOut => 'Έληξε ο χρόνος';

  @override
  String get goalCheckNotRerun => 'Δεν εκτελέστηκε ξανά: δεν άλλαξε τίποτα';

  @override
  String get goalCheckBroken => 'Δεν μπορεί να εκτελεστεί';

  @override
  String get goalCriterionMet => 'Ικανοποιήθηκε';

  @override
  String get goalCriterionUnmet => 'Δεν ικανοποιήθηκε';

  @override
  String get goalCriterionCannotTell => 'Δεν μπορεί να κριθεί';

  @override
  String get goalVerdictPass => 'Απόφαση: ολοκληρώθηκε';

  @override
  String get goalVerdictFail => 'Απόφαση: δεν ολοκληρώθηκε';

  @override
  String get goalVerdictCannotVerify => 'Απόφαση: δεν μπόρεσε να κριθεί';

  @override
  String get goalConcerns => 'Ανησυχίες';

  @override
  String goalVerifiedBy(String agent) {
    return 'Επαληθεύτηκε από τον $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Επαληθεύτηκε από τον ίδιο (χωρίς ξεχωριστό ελεγκτή)';

  @override
  String get goalClosedByPerson => 'Έκλεισε από άτομο χωρίς επιτυχή έλεγχο';

  @override
  String get goalApprove => 'Έγκριση ολοκλήρωσης';

  @override
  String get goalApproveTitle => 'Να κλείσει αυτός ο στόχος ως ολοκληρωμένος;';

  @override
  String get goalApproveBody =>
      'Κανένας έλεγχος δεν το επιβεβαίωσε. Το κλείνετε με δική σας ευθύνη, και ο στόχος καταγράφει ότι το έκλεισε άτομο χωρίς επαλήθευση.';

  @override
  String get goalApproveConfirm => 'Κλείσιμο ως ολοκληρωμένος';

  @override
  String get goalResumeNotYours =>
      'Η συνέχιση ή η αύξηση του προϋπολογισμού του ανήκει σε όποιον τον ξεκίνησε.';

  @override
  String get goalChooseChecker => 'Επιλέξτε άλλον ελεγκτή';

  @override
  String goalCheckerSet(String agent) {
    return 'Τώρα τον ελέγχει ο $agent. Συνεχίστε για νέα επαλήθευση.';
  }

  @override
  String get goalSchedules => 'Χρονοδιαγράμματα';

  @override
  String get goalRepeat => 'Επανάληψη';

  @override
  String get goalCreateChecks => 'Έλεγχοι (προαιρετικό)';

  @override
  String get goalCreateCheckHint =>
      'Μια εντολή που περνά όταν τελειώσει η δουλειά';

  @override
  String get goalCreateAddCheck => 'Προσθήκη ελέγχου';

  @override
  String get goalCreateRemoveCheck => 'Αφαίρεση ελέγχου';

  @override
  String get goalCreateSegmentCap => 'Όριο τμημάτων (προαιρετικό)';

  @override
  String get goalCreateSegmentInvalid =>
      'Το όριο τμημάτων είναι ακέραιος αριθμός, τουλάχιστον 1.';

  @override
  String get scheduleCreateTitle => 'Επανάληψη μιας εντολής';

  @override
  String get scheduleCadence => 'Πόσο συχνά';

  @override
  String get scheduleEveryMinutes => 'Κάθε N λεπτά';

  @override
  String get scheduleEveryHours => 'Κάθε N ώρες';

  @override
  String get scheduleSelfPaced => 'Με τον ρυθμό του πράκτορα';

  @override
  String get scheduleSelfPacedHint =>
      'Ο πράκτορας επιλέγει την καθυστέρηση μετά από κάθε εκτέλεση, μεταξύ 1 λεπτού και 1 ώρας.';

  @override
  String get scheduleInterval => 'Διάστημα';

  @override
  String get scheduleNote => 'Τι πρέπει να κάνει κάθε εκτέλεση;';

  @override
  String get scheduleCostCap => 'Όριο κόστους σε USD (προαιρετικό)';

  @override
  String get scheduleExpiryDays => 'Λήγει μετά από N ημέρες (προαιρετικό)';

  @override
  String get scheduleCreateInvalid =>
      'Επιλέξτε έναν χώρο και έναν πράκτορα, γράψτε τι πρέπει να κάνει κάθε εκτέλεση, και δώστε ακέραιους αριθμούς τουλάχιστον 1.';

  @override
  String get scheduleCreateButton => 'Έναρξη χρονοδιαγράμματος';

  @override
  String get scheduleCreateConfirmTitle =>
      'Να ξεκινήσει αυτό το χρονοδιάγραμμα;';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εκτελείται κάθε $countString λεπτά, ξεκινώντας τώρα.',
      one: 'Εκτελείται κάθε λεπτό, ξεκινώντας τώρα.',
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
      other: 'Εκτελείται κάθε $countString ώρες, ξεκινώντας τώρα.',
      one: 'Εκτελείται κάθε ώρα, ξεκινώντας τώρα.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Εκτελείται τώρα, και μετά ο πράκτορας επιλέγει πότε θα ξανατρέξει.';

  @override
  String get scheduleCreated =>
      'Το χρονοδιάγραμμα ξεκίνησε. Εμφανίζεται στα Χρονοδιαγράμματα.';

  @override
  String get schedulesTitle => 'Χρονοδιαγράμματα';

  @override
  String get schedulesLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των χρονοδιαγραμμάτων';

  @override
  String get schedulesEmpty =>
      'Δεν υπάρχουν χρονοδιαγράμματα ή παρακολουθήσεις';

  @override
  String get schedulesEmptyDescription =>
      'Επαναλάβετε μια εντολή από την οθόνη στόχων, ή στείλτε /loop ή /schedule σε μια συνομιλία.';

  @override
  String get scheduleMissing =>
      'Αυτό το χρονοδιάγραμμα δεν είναι πια διαθέσιμο σε αυτόν τον χώρο εργασίας.';

  @override
  String scheduleEvery(String interval) {
    return 'Κάθε $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Βρόχος με τον ρυθμό του πράκτορα';

  @override
  String get scheduleCron => 'Χρονοδιάγραμμα cron';

  @override
  String scheduleOnce(String time) {
    return 'Μία φορά στις $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Παρακολούθηση: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'έλεγχοι του pull request';

  @override
  String get scheduleWatchPrReview => 'ανασκοπήσεις του pull request';

  @override
  String get scheduleWatchPrMerged => 'συγχώνευση του pull request';

  @override
  String get scheduleWatchEnvironment => 'περιβάλλον';

  @override
  String get scheduleWatchTicket => 'εισιτήριο';

  @override
  String get scheduleWatchPipelineRun => 'εκτέλεση pipeline';

  @override
  String get scheduleStatusActive => 'Ενεργό';

  @override
  String get scheduleStatusPaused => 'Σε παύση';

  @override
  String get scheduleStatusEnded => 'Έληξε';

  @override
  String scheduleWakes(String agent) {
    return 'Ξυπνά τον $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Επόμενη εκτέλεση $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Τελευταία εκτέλεση $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString εκτελέσεις',
      one: '1 εκτέλεση',
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

    return '$countString από $maxString εκτελέσεις';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString παραλείψεις',
      one: '1 παράλειψη',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Λήγει $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Μέρος αλυσίδας: απομένουν $countString εκτελέσεις, λήγει $time';
  }

  @override
  String get scheduleNoteAgent =>
      'Η δική σημείωση του πράκτορα, με τα δικά του λόγια:';

  @override
  String get scheduleNotePerson => 'Σημείωση ενός ατόμου:';

  @override
  String scheduleActsFor(String name) {
    return 'Ενεργεί για λογαριασμό του $name';
  }

  @override
  String get scheduleActsForBot => 'Δεν ενεργεί για λογαριασμό ατόμου';

  @override
  String get scheduleGoalBound => 'Τελειώνει μαζί με τον στόχο του.';

  @override
  String get schedulePause => 'Παύση';

  @override
  String get scheduleResume => 'Συνέχεια';

  @override
  String get scheduleDelete => 'Διαγραφή';

  @override
  String get scheduleRemove => 'Αφαίρεση';

  @override
  String get scheduleDeleteTitle => 'Διαγραφή αυτού του χρονοδιαγράμματος;';

  @override
  String get scheduleDeleteBody =>
      'Σταματά οριστικά. Ό,τι έχει ήδη κάνει δεν αναιρείται.';

  @override
  String get scheduleRemoveTitle => 'Αφαίρεση αυτού του χρονοδιαγράμματος;';

  @override
  String get scheduleRemoveBody => 'Εξαφανίζεται από τη λίστα.';

  @override
  String get scheduleResumeNotYours =>
      'Μόνο το άτομο για το οποίο ενεργεί αυτό το χρονοδιάγραμμα μπορεί να το συνεχίσει.';

  @override
  String get scheduleResumeAdminOnly =>
      'Μόνο ένας διαχειριστής του χώρου εργασίας μπορεί να συνεχίσει ένα χρονοδιάγραμμα που δεν ανήκει σε άτομο.';

  @override
  String get scheduleOpenConversation => 'Άνοιγμα συνομιλίας';

  @override
  String get progressWaiting => 'Αναμονή';

  @override
  String get progressNothingWaiting => 'Τίποτα δεν περιμένει.';

  @override
  String get wakeOriginGoal => 'Στόχος';

  @override
  String get wakeOriginGoalCheck => 'Έλεγχος στόχου';

  @override
  String get wakeOriginGoalReview => 'Ανασκόπηση στόχου';

  @override
  String get wakeOriginSchedule => 'Χρονοδιάγραμμα';

  @override
  String get wakeOriginWatch => 'Παρακολούθηση';

  @override
  String get wakeOriginReply => 'Απάντηση';

  @override
  String get wakeOriginMessage => 'Μήνυμα';

  @override
  String get wakeOriginWorkFinished => 'Ολοκληρωμένη εργασία';

  @override
  String get wakeOriginLimitReset => 'Επαναφορά ορίου';

  @override
  String get wakeOriginRecovery => 'Ανάκτηση';

  @override
  String get wakeOriginAssignment => 'Ανάθεση';

  @override
  String get wakeOriginPipelineStep => 'Βήμα pipeline';

  @override
  String get wakeOriginImprovementReview => 'Ανασκόπηση βελτιώσεων';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Απάντηση από $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Μήνυμα από $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Ολοκληρωμένη εργασία από $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Για τον $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Προγραμματισμένη για $time';
  }

  @override
  String get wakeDueNow => 'Έφτασε η ώρα';

  @override
  String get wakeHeld => 'Κρατημένη';

  @override
  String wakeExpires(String time) {
    return 'Λήγει $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Προσπάθεια $attemptString';
  }

  @override
  String get wakeCancel => 'Ακύρωση';

  @override
  String get wakeDeliverNow => 'Παράδοση τώρα';

  @override
  String get wakeResume => 'Συνέχεια';

  @override
  String get wakeDismiss => 'Απόρριψη';

  @override
  String get wakeResumeOnlyTheirs =>
      'Μόνο το άτομο του οποίου είναι αυτή η εκτέλεση μπορεί να τη συνεχίσει.';

  @override
  String get wakeRecovery =>
      'Ο διακομιστής επανεκκινήθηκε κατά τη διάρκεια αυτής της εκτέλεσης. Συνεχίστε την ή απορρίψτε την.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Σε παύση στο όριο χρήσης του $provider, που επαναφέρεται στις $time. Η εκτέλεση περιμένει τη Συνέχεια, για έως 7 ημέρες μετά την επαναφορά.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Σε παύση στο όριο χρήσης του παρόχου, που επαναφέρεται στις $time. Η εκτέλεση περιμένει τη Συνέχεια, για έως 7 ημέρες μετά την επαναφορά.';
  }

  @override
  String get limitParkResumeNow => 'Συνέχεια τώρα';

  @override
  String get limitParkCancel => 'Ακύρωση';

  @override
  String limitParkResumed(String provider) {
    return 'Συνεχίστηκε μετά το όριο χρήσης του $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Δεν αναμένει πια στο όριο χρήσης του $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'ο πάροχος';

  @override
  String get mobileHeldMessages => 'Κρατημένα μηνύματα';

  @override
  String get heldSteeringTitle =>
      'Κρατήθηκαν επειδή η εκτέλεση τελείωσε πριν μπορέσει να τα πάρει. Στείλτε τα δικά σας τώρα ή αφαιρέστε τα.';

  @override
  String get heldSteeringRelease => 'Αποστολή κρατημένων μηνυμάτων';

  @override
  String get notifGoalCompleted => 'Ο στόχος ολοκληρώθηκε';

  @override
  String get notifGoalFailed => 'Ο στόχος απέτυχε';

  @override
  String get notifGoalCancelled => 'Ο στόχος ακυρώθηκε';

  @override
  String get notifGoalBudgetExhausted =>
      'Ο στόχος εξάντλησε τον προϋπολογισμό του';

  @override
  String get notifGoalNeedsReview => 'Ένας στόχος περιμένει την ανασκόπησή σας';

  @override
  String get notifGoalNeedsPerson => 'Ένας στόχος σάς χρειάζεται';

  @override
  String get notifGoalOnHold => 'Ένας στόχος είναι σε αναμονή';

  @override
  String get notifWakeRuleEnded => 'Ένα χρονοδιάγραμμα τελείωσε';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString εκκρεμότητες περιμένουν εσάς',
      one: '1 εκκρεμότητα περιμένει εσάς',
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
      other: 'Προτάθηκαν $countString βελτιώσεις',
      one: 'Προτάθηκε μια βελτίωση',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Μια εκτέλεση pipeline είναι σε αναμονή στον προϋπολογισμό της';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Δαπάνη $spent από $cap';
  }

  @override
  String get notifNeedsYou => 'Χρειάζεται εσάς';

  @override
  String get notifDigestGoalReview => 'Ο στόχος περιμένει ανασκόπηση';

  @override
  String get notifDigestGoalPerson => 'Ο στόχος χρειάζεται άτομο';

  @override
  String get notifDigestHeldWake => 'Κρατημένη αφύπνιση';

  @override
  String get notifDigestImprovement => 'Προτεινόμενη βελτίωση';

  @override
  String get wakeKindRulePaused => 'Το χρονοδιάγραμμά της ήταν σε παύση.';

  @override
  String get wakeKindRuleBusy =>
      'Ο πράκτορας ήταν απασχολημένος, και αυτό το χρονοδιάγραμμα παραλείπει μια τέτοια ώρα.';

  @override
  String get wakeKindRuleFolded =>
      'Την αντικατέστησε ένα μεταγενέστερο γεγονός της ίδιας παρακολούθησης.';

  @override
  String get wakeKindRuleSuperseded =>
      'Την αντικατέστησε μια μεταγενέστερη ώρα του χρονοδιαγράμματός της.';

  @override
  String get wakeKindRuleNotified =>
      'Το χρονοδιάγραμμά της στέλνει μόνο ειδοποίηση, γι\' αυτό δεν ξεκίνησε εκτέλεση.';

  @override
  String get wakeKindRuleLimitParked =>
      'Το χρονοδιάγραμμά της περιμένει να επαναφερθεί το όριο χρήσης του παρόχου.';

  @override
  String get improvementRefusalCooldown =>
      'Μια ανασκόπηση βελτιώσεων σε αυτή τη συνομιλία έτρεξε πριν από λίγο. Δοκιμάστε ξανά αργότερα.';

  @override
  String get improvementRefusalQueued =>
      'Μια ανασκόπηση βελτιώσεων αυτής της συνομιλίας περιμένει ήδη να εκτελεστεί.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Αυτός ο πράκτορας δεν είναι πράκτορας αυτού του χώρου εργασίας.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Τα μηνύματα που κρατά το όριο χρήσης δεν μπορούν να σταλούν με το χέρι. Περιμένουν να συνεχιστεί η εκτέλεση που είναι σε παύση.';

  @override
  String limitParkCancelled(String provider) {
    return 'Η αναμονή στο όριο χρήσης του $provider ακυρώθηκε.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Η αναμονή στο όριο χρήσης του $provider έληξε πριν συνεχιστεί η εκτέλεση.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Η εκτέλεση δεν συνεχίστηκε μετά το όριο χρήσης του $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Κρατούνται όσο η εκτέλεση περιμένει την επαναφορά του ορίου χρήσης. Αποστέλλονται όταν το πρόσωπο για το οποίο εκτελείται πατήσει Συνέχεια.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Κρατούνται έως ότου επαναφερθεί το όριο χρήσης στις $time. Αποστέλλονται όταν το πρόσωπο για το οποίο εκτελείται πατήσει Συνέχεια.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Κρατήθηκαν από τον διακομιστή. Μπορείτε να τα αφαιρέσετε.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ξύπνησε ο $agent για $countString αναμένοντα στοιχεία',
      one: 'Ξύπνησε ο $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Μια αφύπνιση για τον $agent χάθηκε όσο ο διακομιστής ήταν εκτός λειτουργίας.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Μια αφύπνιση για τον $agent δεν παραδόθηκε.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Ορίστηκε χρονοδιάγραμμα για τον $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Το χρονοδιάγραμμα του $agent τελείωσε.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Σημείωση χρονοδιαγράμματος από τον $agent:';
  }

  @override
  String get workRowNoteFromPerson =>
      'Σημείωση χρονοδιαγράμματος από ένα άτομο:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Η εντολή $command απορρίφθηκε.';
  }

  @override
  String get workRowCommandRefused => 'Μια εντολή απορρίφθηκε.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person αύξησε το όριο δαπάνης του pipeline από $from σε $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person αύξησε το όριο δαπάνης του pipeline.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Μια αποδεκτή αλλαγή σε αυτή τη δεξιότητα δεν μπόρεσε να ολοκληρωθεί, επειδή η δεξιότητα άλλαξε στο μεταξύ. Η πρόταση επαναφέρθηκε.';

  @override
  String get workRowOpenSchedule => 'Άνοιγμα χρονοδιαγράμματος';

  @override
  String get heldSteeringOthersTitle =>
      'Κρατήθηκαν επειδή η εκτέλεση τελείωσε πριν μπορέσει να τα πάρει. Μόνο το άτομο που έγραψε ένα μήνυμα μπορεί να το στείλει.';

  @override
  String get heldSteeringOnlyYours =>
      'Στέλνει μόνο τα δικά σας μηνύματα. Τα άλλα περιμένουν τα άτομα που τα έγραψαν.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Γράφτηκε από $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Μόνο το άτομο που έγραψε ένα κρατημένο μήνυμα μπορεί να το στείλει, και κανένα από αυτά δεν είναι δικό σας.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Χρειάζεστε πρόσβαση εγγραφής στα αποθετήρια αυτού του χώρου για να κατευθύνετε μια εκτέλεση που ενεργεί για άλλο πρόσωπο.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return 'Το χρονοδιάγραμμα για το $agent τέθηκε σε παύση από $name.';
  }

  @override
  String get goalVerdictObjective => 'Ο αντικειμενικός σκοπός συνολικά';

  @override
  String get notifDigestRequest => 'Αναμένει την απάντησή σας';
}
